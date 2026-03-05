extends Control
class_name MiniMap

var map_size = Vector2(100.0, 100.0)
var roads: Array[Rect2] = []
var alleys: Array[Rect2] = []
var sidewalks: Array[Rect2] = []
var buildings: Array[Rect2] = []
var store_buildings: Array[Rect2] = []
var store_entries = PackedVector2Array()
var store_entry_dirs = PackedVector2Array()
var dog_park = Rect2()

var freya_position = Vector2.ZERO
var dog_positions = PackedVector2Array()
var poop_positions = PackedVector2Array()
var vomit_positions = PackedVector2Array()
var claimed_poles_freya = PackedVector2Array()
var claimed_trees_freya = PackedVector2Array()
var claimed_hydrants_freya = PackedVector2Array()
var claimed_poles_enemy = PackedVector2Array()
var claimed_trees_enemy = PackedVector2Array()
var claimed_hydrants_enemy = PackedVector2Array()
var camera_forward = Vector2(1.0, -1.0)
var freya_forward = Vector2(0.0, -1.0)
var zoom_level = 2.6
var min_zoom = 1.0
var max_zoom = 4.5
var _smoothed_world_origin = Vector2.ZERO
var _smoothed_angle = 0.0
var _has_smoothing_seed = false
const MINIMAP_VIEW_PADDING_PX = 4.0
const MINIMAP_ORIGIN_SMOOTH = 0.32
const MINIMAP_ANGLE_SMOOTH = 0.28
const CLAIM_MARKER_POLE = 1
const CLAIM_MARKER_TREE = 2
const CLAIM_MARKER_HYDRANT = 3

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_zoom(value: float) -> void:
	zoom_level = clampf(value, min_zoom, max_zoom)
	queue_redraw()

func update_dynamic(
	freya_pos: Vector2,
	dogs: PackedVector2Array,
	poops: PackedVector2Array,
	vomits: PackedVector2Array,
	forward: Vector2 = Vector2(1.0, -1.0),
	freya_face: Vector2 = Vector2(0.0, -1.0),
	poles_freya: PackedVector2Array = PackedVector2Array(),
	trees_freya: PackedVector2Array = PackedVector2Array(),
	hydrants_freya: PackedVector2Array = PackedVector2Array(),
	poles_enemy: PackedVector2Array = PackedVector2Array(),
	trees_enemy: PackedVector2Array = PackedVector2Array(),
	hydrants_enemy: PackedVector2Array = PackedVector2Array()
) -> void:
	freya_position = freya_pos
	dog_positions = dogs
	poop_positions = poops
	vomit_positions = vomits
	claimed_poles_freya = poles_freya
	claimed_trees_freya = trees_freya
	claimed_hydrants_freya = hydrants_freya
	claimed_poles_enemy = poles_enemy
	claimed_trees_enemy = trees_enemy
	claimed_hydrants_enemy = hydrants_enemy
	if forward.length_squared() > 0.000001:
		# Smooth heading changes to reduce minimap rotation jitter.
		camera_forward = camera_forward.lerp(forward.normalized(), 0.46).normalized()
	if freya_face.length_squared() > 0.000001:
		freya_forward = freya_face.normalized()
	queue_redraw()

func _rotation_angle() -> float:
	var current = atan2(camera_forward.y, camera_forward.x)
	return -PI * 0.5 - current

func _rotate_about_center(point: Vector2, center: Vector2, angle: float) -> Vector2:
	var d = point - center
	var c = cos(angle)
	var s = sin(angle)
	return center + Vector2(d.x * c - d.y * s, d.x * s + d.y * c)

func _draw_rect() -> Rect2:
	var pad = MINIMAP_VIEW_PADDING_PX
	var rect = Rect2(Vector2(pad, pad), size - Vector2(pad * 2.0, pad * 2.0))
	rect.size.x = maxf(2.0, rect.size.x)
	rect.size.y = maxf(2.0, rect.size.y)
	return rect

func _to_map_pos(p: Vector2, world_origin: Vector2, scale_vec: Vector2, angle: float, draw_rect: Rect2) -> Vector2:
	var base = draw_rect.position + (p - world_origin) * scale_vec
	return _rotate_about_center(base, draw_rect.get_center(), angle)

func _rect_to_points(rect: Rect2, world_origin: Vector2, scale_vec: Vector2, angle: float, draw_rect: Rect2) -> PackedVector2Array:
	var p0 = _to_map_pos(rect.position, world_origin, scale_vec, angle, draw_rect)
	var p1 = _to_map_pos(rect.position + Vector2(rect.size.x, 0.0), world_origin, scale_vec, angle, draw_rect)
	var p2 = _to_map_pos(rect.position + rect.size, world_origin, scale_vec, angle, draw_rect)
	var p3 = _to_map_pos(rect.position + Vector2(0.0, rect.size.y), world_origin, scale_vec, angle, draw_rect)
	return PackedVector2Array([p0, p1, p2, p3])

func _draw_map_rect(rect: Rect2, world_origin: Vector2, scale_vec: Vector2, angle: float, draw_rect: Rect2, color: Color, filled: bool, width: float = 1.0) -> void:
	var points = _rect_to_points(rect, world_origin, scale_vec, angle, draw_rect)
	if filled:
		draw_colored_polygon(points, color)
		return
	var outline = PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	draw_polyline(outline, color, width, true)

func _draw_claim_markers(
	points: PackedVector2Array,
	marker_type: int,
	fill_color: Color,
	outline_color: Color,
	world_origin: Vector2,
	scale_vec: Vector2,
	angle: float,
	draw_rect: Rect2
) -> void:
	for p in points:
		var center = _to_map_pos(p, world_origin, scale_vec, angle, draw_rect)
		if marker_type == CLAIM_MARKER_POLE:
			var pole_rect = Rect2(center - Vector2(1.4, 1.4), Vector2(2.8, 2.8))
			draw_rect(pole_rect, fill_color, true)
			draw_rect(pole_rect, outline_color, false, 1.0)
		elif marker_type == CLAIM_MARKER_TREE:
			draw_circle(center, 1.9, fill_color)
			draw_circle(center, 1.1, Color(fill_color.r * 0.65, fill_color.g * 0.65, fill_color.b * 0.65, 0.95))
			draw_arc(center, 1.9, 0.0, TAU, 12, outline_color, 1.0)
		else:
			draw_line(center + Vector2(-1.6, -1.6), center + Vector2(1.6, 1.6), outline_color, 1.2, true)
			draw_line(center + Vector2(-1.6, 1.6), center + Vector2(1.6, -1.6), outline_color, 1.2, true)
			draw_circle(center, 1.15, fill_color)

func _compute_world_origin(view_world: Vector2) -> Vector2:
	var origin = freya_position - view_world * 0.5
	var max_origin = map_size - view_world

	if max_origin.x <= 0.0:
		origin.x = (map_size.x - view_world.x) * 0.5
	else:
		origin.x = clampf(origin.x, 0.0, max_origin.x)

	if max_origin.y <= 0.0:
		origin.y = (map_size.y - view_world.y) * 0.5
	else:
		origin.y = clampf(origin.y, 0.0, max_origin.y)
	return origin

func _draw() -> void:
	if map_size.x <= 0.0 or map_size.y <= 0.0:
		return

	var bg = Rect2(Vector2.ZERO, size)
	draw_rect(bg, Color(0.05, 0.09, 0.11, 0.88), true)
	var draw_rect = _draw_rect()

	var angle = _rotation_angle()
	var zoom = clampf(zoom_level, min_zoom, max_zoom)
	var view_world = Vector2(map_size.x / zoom, map_size.y / zoom)
	view_world.x = maxf(8.0, view_world.x)
	view_world.y = maxf(8.0, view_world.y)
	var scale_vec = Vector2(draw_rect.size.x / view_world.x, draw_rect.size.y / view_world.y)
	var world_origin = _compute_world_origin(view_world)
	if not _has_smoothing_seed:
		_smoothed_world_origin = world_origin
		_smoothed_angle = angle
		_has_smoothing_seed = true
	else:
		_smoothed_world_origin = _smoothed_world_origin.lerp(world_origin, MINIMAP_ORIGIN_SMOOTH)
		_smoothed_angle = lerp_angle(_smoothed_angle, angle, MINIMAP_ANGLE_SMOOTH)
	world_origin = _smoothed_world_origin
	angle = _smoothed_angle

	for s in sidewalks:
		_draw_map_rect(s, world_origin, scale_vec, angle, draw_rect, Color(0.72, 0.74, 0.76, 0.95), true)

	for r in roads:
		_draw_map_rect(r, world_origin, scale_vec, angle, draw_rect, Color(0.29, 0.31, 0.35, 0.96), true)

	for a in alleys:
		_draw_map_rect(a, world_origin, scale_vec, angle, draw_rect, Color(0.38, 0.4, 0.43, 0.96), true)

	if dog_park.size.x > 0.0 and dog_park.size.y > 0.0:
		_draw_map_rect(dog_park, world_origin, scale_vec, angle, draw_rect, Color(0.36, 0.63, 0.33, 0.55), true)
		_draw_map_rect(dog_park, world_origin, scale_vec, angle, draw_rect, Color(0.8, 0.93, 0.75, 0.82), false, 1.0)

	for b in buildings:
		_draw_map_rect(b, world_origin, scale_vec, angle, draw_rect, Color(0.45, 0.28, 0.2, 0.95), true)

	for s in store_buildings:
		_draw_map_rect(s, world_origin, scale_vec, angle, draw_rect, Color(0.08, 0.42, 0.56, 0.6), true)
		_draw_map_rect(s, world_origin, scale_vec, angle, draw_rect, Color(0.98, 0.98, 0.98, 0.98), false, 2.2)

	var pulse = 0.72 + 0.28 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006))
	for i in range(store_entries.size()):
		var s = store_entries[i]
		var center = _to_map_pos(s, world_origin, scale_vec, angle, draw_rect)
		var inward = Vector2(0.0, -1.0)
		if i < store_entry_dirs.size():
			var d_world: Vector2 = store_entry_dirs[i]
			if d_world.length_squared() > 0.0001:
				var sample = _to_map_pos(s + d_world.normalized(), world_origin, scale_vec, angle, draw_rect)
				var d_map = sample - center
				if d_map.length_squared() > 0.0001:
					inward = d_map.normalized()
		var side = Vector2(-inward.y, inward.x)
		var tip = center + inward * (5.8 + pulse * 1.5)
		var base = center - inward * (2.1 + pulse * 0.9)
		var half_w = 2.26 + pulse * 0.5
		var outer_arrow = PackedVector2Array([
			tip + inward * 0.38,
			base + side * (half_w + 0.7),
			base - side * (half_w + 0.7)
		])
		draw_colored_polygon(outer_arrow, Color(0.0, 0.0, 0.0, 0.97))
		var arrow_shadow = PackedVector2Array([
			tip + Vector2(0.95, 0.95),
			base + side * half_w + Vector2(0.95, 0.95),
			base - side * half_w + Vector2(0.95, 0.95)
		])
		draw_colored_polygon(arrow_shadow, Color(0.0, 0.0, 0.0, 0.66))
		var arrow = PackedVector2Array([
			tip,
			base + side * half_w,
			base - side * half_w
		])
		draw_colored_polygon(arrow, Color(1.0, 0.24, 0.04, 1.0))
		draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), Color(0.0, 0.0, 0.0, 0.97), 1.15, true)
		var inner_arrow = PackedVector2Array([
			center + inward * (3.45 + pulse * 0.85),
			center + side * (1.06 + pulse * 0.24),
			center - side * (1.06 + pulse * 0.24)
		])
		draw_colored_polygon(inner_arrow, Color(1.0, 0.95, 0.24, 0.99))
		var stem_end = center - inward * 2.6
		draw_line(base, stem_end, Color(0.0, 0.0, 0.0, 0.92), 2.6, true)
		draw_line(base, stem_end, Color(1.0, 0.86, 0.14, 0.99), 1.35, true)

	_draw_claim_markers(
		claimed_poles_freya,
		CLAIM_MARKER_POLE,
		Color(0.99, 0.83, 0.22, 0.98),
		Color(0.0, 0.0, 0.0, 0.95),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)
	_draw_claim_markers(
		claimed_trees_freya,
		CLAIM_MARKER_TREE,
		Color(0.29, 0.84, 0.52, 0.98),
		Color(0.03, 0.2, 0.11, 0.95),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)
	_draw_claim_markers(
		claimed_hydrants_freya,
		CLAIM_MARKER_HYDRANT,
		Color(0.99, 0.94, 0.44, 0.98),
		Color(0.1, 0.08, 0.03, 0.95),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)
	_draw_claim_markers(
		claimed_poles_enemy,
		CLAIM_MARKER_POLE,
		Color(0.94, 0.34, 0.31, 0.98),
		Color(0.1, 0.0, 0.0, 0.98),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)
	_draw_claim_markers(
		claimed_trees_enemy,
		CLAIM_MARKER_TREE,
		Color(0.84, 0.22, 0.2, 0.98),
		Color(0.14, 0.0, 0.0, 0.98),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)
	_draw_claim_markers(
		claimed_hydrants_enemy,
		CLAIM_MARKER_HYDRANT,
		Color(0.97, 0.52, 0.34, 0.98),
		Color(0.1, 0.0, 0.0, 0.98),
		world_origin,
		scale_vec,
		angle,
		draw_rect
	)

	for p in poop_positions:
		draw_circle(_to_map_pos(p, world_origin, scale_vec, angle, draw_rect), 1.4, Color(0.56, 0.35, 0.19, 1.0))

	for v in vomit_positions:
		draw_circle(_to_map_pos(v, world_origin, scale_vec, angle, draw_rect), 1.5, Color(0.52, 0.74, 0.31, 0.95))

	for d in dog_positions:
		draw_circle(_to_map_pos(d, world_origin, scale_vec, angle, draw_rect), 2.0, Color(0.97, 0.95, 0.9, 0.95))

	var freya_map = _to_map_pos(freya_position, world_origin, scale_vec, angle, draw_rect)
	var marker_pulse = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.0075)
	draw_circle(freya_map, 5.8 + marker_pulse * 1.2, Color(1.0, 0.93, 0.36, 0.26))
	draw_circle(freya_map, 4.1, Color(0.0, 0.0, 0.0, 0.98))
	draw_circle(freya_map, 3.0, Color(1.0, 0.96, 0.34, 1.0))
	draw_circle(freya_map, 1.2, Color(0.08, 0.08, 0.09, 1.0))
	var pointer_dir = Vector2(0.0, -1.0)
	if freya_forward.length_squared() > 0.0001:
		var forward_map_sample = _to_map_pos(freya_position + freya_forward.normalized(), world_origin, scale_vec, angle, draw_rect)
		var mapped = forward_map_sample - freya_map
		if mapped.length_squared() > 0.0001:
			pointer_dir = -mapped.normalized()
	var pointer_side = Vector2(-pointer_dir.y, pointer_dir.x)
	var pointer_shadow = PackedVector2Array([
		freya_map + pointer_dir * 6.6 + Vector2(0.9, 0.9),
		freya_map + pointer_side * 2.8 + pointer_dir * 2.1 + Vector2(0.9, 0.9),
		freya_map - pointer_side * 2.8 + pointer_dir * 2.1 + Vector2(0.9, 0.9)
	])
	draw_colored_polygon(pointer_shadow, Color(0.0, 0.0, 0.0, 0.72))
	var pointer = PackedVector2Array([
		freya_map + pointer_dir * 6.8,
		freya_map + pointer_side * 2.8 + pointer_dir * 2.7,
		freya_map - pointer_side * 2.8 + pointer_dir * 2.7
	])
	draw_colored_polygon(pointer, Color(1.0, 0.86, 0.2, 0.99))
	draw_polyline(PackedVector2Array([pointer[0], pointer[1], pointer[2], pointer[0]]), Color(0.0, 0.0, 0.0, 0.96), 1.0, true)
