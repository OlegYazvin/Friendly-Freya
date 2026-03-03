extends RefCounted
class_name BuildingFactory

const EXTERNAL_BUILDING_MODEL_PATHS = [
	"res://assets/models/buildings/building_apartment.glb",
	"res://assets/models/buildings/building_large_01.glb",
	"res://assets/models/buildings/building_large_02.glb",
	"res://assets/models/buildings/building_house.glb",
	"res://assets/models/buildings/building_roofgarden.glb",
	"res://assets/models/buildings/building_big.glb"
]

static var _materials_ready = false
static var _wall_materials: Array[StandardMaterial3D] = []
static var _roof_material: StandardMaterial3D
static var _trim_material: StandardMaterial3D
static var _glass_material: StandardMaterial3D
static var _stone_material: StandardMaterial3D
static var _external_models_scanned = false
static var _external_building_scenes: Array[PackedScene] = []

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

static func _ensure_external_models() -> void:
	if _external_models_scanned:
		return
	_external_models_scanned = true
	_external_building_scenes.clear()
	for path in EXTERNAL_BUILDING_MODEL_PATHS:
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
			continue
		var res = load(path)
		if res is PackedScene:
			_external_building_scenes.append(res as PackedScene)

static func create_building(footprint: Rect2, floors: int, front_is_south: bool, rng: RandomNumberGenerator) -> Dictionary:
	_ensure_materials()
	_ensure_external_models()
	if _external_building_scenes.size() > 0:
		return _create_external_building(footprint, floors, front_is_south, rng)

	var root = Node3D.new()
	root.name = "Building"

	var width = footprint.size.x
	var depth = footprint.size.y
	var floor_h = 4.25
	var body_h = float(floors) * floor_h + 0.9
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
		if side == "north" or side == "south":
			mesh.size = Vector3(width + 0.18, parapet_h, parapet_t)
			pos = Vector3(0.0, body_h + parapet_h * 0.5, -depth * 0.5 - 0.01 if side == "north" else depth * 0.5 + 0.01)
		else:
			mesh.size = Vector3(parapet_t, parapet_h, depth + 0.18)
			pos = Vector3(-width * 0.5 - 0.01 if side == "west" else width * 0.5 + 0.01, body_h + parapet_h * 0.5, 0.0)
		wall.mesh = mesh
		wall.position = pos
		wall.material_override = _roof_material
		roof_parts.append(wall)
		root.add_child(wall)

	var mech = MeshInstance3D.new()
	var mech_mesh = BoxMesh.new()
	mech_mesh.size = Vector3(0.72, 0.44, 0.55)
	mech.mesh = mech_mesh
	mech.position = Vector3(width * 0.18 - width * 0.5, body_h + 0.4, -depth * 0.17)
	mech.material_override = _stone_material
	roof_parts.append(mech)
	root.add_child(mech)

	var vent = MeshInstance3D.new()
	var vent_mesh = CylinderMesh.new()
	vent_mesh.top_radius = 0.06
	vent_mesh.bottom_radius = 0.08
	vent_mesh.height = 0.7
	vent.mesh = vent_mesh
	vent.position = Vector3(width * 0.28 - width * 0.5, body_h + 0.54, depth * 0.22)
	vent.material_override = _stone_material
	roof_parts.append(vent)
	root.add_child(vent)

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

	var resolved_h = max(body_h + parapet_h, _snap_building_to_ground(root))
	return {
		"node": root,
		"footprint": footprint,
		"height": resolved_h,
		"roof_parts": roof_parts,
		"front_is_south": front_is_south
	}

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
	var root = Node3D.new()
	root.name = "BuildingExternal"

	var width = footprint.size.x
	var depth = footprint.size.y
	var target_h = max(6.8, float(floors) * 4.35 + 1.4)
	var center = Vector3(footprint.position.x + width * 0.5, 0.0, footprint.position.y + depth * 0.5)
	root.position = center

	var packed: PackedScene = _external_building_scenes[rng.randi_range(0, _external_building_scenes.size() - 1)]
	var model = packed.instantiate()
	if model is Node3D:
		var model_root: Node3D = model as Node3D
		root.add_child(model_root)
		var bounds := _compute_model_bounds(model_root)

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
		var y_ratio: float = clampf(target_h / current_h, 0.84, 1.9)
		model_root.scale.y *= y_ratio
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

		bounds = _compute_model_bounds(model_root)
		var top_y = bounds.position.y + bounds.size.y
		var roof_cap = _make_external_roof_cap(width, depth, top_y)
		root.add_child(roof_cap)

		var roof_parts: Array[Node3D] = _collect_roof_nodes(model_root)
		roof_parts.append(roof_cap)
		var resolved_h = max(top_y, roof_cap.position.y + (roof_cap.mesh as BoxMesh).size.y * 0.5)
		resolved_h = max(resolved_h, _snap_building_to_ground(root))

		return {
			"node": root,
			"footprint": footprint,
			"height": max(target_h, resolved_h),
			"roof_parts": roof_parts,
			"front_is_south": front_is_south
		}

	# Safety fallback if instantiate did not produce Node3D.
	var fallback_body = MeshInstance3D.new()
	var fallback_mesh = BoxMesh.new()
	fallback_mesh.size = Vector3(width, max(6.4, float(floors) * 4.25), depth)
	fallback_body.mesh = fallback_mesh
	fallback_body.position = Vector3(0.0, fallback_mesh.size.y * 0.5, 0.0)
	fallback_body.material_override = _wall_materials[rng.randi_range(0, _wall_materials.size() - 1)]
	root.add_child(fallback_body)
	var fallback_h = max(fallback_mesh.size.y, _snap_building_to_ground(root))
	return {
		"node": root,
		"footprint": footprint,
		"height": fallback_h,
		"roof_parts": [fallback_body],
		"front_is_south": front_is_south
	}

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
