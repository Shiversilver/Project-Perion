class_name Projectile
extends Node2D
## A bullet, bolt or missile. Moves itself and checks hits against shields
## first, then hulls, using a swept segment so fast shots can't tunnel.

var faction := ""
var velocity := Vector2.ZERO
var damage := 0.0
var damage_type := 0
var max_distance := 600.0
var color := Color.WHITE
var length := 10.0
var width := 2.0

var is_missile := false
var homing_target: Ship
var max_speed := 0.0
var accel := 0.0
var turn_rate := 0.0

var _traveled := 0.0


func setup(data: WeaponData, source: Ship, direction: Vector2, target: Ship) -> void:
	faction = source.faction
	damage = data.damage
	damage_type = data.damage_type
	color = data.projectile_color
	length = data.projectile_length
	width = data.projectile_width
	is_missile = data.is_missile
	if is_missile:
		max_distance = data.max_range * 1.3
		velocity = direction * data.projectile_speed * 0.35 + source.velocity
		max_speed = data.projectile_speed
		accel = data.missile_accel
		turn_rate = deg_to_rad(data.missile_turn_rate_deg)
		homing_target = target
	else:
		max_distance = data.max_range * 1.15
		velocity = direction * data.projectile_speed + source.velocity
	rotation = velocity.angle()


func _ready() -> void:
	add_to_group("projectiles")


func _physics_process(delta: float) -> void:
	if is_missile:
		_steer(delta)
	var from := global_position
	var step := velocity * delta
	global_position += step
	_traveled += step.length()
	rotation = velocity.angle()
	if _check_hits(from, global_position):
		return
	if _traveled >= max_distance:
		if is_missile:
			Combat.spawn_effect(global_position, 8.0, Color(1, 0.6, 0.3, 0.6), 0.3)
		queue_free()
	queue_redraw()


func _steer(delta: float) -> void:
	var speed := move_toward(velocity.length(), max_speed, accel * delta)
	var heading := velocity.angle()
	if is_instance_valid(homing_target) and not homing_target.is_dead:
		var desired := (homing_target.global_position - global_position).angle()
		heading += clampf(wrapf(desired - heading, -PI, PI), -turn_rate * delta, turn_rate * delta)
	velocity = Vector2.from_angle(heading) * speed


func _check_hits(from: Vector2, to: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("ships"):
		var ship := node as Ship
		if ship.is_dead or ship.faction == faction:
			continue
		if ship.shield_on:
			var t := Geometry2D.segment_intersects_circle(from, to, ship.global_position, ship.shield_radius())
			if t >= 0.0:
				var point := from.lerp(to, t)
				if ship.is_shield_facing(point):
					ship.take_hit(damage, damage_type, true)
					_impact(point, Color(0.6, 0.85, 1.0))
					return true
		var hull_t := Geometry2D.segment_intersects_circle(from, to, ship.global_position, ship.data.radius * 0.85)
		if hull_t >= 0.0:
			var hull_point := from.lerp(to, hull_t)
			ship.take_hit(damage, damage_type, false)
			_impact(hull_point, color)
			return true
	return false


func _impact(point: Vector2, impact_color: Color) -> void:
	var size := clampf(damage * 0.12, 4.0, 26.0)
	Combat.spawn_effect(point, size, impact_color, 0.25 if not is_missile else 0.6,
		is_missile, 6 if not is_missile else 16)
	queue_free()


func _draw() -> void:
	if is_missile:
		draw_line(Vector2(-length, 0), Vector2(0, 0), Color(0.85, 0.85, 0.9), width)
		draw_line(Vector2(-length - 6.0 - randf() * 4.0, 0), Vector2(-length, 0), Color(1, 0.7, 0.3, 0.8), width)
	else:
		draw_line(Vector2(-length, 0), Vector2.ZERO, Color(color, 0.6), width)
		draw_circle(Vector2.ZERO, width * 0.7, color.lightened(0.4))
