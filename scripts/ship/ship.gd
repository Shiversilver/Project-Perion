class_name Ship
extends Node2D
## A combat ship. Movement, flux, shields and damage live here. *Who* flies it
## is decided by a controller (PlayerController or ShipAI) that writes the
## intent fields below every physics tick via think(ship, delta).

signal destroyed(ship: Ship)

const SHIELD_MULT := {
	WeaponData.DamageType.KINETIC: 2.0,
	WeaponData.DamageType.HIGH_EXPLOSIVE: 0.5,
	WeaponData.DamageType.ENERGY: 1.0,
	WeaponData.DamageType.FRAGMENTATION: 0.25,
}
const ARMOR_MULT := {
	WeaponData.DamageType.KINETIC: 0.5,
	WeaponData.DamageType.HIGH_EXPLOSIVE: 2.0,
	WeaponData.DamageType.ENERGY: 1.0,
	WeaponData.DamageType.FRAGMENTATION: 0.25,
}
## Armor never blocks more than 85% of a hit.
const MIN_ARMOR_FACTOR := 0.15
const OVERLOAD_TIME := 4.0
const VENT_RATE_MULT := 2.0
const SHIELD_RAISE_SPEED := 3.0
## Drag applied when no thrust is given, as a fraction of acceleration.
const IDLE_DRAG := 0.15

@export var data: ShipData
var faction := "neutral"
var controller: Node

# --- Intent: written by the controller each tick ---
var thrust := 0.0 ## -1 back .. 1 forward
var strafe := 0.0 ## -1 port .. 1 starboard
var turn := 0.0 ## -1 left .. 1 right
var face_point: Variant = null ## when set, the ship steers to face this point
var aim_point := Vector2.ZERO
var trigger := false
var hold_fire := false
var selected_group := 1
var autofire := {} ## group id -> bool
var wants_shield := false
var request_vent := false
var target: Ship

# --- State ---
var velocity := Vector2.ZERO
var angular_velocity := 0.0
var hull := 0.0
var armor := 0.0
var soft_flux := 0.0
var hard_flux := 0.0
var shield_on := false
var shield_raise := 0.0
var overload_timer := 0.0
var venting := false
var is_dead := false
var weapons: Array[Weapon] = []

var _hit_flash := 0.0
var _overlay: Node2D


func _ready() -> void:
	add_to_group("ships")
	hull = data.max_hull
	armor = data.max_armor
	for mount in data.mounts:
		var weapon := Weapon.new()
		weapon.setup(self, mount)
		add_child(weapon)
		weapons.append(weapon)
	# Shield and status bars draw above the weapon turrets.
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	var ids := group_ids()
	for g in ids:
		autofire[g] = false
	if not ids.is_empty():
		selected_group = ids[0]
	if controller and controller.get_parent() == null:
		add_child(controller)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if controller:
		controller.think(self, delta)
	_update_systems(delta)
	_update_movement(delta)
	_update_weapons(delta)
	_resolve_collisions()
	_hit_flash = maxf(_hit_flash - delta * 4.0, 0.0)
	queue_redraw()
	_overlay.queue_redraw()


# --- Queries ---

func total_flux() -> float:
	return soft_flux + hard_flux


func flux_level() -> float:
	return total_flux() / data.flux_capacity


func is_overloaded() -> bool:
	return overload_timer > 0.0


func shield_radius() -> float:
	return data.radius * 1.35


func is_enemy_of(other: Ship) -> bool:
	return other != null and other.faction != faction


func can_fire(flux_cost: float) -> bool:
	return not is_overloaded() and not venting \
		and total_flux() + flux_cost <= data.flux_capacity


func group_ids() -> Array[int]:
	var ids: Array[int] = []
	for weapon in weapons:
		if not ids.has(weapon.mount.group):
			ids.append(weapon.mount.group)
	ids.sort()
	return ids


func weapons_in_group(group: int) -> Array[Weapon]:
	var result: Array[Weapon] = []
	for weapon in weapons:
		if weapon.mount.group == group:
			result.append(weapon)
	return result


## Distance the AI likes to fight at: just inside its shortest gun range.
func preferred_range() -> float:
	var best := INF
	for weapon in weapons:
		if not weapon.data.is_missile:
			best = minf(best, weapon.data.max_range)
	return 500.0 if best == INF else best * 0.8


func is_shield_facing(point: Vector2) -> bool:
	if not shield_on or is_overloaded() or shield_raise < 0.05:
		return false
	var half_arc := deg_to_rad(data.shield_arc_deg * shield_raise) * 0.5
	var angle := (point - global_position).angle()
	return absf(wrapf(angle - global_rotation, -PI, PI)) <= half_arc


func nearest_enemy(from: Vector2, max_distance := INF) -> Ship:
	var best: Ship = null
	var best_dist := max_distance
	for node in get_tree().get_nodes_in_group("ships"):
		var other := node as Ship
		if other.is_dead or not is_enemy_of(other):
			continue
		var dist := from.distance_to(other.global_position)
		if dist < best_dist:
			best_dist = dist
			best = other
	return best


# --- Flux & damage ---

func spend_flux(amount: float) -> void:
	soft_flux += amount


func add_hard_flux(amount: float) -> void:
	hard_flux += amount
	if total_flux() >= data.flux_capacity:
		_overload()


## Applies a hit. on_shield is decided by the projectile (see is_shield_facing).
func take_hit(damage: float, damage_type: int, on_shield: bool) -> void:
	if is_dead:
		return
	if on_shield:
		add_hard_flux(damage * float(SHIELD_MULT[damage_type]) * data.shield_efficiency)
		return
	var vs_armor := damage * float(ARMOR_MULT[damage_type])
	var factor := 1.0
	if armor > 0.0:
		factor = maxf(MIN_ARMOR_FACTOR, vs_armor / (vs_armor + armor))
		armor = maxf(0.0, armor - vs_armor * factor)
	hull -= damage * factor
	_hit_flash = 1.0
	if hull <= 0.0:
		_die()


func _overload() -> void:
	overload_timer = OVERLOAD_TIME
	shield_on = false
	venting = false
	hard_flux = minf(hard_flux, data.flux_capacity)
	soft_flux = minf(soft_flux, data.flux_capacity - hard_flux)


func _dissipate(amount: float, include_hard: bool) -> void:
	var from_soft := minf(soft_flux, amount)
	soft_flux -= from_soft
	if include_hard:
		hard_flux = maxf(0.0, hard_flux - (amount - from_soft))


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("ships")
	Combat.spawn_explosion(global_position, data.radius)
	destroyed.emit(self)
	queue_free()


# --- Per-tick updates ---

func _update_systems(delta: float) -> void:
	if is_overloaded():
		overload_timer -= delta
		shield_on = false
		_dissipate(data.flux_dissipation * delta, true)
	elif venting:
		shield_on = false
		_dissipate(data.flux_dissipation * VENT_RATE_MULT * delta, true)
		if total_flux() <= 0.5:
			venting = false
	elif request_vent and total_flux() > 0.0:
		venting = true
		shield_on = false
	else:
		shield_on = wants_shield
		if shield_on:
			soft_flux = minf(soft_flux + data.shield_upkeep * delta,
				data.flux_capacity - hard_flux)
		_dissipate(data.flux_dissipation * delta, not shield_on)
	request_vent = false
	var raise_target := 1.0 if shield_on else 0.0
	shield_raise = move_toward(shield_raise, raise_target, SHIELD_RAISE_SPEED * delta)


func _update_movement(delta: float) -> void:
	var forward := Vector2.RIGHT.rotated(rotation)
	var starboard := forward.rotated(PI * 0.5)
	var accel := forward * thrust * data.acceleration * (1.0 if thrust > 0.0 else 0.6)
	accel += starboard * strafe * data.acceleration * 0.6
	velocity += accel * delta
	if is_zero_approx(thrust) and is_zero_approx(strafe):
		velocity = velocity.move_toward(Vector2.ZERO, data.acceleration * IDLE_DRAG * delta)
	velocity = velocity.limit_length(data.max_speed)

	var max_turn := deg_to_rad(data.turn_rate_deg)
	var desired_turn := turn * max_turn
	if face_point != null:
		var point: Vector2 = face_point
		var diff := wrapf((point - global_position).angle() - rotation, -PI, PI)
		desired_turn = clampf(diff * 4.0, -max_turn, max_turn)
	angular_velocity = move_toward(angular_velocity, desired_turn,
		deg_to_rad(data.turn_acceleration_deg) * delta)
	rotation = wrapf(rotation + angular_velocity * delta, -PI, PI)
	position += velocity * delta


func _update_weapons(delta: float) -> void:
	if is_instance_valid(target) and target.is_dead:
		target = null
	for weapon in weapons:
		var group := weapon.mount.group
		var homing := target if is_instance_valid(target) else null
		if group == selected_group:
			if homing == null and weapon.data.is_missile:
				homing = nearest_enemy(aim_point, 400.0)
			weapon.update_weapon(delta, aim_point, trigger and not hold_fire, false, homing)
		elif autofire.get(group, false) and not hold_fire:
			var auto_target := _autofire_target(weapon)
			if auto_target:
				weapon.update_weapon(delta, _lead(weapon, auto_target), true, true, auto_target)
			else:
				weapon.update_weapon(delta, null, false, false, null)
		else:
			weapon.update_weapon(delta, null, false, false, null)


func _autofire_target(weapon: Weapon) -> Ship:
	var reach := weapon.data.max_range * 1.05
	if is_instance_valid(target) and not target.is_dead \
			and weapon.global_position.distance_to(target.global_position) <= reach:
		return target
	return nearest_enemy(weapon.global_position, reach)


## Where to aim so the shot meets the target (projectiles inherit our velocity).
func _lead(weapon: Weapon, other: Ship) -> Vector2:
	if weapon.data.is_missile:
		return other.global_position
	var dist := weapon.global_position.distance_to(other.global_position)
	var time := dist / weapon.data.projectile_speed
	return other.global_position + (other.velocity - velocity) * time


func _resolve_collisions() -> void:
	for node in get_tree().get_nodes_in_group("ships"):
		var other := node as Ship
		if other == self or other.get_instance_id() < get_instance_id():
			continue
		var offset := other.global_position - global_position
		var min_dist := data.radius + other.data.radius
		var dist := offset.length()
		if dist >= min_dist or dist < 0.01:
			continue
		var normal := offset / dist
		var push := (min_dist - dist) * 0.5
		global_position -= normal * push
		other.global_position += normal * push
		var closing := (other.velocity - velocity).dot(normal)
		if closing < 0.0:
			velocity += normal * closing * 0.6
			other.velocity -= normal * closing * 0.6


# --- Drawing (placeholder vector art) ---

func _draw() -> void:
	if data.outline.is_empty():
		return
	if thrust > 0.05 or absf(strafe) > 0.05:
		var flame := 10.0 + 8.0 * maxf(thrust, absf(strafe)) + randf() * 4.0
		for point in data.engine_points:
			draw_colored_polygon(PackedVector2Array([
				point + Vector2(0, -4), point + Vector2(-flame, 0), point + Vector2(0, 4),
			]), Color(0.5, 0.8, 1.0, 0.8))
	var body := data.hull_color
	if _hit_flash > 0.0:
		body = body.lerp(Color(1, 0.9, 0.8), _hit_flash * 0.6)
	if is_overloaded() and int(overload_timer * 10.0) % 2 == 0:
		body = body.lerp(Color(0.6, 0.4, 1.0), 0.5)
	draw_colored_polygon(data.outline, body)
	var closed := data.outline.duplicate()
	closed.append(data.outline[0])
	draw_polyline(closed, data.accent_color, 1.5, true)


func _draw_overlay() -> void:
	if shield_raise > 0.01:
		var half := deg_to_rad(data.shield_arc_deg * shield_raise) * 0.5
		var shield_color := Color(0.4, 0.8, 1.0) if faction == "player" else Color(1.0, 0.5, 0.4)
		_overlay.draw_arc(Vector2.ZERO, shield_radius(), -half, half, 40,
			Color(shield_color, 0.85), 3.0, true)
		_overlay.draw_arc(Vector2.ZERO, shield_radius() - 4.0, -half, half, 40,
			Color(shield_color, 0.2), 6.0, true)
	if faction == "player":
		return
	# Counter-rotate so the status bars stay level on screen.
	_overlay.draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE)
	var width := data.radius * 2.0
	var top := Vector2(-data.radius, -shield_radius() - 14.0)
	_overlay.draw_rect(Rect2(top, Vector2(width, 4)), Color(0, 0, 0, 0.6))
	_overlay.draw_rect(Rect2(top, Vector2(width * hull / data.max_hull, 4)), Color(0.4, 0.9, 0.4))
	top.y += 6.0
	_overlay.draw_rect(Rect2(top, Vector2(width, 3)), Color(0, 0, 0, 0.6))
	_overlay.draw_rect(Rect2(top, Vector2(width * minf(flux_level(), 1.0), 3)), Color(0.6, 0.75, 1.0))
	if is_overloaded():
		_overlay.draw_string(ThemeDB.fallback_font, top + Vector2(0, -12), "OVERLOAD",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.6, 1.0))
