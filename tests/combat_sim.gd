extends Node
## Headless smoke test: puts the player ship under AI control and lets it
## fight pirate waves for a while. Fails on script errors or if nothing
## actually happens (no shots, no damage, no kills).
##
## Run: godot --headless --path . --fixed-fps 60 res://tests/combat_sim.tscn

const SIM_SECONDS := 90.0

var _main: Node
var _elapsed := 0.0
var _shots_seen := 0
var _shield_hits_seen := false
var _seen_projectiles := {}
var _last_kills := 0


func _ready() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	add_child(_main)
	var player: Ship = _main.player
	player.controller.queue_free()
	var ai := ShipAI.new()
	player.controller = ai
	player.add_child(ai)
	# Keep the test ship alive long enough to see several waves.
	player.hull = 100000.0


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _main.kills != _last_kills:
		_last_kills = _main.kills
		print("t=%5.1fs  wave %d  kills %d" % [_elapsed, _main.wave, _main.kills])
	for node in get_tree().get_nodes_in_group("projectiles"):
		var id := node.get_instance_id()
		if not _seen_projectiles.has(id):
			_seen_projectiles[id] = true
			_shots_seen += 1
	for node in get_tree().get_nodes_in_group("ships"):
		if (node as Ship).hard_flux > 0.0:
			_shield_hits_seen = true
	if _elapsed >= SIM_SECONDS:
		_finish()


func _finish() -> void:
	set_physics_process(false)
	var ok: bool = _shots_seen > 0 and _main.kills > 0 and _shield_hits_seen
	print("SIM wave=%d kills=%d shots=%d shield_hits=%s player_alive=%s" % [
		_main.wave, _main.kills, _shots_seen, _shield_hits_seen, _main.player != null])
	print("SIM RESULT: %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
