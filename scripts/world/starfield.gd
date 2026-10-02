extends Node2D
## Screen-space parallax starfield. Lives in a background CanvasLayer and
## scrolls based on the camera position.

const TILE := 1024.0
const LAYERS := [
	{"count": 160, "factor": 0.04, "size": 0.9, "color": Color(0.6, 0.65, 0.8, 0.55)},
	{"count": 90, "factor": 0.12, "size": 1.4, "color": Color(0.75, 0.8, 0.95, 0.75)},
	{"count": 35, "factor": 0.3, "size": 2.0, "color": Color(0.95, 0.95, 1.0, 0.9)},
]

var camera: Camera2D
var _stars: Array[PackedVector2Array] = []
var _nebulae: Array[Dictionary] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7151
	for layer in LAYERS:
		var points := PackedVector2Array()
		for i in int(layer.count):
			points.append(Vector2(rng.randf() * TILE, rng.randf() * TILE))
		_stars.append(points)
	for i in 5:
		_nebulae.append({
			"pos": Vector2(rng.randf() * TILE, rng.randf() * TILE),
			"radius": rng.randf_range(180.0, 380.0),
			"color": Color(rng.randf_range(0.15, 0.35), 0.12, rng.randf_range(0.3, 0.5), 0.05),
		})


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var cam := camera.get_screen_center_position() if camera else Vector2.ZERO
	var tiles_x := int(ceil(view.x / TILE)) + 1
	var tiles_y := int(ceil(view.y / TILE)) + 1
	for nebula in _nebulae:
		var base := _wrap(nebula.pos - cam * 0.02)
		for tx in range(-1, tiles_x):
			for ty in range(-1, tiles_y):
				var center: Vector2 = base + Vector2(tx, ty) * TILE
				for k in 3:
					draw_circle(center, nebula.radius * (1.0 - k * 0.25), nebula.color)
	for i in LAYERS.size():
		var layer: Dictionary = LAYERS[i]
		var offset: Vector2 = -cam * float(layer.factor)
		for star in _stars[i]:
			var base := _wrap(star + offset)
			for tx in tiles_x:
				for ty in tiles_y:
					draw_circle(base + Vector2(tx, ty) * TILE, layer.size, layer.color)


func _wrap(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, TILE), fposmod(p.y, TILE))
