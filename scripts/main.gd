extends Node2D
## Milestone 1 sandbox: the player's patrol frigate against escalating pirate
## waves. Owns spawning, the camera, pausing and restarting.

const PLAYER_SHIP := preload("res://data/ships/marshal_frigate.tres")
const PIRATE_SCRAPPER := preload("res://data/ships/pirate_scrapper.tres")
const PIRATE_RAIDER := preload("res://data/ships/pirate_raider.tres")
const SPAWN_DISTANCE := 1500.0
const WAVE_DELAY := 4.0
const ZOOM_MIN := 0.45
const ZOOM_MAX := 1.6

var player: Ship
var wave := 0
var kills := 0
var message := ""
var message_timer := 0.0

var _wave_timer := 2.0
var _zoom := 1.0

@onready var _ships_layer: Node2D = $World/Ships
@onready var _camera: Camera2D = $Camera
@onready var _hud: Control = $HUD/HUDView


func _ready() -> void:
	randomize()
	Combat.projectile_layer = $World/Projectiles
	Combat.effect_layer = $World/Effects
	$Background/Starfield.camera = _camera
	_hud.main = self
	player = spawn_ship(PLAYER_SHIP, "player", PlayerController.new(), Vector2.ZERO)
	_camera.position = player.position
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	show_message("Frontier patrol underway. Pirate activity reported.", 3.5)


func spawn_ship(data: ShipData, faction: String, controller: Node, pos: Vector2,
		facing := 0.0) -> Ship:
	var ship := Ship.new()
	ship.data = data
	ship.faction = faction
	ship.controller = controller
	ship.position = pos
	ship.rotation = facing
	ship.destroyed.connect(_on_ship_destroyed)
	_ships_layer.add_child(ship)
	return ship


func pirates_alive() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("ships"):
		if (node as Ship).faction == "pirate":
			count += 1
	return count


func show_message(text: String, duration := 3.0) -> void:
	message = text
	message_timer = duration


func _process(delta: float) -> void:
	_update_camera(delta)
	if get_tree().paused:
		return
	message_timer -= delta
	if player and pirates_alive() == 0:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_start_next_wave()


func _start_next_wave() -> void:
	wave += 1
	_wave_timer = WAVE_DELAY
	var roster: Array[ShipData] = []
	for i in mini(wave, 3):
		roster.append(PIRATE_SCRAPPER)
	if wave >= 3:
		roster.append(PIRATE_RAIDER)
	if wave >= 5:
		roster.append(PIRATE_RAIDER)
	var base_angle := randf() * TAU
	for i in roster.size():
		var angle := base_angle + randf_range(-0.5, 0.5)
		var pos := player.global_position + Vector2.from_angle(angle) * SPAWN_DISTANCE \
			+ Vector2(randf_range(-150, 150), randf_range(-150, 150))
		var pirate := spawn_ship(roster[i], "pirate", ShipAI.new(), pos,
			(player.global_position - pos).angle())
		pirate.target = player
	show_message("Wave %d — %d pirate contacts inbound" % [wave, roster.size()])


func _on_ship_destroyed(ship: Ship) -> void:
	if ship == player:
		player = null
		show_message("Warden destroyed. Press R to relaunch.", 999.0)
	elif ship.faction == "pirate":
		kills += 1
		if pirates_alive() == 0 and player:
			show_message("Wave %d cleared." % wave)


func _update_camera(delta: float) -> void:
	if player:
		var view := get_viewport_rect().size
		var look := (get_viewport().get_mouse_position() - view * 0.5) / _camera.zoom.x * 0.3
		var desired := player.global_position + look
		_camera.global_position = _camera.global_position.lerp(desired, 1.0 - exp(-8.0 * delta))
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * _zoom, 1.0 - exp(-10.0 * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		if get_tree().paused:
			show_message("PAUSED — Esc to resume", 999.0)
		else:
			message_timer = 0.0
	elif event.is_action_pressed("help"):
		_hud.show_help = not _hud.show_help
	elif event.is_action_pressed("zoom_in"):
		_zoom = clampf(_zoom * 1.1, ZOOM_MIN, ZOOM_MAX)
	elif event.is_action_pressed("zoom_out"):
		_zoom = clampf(_zoom / 1.1, ZOOM_MIN, ZOOM_MAX)
	elif event.is_action_pressed("restart") and player == null:
		get_tree().paused = false
		get_tree().reload_current_scene()
