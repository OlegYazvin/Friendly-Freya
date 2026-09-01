extends RefCounted
class_name BuildingFactory

const EXTERNAL_BUILDING_MODEL_SPECS = [
	{
		"path": "res://assets/models/buildings/building_house.glb",
		"min_floors": 1,
		"max_floors": 1,
		"min_width": 4.4,
		"min_depth": 4.2,
		"min_area": 18.0,
		"min_y_ratio": 0.78,
		"max_y_ratio": 1.28
	}
]
const EXTERNAL_MODEL_MIN_LOT_WIDTH = 5.0
const EXTERNAL_MODEL_MIN_LOT_DEPTH = 4.6
const EXTERNAL_MODEL_MIN_LOT_AREA = 24.0
# Imported house roofs do not align reliably with generated metric lots. Keep
# neighborhood shells on one construction system so eaves and walls agree.
const EXTERNAL_HOUSE_MODEL_CHANCE = 0.0
const CHICAGO_BRICK_PATTERN_WIDTH_PX = 32
const CHICAGO_BRICK_PATTERN_HEIGHT_PX = 10
const CHICAGO_MORTAR_WIDTH_PX = 2
# World-space triplanar mapping keeps a brick close to a real modular brick
# (about 20.3 x 6.8 cm including mortar) on every wall, independent of lot size.
const CHICAGO_BRICK_UV_SCALE = 0.42
const CHICAGO_BRICK_WORLD_WIDTH_M = 0.211
const CHICAGO_BRICK_WORLD_HEIGHT_M = 0.074

static var _materials_ready = false
static var _wall_materials: Array[StandardMaterial3D] = []
static var _chicago_brick_materials: Array[StandardMaterial3D] = []
static var _roof_material: StandardMaterial3D
static var _roof_materials: Array[StandardMaterial3D] = []
static var _trim_material: StandardMaterial3D
static var _soffit_material: StandardMaterial3D
static var _contact_shadow_material: StandardMaterial3D
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
		Color8(218, 205, 180),
		Color8(181, 199, 182),
		Color8(177, 197, 211),
		Color8(224, 218, 202),
		Color8(172, 111, 83)
	]
	for c in wall_colors:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.WHITE
		mat.albedo_texture = _make_suburban_siding_texture(c)
		mat.roughness = 0.88
		mat.metallic = 0.02
		mat.ao_enabled = true
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * 0.62
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

	_roof_materials.clear()
	for roof_color in [Color8(68, 73, 76), Color8(92, 79, 69), Color8(72, 83, 70)]:
		var roof_mat = StandardMaterial3D.new()
		roof_mat.albedo_color = Color.WHITE
		roof_mat.albedo_texture = _make_asphalt_shingle_texture(roof_color)
		roof_mat.roughness = 0.94
		roof_mat.metallic = 0.0
		roof_mat.cull_mode = StandardMaterial3D.CULL_DISABLED
		roof_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		roof_mat.uv1_triplanar = true
		roof_mat.uv1_world_triplanar = true
		roof_mat.uv1_scale = Vector3.ONE * 0.78
		roof_mat.ao_enabled = true
		roof_mat.ao_light_affect = 0.34
		_roof_materials.append(roof_mat)
	_roof_material = _roof_materials[0]

	_trim_material = StandardMaterial3D.new()
	_trim_material.albedo_color = Color8(235, 232, 220)
	_trim_material.roughness = 0.65

	_soffit_material = StandardMaterial3D.new()
	_soffit_material.albedo_color = Color8(207, 205, 194)
	_soffit_material.roughness = 0.8
	_soffit_material.ao_enabled = true

	_contact_shadow_material = StandardMaterial3D.new()
	_contact_shadow_material.albedo_color = Color(0.08, 0.09, 0.085, 0.24)
	_contact_shadow_material.roughness = 1.0
	_contact_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_contact_shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED

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
	floors = clampi(floors, 1, 3)

	var width = footprint.size.x
	var depth = footprint.size.y
	var area = width * depth
	var allow_external = (
		_external_building_specs.size() > 0
		and floors == 1
		and width >= EXTERNAL_MODEL_MIN_LOT_WIDTH
		and depth >= EXTERNAL_MODEL_MIN_LOT_DEPTH
		and area >= EXTERNAL_MODEL_MIN_LOT_AREA
		and rng.randf() < EXTERNAL_HOUSE_MODEL_CHANCE
	)
	if allow_external:
		var external_created = _create_external_building(footprint, floors, front_is_south, rng)
		if not external_created.is_empty() and external_created.has("node"):
			return external_created

	var root = Node3D.new()
	root.name = "Building"

	var floor_h = 2.78
	var body_h = float(floors) * floor_h + 0.24
	var center = Vector3(footprint.position.x + width * 0.5, 0.0, footprint.position.y + depth * 0.5)
	root.position = center

	var wall_mat: StandardMaterial3D = _wall_materials[rng.randi_range(0, _wall_materials.size() - 1)]
	var roof_parts: Array = []

	var base = MeshInstance3D.new()
	base.name = "BuildingBody"
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(width, body_h, depth)
	base.mesh = base_mesh
	base.position = Vector3(0.0, body_h * 0.5, 0.0)
	base.material_override = wall_mat
	root.add_child(base)
	_add_foundation_contact_shadow(root, width, depth)

	var roof_rise = clampf(minf(width, depth) * rng.randf_range(0.2, 0.26), 0.88, 1.46)
	var roof_ridge_axis = "x" if width >= depth else "z"
	var roof_material_index = rng.randi_range(0, _roof_materials.size() - 1)
	var roof_material: StandardMaterial3D = _roof_materials[roof_material_index]
	var roof_style = "gable"
	if rng.randf() < 0.34:
		roof_style = "hip"
		_add_suburban_hip_roof(root, width, depth, body_h, roof_rise, roof_material, roof_parts)
	else:
		_add_suburban_gable_roof(root, width, depth, body_h, roof_rise, wall_mat, roof_material, roof_parts)
	if rng.randf() < 0.54:
		_add_suburban_chimney(root, width, depth, body_h, roof_rise, rng, roof_parts)

	var half_w = width * 0.5
	var half_d = depth * 0.5
	var front_z = half_d if front_is_south else -half_d
	var front_sign = 1.0 if front_is_south else -1.0
	var window_transforms: Array[Transform3D] = []
	var window_size = Vector3(0.72, 1.08, 0.04)
	for floor_index in range(floors):
		var y_center = 1.48 + float(floor_index) * floor_h
		var front_cols = clampi(int(floor((width - 0.9) / 1.7)), 2, 4)
		for c in range(front_cols):
			var tx = lerp(-half_w + 0.72, half_w - 0.72, float(c) / max(1.0, float(front_cols - 1)))
			window_transforms.append(Transform3D(Basis.IDENTITY, Vector3(tx, y_center, front_z + front_sign * 0.025)))

		var side_cols = clampi(int(floor((depth - 1.4) / 2.25)), 1, 3)
		for c in range(side_cols):
			var tz = lerp(-half_d + 0.82, half_d - 0.82, float(c) / max(1.0, float(side_cols - 1))) if side_cols > 1 else 0.0
			window_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(half_w + 0.025, y_center, tz)))
			window_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-half_w - 0.025, y_center, tz)))
	_add_box_multimesh(root, window_size, window_transforms, _glass_material, "Windows", false, 76.0)

	var porch_style = _add_suburban_front_porch(root, width, front_z, front_sign, rng)

	var brick_height = _chicago_brick_base_height(floors, body_h)
	_add_chicago_brick_base(root, width, depth, brick_height, rng)

	var resolved_h = max(body_h + roof_rise, _snap_building_to_ground(root))
	return {
		"node": root,
		"footprint": footprint,
		"height": resolved_h,
		"body_height": body_h,
		"roof_eave_y": body_h - 0.12,
		"roof_rise": roof_rise,
		"roof_ridge_axis": roof_ridge_axis,
		"roof_material_index": roof_material_index,
		"roof_parts": roof_parts,
		"roof_style": roof_style,
		"porch_style": porch_style,
		"front_is_south": front_is_south,
		"model_source": "procedural",
		"external_model_path": ""
	}

static func _add_box_multimesh(
	parent: Node3D,
	size: Vector3,
	transforms: Array[Transform3D],
	material: Material,
	node_name: String,
	cast_shadows: bool = false,
	visibility_end: float = 0.0
) -> MultiMeshInstance3D:
	if parent == null or transforms.is_empty():
		return null
	var box = BoxMesh.new()
	box.size = size
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
	var instance = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = mm
	instance.material_override = material
	instance.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if cast_shadows
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	if visibility_end > 0.0:
		instance.visibility_range_end = visibility_end
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(instance)
	return instance

static func _add_suburban_gable_roof(
	root: Node3D,
	width: float,
	depth: float,
	body_h: float,
	roof_rise: float,
	wall_material: Material,
	roof_material: Material,
	roof_parts: Array
) -> void:
	var ridge_along_x = width >= depth
	var run_span = depth if ridge_along_x else width
	var half_run = run_span * 0.5 + 0.24
	var eave_y = body_h - 0.12
	var ridge_y = body_h + roof_rise
	var roof_span_y = ridge_y - eave_y
	var pitch = atan2(roof_span_y, half_run)
	var panel_length = sqrt(half_run * half_run + roof_span_y * roof_span_y)
	var panel_mesh_size = Vector3(width + 0.52, 0.16, panel_length) if ridge_along_x else Vector3(panel_length, 0.16, depth + 0.52)
	var transforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		var basis = Basis(Vector3.RIGHT, side * pitch) if ridge_along_x else Basis(Vector3.FORWARD, -side * pitch)
		var pos = Vector3(0.0, (eave_y + ridge_y) * 0.5, side * half_run * 0.5) if ridge_along_x else Vector3(side * half_run * 0.5, (eave_y + ridge_y) * 0.5, 0.0)
		transforms.append(Transform3D(basis, pos))
	var roof = _add_box_multimesh(root, panel_mesh_size, transforms, roof_material, "GableRoof", true)
	if roof != null:
		roof_parts.append(roof)

	# Fill the triangular gable ends into the wall shell. Roof cutaway can hide
	# shingles, but must never remove the wall that visibly supports them.
	var half_w = width * 0.5
	var half_d = depth * 0.5
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gable_vertices = []
	if ridge_along_x:
		var end_x = half_w + 0.012
		gable_vertices = [
			Vector3(end_x, body_h - 0.035, half_d),
			Vector3(end_x, body_h - 0.035, -half_d),
			Vector3(end_x, ridge_y - 0.035, 0.0),
			Vector3(-end_x, body_h - 0.035, -half_d),
			Vector3(-end_x, body_h - 0.035, half_d),
			Vector3(-end_x, ridge_y - 0.035, 0.0)
		]
	else:
		var end_z = half_d + 0.012
		gable_vertices = [
			Vector3(-half_w, body_h - 0.035, end_z),
			Vector3(half_w, body_h - 0.035, end_z),
			Vector3(0.0, ridge_y - 0.035, end_z),
			Vector3(half_w, body_h - 0.035, -end_z),
			Vector3(-half_w, body_h - 0.035, -end_z),
			Vector3(0.0, ridge_y - 0.035, -end_z)
		]
	for vertex in gable_vertices:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var gable_mesh = surface.commit()
	var gable_ends = MeshInstance3D.new()
	gable_ends.name = "SupportedGableEnds"
	gable_ends.mesh = gable_mesh
	gable_ends.material_override = wall_material
	gable_ends.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(gable_ends)

	# Deep fascia overlaps the wall top and removes the bright seam that made
	# edge-aligned roof planes read as detached from the house.
	var fascia_transforms: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		var fascia_pos = Vector3(0.0, body_h - 0.055, side * (depth * 0.5 + 0.2)) if ridge_along_x else Vector3(side * (width * 0.5 + 0.2), body_h - 0.055, 0.0)
		fascia_transforms.append(Transform3D(Basis.IDENTITY, fascia_pos))
	var fascia_size = Vector3(width + 0.54, 0.2, 0.16) if ridge_along_x else Vector3(0.16, 0.2, depth + 0.54)
	var fascia = _add_box_multimesh(
		root,
		fascia_size,
		fascia_transforms,
		_trim_material,
		"GableEaveFascia",
		false
	)
	if fascia != null:
		roof_parts.append(fascia)
	var soffit = _add_box_multimesh(
		root,
		(Vector3(width + 0.48, 0.055, 0.28) if ridge_along_x else Vector3(0.28, 0.055, depth + 0.48)),
		fascia_transforms,
		_soffit_material,
		"GableSoffit",
		false
	)
	if soffit != null:
		soffit.position.y -= 0.105
		roof_parts.append(soffit)

static func _add_suburban_hip_roof(
	root: Node3D,
	width: float,
	depth: float,
	body_h: float,
	roof_rise: float,
	roof_material: Material,
	roof_parts: Array
) -> void:
	var half_w = width * 0.5 + 0.26
	var half_d = depth * 0.5 + 0.26
	var eave_y = body_h - 0.12
	var front_left = Vector3(-half_w, eave_y, half_d)
	var front_right = Vector3(half_w, eave_y, half_d)
	var back_left = Vector3(-half_w, eave_y, -half_d)
	var back_right = Vector3(half_w, eave_y, -half_d)
	var triangles = []
	if half_w >= half_d:
		# Wide ranch houses need an east-west ridge. A single centered peak on a
		# long footprint creates the giant pyramid silhouette that read as a
		# floating roof.
		var ridge_half_x = maxf(0.0, half_w - half_d)
		var ridge_left = Vector3(-ridge_half_x, body_h + roof_rise, 0.0)
		var ridge_right = Vector3(ridge_half_x, body_h + roof_rise, 0.0)
		triangles = [
			front_left, front_right, ridge_right,
			front_left, ridge_right, ridge_left,
			back_right, back_left, ridge_left,
			back_right, ridge_left, ridge_right,
			back_left, front_left, ridge_left,
			front_right, back_right, ridge_right
		]
	else:
		var ridge_half_z = maxf(0.0, half_d - half_w)
		var ridge_front = Vector3(0.0, body_h + roof_rise, ridge_half_z)
		var ridge_back = Vector3(0.0, body_h + roof_rise, -ridge_half_z)
		triangles = [
			front_left, front_right, ridge_front,
			back_right, back_left, ridge_back,
			back_left, front_left, ridge_front,
			back_left, ridge_front, ridge_back,
			front_right, back_right, ridge_back,
			front_right, ridge_back, ridge_front
		]
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in triangles:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var roof = MeshInstance3D.new()
	roof.name = "HipRoof"
	roof.mesh = surface.commit()
	roof.material_override = roof_material
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(roof)
	roof_parts.append(roof)

	var fascia_specs = [
		[Vector3(width + 0.56, 0.2, 0.16), Vector3(0.0, body_h - 0.055, half_d - 0.03)],
		[Vector3(width + 0.56, 0.2, 0.16), Vector3(0.0, body_h - 0.055, -half_d + 0.03)],
		[Vector3(0.16, 0.2, depth + 0.56), Vector3(half_w - 0.03, body_h - 0.055, 0.0)],
		[Vector3(0.16, 0.2, depth + 0.56), Vector3(-half_w + 0.03, body_h - 0.055, 0.0)]
	]
	for spec in fascia_specs:
		var fascia = _add_roof_box(root, spec[0], spec[1], _trim_material, roof_parts)
		fascia.name = "HipEaveFascia"
		var soffit_size: Vector3 = spec[0]
		soffit_size.y = 0.055
		if soffit_size.x < soffit_size.z:
			soffit_size.x = 0.28
		else:
			soffit_size.z = 0.28
		var soffit_pos: Vector3 = spec[1]
		soffit_pos.y -= 0.105
		var soffit = _add_roof_box(root, soffit_size, soffit_pos, _soffit_material, roof_parts)
		soffit.name = "HipSoffit"

static func _add_suburban_chimney(
	root: Node3D,
	width: float,
	depth: float,
	body_h: float,
	roof_rise: float,
	rng: RandomNumberGenerator,
	roof_parts: Array
) -> void:
	var chimney = MeshInstance3D.new()
	var chimney_mesh = BoxMesh.new()
	chimney_mesh.size = Vector3(0.42, 1.18, 0.48)
	chimney.mesh = chimney_mesh
	chimney.position = Vector3(
		rng.randf_range(-width * 0.28, width * 0.28),
		body_h + roof_rise * 0.62,
		rng.randf_range(-depth * 0.24, depth * 0.24)
	)
	chimney.material_override = _chicago_brick_materials[0]
	chimney.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chimney.visibility_range_end = 78.0
	chimney.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	root.add_child(chimney)
	roof_parts.append(chimney)

static func _add_suburban_front_porch(root: Node3D, width: float, front_z: float, front_sign: float, rng: RandomNumberGenerator) -> String:
	var style_roll = rng.randf()
	var porch_style = "stoop"
	if style_roll >= 0.68:
		porch_style = "covered"
	elif style_roll >= 0.34:
		porch_style = "low_deck"
	var porch_w = clampf(width * (0.56 if porch_style != "stoop" else 0.42), 2.0, 4.4)
	var porch_d = 0.72 if porch_style == "stoop" else (1.08 if porch_style == "covered" else 1.28)
	var porch = MeshInstance3D.new()
	porch.name = "FrontPorch_%s" % porch_style
	var porch_mesh = BoxMesh.new()
	porch_mesh.size = Vector3(porch_w, 0.16 if porch_style != "low_deck" else 0.2, porch_d)
	porch.mesh = porch_mesh
	porch.position = Vector3(0.0, porch_mesh.size.y * 0.5, front_z + front_sign * (porch_d * 0.5 + 0.02))
	porch.material_override = _stone_material
	porch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(porch)

	if porch_style == "covered":
		for side in [-1.0, 1.0]:
			var post = MeshInstance3D.new()
			post.name = "PorchPost"
			var post_mesh = BoxMesh.new()
			post_mesh.size = Vector3(0.12, 2.18, 0.12)
			post.mesh = post_mesh
			post.position = Vector3(side * (porch_w * 0.5 - 0.16), 1.17, front_z + front_sign * (porch_d - 0.08))
			post.material_override = _trim_material
			post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(post)
		var canopy = MeshInstance3D.new()
		canopy.name = "PorchCanopy"
		var canopy_mesh = BoxMesh.new()
		canopy_mesh.size = Vector3(porch_w + 0.18, 0.13, porch_d + 0.18)
		canopy.mesh = canopy_mesh
		canopy.position = Vector3(0.0, 2.28, front_z + front_sign * (porch_d * 0.5 + 0.02))
		canopy.material_override = _soffit_material
		canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(canopy)
	elif porch_style == "low_deck":
		var step = MeshInstance3D.new()
		step.name = "DeckStep"
		var step_mesh = BoxMesh.new()
		step_mesh.size = Vector3(minf(1.5, porch_w * 0.42), 0.1, 0.36)
		step.mesh = step_mesh
		step.position = Vector3(0.0, 0.05, front_z + front_sign * (porch_d + 0.18))
		step.material_override = _stone_material
		step.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(step)
		for side in [-1.0, 1.0]:
			var rail = MeshInstance3D.new()
			rail.name = "DeckRail"
			var rail_mesh = BoxMesh.new()
			rail_mesh.size = Vector3(0.08, 0.54, porch_d * 0.72)
			rail.mesh = rail_mesh
			rail.position = Vector3(side * (porch_w * 0.5 - 0.08), 0.38, front_z + front_sign * porch_d * 0.52)
			rail.material_override = _trim_material
			rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(rail)

	var door = MeshInstance3D.new()
	door.name = "FrontDoor"
	var door_mesh = BoxMesh.new()
	door_mesh.size = Vector3(0.82, 1.92, 0.055)
	door.mesh = door_mesh
	door.position = Vector3(0.0, 1.02, front_z + front_sign * 0.035)
	door.material_override = _trim_material
	door.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(door)
	return porch_style

static func _add_foundation_contact_shadow(root: Node3D, width: float, depth: float) -> void:
	var shadow = MeshInstance3D.new()
	shadow.name = "FoundationContactShadow"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(width + 0.14, 0.026, depth + 0.14)
	shadow.mesh = mesh
	shadow.position = Vector3(0.0, 0.019, 0.0)
	shadow.material_override = _contact_shadow_material
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(shadow)

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

static func _make_suburban_siding_texture(base_color: Color) -> Texture2D:
	var tex_size = 256
	var course_height = 16
	var img = Image.create(tex_size, tex_size, true, Image.FORMAT_RGBA8)
	for y in range(tex_size):
		var course_y = posmod(y, course_height)
		var course = int(floor(float(y) / float(course_height)))
		var edge_shade = 1.0
		if course_y <= 1:
			edge_shade = 0.73
		elif course_y <= 4:
			edge_shade = 0.9
		elif course_y >= course_height - 2:
			edge_shade = 1.08
		for x in range(tex_size):
			var grain = 0.975 + 0.035 * sin(float(x) * 0.19 + float(course) * 1.7)
			grain += 0.012 * sin(float(x) * 0.057 + float(y) * 0.11)
			var value = clampf(edge_shade * grain, 0.68, 1.12)
			img.set_pixel(
				x,
				y,
				Color(
					clampf(base_color.r * value, 0.0, 1.0),
					clampf(base_color.g * value, 0.0, 1.0),
					clampf(base_color.b * value, 0.0, 1.0),
					1.0
				)
			)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

static func _make_asphalt_shingle_texture(base_color: Color) -> Texture2D:
	var tex_size = 256
	var course_h = 18
	var tab_w = 34
	var img = Image.create(tex_size, tex_size, true, Image.FORMAT_RGBA8)
	for y in range(tex_size):
		var course = int(floor(float(y) / float(course_h)))
		var course_y = posmod(y, course_h)
		var stagger = (tab_w / 2) if course % 2 == 1 else 0
		for x in range(tex_size):
			var tab_x = posmod(x + stagger, tab_w)
			var grain = 0.91 + 0.075 * sin(float(x) * 0.41 + float(y) * 0.19)
			grain += 0.035 * sin(float(x) * 1.13 + float(course) * 2.7)
			if course_y <= 2:
				grain *= 0.72
			elif course_y >= course_h - 2:
				grain *= 1.06
			if tab_x <= 1 and course_y > 3:
				grain *= 0.68
			var value = clampf(grain, 0.58, 1.1)
			img.set_pixel(x, y, Color(base_color.r * value, base_color.g * value, base_color.b * value, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

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
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * CHICAGO_BRICK_UV_SCALE
	return mat

static func brick_style_metrics() -> Dictionary:
	return {
		"uv_scale": CHICAGO_BRICK_UV_SCALE,
		"brick_px_w": CHICAGO_BRICK_PATTERN_WIDTH_PX,
		"brick_px_h": CHICAGO_BRICK_PATTERN_HEIGHT_PX,
		"mortar_px": CHICAGO_MORTAR_WIDTH_PX,
		"brick_world_w_m": CHICAGO_BRICK_WORLD_WIDTH_M,
		"brick_world_h_m": CHICAGO_BRICK_WORLD_HEIGHT_M
	}

static func suburban_style_metrics() -> Dictionary:
	_ensure_materials()
	var textured_siding_materials = 0
	for material in _wall_materials:
		if material != null and material.albedo_texture != null:
			textured_siding_materials += 1
	var textured_roof_materials = 0
	for material in _roof_materials:
		if material != null and material.albedo_texture != null:
			textured_roof_materials += 1
	return {
		"siding_materials": _wall_materials.size(),
		"textured_siding_materials": textured_siding_materials,
		"roof_materials": _roof_materials.size(),
		"textured_roof_materials": textured_roof_materials
	}

static func _chicago_brick_base_height(floors: int, total_height: float) -> float:
	var story_count = clampi(floors, 1, 3)
	var desired = 0.72 + float(story_count - 1) * 0.08
	return minf(desired, total_height * 0.3)

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

	var panel_transforms: Array[Transform3D] = [
		Transform3D(Basis().scaled(Vector3(ns_width, brick_height, shell_t)), Vector3(0.0, brick_height * 0.5, -half_d + edge_inset + shell_t * 0.5)),
		Transform3D(Basis().scaled(Vector3(ns_width, brick_height, shell_t)), Vector3(0.0, brick_height * 0.5, half_d - edge_inset - shell_t * 0.5)),
		Transform3D(Basis().scaled(Vector3(shell_t, brick_height, ew_depth)), Vector3(-half_w + edge_inset + shell_t * 0.5, brick_height * 0.5, 0.0)),
		Transform3D(Basis().scaled(Vector3(shell_t, brick_height, ew_depth)), Vector3(half_w - edge_inset - shell_t * 0.5, brick_height * 0.5, 0.0))
	]
	_add_box_multimesh(parent, Vector3.ONE, panel_transforms, brick_material, "BrickFoundation", false, 82.0)

	var belt = MeshInstance3D.new()
	belt.name = "FoundationBelt"
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
	var target_h = float(clampi(floors, 1, 3)) * 2.78 + 1.45
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
		_configure_external_model_performance(model_root)
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

static func _configure_external_model_performance(root: Node) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is GeometryInstance3D:
			var geometry = node as GeometryInstance3D
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			geometry.visibility_range_end = 92.0
			geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		for child in node.get_children():
			stack.append(child)

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
