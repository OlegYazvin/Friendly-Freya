extends RefCounted
class_name TreeFactory

static var _materials_ready = false
static var _trunk_mat: StandardMaterial3D
static var _leaf_mats: Array[StandardMaterial3D] = []

static func _ensure_materials() -> void:
	if _materials_ready:
		return
	_materials_ready = true

	_trunk_mat = StandardMaterial3D.new()
	_trunk_mat.albedo_color = Color8(98, 70, 46)
	_trunk_mat.roughness = 0.92

	for c in [Color8(58, 131, 66), Color8(69, 148, 74), Color8(76, 158, 83)]:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = c
		mat.roughness = 0.93
		mat.metallic = 0.0
		_leaf_mats.append(mat)

static func create_tree(pos: Vector3, tree_scale: float, rng: RandomNumberGenerator) -> Node3D:
	_ensure_materials()

	var root = Node3D.new()
	root.name = "Tree"
	root.position = pos

	var shadow = MeshInstance3D.new()
	var shadow_mesh = CylinderMesh.new()
	shadow_mesh.top_radius = 0.62 * tree_scale
	shadow_mesh.bottom_radius = 0.62 * tree_scale
	shadow_mesh.height = 0.03
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.0, 0.02, 0.0)
	var shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.05, 0.1, 0.05, 0.22)
	shadow_mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	shadow.material_override = shadow_mat
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.12 * tree_scale
	trunk_mesh.bottom_radius = 0.15 * tree_scale
	trunk_mesh.height = 2.6 * tree_scale
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0.0, 1.3 * tree_scale, 0.0)
	trunk.material_override = _trunk_mat
	root.add_child(trunk)

	for i in range(4):
		var branch = MeshInstance3D.new()
		var branch_mesh = CylinderMesh.new()
		branch_mesh.top_radius = 0.04 * tree_scale
		branch_mesh.bottom_radius = 0.06 * tree_scale
		branch_mesh.height = 1.05 * tree_scale
		branch.mesh = branch_mesh
		branch.position = Vector3(0.0, 2.1 * tree_scale, 0.0)
		branch.rotation_degrees = Vector3(-35.0 + rng.randf_range(-8.0, 8.0), float(i) * 90.0 + rng.randf_range(-12.0, 12.0), 0.0)
		branch.material_override = _trunk_mat
		root.add_child(branch)

	for i in range(8):
		var canopy = MeshInstance3D.new()
		var canopy_mesh = SphereMesh.new()
		canopy_mesh.radius = 0.44 * tree_scale
		canopy_mesh.height = 0.88 * tree_scale
		canopy.mesh = canopy_mesh
		var ang = float(i) / 8.0 * TAU
		var radius = 0.6 * tree_scale + rng.randf_range(-0.08, 0.1)
		canopy.position = Vector3(
			cos(ang) * radius,
			2.5 * tree_scale + rng.randf_range(-0.18, 0.28),
			sin(ang) * radius
		)
		canopy.scale = Vector3(
			rng.randf_range(0.95, 1.2),
			rng.randf_range(0.9, 1.2),
			rng.randf_range(0.95, 1.2)
		)
		canopy.material_override = _leaf_mats[rng.randi_range(0, _leaf_mats.size() - 1)]
		root.add_child(canopy)

	var top = MeshInstance3D.new()
	var top_mesh = SphereMesh.new()
	top_mesh.radius = 0.5 * tree_scale
	top_mesh.height = 1.0 * tree_scale
	top.mesh = top_mesh
	top.position = Vector3(0.0, 3.05 * tree_scale, 0.0)
	top.material_override = _leaf_mats[rng.randi_range(0, _leaf_mats.size() - 1)]
	root.add_child(top)

	return root
