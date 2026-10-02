extends Node
## Registers all input actions in code so the bindings live in one readable
## place. Uses physical keys, so the WASD layout works on AZERTY/QWERTZ too.


func _init() -> void:
	_key("thrust_forward", KEY_W)
	_key("thrust_back", KEY_S)
	_key("turn_left", KEY_A)
	_key("turn_right", KEY_D)
	_key("strafe_left", KEY_Q)
	_key("strafe_right", KEY_E)
	_key("vent", KEY_V)
	_key("target", KEY_R)
	_key("restart", KEY_R)
	_key("toggle_face_cursor", KEY_T)
	_key("pause", KEY_ESCAPE)
	_key("help", KEY_F1)
	for i in 5:
		_key("group_%d" % (i + 1), (KEY_1 + i) as Key)
	_mouse("fire", MOUSE_BUTTON_LEFT)
	_mouse("shield_toggle", MOUSE_BUTTON_RIGHT)
	_mouse("zoom_in", MOUSE_BUTTON_WHEEL_UP)
	_mouse("zoom_out", MOUSE_BUTTON_WHEEL_DOWN)


func _key(action: StringName, keycode: Key) -> void:
	_ensure(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _mouse(action: StringName, button: MouseButton) -> void:
	_ensure(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
