class_name ShipAI
extends Node
## Simple combat AI: keeps at gun range, circles, shields against incoming
## fire and backs off to vent when its flux gets high.

var _strafe_dir := 1.0
var _strafe_timer := 0.0
var _shield_hold := 0.0
var _backing_off := false
var _backing_off_time := 0.0


func think(ship: Ship, delta: float) -> void:
	if not is_instance_valid(ship.target) or ship.target.is_dead:
		ship.target = ship.nearest_enemy(ship.global_position)
	var target := ship.target
	ship.selected_group = -1
	for group in ship.group_ids():
		ship.autofire[group] = true
	if target == null:
		ship.thrust = 0.0
		ship.strafe = 0.0
		ship.turn = 0.0
		ship.face_point = null
		ship.wants_shield = false
		return

	var distance := ship.global_position.distance_to(target.global_position)
	var preferred := ship.preferred_range()
	var flux := ship.flux_level()
	if flux > 0.8:
		_backing_off = true
	elif flux < 0.35:
		_backing_off = false
	_backing_off_time = _backing_off_time + delta if _backing_off else 0.0

	ship.face_point = target.global_position
	ship.aim_point = target.global_position
	var wanted_distance := preferred * (1.7 if _backing_off else 1.0)
	ship.thrust = clampf((distance - wanted_distance) / 150.0, -1.0, 1.0)

	_strafe_timer -= delta
	if _strafe_timer <= 0.0:
		if randf() < 0.5:
			_strafe_dir = -_strafe_dir
		_strafe_timer = randf_range(1.5, 3.5)
	ship.strafe = _strafe_dir * 0.7

	var threatened := _incoming_fire(ship)
	if threatened:
		_shield_hold = 0.6
	_shield_hold -= delta
	ship.wants_shield = _shield_hold > 0.0 and flux < 0.92
	ship.hold_fire = _backing_off

	# Vent once clear of incoming fire, or anyway if we can't shake the enemy.
	if _backing_off and flux > 0.4 and (not threatened or _backing_off_time > 4.0):
		ship.request_vent = true


func _incoming_fire(ship: Ship) -> bool:
	var guard := ship.data.radius * 2.0
	for node in ship.get_tree().get_nodes_in_group("projectiles"):
		var shot := node as Projectile
		if shot.faction == ship.faction:
			continue
		var to_ship := ship.global_position - shot.global_position
		if to_ship.length() > 350.0 or shot.velocity.dot(to_ship) <= 0.0:
			continue
		var miss_distance := absf(to_ship.cross(shot.velocity.normalized()))
		if miss_distance < guard:
			return true
	return false
