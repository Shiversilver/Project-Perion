class_name Weapon
extends Node2D
## A fitted weapon. Swivels within its mount arc, fires bursts, spends flux
## and ammo. Created by Ship from a WeaponMount.

## Autofire only shoots when the barrel is within this angle of the target.
const AIM_TOLERANCE := 0.1

var data: WeaponData
var mount: WeaponMount
var ship: Ship
var ammo := -1

var _cooldown := 0.0
var _burst_left := 0
var _burst_timer := 0.0
var _burst_target: Ship
var _recoil := 0.0


func setup(p_ship: Ship, p_mount: WeaponMount) -> void:
	ship = p_ship
	mount = p_mount
	data = mount.weapon
	position = mount.offset
	rotation = deg_to_rad(mount.facing_deg)
	ammo = data.max_ammo


## aim_at: world point to track, or null to return to rest.
## needs_alignment: autofire only shoots when on target and in range.
func update_weapon(delta: float, aim_at: Variant, firing: bool, needs_alignment: bool,
		homing_target: Ship) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_recoil = maxf(_recoil - delta * 5.0, 0.0)
	_swivel(delta, aim_at)

	if firing and _burst_left == 0 and _cooldown <= 0.0 and _ready_to_fire(aim_at, needs_alignment):
		_burst_left = data.burst_size
		_burst_timer = 0.0
		_cooldown = data.refire_delay
		_burst_target = homing_target
	if _burst_left > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			if ammo != 0 and ship.can_fire(data.flux_per_shot):
				_fire_one()
			_burst_left -= 1
			_burst_timer = data.burst_delay
	queue_redraw()


func _swivel(delta: float, aim_at: Variant) -> void:
	var facing := deg_to_rad(mount.facing_deg)
	var half_arc := deg_to_rad(mount.arc_deg) * 0.5
	var desired_local := 0.0
	if aim_at != null:
		var point: Vector2 = aim_at
		var world_angle := (point - global_position).angle()
		desired_local = clampf(wrapf(world_angle - ship.global_rotation - facing, -PI, PI),
			-half_arc, half_arc)
	# Work relative to the mount facing so we never swing through the blind arc.
	var current_local := wrapf(rotation - facing, -PI, PI)
	current_local = move_toward(current_local, desired_local,
		deg_to_rad(data.turn_rate_deg) * delta)
	rotation = facing + current_local


func _ready_to_fire(aim_at: Variant, needs_alignment: bool) -> bool:
	if ammo == 0 or not ship.can_fire(data.flux_per_shot):
		return false
	if not needs_alignment or aim_at == null:
		return true
	var point: Vector2 = aim_at
	if global_position.distance_to(point) > data.max_range:
		return false
	if data.is_missile:
		return true # missiles steer themselves
	var error := wrapf((point - global_position).angle() - global_rotation, -PI, PI)
	return absf(error) <= AIM_TOLERANCE


func _fire_one() -> void:
	ship.spend_flux(data.flux_per_shot)
	if ammo > 0:
		ammo -= 1
	var spread := deg_to_rad(randf_range(-data.spread_deg, data.spread_deg) * 0.5)
	var direction := Vector2.from_angle(global_rotation + spread)
	var muzzle := global_position + direction * data.barrel_length
	var projectile := Projectile.new()
	projectile.position = muzzle
	projectile.setup(data, ship, direction,
		_burst_target if is_instance_valid(_burst_target) else null)
	Combat.spawn_projectile(projectile)
	Combat.spawn_effect(muzzle, 4.0 + data.projectile_width, data.projectile_color, 0.08)
	_recoil = 1.0


func _draw() -> void:
	var base := ship.data.hull_color.darkened(0.35)
	var barrel := ship.data.accent_color
	var kick := -_recoil * 3.0
	match data.kind:
		WeaponData.Kind.BALLISTIC:
			draw_circle(Vector2.ZERO, 5.0, base)
			draw_rect(Rect2(kick, -1.5, data.barrel_length, 3.0), barrel)
		WeaponData.Kind.ENERGY:
			draw_rect(Rect2(-4, -3, 8, 6), base)
			draw_line(Vector2(kick, 0), Vector2(kick + data.barrel_length, 0), Color(0.5, 0.9, 1.0), 2.5)
		WeaponData.Kind.MISSILE:
			draw_rect(Rect2(-6, -5, 12, 10), base)
			var shown := mini(ammo, 6) if ammo >= 0 else 0
			for i in shown:
				draw_rect(Rect2(-5 + (i % 3) * 3.5, -4 + (i / 3) * 4.5, 2.5, 3.5), Color(1, 0.45, 0.35))
