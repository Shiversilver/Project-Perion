extends Node
## Global combat helpers: where projectiles and effects get spawned.
## The main scene assigns the layers on startup.

var projectile_layer: Node2D
var effect_layer: Node2D


func spawn_projectile(projectile: Node2D) -> void:
	if is_instance_valid(projectile_layer):
		projectile_layer.add_child(projectile)
	else:
		projectile.queue_free()


func spawn_effect(pos: Vector2, radius: float, color: Color, duration: float,
		ring := false, sparks := 0) -> void:
	if not is_instance_valid(effect_layer):
		return
	var effect := Effect.new()
	effect.position = pos
	effect.radius = radius
	effect.color = color
	effect.duration = duration
	effect.ring = ring
	effect.add_sparks(sparks, radius * 3.0)
	effect_layer.add_child(effect)


func spawn_explosion(pos: Vector2, size: float) -> void:
	spawn_effect(pos, size * 1.8, Color(1.0, 0.55, 0.2), 1.0, true, 28)
	spawn_effect(pos, size * 0.9, Color(1.0, 0.95, 0.75), 0.45)
