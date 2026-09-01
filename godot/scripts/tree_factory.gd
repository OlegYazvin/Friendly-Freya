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
	return root

static func create_forest_visuals(tree_entries: Array, parent: Node3D) -> Node3D:
	_ensure_materials()
	var forest = Node3D.new()
	forest.name = "BatchedForest"
	parent.add_child(forest)
	if tree_entries.is_empty():
		return forest
	var chunks: Dictionary = {}
	for entry in tree_entries:
		if not (entry is Dictionary):
			continue
		var p: Vector2 = (entry as Dictionary).get("pos", Vector2.ZERO)
		var cell = Vector2i(int(floor(p.x / 56.0)), int(floor(p.y / 56.0)))
		var chunk_entries: Array = chunks.get(cell, [])
		chunk_entries.append(entry)
		chunks[cell] = chunk_entries
	for cell in chunks.keys():
		_add_forest_chunk(chunks[cell], forest, "%d_%d" % [(cell as Vector2i).x, (cell as Vector2i).y])
	return forest

static func _add_forest_chunk(tree_entries: Array, forest: Node3D, chunk_name: String) -> void:
	var trunk_transforms: Array[Transform3D] = []
	var branch_transforms: Array[Transform3D] = []
	var canopy_groups: Array = [[], [], []]
	for tree_index in range(tree_entries.size()):
		var entry: Dictionary = tree_entries[tree_index]
		var p2: Vector2 = entry.get("pos", Vector2.ZERO)
		var tree_scale = float(entry.get("scale", 1.0))
		var base = Vector3(p2.x, 0.0, p2.y)
		trunk_transforms.append(Transform3D(
			Basis().scaled(Vector3.ONE * tree_scale),
			base + Vector3(0.0, 1.3 * tree_scale, 0.0)
		))
		for branch_index in range(2):
			var branch_pitch = deg_to_rad(-35.0 + sin(float(tree_index * 7 + branch_index * 13)) * 7.0)
			var branch_yaw = deg_to_rad(float(branch_index) * 180.0 + sin(float(tree_index * 11 + branch_index * 5)) * 12.0)
			var branch_basis = Basis.from_euler(Vector3(branch_pitch, branch_yaw, 0.0)).scaled(Vector3.ONE * tree_scale)
			branch_transforms.append(Transform3D(branch_basis, base + Vector3(0.0, 2.1 * tree_scale, 0.0)))

		var leaf_group = posmod(tree_index, canopy_groups.size())
		var canopy_transforms: Array = canopy_groups[leaf_group]
		for canopy_index in range(4):
			var ang = float(canopy_index) / 4.0 * TAU
			var radial_jitter = sin(float(tree_index * 17 + canopy_index * 23)) * 0.08
			var radius = (0.6 + radial_jitter) * tree_scale
			var y_jitter = sin(float(tree_index * 19 + canopy_index * 29)) * 0.2
			var shape_x = 0.88 + 0.12 * sin(float(tree_index * 3 + canopy_index * 7))
			var shape_y = 0.84 + 0.14 * cos(float(tree_index * 5 + canopy_index * 11))
			var shape_z = 0.88 + 0.12 * cos(float(tree_index * 7 + canopy_index * 3))
			canopy_transforms.append(Transform3D(
				Basis().scaled(Vector3(shape_x, shape_y, shape_z) * tree_scale),
				base + Vector3(cos(ang) * radius, 2.5 * tree_scale + y_jitter, sin(ang) * radius)
			))
		canopy_transforms.append(Transform3D(
			Basis().scaled(Vector3(1.0, 1.0, 1.0) * tree_scale),
			base + Vector3(0.0, 3.05 * tree_scale, 0.0)
		))
		canopy_groups[leaf_group] = canopy_transforms

	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.15
	trunk_mesh.height = 2.6
	_add_multimesh(forest, "TreeTrunks_%s" % chunk_name, trunk_mesh, _trunk_mat, trunk_transforms)

	var branch_mesh = CylinderMesh.new()
	branch_mesh.top_radius = 0.04
	branch_mesh.bottom_radius = 0.06
	branch_mesh.height = 1.05
	_add_multimesh(forest, "TreeBranches_%s" % chunk_name, branch_mesh, _trunk_mat, branch_transforms)

	var canopy_mesh = SphereMesh.new()
	canopy_mesh.radius = 0.5
	canopy_mesh.height = 1.0
	canopy_mesh.radial_segments = 8
	canopy_mesh.rings = 4
	for group_index in range(canopy_groups.size()):
		var transforms: Array[Transform3D] = []
		for transform in canopy_groups[group_index]:
			transforms.append(transform as Transform3D)
		_add_multimesh(forest, "TreeCanopies%d_%s" % [group_index, chunk_name], canopy_mesh, _leaf_mats[group_index], transforms)

static func _add_multimesh(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	material: Material,
	transforms: Array[Transform3D]
) -> void:
	if transforms.is_empty():
		return
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
	var instance = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
