extends RefCounted
class_name BuildingFactory

const EXTERNAL_BUILDING_MODEL_SPECS = [
	{
		"path": "res://assets/models/buildings/building_apartment.glb",
		"min_floors": 2,
		"max_floors": 8,
		"min_width": 5.0,
		"min_depth": 4.6,
		"min_area": 24.0,
		"min_y_ratio": 0.88,
		"max_y_ratio": 1.5
	},
	{
		"path": "res://assets/models/buildings/building_large_01.glb",
		"min_floors": 2,
		"max_floors": 10,
		"min_width": 5.0,
		"min_depth": 4.6,
		"min_area": 24.0,
		"min_y_ratio": 0.86,
		"max_y_ratio": 1.55
	},
	{
		"path": "res://assets/models/buildings/building_large_02.glb",
		"min_floors": 2,
		"max_floors": 10,
		"min_width": 5.0,
		"min_depth": 4.6,
		"min_area": 24.0,
		"min_y_ratio": 0.86,
		"max_y_ratio": 1.55
	},
	{
		"path": "res://assets/models/buildings/building_house.glb",
		"min_floors": 1,
		"max_floors": 1,
		"min_width": 4.4,
		"min_depth": 4.2,
		"min_area": 18.0,
		"min_y_ratio": 0.92,
		"max_y_ratio": 1.18
	},
	{
		"path": "res://assets/models/buildings/building_roofgarden.glb",
		"min_floors": 2,
		"max_floors": 7,
		"min_width": 5.2,
		"min_depth": 4.8,
		"min_area": 26.0,
		"min_y_ratio": 0.88,
		"max_y_ratio": 1.48
	},
	{
		"path": "res://assets/models/buildings/building_big.glb",
		"min_floors": 2,
		"max_floors": 12,
		"min_width": 5.2,
		"min_depth": 4.8,
		"min_area": 28.0,
		"min_y_ratio": 0.84,
		"max_y_ratio": 1.52
	}
]
const EXTERNAL_MODEL_MIN_LOT_WIDTH = 5.0
const EXTERNAL_MODEL_MIN_LOT_DEPTH = 4.6
const EXTERNAL_MODEL_MIN_LOT_AREA = 24.0
const CHICAGO_BRICK_PATTERN_WIDTH_PX = 32
const CHICAGO_BRICK_PATTERN_HEIGHT_PX = 10
const CHICAGO_MORTAR_WIDTH_PX = 2
const CHICAGO_BRICK_UV_SCALE = 5.4

static var _materials_ready = false
static var _wall_materials: Array[StandardMaterial3D] = []
static var _chicago_brick_materials: Array[StandardMaterial3D] = []
static var _roof_material: StandardMaterial3D
static var _trim_material: StandardMaterial3D
static var _glass_material: StandardMaterial3D
static var _stone_material: StandardMaterial3D
static var _chicago_limestone_material: StandardMaterial3D
static var _external_models_scanned = false
static var _external_building_specs: Array[Dictionary] = []

static func _ensure_materials() -> void:
	if _materials_ready:
		return
	_materials_ready = true

	var wall_colors = [
		Color8(165, 90, 62),
		Color8(147, 82, 66),
		Color8(178, 98, 70),
		Color8(132, 96, 76)
	]
	for c in wall_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = c
		mat.roughness = 0.88
		mat.metallic = 0.02
		mat.ao_enabled = true
		_wall_materials.append(mat)

	_chicago_brick_materials.clear()
	_chicago_brick_materials.append(_make_chicago_brick_material(
		Color8(146, 73, 50),
		Color8(190, 104, 70),
		Color8(196, 181, 165)
	))
	_chicago_brick_materials.append(_make_chicago_brick_material(
		Color8(138, 68, 48),
		Color8(182, 97, 67),
		Color8(205, 188, 171)
	))
	_chicago_brick_materials.append(_make_chicago_brick_material(
		Color8(158, 82, 58),
		Color8(198, 113, 79),
		Color8(210, 194, 178)
	))

	_roof_material = StandardMaterial3D.new()
	_roof_material.albedo_color = Color8(78, 70, 64)
	_roof_material.roughness = 0.92
	_roof_material.metallic = 0.0
	_roof_material.cull_mode = StandardMaterial3D.CULL_DISABLED

	_trim_material = StandardMaterial3D.new()
	_trim_material.albedo_color = Color8(205, 196, 182)
	_trim_material.roughness = 0.65

	_glass_material = StandardMaterial3D.new()
	_glass_material.albedo_color = Color8(89, 114, 136)
	_glass_material.roughness = 0.16
	_glass_material.metallic = 0.22
	_glass_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	_glass_material.cull_mode = StandardMaterial3D.CULL_BACK

	_stone_material = StandardMaterial3D.new()
	_stone_material.albedo_color = Color8(156, 154, 151)
	_stone_material.roughness = 0.9

	_chicago_limestone_material = StandardMaterial3D.new()
	_chicago_limestone_material.albedo_color = Color8(206, 196, 180)
	_chicago_limestone_material.roughness = 0.86
	_chicago_limestone_material.metallic = 0.0

static func _ensure_external_models() -> void:
	if _external_models_scanned:
		return
	_external_models_scanned = true
	_external_building_specs.clear()
	for raw_spec in EXTERNAL_BUILDING_MODEL_SPECS:
		if not (raw_spec is Dictionary):
			continue
		var spec: Dictionary = raw_spec
		var path = str(spec.get("path", ""))
		if path.is_empty():
			continue
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
			continue
		var res = load(path)
		if res is PackedScene:
			var entry = spec.duplicate(true)
			entry["scene"] = res as PackedScene
			_external_building_specs.append(entry)

static func create_building(footprint: Rect2, floors: int, front_is_south: bool, rng: RandomNumberGenerator) -> Dictionary:
	_ensure_materials()
	_ensure_external_models()

	var width = footprint.size.x
	var depth = footprint.size.y
	var area = width * depth
	var allow_external = (
		_external_building_specs.size() > 0
		and width >= EXTERNAL_MODEL_MIN_LOT_WIDTH
		and depth >= EXTERNAL_MODEL_MIN_LOT_DEPTH
		and area >= EXTERNAL_MODEL_MIN_LOT_AREA
	)
	if allow_external:
		var external_created = _create_external_building(footprint, floors, front_is_south, rng)
		if not external_created.is_empty() and external_created.has("node"):
			return external_created

	var root = Node3D.new()
	root.name = "Building"

	var floor_h = 4.9
	var body_h = float(floors) * floor_h + 1.2
	var center = Vector3(footprint.position.x + width * 0.5, 0.0, footprint.position.y + depth * 0.5)
	root.position = center

	var wall_mat: StandardMaterial3D = _wall_materials[rng.randi_range(0, _wall_materials.size() - 1)]
	var roof_parts: Array[MeshInstance3D] = []

	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(width, body_h, depth)
	base.mesh = base_mesh
	base.position = Vector3(0.0, body_h * 0.5, 0.0)
	base.material_override = wall_mat
	root.add_child(base)

	var cornice = MeshInstance3D.new()
	var cornice_mesh = BoxMesh.new()
	cornice_mesh.size = Vector3(width + 0.12, 0.18, depth + 0.12)
	cornice.mesh = cornice_mesh
	cornice.position = Vector3(0.0, body_h - 0.32, 0.0)
	cornice.material_override = _trim_material
	root.add_child(cornice)

	var roof_slab = MeshInstance3D.new()
	var slab_mesh = BoxMesh.new()
	slab_mesh.size = Vector3(width + 0.16, 0.26, depth + 0.16)
	roof_slab.mesh = slab_mesh
	roof_slab.position = Vector3(0.0, body_h + 0.13, 0.0)
	roof_slab.material_override = _roof_material
	roof_parts.append(roof_slab)
	root.add_child(roof_slab)

	var parapet_h = 0.82 + float(floors) * 0.16
	var parapet_t = 0.14
	for side in ["north", "south", "east", "west"]:
		var wall = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		var pos = Vector3.ZERO
		var side_h = clampf(parapet_h + rng.randf_range(-0.08, 0.16), 0.68, parapet_h + 0.24)
		if side == "north" or side == "south":
			mesh.size = Vector3(width + 0.18, side_h, parapet_t)
			pos = Vector3(0.0, body_h + side_h * 0.5, -depth * 0.5 - 0.01 if side == "north" else depth * 0.5 + 0.01)
		else:
			mesh.size = Vector3(parapet_t, side_h, depth + 0.18)
			pos = Vector3(-width * 0.5 - 0.01 if side == "west" else width * 0.5 + 0.01, body_h + side_h * 0.5, 0.0)
		wall.mesh = mesh
		wall.position = pos
		wall.material_override = _roof_material
		roof_parts.append(wall)
		root.add_child(wall)

	var mech = MeshInstance3D.new()
	var mech_mesh = BoxMesh.new()
	mech_mesh.size = Vector3(rng.randf_range(0.62, 0.88), rng.randf_range(0.36, 0.52), rng.randf_range(0.46, 0.72))
	mech.mesh = mech_mesh
	mech.position = Vector3(
		rng.randf_range(-width * 0.3, width * 0.3),
		body_h + mech_mesh.size.y * 0.5 + 0.12,
		rng.randf_range(-depth * 0.26, depth * 0.26)
	)
	mech.material_override = _stone_material
	roof_parts.append(mech)
	root.add_child(mech)

	var vent = MeshInstance3D.new()
	var vent_mesh = CylinderMesh.new()
	vent_mesh.top_radius = rng.randf_range(0.045, 0.075)
	vent_mesh.bottom_radius = vent_mesh.top_radius + rng.randf_range(0.012, 0.03)
	vent_mesh.height = rng.randf_range(0.54, 0.86)
	vent.mesh = vent_mesh
	vent.position = Vector3(
		rng.randf_range(-width * 0.32, width * 0.32),
		body_h + vent_mesh.height * 0.5 + 0.16,
		rng.randf_range(-depth * 0.3, depth * 0.3)
	)
	vent.material_override = _stone_material
	roof_parts.append(vent)
	root.add_child(vent)

	_add_rooftop_silhouette_profile(root, width, depth, body_h, parapet_h, rng, roof_parts)

	var half_w = width * 0.5
	var half_d = depth * 0.5
	var front_z = half_d if front_is_south else -half_d
	var front_sign = 1.0 if front_is_south else -1.0
	var side_inset = 0.025
	var front_inset = 0.02

	for floor_index in range(floors):
		var z0 = 0.72 + float(floor_index) * floor_h
		var z1 = min(body_h - 0.9, z0 + 2.15)
		var y_center = (z0 + z1) * 0.5
		var y_size = max(1.0, z1 - z0)

		var front_cols = max(2, int(floor((width - 1.0) / 1.45)))
		for c in range(front_cols):
			var tx = lerp(-half_w + 0.55, half_w - 0.55, float(c) / max(1.0, float(front_cols - 1)))
			_add_window_box(root, Vector3(0.72, y_size, 0.03), Vector3(tx, y_center, front_z - front_sign * front_inset), _glass_material)
			_add_trim_box(root, Vector3(0.82, 0.1, 0.05), Vector3(tx, z1 + 0.12, front_z - front_sign * 0.025), _trim_material)

		var side_cols = max(2, int(floor((depth - 1.2) / 1.45)))
		for c in range(side_cols):
			var tz = lerp(-half_d + 0.6, half_d - 0.6, float(c) / max(1.0, float(side_cols - 1)))
			_add_window_box(root, Vector3(0.03, y_size * 0.95, 0.72), Vector3(half_w - side_inset, y_center, tz), _glass_material)
			_add_window_box(root, Vector3(0.03, y_size * 0.95, 0.72), Vector3(-half_w + side_inset, y_center, tz), _glass_material)

	if floors <= 1:
		var stoop_depth = 0.62
		var stoop = MeshInstance3D.new()
		var stoop_mesh = BoxMesh.new()
		stoop_mesh.size = Vector3(width * 0.26, 0.16, stoop_depth)
		stoop.mesh = stoop_mesh
		stoop.position = Vector3(0.0, 0.08, front_z + front_sign * (stoop_depth * 0.5 + 0.02))
		stoop.material_override = _stone_material
		root.add_child(stoop)
	else:
		var bay = MeshInstance3D.new()
		var bay_mesh = BoxMesh.new()
		bay_mesh.size = Vector3(width * 0.34, 1.6, 0.48)
		bay.mesh = bay_mesh
		bay.position = Vector3(0.0, floor_h + 0.55, front_z + front_sign * 0.26)
		bay.material_override = _wall_materials[(rng.randi_range(0, _wall_materials.size() - 1))]
		root.add_child(bay)

	var brick_height = _chicago_brick_base_height(floors, body_h)
	_add_chicago_brick_base(root, width, depth, brick_height, rng)

	var resolved_h = max(body_h + parapet_h, _snap_building_to_ground(root))
	return {
		"node": root,
		"footprint": footprint,
		"height": resolved_h,
		"roof_parts": roof_parts,
		"front_is_south": front_is_south,
		"model_source": "procedural",
		"external_model_path": ""
	}

static func _add_rooftop_silhouette_profile(
	root: Node3D,
	width: float,
	depth: float,
	body_h: float,
	parapet_h: float,
	rng: RandomNumberGenerator,
	roof_parts: Array
) -> void:
	if root == null:
		return
	var roof_y = body_h + 0.14
	var profile = rng.randi_range(0, 3)

	if profile == 0:
		var bulk_w = clampf(width * rng.randf_range(0.26, 0.38), 1.05, 2.5)
		var bulk_d = clampf(depth * rng.randf_range(0.24, 0.36), 0.95, 2.2)
		var bulk_h = rng.randf_range(0.58, 0.96)
		_add_roof_box(root, Vector3(bulk_w, bulk_h, bulk_d), Vector3(0.0, roof_y + bulk_h * 0.5, 0.0), _stone_material, roof_parts)
		_add_roof_box(
			root,
			Vector3(bulk_w + 0.12, 0.1, bulk_d + 0.12),
			Vector3(0.0, roof_y + bulk_h + 0.05, 0.0),
			_trim_material,
			roof_parts
		)
	elif profile == 1:
		var tower_h = rng.randf_range(0.7, 1.15)
		var tower_w = clampf(minf(width, depth) * 0.16, 0.44, 0.72)
		var x_off = width * 0.5 - tower_w * 0.72
		var z_off = depth * 0.5 - tower_w * 0.72
		for side in [-1.0, 1.0]:
			var x = side * x_off
			var z = -z_off if side < 0.0 else z_off
			_add_roof_box(
				root,
				Vector3(tower_w, tower_h, tower_w),
				Vector3(x, roof_y + tower_h * 0.5, z),
				_stone_material,
				roof_parts
			)
	elif profile == 2:
		var tank_r = clampf(minf(width, depth) * 0.07, 0.2, 0.34)
		var leg_h = rng.randf_range(0.34, 0.56)
		var tank_h = rng.randf_range(0.34, 0.52)
		var tank_center = Vector3(rng.randf_range(-width * 0.18, width * 0.18), roof_y + leg_h + tank_h * 0.5, rng.randf_range(-depth * 0.18, depth * 0.18))
		var tank = MeshInstance3D.new()
		var tank_mesh = CylinderMesh.new()
		tank_mesh.top_radius = tank_r * 0.95
		tank_mesh.bottom_radius = tank_r
		tank_mesh.height = tank_h
		tank.mesh = tank_mesh
		tank.position = tank_center
		tank.material_override = _stone_material
		root.add_child(tank)
		roof_parts.append(tank)
		var leg_offset = tank_r * 0.82
		for lx in [-1.0, 1.0]:
			for lz in [-1.0, 1.0]:
				_add_roof_box(
					root,
					Vector3(0.06, leg_h, 0.06),
					Vector3(tank_center.x + lx * leg_offset, roof_y + leg_h * 0.5, tank_center.z + lz * leg_offset),
					_roof_material,
					roof_parts
				)
	else:
		if width >= 5.6:
			var span = clampf(width * 0.44, 2.0, 3.7)
			var post_h = rng.randf_range(0.8, 1.25)
			var z = -depth * 0.5 + 0.24
			for side in [-1.0, 1.0]:
				_add_roof_box(
					root,
					Vector3(0.08, post_h, 0.08),
					Vector3(side * span * 0.5, roof_y + post_h * 0.5, z),
					_roof_material,
					roof_parts
				)
			_add_roof_box(
				root,
				Vector3(span + 0.08, 0.08, 0.08),
				Vector3(0.0, roof_y + post_h, z),
				_trim_material,
				roof_parts
			)

	if rng.randf() < 0.58:
		var vent_count = rng.randi_range(2, 4)
		for i in range(vent_count):
			var v = MeshInstance3D.new()
			var vm = CylinderMesh.new()
			vm.top_radius = rng.randf_range(0.04, 0.065)
			vm.bottom_radius = vm.top_radius + rng.randf_range(0.01, 0.026)
			vm.height = rng.randf_range(0.3, 0.55)
			v.mesh = vm
			v.position = Vector3(
				rng.randf_range(-width * 0.34, width * 0.34),
				roof_y + vm.height * 0.5 + 0.08 + float(i) * 0.02,
				rng.randf_range(-depth * 0.34, depth * 0.34)
			)
			v.material_override = _roof_material
			root.add_child(v)
			roof_parts.append(v)

static func _add_roof_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, roof_parts: Array) -> MeshInstance3D:
	var box = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.position = pos
	box.material_override = material
	parent.add_child(box)
	if roof_parts != null:
		roof_parts.append(box)
	return box

static func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p := aabb.position
	var s := aabb.size
	return [
		p,
		p + Vector3(s.x, 0.0, 0.0),
		p + Vector3(0.0, s.y, 0.0),
		p + Vector3(0.0, 0.0, s.z),
		p + Vector3(s.x, s.y, 0.0),
		p + Vector3(s.x, 0.0, s.z),
		p + Vector3(0.0, s.y, s.z),
		p + s
	]

static func _compute_model_bounds(root: Node3D) -> AABB:
	var node_stack: Array[Node3D] = [root]
	var xf_stack: Array[Transform3D] = [Transform3D.IDENTITY]
	var has_point := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO

	while not node_stack.is_empty():
		var n: Node3D = node_stack.pop_back()
		var xf: Transform3D = xf_stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null:
				var local_aabb := mi.mesh.get_aabb().merge(mi.get_aabb())
				for corner in _aabb_corners(local_aabb):
					var p := xf * corner
					if not has_point:
						min_v = p
						max_v = p
						has_point = true
					else:
						min_v = min_v.min(p)
						max_v = max_v.max(p)
		for c in n.get_children():
			if c is Node3D:
				var child := c as Node3D
				node_stack.append(child)
				xf_stack.append(xf * child.transform)

	if not has_point:
		return AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	return AABB(min_v, max_v - min_v)

static func _snap_building_to_ground(root: Node3D, ground_y: float = 0.018) -> float:
	var bounds := _compute_model_bounds(root)
	var dy = ground_y - bounds.position.y
	root.position.y += dy
	return bounds.position.y + bounds.size.y + root.position.y

static func _make_chicago_brick_texture(base_color: Color, accent_color: Color, mortar_color: Color) -> Texture2D:
	var tex_w = 384
	var tex_h = 384
	var mortar_px = CHICAGO_MORTAR_WIDTH_PX
	var brick_w = CHICAGO_BRICK_PATTERN_WIDTH_PX
	var brick_h = CHICAGO_BRICK_PATTERN_HEIGHT_PX
	var row_step = brick_h + mortar_px
	var col_step = brick_w + mortar_px
	var img = Image.create(tex_w, tex_h, true, Image.FORMAT_RGBA8)
	img.fill(mortar_color)

	var row_count = int(ceil(float(tex_h + row_step) / float(row_step)))
	var col_count = int(ceil(float(tex_w + col_step * 2) / float(col_step)))
	for row in range(row_count):
		var y0 = row * row_step + mortar_px
		var row_shift = col_step / 2 if row % 2 == 1 else 0
		for col in range(col_count):
			var x0 = col * col_step - row_shift + mortar_px
			var x1 = x0 + brick_w
			var y1 = y0 + brick_h
			if x1 <= 0 or x0 >= tex_w or y1 <= 0 or y0 >= tex_h:
				continue

			var tone_mix = clampf(0.48 + 0.52 * sin(float(row) * 1.79 + float(col) * 2.21), 0.0, 1.0)
			var brick_color = base_color.lerp(accent_color, tone_mix * 0.56)
			if posmod(row + col * 2, 11) == 0:
				brick_color = brick_color.lerp(Color8(92, 57, 44), 0.36)
			elif posmod(row * 3 + col, 13) == 0:
				brick_color = brick_color.lerp(Color8(208, 140, 99), 0.24)
			var tone_mul = 0.93 + 0.09 * sin(float(row) * 3.4 + float(col) * 5.1)
			brick_color = Color(
				clampf(brick_color.r * tone_mul, 0.0, 1.0),
				clampf(brick_color.g * tone_mul, 0.0, 1.0),
				clampf(brick_color.b * tone_mul, 0.0, 1.0),
				1.0
			)

			var draw_x0 = maxi(0, x0)
			var draw_x1 = mini(tex_w, x1)
			var draw_y0 = maxi(0, y0)
			var draw_y1 = mini(tex_h, y1)
			for py in range(draw_y0, draw_y1):
				var local_y = py - y0
				var y_mul = 1.0
				if local_y <= 1:
					y_mul = 0.93
				elif local_y >= brick_h - 2:
					y_mul = 1.02
				for px in range(draw_x0, draw_x1):
					var local_x = px - x0
					var edge_mul = y_mul
					if local_x <= 1 or local_x >= brick_w - 2:
						edge_mul *= 0.94
					var soot_mix = clampf(0.1 + 0.2 * sin(float(px) * 0.13 + float(py) * 0.09), 0.0, 0.24)
					if posmod(row, 8) == 0:
						edge_mul *= (1.0 - soot_mix * 0.35)
					img.set_pixel(
						px,
						py,
						Color(
							clampf(brick_color.r * edge_mul, 0.0, 1.0),
							clampf(brick_color.g * edge_mul, 0.0, 1.0),
							clampf(brick_color.b * edge_mul, 0.0, 1.0),
							1.0
						)
					)

	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _make_chicago_brick_material(base_color: Color, accent_color: Color, mortar_color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = _make_chicago_brick_texture(base_color, accent_color, mortar_color)
	mat.albedo_color = Color.WHITE
	mat.roughness = 0.92
	mat.metallic = 0.0
	mat.ao_enabled = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_scale = Vector3(CHICAGO_BRICK_UV_SCALE, CHICAGO_BRICK_UV_SCALE, 1.0)
	return mat

static func brick_style_metrics() -> Dictionary:
	return {
		"uv_scale": CHICAGO_BRICK_UV_SCALE,
		"brick_px_w": CHICAGO_BRICK_PATTERN_WIDTH_PX,
		"brick_px_h": CHICAGO_BRICK_PATTERN_HEIGHT_PX,
		"mortar_px": CHICAGO_MORTAR_WIDTH_PX
	}

static func _chicago_brick_base_height(floors: int, total_height: float) -> float:
	var story_count = clampi(floors, 1, 4)
	var desired = 3.6 + float(story_count - 1) * 2.55
	var cap_by_height = maxf(3.35, total_height * 0.72)
	return clampf(desired, 3.35, cap_by_height)

static func _add_chicago_brick_base(parent: Node3D, width: float, depth: float, brick_height: float, rng: RandomNumberGenerator) -> void:
	if parent == null:
		return
	if width <= 1.3 or depth <= 1.3 or brick_height <= 0.2:
		return

	var brick_material: Material = _wall_materials[0]
	if not _chicago_brick_materials.is_empty():
		brick_material = _chicago_brick_materials[rng.randi_range(0, _chicago_brick_materials.size() - 1)]
	var band_material: Material = _trim_material if _trim_material != null else brick_material
	if _chicago_limestone_material != null:
		band_material = _chicago_limestone_material

	var shell_t = clampf(minf(width, depth) * 0.045, 0.18, 0.32)
	var edge_inset = clampf(minf(width, depth) * 0.012, 0.02, 0.08)
	var half_w = width * 0.5
	var half_d = depth * 0.5
	var ns_width = maxf(0.7, width - edge_inset * 2.0)
	var ew_depth = maxf(0.7, depth - edge_inset * 2.0 - shell_t * 2.0)

	var side_panels = [
		{
			"size": Vector3(ns_width, brick_height, shell_t),
			"pos": Vector3(0.0, brick_height * 0.5, -half_d + edge_inset + shell_t * 0.5)
		},
		{
			"size": Vector3(ns_width, brick_height, shell_t),
			"pos": Vector3(0.0, brick_height * 0.5, half_d - edge_inset - shell_t * 0.5)
		},
		{
			"size": Vector3(shell_t, brick_height, ew_depth),
			"pos": Vector3(-half_w + edge_inset + shell_t * 0.5, brick_height * 0.5, 0.0)
		},
		{
			"size": Vector3(shell_t, brick_height, ew_depth),
			"pos": Vector3(half_w - edge_inset - shell_t * 0.5, brick_height * 0.5, 0.0)
		}
	]
	for spec in side_panels:
		var panel = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		var panel_size: Vector3 = spec.get("size", Vector3.ONE)
		var panel_pos: Vector3 = spec.get("pos", Vector3.ZERO)
		mesh.size = panel_size
		panel.mesh = mesh
		panel.position = panel_pos
		panel.material_override = brick_material
		parent.add_child(panel)

	var belt = MeshInstance3D.new()
	var belt_mesh = BoxMesh.new()
	belt_mesh.size = Vector3(
		maxf(0.8, width - edge_inset * 2.0 + 0.04),
		0.14,
		maxf(0.8, depth - edge_inset * 2.0 + 0.04)
	)
	belt.mesh = belt_mesh
	belt.position = Vector3(0.0, brick_height + 0.07, 0.0)
	belt.material_override = band_material
	parent.add_child(belt)

static func _make_external_roof_cap(width: float, depth: float, top_y: float) -> MeshInstance3D:
	var cap = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	var cap_h = clampf(maxf(width, depth) * 0.06, 0.22, 0.58)
	mesh.size = Vector3(width + 0.18, cap_h, depth + 0.18)
	cap.mesh = mesh
	cap.position = Vector3(0.0, top_y - cap_h * 0.5 + 0.02, 0.0)
	cap.material_override = _roof_material
	return cap

static func _create_external_building(footprint: Rect2, floors: int, front_is_south: bool, rng: RandomNumberGenerator) -> Dictionary:
	var width = footprint.size.x
	var depth = footprint.size.y
	var area = width * depth
	var target_h = max(8.8, float(floors) * 5.0 + 1.8)
	var center = Vector3(footprint.position.x + width * 0.5, 0.0, footprint.position.y + depth * 0.5)
	var compatible_specs: Array[Dictionary] = []
	for spec in _external_building_specs:
		var min_floors = int(spec.get("min_floors", 1))
		var max_floors = int(spec.get("max_floors", 99))
		if floors < min_floors or floors > max_floors:
			continue
		if width < float(spec.get("min_width", 0.0)):
			continue
		if depth < float(spec.get("min_depth", 0.0)):
			continue
		if area < float(spec.get("min_area", 0.0)):
			continue
		compatible_specs.append(spec)

	while not compatible_specs.is_empty():
		var spec_idx = rng.randi_range(0, compatible_specs.size() - 1)
		var spec: Dictionary = compatible_specs[spec_idx]
		compatible_specs.remove_at(spec_idx)

		var packed: PackedScene = spec.get("scene", null)
		if packed == null:
			continue
		var model = packed.instantiate()
		if not (model is Node3D):
			continue

		var model_root: Node3D = model as Node3D
		var bounds := _compute_model_bounds(model_root)
		if bounds.size.x <= 0.01 or bounds.size.y <= 0.01 or bounds.size.z <= 0.01:
			model_root.free()
			continue

		var parcel_ratio = width / maxf(depth, 0.01)
		var model_ratio = bounds.size.x / maxf(bounds.size.z, 0.01)
		var score_same = absf(model_ratio - parcel_ratio)
		var score_rot = absf((1.0 / maxf(model_ratio, 0.01)) - parcel_ratio)
		if score_rot + 0.03 < score_same:
			model_root.rotation.y += PI * 0.5
			bounds = _compute_model_bounds(model_root)

		var fit_scale_x: float = (width * 0.94) / maxf(bounds.size.x, 0.05)
		var fit_scale_z: float = (depth * 0.94) / maxf(bounds.size.z, 0.05)
		var footprint_scale: float = clampf(minf(fit_scale_x, fit_scale_z), 0.02, 28.0)
		model_root.scale = Vector3.ONE * footprint_scale
		bounds = _compute_model_bounds(model_root)

		var current_h: float = maxf(bounds.size.y, 0.05)
		var y_ratio_raw: float = target_h / current_h
		var min_y_ratio = float(spec.get("min_y_ratio", 0.86))
		var max_y_ratio = float(spec.get("max_y_ratio", 1.55))
		if y_ratio_raw < min_y_ratio or y_ratio_raw > max_y_ratio:
			model_root.free()
			continue
		model_root.scale.y *= clampf(y_ratio_raw, min_y_ratio, max_y_ratio)
		bounds = _compute_model_bounds(model_root)

		model_root.position = Vector3(
			-(bounds.position.x + bounds.size.x * 0.5),
			-bounds.position.y,
			-(bounds.position.z + bounds.size.z * 0.5)
		)
		if not front_is_south:
			model_root.rotation.y += PI
			bounds = _compute_model_bounds(model_root)
			model_root.position += Vector3(
				-(bounds.position.x + bounds.size.x * 0.5),
				-bounds.position.y,
				-(bounds.position.z + bounds.size.z * 0.5)
			)

		var root = Node3D.new()
		root.name = "BuildingExternal"
		root.position = center
		root.add_child(model_root)

		bounds = _compute_model_bounds(model_root)
		var top_y = bounds.position.y + bounds.size.y
		var brick_height = _chicago_brick_base_height(floors, top_y)
		var brick_height_cap = clampf(top_y * 0.72, 3.35, maxf(3.35, top_y - 0.6))
		brick_height = minf(brick_height, brick_height_cap)
		_add_chicago_brick_base(root, width * 0.94, depth * 0.94, brick_height, rng)
		var roof_cap = _make_external_roof_cap(width, depth, top_y)
		root.add_child(roof_cap)

		var roof_parts: Array[Node3D] = _collect_roof_nodes(model_root)
		roof_parts.append(roof_cap)
		_add_external_rooftop_polish(root, width, depth, top_y, rng, roof_parts)
		var resolved_h = max(top_y, roof_cap.position.y + (roof_cap.mesh as BoxMesh).size.y * 0.5)
		resolved_h = max(resolved_h, _snap_building_to_ground(root))

		return {
			"node": root,
			"footprint": footprint,
			"height": resolved_h,
			"roof_parts": roof_parts,
			"front_is_south": front_is_south,
			"model_source": "external",
			"external_model_path": str(spec.get("path", ""))
		}

	# No compatible external model found; let caller fall back to procedural generation.
	return {}

static func _add_external_rooftop_polish(
	root: Node3D,
	width: float,
	depth: float,
	roof_y: float,
	rng: RandomNumberGenerator,
	roof_parts: Array
) -> void:
	if root == null:
		return

	if rng.randf() < 0.74:
		var pent_w = clampf(width * rng.randf_range(0.18, 0.32), 0.9, 2.1)
		var pent_d = clampf(depth * rng.randf_range(0.18, 0.3), 0.86, 1.9)
		var pent_h = rng.randf_range(0.35, 0.7)
		var pent_x = rng.randf_range(-width * 0.22, width * 0.22)
		var pent_z = rng.randf_range(-depth * 0.22, depth * 0.22)
		_add_roof_box(
			root,
			Vector3(pent_w, pent_h, pent_d),
			Vector3(pent_x, roof_y + pent_h * 0.5 + 0.08, pent_z),
			_stone_material,
			roof_parts
		)

	if rng.randf() < 0.66:
		var skylight_count = rng.randi_range(2, 4)
		for i in range(skylight_count):
			var sky_w = rng.randf_range(0.16, 0.32)
			var sky_d = rng.randf_range(0.24, 0.46)
			var sky_h = rng.randf_range(0.07, 0.13)
			_add_roof_box(
				root,
				Vector3(sky_w, sky_h, sky_d),
				Vector3(
					rng.randf_range(-width * 0.32, width * 0.32),
					roof_y + sky_h * 0.5 + 0.05 + float(i) * 0.01,
					rng.randf_range(-depth * 0.3, depth * 0.3)
				),
				_glass_material,
				roof_parts
			)

	if width >= 6.2 and rng.randf() < 0.34:
		var span = clampf(width * 0.36, 2.0, 3.8)
		var post_h = rng.randf_range(0.62, 0.96)
		var z = depth * 0.5 - 0.26
		for side in [-1.0, 1.0]:
			_add_roof_box(
				root,
				Vector3(0.08, post_h, 0.08),
				Vector3(side * span * 0.5, roof_y + post_h * 0.5 + 0.05, z),
				_roof_material,
				roof_parts
			)
		_add_roof_box(
			root,
			Vector3(span + 0.08, 0.08, 0.08),
			Vector3(0.0, roof_y + post_h + 0.05, z),
			_trim_material,
			roof_parts
		)

static func _collect_roof_nodes(root: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var lname := n.name.to_lower()
		if n is Node3D and (lname.contains("roof") or lname.contains("top") or lname.contains("parapet")):
			out.append(n as Node3D)
		for c in n.get_children():
			stack.append(c)
	return out

static func _add_window_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var m = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	m.mesh = box
	m.position = pos
	m.material_override = material
	parent.add_child(m)

static func _add_trim_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> void:
	var m = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	m.mesh = box
	m.position = pos
	m.material_override = material
	parent.add_child(m)
