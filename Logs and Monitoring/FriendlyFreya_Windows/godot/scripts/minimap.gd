extends Control
class_name MiniMap

var map_size = Vector2(100.0, 100.0)
var roads: Array[Rect2] = []
var alleys: Array[Rect2] = []
var sidewalks: Array[Rect2] = []
var buildings: Array[Rect2] = []
var dog_park = Rect2()

var freya_position = Vector2.ZERO
var dog_positions = PackedVector2Array()
var poop_positions = PackedVector2Array()
var vomit_positions = PackedVector2Array()
var camera_forward = Vector2(1.0, -1.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_dynamic(
	freya_pos: Vector2,
	dogs: PackedVector2Array,
	poops: PackedVector2Array,
	vomits: PackedVector2Array,
	forward: Vector2 = Vector2(1.0, -1.0)
) -> void:
	freya_position = freya_pos
	dog_positions = dogs
	poop_positions = poops
	vomit_positions = vomits
	if forward.length_squared() > 0.000001:
		camera_forward = forward.normalized()
	queue_redraw()

func _rotation_angle() -> float:
	var current = atan2(camera_forward.y, camera_forward.x)
	return -PI * 0.5 - current

func _fit_scale_factor(angle: float) -> float:
	var c = absf(cos(angle))
	var s = absf(sin(angle))
	var rotated_w = size.x * c + size.y * s
	var rotated_h = size.x * s + size.y * c
	if rotated_w <= 0.001 or rotated_h <= 0.001:
		return 1.0
	return minf(size.x / rotated_w, size.y / rotated_h) * 0.96

func _rotate_about_center(point: Vector2, angle: float) -> Vector2:
	var center = size * 0.5
	var d = point - center
	var c = cos(angle)
	var s = sin(angle)
	return center + Vector2(d.x * c - d.y * s, d.x * s + d.y * c)

func _to_map_pos(p: Vector2, scale_vec: Vector2, offset: Vector2, angle: float) -> Vector2:
	var base = p * scale_vec + offset
	return _rotate_about_center(base, angle)

func _rect_to_points(rect: Rect2, scale_vec: Vector2, offset: Vector2, angle: float) -> PackedVector2Array:
	var p0 = _to_map_pos(rect.position, scale_vec, offset, angle)
	var p1 = _to_map_pos(rect.position + Vector2(rect.size.x, 0.0), scale_vec, offset, angle)
	var p2 = _to_map_pos(rect.position + rect.size, scale_vec, offset, angle)
	var p3 = _to_map_pos(rect.position + Vector2(0.0, rect.size.y), scale_vec, offset, angle)
	return PackedVector2Array([p0, p1, p2, p3])

func _draw_map_rect(rect: Rect2, scale_vec: Vector2, offset: Vector2, angle: float, color: Color, filled: bool, width: float = 1.0) -> void:
	var points = _rect_to_points(rect, scale_vec, offset, angle)
	if filled:
		draw_colored_polygon(points, color)
		return
	var outline = PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	draw_polyline(outline, color, width, true)

func _draw() -> void:
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return

	var bg = Rect2(Vector2.ZERO, size)
	draw_rect(bg, Color(0.05, 0.09, 0.11, 0.88), true)
	draw_rect(bg, Color(0.78, 0.87, 0.9, 0.8), false, 2.0)

	var angle = _rotation_angle()
	var fit = _fit_scale_factor(angle)
	var scale_vec = Vector2(size.x / map_size.x, size.y / map_size.y) * fit
	var map_draw_size = Vector2(map_size.x * scale_vec.x, map_size.y * scale_vec.y)
	var offset = (size - map_draw_size) * 0.5

	_draw_map_rect(Rect2(Vector2.ZERO, map_size), scale_vec, offset, angle, Color(0.2, 0.52, 0.2, 0.85), true)

	for s in sidewalks:
		_draw_map_rect(s, scale_vec, offset, angle, Color(0.72, 0.74, 0.76, 0.95), true)

	for r in roads:
		_draw_map_rect(r, scale_vec, offset, angle, Color(0.29, 0.31, 0.35, 0.96), true)

	for a in alleys:
		_draw_map_rect(a, scale_vec, offset, angle, Color(0.38, 0.4, 0.43, 0.96), true)

	if dog_park.size.x > 0.0 and dog_park.size.y > 0.0:
		_draw_map_rect(dog_park, scale_vec, offset, angle, Color(0.36, 0.63, 0.33, 0.55), true)
		_draw_map_rect(dog_park, scale_vec, offset, angle, Color(0.8, 0.93, 0.75, 0.82), false, 1.0)

	for b in buildings:
		_draw_map_rect(b, scale_vec, offset, angle, Color(0.45, 0.28, 0.2, 0.95), true)

	for p in poop_positions:
		draw_circle(_to_map_pos(p, scale_vec, offset, angle), 1.4, Color(0.56, 0.35, 0.19, 1.0))

	for v in vomit_positions:
		draw_circle(_to_map_pos(v, scale_vec, offset, angle), 1.5, Color(0.52, 0.74, 0.31, 0.95))

	for d in dog_positions:
		draw_circle(_to_map_pos(d, scale_vec, offset, angle), 2.0, Color(0.97, 0.95, 0.9, 0.95))

	draw_circle(_to_map_pos(freya_position, scale_vec, offset, angle), 2.5, Color(0.02, 0.02, 0.02, 1.0))
