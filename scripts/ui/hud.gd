extends Control
## Combat HUD, drawn directly: ship status, weapon groups, target info,
## off-screen contact markers, crosshair and messages.

const TEXT := Color(0.85, 0.92, 1.0)
const DIM := Color(0.55, 0.62, 0.75)
const PANEL := Color(0.03, 0.05, 0.1, 0.75)
const HOSTILE := Color(1.0, 0.45, 0.35)

var main: Node
var show_help := true
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var player: Ship = main.player
	_draw_contacts(player)
	_draw_wave_info()
	if player:
		_draw_status(player)
		_draw_weapons(player)
		if is_instance_valid(player.target):
			_draw_target(player.target)
	if show_help:
		_draw_help()
	_draw_message()
	_draw_crosshair()


func _text(pos: Vector2, text: String, size := 14, color := TEXT,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(_font, pos, text, align, width, size, color)


func _bar(pos: Vector2, width: float, frac: float, color: Color, label: String,
		value: String, extra_frac := 0.0, extra_color := Color.TRANSPARENT) -> void:
	_text(pos + Vector2(0, -3), label, 12, DIM)
	_text(pos + Vector2(0, -3), value, 12, TEXT, HORIZONTAL_ALIGNMENT_RIGHT, width)
	draw_rect(Rect2(pos, Vector2(width, 8)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(pos, Vector2(width * clampf(frac, 0.0, 1.0), 8)), color)
	if extra_frac > 0.0:
		draw_rect(Rect2(pos, Vector2(width * clampf(extra_frac, 0.0, 1.0), 8)), extra_color)


func _draw_status(ship: Ship) -> void:
	var origin := Vector2(20, size.y - 190)
	draw_rect(Rect2(origin, Vector2(320, 170)), PANEL)
	var data := ship.data
	_text(origin + Vector2(14, 24), "%s  —  %s" % [data.display_name, data.hull_class], 15)
	var x := origin.x + 14
	var w := 292.0
	_bar(Vector2(x, origin.y + 50), w, ship.hull / data.max_hull, Color(0.4, 0.85, 0.45),
		"HULL", "%d / %d" % [ship.hull, data.max_hull])
	_bar(Vector2(x, origin.y + 82), w, ship.armor / data.max_armor, Color(0.9, 0.7, 0.3),
		"ARMOR", "%d / %d" % [ship.armor, data.max_armor])
	_bar(Vector2(x, origin.y + 114), w, ship.flux_level(), Color(0.55, 0.75, 1.0),
		"FLUX", "%d / %d  (hard %d)" % [ship.total_flux(), data.flux_capacity, ship.hard_flux],
		ship.hard_flux / data.flux_capacity, Color(0.3, 0.45, 0.9))
	var state := "SHIELD UP" if ship.shield_on else "shield down"
	var state_color := Color(0.5, 0.85, 1.0) if ship.shield_on else DIM
	if ship.is_overloaded():
		state = "OVERLOADED  %.1fs" % ship.overload_timer
		state_color = Color(0.8, 0.55, 1.0) if int(Time.get_ticks_msec() / 150) % 2 == 0 else TEXT
	elif ship.venting:
		state = "VENTING FLUX"
		state_color = Color(1.0, 0.85, 0.4)
	_text(Vector2(x, origin.y + 148), state, 14, state_color)
	var pilot := ship.controller as PlayerController
	var steering := "facing cursor" if pilot and pilot.face_cursor else "manual"
	_text(Vector2(x, origin.y + 148), "%d m/s  ·  %s" % [ship.velocity.length(), steering],
		12, DIM, HORIZONTAL_ALIGNMENT_RIGHT, w)


func _draw_weapons(ship: Ship) -> void:
	var groups := ship.group_ids()
	var height := 38.0 + groups.size() * 24.0
	var origin := Vector2(size.x - 360, size.y - 20 - height)
	draw_rect(Rect2(origin, Vector2(340, height)), PANEL)
	_text(origin + Vector2(14, 24), "WEAPON GROUPS", 12, DIM)
	_text(origin + Vector2(14, 24), "Ctrl+# autofire", 11, DIM, HORIZONTAL_ALIGNMENT_RIGHT, 312)
	var y := origin.y + 50
	for group in groups:
		var list := ship.weapons_in_group(group)
		var selected := group == ship.selected_group
		var label := "%d  %s" % [group, list[0].data.display_name]
		if list.size() > 1:
			label += " ×%d" % list.size()
		if list[0].data.max_ammo > 0:
			var ammo := 0
			for weapon in list:
				ammo += weapon.ammo
			label += "  [%d]" % ammo
		if selected:
			draw_rect(Rect2(origin.x + 6, y - 16, 328, 22), Color(0.3, 0.5, 0.8, 0.35))
		_text(Vector2(origin.x + 14, y), label, 14, TEXT if selected else DIM)
		if ship.autofire.get(group, false) and not selected:
			_text(Vector2(origin.x + 14, y), "AUTO", 12, Color(0.5, 1.0, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, 312)
		elif selected:
			_text(Vector2(origin.x + 14, y), "MANUAL", 12, TEXT, HORIZONTAL_ALIGNMENT_RIGHT, 312)
		y += 24


func _draw_target(target: Ship) -> void:
	var origin := Vector2(size.x - 300, 20)
	draw_rect(Rect2(origin, Vector2(280, 110)), PANEL)
	_text(origin + Vector2(14, 22), "TARGET", 12, HOSTILE)
	_text(origin + Vector2(14, 42), "%s  —  %s" % [target.data.display_name, target.data.hull_class], 14)
	_bar(origin + Vector2(14, 66), 252, target.hull / target.data.max_hull, Color(0.4, 0.85, 0.45),
		"HULL", "%d%%" % (100.0 * target.hull / target.data.max_hull))
	_bar(origin + Vector2(14, 96), 252, target.flux_level(), Color(0.55, 0.75, 1.0),
		"FLUX", "OVERLOADED" if target.is_overloaded() else "%d%%" % (100.0 * target.flux_level()))
	var screen := get_viewport().get_canvas_transform() * target.global_position
	var r := target.data.radius * get_viewport().get_canvas_transform().get_scale().x + 10.0
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var c: Vector2 = screen + corner * r
		draw_line(c, c - Vector2(corner.x * 10, 0), HOSTILE, 2.0)
		draw_line(c, c - Vector2(0, corner.y * 10), HOSTILE, 2.0)


func _draw_contacts(player: Ship) -> void:
	var view := Rect2(Vector2.ZERO, size).grow(-30)
	var center := size * 0.5
	for node in get_tree().get_nodes_in_group("ships"):
		var ship := node as Ship
		if ship == player or ship.faction == "player":
			continue
		var screen := get_viewport().get_canvas_transform() * ship.global_position
		if view.has_point(screen):
			continue
		var dir := (screen - center).normalized()
		var scale_x := (size.x * 0.5 - 30) / maxf(absf(dir.x), 0.001)
		var scale_y := (size.y * 0.5 - 30) / maxf(absf(dir.y), 0.001)
		var edge := center + dir * minf(scale_x, scale_y)
		var side := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([
			edge + dir * 12, edge - dir * 6 + side * 8, edge - dir * 6 - side * 8,
		]), HOSTILE)


func _draw_wave_info() -> void:
	draw_rect(Rect2(20, 20, 240, 78), PANEL)
	_text(Vector2(34, 46), "WAVE %d" % main.wave, 18)
	_text(Vector2(34, 68), "Pirate contacts: %d" % main.pirates_alive(), 13, DIM)
	_text(Vector2(34, 88), "Kills: %d" % main.kills, 13, DIM)


func _draw_help() -> void:
	var lines := [
		"W / S  thrust · reverse", "A / D  turn", "Q / E  strafe",
		"T  toggle face-cursor steering", "LMB  fire selected group",
		"1-5  select group · Ctrl+1-5 autofire", "RMB  toggle shield", "V  vent flux",
		"R  target nearest to cursor", "Wheel  zoom · Esc  pause · F1  hide help",
	]
	var origin := Vector2(20, 112)
	draw_rect(Rect2(origin, Vector2(300, 20 + lines.size() * 18)), PANEL)
	for i in lines.size():
		_text(origin + Vector2(14, 22 + i * 18), lines[i], 12, DIM)


func _draw_message() -> void:
	if main.message_timer <= 0.0 or main.message.is_empty():
		return
	var alpha := clampf(main.message_timer, 0.0, 1.0)
	_text(Vector2(0, size.y * 0.22), main.message, 24, Color(TEXT, alpha),
		HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _draw_crosshair() -> void:
	var m := get_local_mouse_position()
	var c := Color(0.8, 0.95, 1.0, 0.9)
	draw_arc(m, 9, 0, TAU, 24, c, 1.5, true)
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(m + d * 5, m + d * 14, c, 1.5)
