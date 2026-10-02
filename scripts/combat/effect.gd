class_name Effect
extends Node2D
## Short-lived visual: flash, hit spark or explosion. Frees itself.

var radius := 10.0
var color := Color.WHITE
var duration := 0.3
var ring := false

var _age := 0.0
var _sparks: Array[Vector2] = [] ## each is direction * speed


func add_sparks(count: int, speed: float) -> void:
	for i in count:
		_sparks.append(Vector2.from_angle(randf() * TAU) * speed * randf_range(0.4, 1.2))


func _process(delta: float) -> void:
	_age += delta
	if _age >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / duration
	var alpha := 1.0 - t
	draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * t), Color(color, color.a * alpha * 0.7))
	if ring:
		draw_arc(Vector2.ZERO, radius * (0.6 + 1.2 * t), 0.0, TAU, 40, Color(color, alpha), 2.0, true)
	for spark in _sparks:
		var p := spark * _age
		draw_line(p, p + spark.normalized() * 5.0, Color(color, alpha), 1.5)
