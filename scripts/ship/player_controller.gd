class_name PlayerController
extends Node
## Turns keyboard and mouse input into ship intent.

var shield_toggled := false
## When on, the ship turns to face the cursor and A/D strafe instead.
var face_cursor := false


func think(ship: Ship, _delta: float) -> void:
	var turn_input := Input.get_axis("turn_left", "turn_right")
	var strafe_input := Input.get_axis("strafe_left", "strafe_right")
	var mouse := ship.get_global_mouse_position()
	ship.thrust = Input.get_axis("thrust_back", "thrust_forward")
	if face_cursor:
		ship.face_point = mouse
		ship.turn = 0.0
		ship.strafe = clampf(strafe_input + turn_input, -1.0, 1.0)
	else:
		ship.face_point = null
		ship.turn = turn_input
		ship.strafe = strafe_input
	ship.aim_point = mouse
	ship.trigger = Input.is_action_pressed("fire")
	if ship.is_overloaded() or ship.venting:
		shield_toggled = false
	ship.wants_shield = shield_toggled


func _unhandled_input(event: InputEvent) -> void:
	var ship := get_parent() as Ship
	if ship == null or ship.is_dead:
		return
	if event.is_action_pressed("shield_toggle"):
		shield_toggled = not shield_toggled
	elif event.is_action_pressed("vent"):
		ship.request_vent = true
	elif event.is_action_pressed("toggle_face_cursor"):
		face_cursor = not face_cursor
	elif event.is_action_pressed("target"):
		ship.target = ship.nearest_enemy(ship.get_global_mouse_position())
	else:
		for group in range(1, 6):
			if not event.is_action_pressed("group_%d" % group):
				continue
			if not ship.group_ids().has(group):
				return
			var with_ctrl := event is InputEventWithModifiers and (event as InputEventWithModifiers).ctrl_pressed
			if with_ctrl:
				ship.autofire[group] = not ship.autofire.get(group, false)
			else:
				ship.selected_group = group
			return
