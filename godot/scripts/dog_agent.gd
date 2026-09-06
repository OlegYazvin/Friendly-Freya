extends Node3D
class_name DogAgent

const FREYA_COAT_COLOR = Color(0.03, 0.03, 0.03)

var is_freya = false
var coat_color = Color(0.12, 0.12, 0.12)
var speed = 2.2
var bark_cooldown = 0.0
var wander_timer = 0.0
var scene_path = ""
var model_scale = 1.0
var model_target_length = -1.0
var model_target_height = -1.0
var breed_profile = "mixed"
var breed_id = "mixed"
var breed_mix: Dictionary = {}
var variant_seed = 0

var _step_time = 0.0
var _head_pivot: Node3D
var _tail_pivot: Node3D
var _tail_tip_pivot: Node3D
var _leg_pivots: Array[Node3D] = []
var _ear_pivots: Array[Node3D] = []
var _visual_root: Node3D
var _base_visual_y = 0.06
var _anim_player: AnimationPlayer
var _anim_idle = ""
var _anim_walk = ""
var _anim_run = ""
var _anim_eat = ""
var _has_move_animation = false
var _model_forward_yaw_offset = PI
var _mouth_anchor_node: Node3D
var _mouth_anchor_skeleton: Skeleton3D
var _mouth_anchor_bone = -1
var _hidden_leg_chains: Array[Dictionary] = []
var _cosmetic_style = "none"
var _cosmetic_color_index = -1
var _breed_shape_signature = "voxel_default"
var _cosmetic_root: Node3D
var _army_collar_root: Node3D
var _dog_armor_root: Node3D
var _discomfort_strength = 0.0
var _discomfort_phase = 0.0
var _training_pose_active = false
var _training_node_base_scale = Vector3.ONE

func configure(config: Dictionary) -> void:
	is_freya = bool(config.get("is_freya", false))
	coat_color = FREYA_COAT_COLOR if is_freya else config.get("coat_color", Color(0.2, 0.2, 0.2))
	speed = float(config.get("speed", 2.2))
	scene_path = str(config.get("scene_path", ""))
	model_scale = float(config.get("model_scale", 1.0))
	model_target_length = float(config.get("target_length", -1.0))
	model_target_height = float(config.get("target_height", -1.0))
	breed_profile = str(config.get("breed_profile", "mixed")).to_lower()
	breed_id = str(config.get("breed_id", breed_profile)).to_lower()
	var mix_cfg = config.get("breed_mix", {})
	breed_mix = mix_cfg if mix_cfg is Dictionary else {}
	variant_seed = int(config.get("variant_seed", 0))
	_build_visual()

func _build_visual() -> void:
	_training_pose_active = false
	_training_node_base_scale = scale
	if not _try_build_custom_model():
		_build_model()
	_add_npc_cosmetic_variation()

func _cosmetic_material(color: Color, metallic: float = 0.02) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.52
	material.metallic = metallic
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _add_npc_cosmetic_variation() -> void:
	if is_freya:
		_cosmetic_style = "freya"
		_cosmetic_color_index = -1
		return
	var cosmetic_rng = RandomNumberGenerator.new()
	cosmetic_rng.seed = int(variant_seed) ^ 0x45D9F3B
	var palette = [
		Color8(38, 118, 168),
		Color8(208, 72, 62),
		Color8(226, 164, 42),
		Color8(71, 153, 91),
		Color8(130, 79, 164),
		Color8(47, 47, 51)
	]
	_cosmetic_color_index = cosmetic_rng.randi_range(0, palette.size() - 1)
	var style_index = cosmetic_rng.randi_range(0, 3)
	_cosmetic_style = ["collar", "tagged_collar", "bandana", "wide_collar"][style_index]
	var accent: Color = palette[_cosmetic_color_index]
	var neck_frame = _accessory_neck_frame()
	var neck_radius = float(neck_frame.get("radius", 0.13)) * (1.08 if style_index == 3 else 1.0)

	var root = Node3D.new()
	root.name = "DogCosmetics"
	add_child(root)
	_cosmetic_root = root
	_apply_neck_frame(root, neck_frame)

	var collar = MeshInstance3D.new()
	collar.name = "Collar"
	var collar_mesh = TorusMesh.new()
	collar_mesh.inner_radius = neck_radius * 0.76
	collar_mesh.outer_radius = neck_radius
	collar_mesh.rings = 12
	collar_mesh.ring_segments = 6
	collar.mesh = collar_mesh
	collar.rotation_degrees.x = 90.0
	collar.scale = Vector3(1.0, 0.78, 1.0)
	collar.material_override = _cosmetic_material(accent)
	root.add_child(collar)

	if style_index == 1:
		var tag = MeshInstance3D.new()
		tag.name = "CollarTag"
		var tag_mesh = SphereMesh.new()
		tag_mesh.radius = clampf(neck_radius * 0.24, 0.022, 0.042)
		tag_mesh.height = tag_mesh.radius * 2.0
		tag.mesh = tag_mesh
		tag.position = Vector3(0.0, -neck_radius * 0.88, -neck_radius * 0.86)
		tag.scale = Vector3(1.0, 1.15, 0.42)
		tag.material_override = _cosmetic_material(Color8(226, 190, 72), 0.48)
		root.add_child(tag)
	elif style_index == 2:
		var bandana = MeshInstance3D.new()
		bandana.name = "Bandana"
		var surface = SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var half_w = neck_radius * 0.86
		surface.add_vertex(Vector3(-half_w, -neck_radius * 0.26, -neck_radius * 0.94))
		surface.add_vertex(Vector3(half_w, -neck_radius * 0.26, -neck_radius * 0.94))
		surface.add_vertex(Vector3(0.0, -neck_radius * 1.78, -neck_radius * 0.98))
		surface.generate_normals()
		bandana.mesh = surface.commit()
		bandana.material_override = _cosmetic_material(accent.lightened(0.08))
		root.add_child(bandana)
	elif style_index == 3:
		collar.scale.y = 1.18

func cosmetic_signature() -> String:
	return "%s:%d" % [_cosmetic_style, _cosmetic_color_index]

func visual_style_signature() -> String:
	if scene_path.get_file() == "freya_portuguese_water_dog.glb":
		return "freya_voxel_rig"
	if scene_path.is_empty():
		return "procedural_voxel"
	return "external_model"

func breed_shape_signature() -> String:
	return _breed_shape_signature

func _accessory_neck_frame() -> Dictionary:
	var bounds = _compute_model_bounds(self)
	var body_center = bounds.get_center()
	# The imported skeleton's named head node is not a stable surface anchor after
	# per-breed bone shaping. Rendered bounds plus the rig's facing axis keep the
	# band between the chest and head for every voxel silhouette.
	var dog_forward = Vector3(sin(_model_forward_yaw_offset), 0.0, cos(_model_forward_yaw_offset))
	if dog_forward.length_squared() < 0.001:
		dog_forward = Vector3.FORWARD
	dog_forward = dog_forward.normalized()
	var forward_extent = absf(dog_forward.x) * bounds.size.x + absf(dog_forward.z) * bounds.size.z
	var dog_right = Vector3(-dog_forward.z, 0.0, dog_forward.x)
	var neck_width = absf(dog_right.x) * bounds.size.x + absf(dog_right.z) * bounds.size.z
	var neck_center = body_center + dog_forward * forward_extent * 0.32
	neck_center.y = bounds.position.y + bounds.size.y * 0.62
	var radius = clampf(minf(neck_width * 0.26, bounds.size.y * 0.18), 0.095, 0.22)
	return {
		"position": neck_center,
		"axis": dog_forward,
		"radius": radius
	}

func _apply_neck_frame(root: Node3D, frame: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	var neck_axis: Vector3 = frame.get("axis", Vector3.FORWARD)
	if neck_axis.length_squared() < 0.001:
		neck_axis = Vector3.FORWARD
	root.position = frame.get("position", Vector3.ZERO)
	root.quaternion = Quaternion(Vector3.FORWARD, neck_axis.normalized())

func _army_camo_material() -> StandardMaterial3D:
	var colors = [Color8(42, 59, 29), Color8(100, 119, 52), Color8(190, 158, 79), Color8(25, 34, 21)]
	var image = Image.create(96, 24, false, Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var block_x = int(x / 6)
			var block_y = int(y / 6)
			var color_index = posmod(block_x * 5 + block_y * 3 + int(block_x / 3), colors.size())
			image.set_pixel(x, y, colors[color_index])
	var material = _cosmetic_material(Color.WHITE)
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return material

func set_army_aligned(aligned: bool) -> void:
	if is_freya:
		return
	if _army_collar_root != null and is_instance_valid(_army_collar_root):
		if aligned:
			return
		# Alignment can be toggled twice during one frame by validation/restoration.
		# Free immediately so a new true state cannot briefly stack two collars.
		_army_collar_root.free()
		_army_collar_root = null
		if _cosmetic_root != null and is_instance_valid(_cosmetic_root):
			_cosmetic_root.visible = true
		return
	if not aligned:
		return

	var neck_frame = _accessory_neck_frame()
	var neck_radius = float(neck_frame.get("radius", 0.13)) * 1.18
	var root = Node3D.new()
	root.name = "ArmyCamoCollar"
	add_child(root)
	_army_collar_root = root
	_apply_neck_frame(root, neck_frame)
	if _cosmetic_root != null and is_instance_valid(_cosmetic_root):
		_cosmetic_root.visible = false

	var base = MeshInstance3D.new()
	base.name = "ArmyCollarBase"
	var base_mesh = TorusMesh.new()
	base_mesh.inner_radius = neck_radius * 0.66
	base_mesh.outer_radius = neck_radius * 1.3
	base_mesh.rings = 16
	base_mesh.ring_segments = 8
	base.mesh = base_mesh
	base.rotation_degrees.x = 90.0
	base.scale = Vector3(1.0, 2.05, 1.0)
	base.material_override = _army_camo_material()
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(base)

	# Large block-color plates keep the camouflage readable after the texture
	# becomes only a few pixels wide at normal gameplay zoom.
	var camo_colors = [Color8(42, 59, 29), Color8(111, 130, 58), Color8(196, 164, 83), Color8(28, 37, 23)]
	var camo_materials: Array[StandardMaterial3D] = []
	for color in camo_colors:
		camo_materials.append(_cosmetic_material(color, 0.78))
	for plate_index in range(12):
		var angle = TAU * float(plate_index) / 12.0
		var plate = MeshInstance3D.new()
		plate.name = "ArmyCollarCamoPlate%02d" % plate_index
		var plate_mesh = BoxMesh.new()
		plate_mesh.size = Vector3(neck_radius * 0.52, neck_radius * 0.4, neck_radius * 1.5)
		plate.mesh = plate_mesh
		plate.position = Vector3(cos(angle) * neck_radius * 1.1, sin(angle) * neck_radius * 1.1, 0.0)
		plate.rotation.z = angle + PI * 0.5
		plate.material_override = camo_materials[plate_index % camo_materials.size()]
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(plate, true)

	var edge_material = _cosmetic_material(Color8(166, 145, 75), 0.55)
	for edge_index in range(2):
		var edge = MeshInstance3D.new()
		edge.name = "ArmyCollarEdgeBand%d" % edge_index
		var edge_mesh = TorusMesh.new()
		edge_mesh.inner_radius = neck_radius * 1.27
		edge_mesh.outer_radius = neck_radius * 1.37
		edge_mesh.rings = 16
		edge_mesh.ring_segments = 5
		edge.mesh = edge_mesh
		edge.rotation_degrees.x = 90.0
		edge.position.z = neck_radius * (-0.76 if edge_index == 0 else 0.76)
		edge.material_override = edge_material
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(edge, true)

	# A broad dorsal panel keeps the collar identifiable from the normal
	# overhead camera even when a dog's muzzle or chest hides the throat buckle.
	var top_panel = MeshInstance3D.new()
	top_panel.name = "ArmyCollarTopPanel"
	var top_panel_mesh = BoxMesh.new()
	top_panel_mesh.size = Vector3(neck_radius * 0.8, neck_radius * 0.3, neck_radius * 1.48)
	top_panel.mesh = top_panel_mesh
	top_panel.position = Vector3(0.0, neck_radius * 1.28, 0.0)
	top_panel.material_override = camo_materials[2]
	top_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(top_panel)
	for patch_index in range(2):
		var top_patch = MeshInstance3D.new()
		top_patch.name = "ArmyCollarTopCamoPatch%d" % patch_index
		var top_patch_mesh = BoxMesh.new()
		top_patch_mesh.size = Vector3(neck_radius * 0.3, neck_radius * 0.08, neck_radius * 0.5)
		top_patch.mesh = top_patch_mesh
		top_patch.position = Vector3(
			neck_radius * (-0.2 if patch_index == 0 else 0.2),
			neck_radius * 1.445,
			neck_radius * (-0.34 if patch_index == 0 else 0.34)
		)
		top_patch.material_override = camo_materials[3 if patch_index == 0 else 0]
		top_patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		root.add_child(top_patch, true)

	var buckle = MeshInstance3D.new()
	buckle.name = "ArmyCollarBuckle"
	var buckle_mesh = BoxMesh.new()
	buckle_mesh.size = Vector3(neck_radius * 0.72, neck_radius * 0.38, neck_radius * 0.66)
	buckle.mesh = buckle_mesh
	buckle.position = Vector3(0.0, -neck_radius * 1.2, -neck_radius * 0.03)
	buckle.material_override = _cosmetic_material(Color8(213, 176, 70), 0.28)
	buckle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(buckle)

	var buckle_inset = MeshInstance3D.new()
	buckle_inset.name = "ArmyCollarBuckleInset"
	var inset_mesh = BoxMesh.new()
	inset_mesh.size = Vector3(neck_radius * 0.34, neck_radius * 0.12, neck_radius * 0.7)
	buckle_inset.mesh = inset_mesh
	buckle_inset.position = Vector3(0.0, -neck_radius * 1.405, -neck_radius * 0.03)
	buckle_inset.material_override = _cosmetic_material(Color8(62, 67, 38), 0.58)
	buckle_inset.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(buckle_inset)

func set_dog_armor(equipped: bool) -> void:
	if is_freya:
		return
	if _dog_armor_root != null and is_instance_valid(_dog_armor_root):
		if equipped:
			return
		_dog_armor_root.free()
		_dog_armor_root = null
		return
	if not equipped:
		return

	var bounds = _compute_model_bounds(self)
	var body_center = bounds.get_center()
	var dog_forward = Vector3(sin(_model_forward_yaw_offset), 0.0, cos(_model_forward_yaw_offset))
	if dog_forward.length_squared() < 0.001:
		dog_forward = Vector3.FORWARD
	dog_forward = dog_forward.normalized()
	var forward_extent = absf(dog_forward.x) * bounds.size.x + absf(dog_forward.z) * bounds.size.z
	var dog_right = Vector3(-dog_forward.z, 0.0, dog_forward.x)
	var width = clampf(absf(dog_right.x) * bounds.size.x + absf(dog_right.z) * bounds.size.z, 0.35, 0.86)
	var length = clampf(forward_extent * 0.48, 0.46, 1.0)
	var root = Node3D.new()
	root.name = "DoggyArmor"
	root.position = Vector3(body_center.x, bounds.position.y + bounds.size.y * 0.63, body_center.z)
	root.quaternion = Quaternion(Vector3.FORWARD, dog_forward)
	add_child(root)
	_dog_armor_root = root

	var plate_material = _cosmetic_material(Color8(48, 56, 65), 0.62)
	plate_material.roughness = 0.34
	var trim_material = _cosmetic_material(Color8(62, 104, 155), 0.48)
	trim_material.roughness = 0.4
	var back_plate = MeshInstance3D.new()
	back_plate.name = "ArmorBackPlate"
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(width * 0.86, 0.12, length)
	back_plate.mesh = back_mesh
	back_plate.material_override = plate_material
	root.add_child(back_plate)
	for side in [-1.0, 1.0]:
		var flank = MeshInstance3D.new()
		flank.name = "ArmorFlank"
		var flank_mesh = BoxMesh.new()
		flank_mesh.size = Vector3(0.1, bounds.size.y * 0.28, length * 0.76)
		flank.mesh = flank_mesh
		flank.position = Vector3(side * width * 0.43, -bounds.size.y * 0.11, 0.0)
		flank.material_override = plate_material
		root.add_child(flank)
	for band_z in [-0.32, 0.32]:
		var band = MeshInstance3D.new()
		band.name = "ArmorBlueBand"
		var band_mesh = BoxMesh.new()
		band_mesh.size = Vector3(width * 0.94, 0.04, 0.09)
		band.mesh = band_mesh
		band.position = Vector3(0.0, 0.08, band_z * length)
		band.material_override = trim_material
		root.add_child(band)

func _update_neck_accessory_poses() -> void:
	if (_cosmetic_root == null or not is_instance_valid(_cosmetic_root)) and (_army_collar_root == null or not is_instance_valid(_army_collar_root)):
		return
	var frame = _accessory_neck_frame()
	_apply_neck_frame(_cosmetic_root, frame)
	_apply_neck_frame(_army_collar_root, frame)

func army_collar_is_neck_mounted() -> bool:
	if _army_collar_root == null or not is_instance_valid(_army_collar_root):
		return false
	var frame = _accessory_neck_frame()
	var expected: Vector3 = frame.get("position", Vector3.ZERO)
	var radius = float(frame.get("radius", 0.13))
	if _army_collar_root.position.distance_to(expected) > maxf(0.035, radius * 0.35):
		return false
	var bounds = _compute_model_bounds(self)
	if _army_collar_root.position.y >= bounds.end.y - radius * 0.15:
		return false
	var base: MeshInstance3D = _army_collar_root.get_node_or_null("ArmyCollarBase")
	if base == null or not (base.material_override is BaseMaterial3D):
		return false
	if (base.material_override as BaseMaterial3D).albedo_texture == null:
		return false
	var stack: Array[Node] = [_army_collar_root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Label3D:
			return false
		for child in current.get_children():
			stack.append(child)
	return true

func army_collar_is_clearly_visible() -> bool:
	if not army_collar_is_neck_mounted():
		return false
	var frame = _accessory_neck_frame()
	var frame_radius = float(frame.get("radius", 0.13))
	var base: MeshInstance3D = _army_collar_root.get_node_or_null("ArmyCollarBase")
	if base == null or not (base.mesh is TorusMesh):
		return false
	var torus = base.mesh as TorusMesh
	var outer_diameter = torus.outer_radius * 2.0
	var axial_width = (torus.outer_radius - torus.inner_radius) * base.scale.y
	if outer_diameter < frame_radius * 2.65 or axial_width < maxf(0.075, frame_radius * 0.72):
		return false
	if _army_collar_root.get_node_or_null("ArmyCollarBuckle") == null or _army_collar_root.get_node_or_null("ArmyCollarBuckleInset") == null or _army_collar_root.get_node_or_null("ArmyCollarTopPanel") == null:
		return false
	var plate_count = 0
	var edge_count = 0
	var plate_colors := {}
	for child in _army_collar_root.get_children():
		if child.name.begins_with("ArmyCollarCamoPlate"):
			plate_count += 1
			if child is MeshInstance3D:
				var material = (child as MeshInstance3D).material_override
				if material is BaseMaterial3D:
					plate_colors[(material as BaseMaterial3D).albedo_color.to_html(false)] = true
		elif child.name.begins_with("ArmyCollarEdgeBand"):
			edge_count += 1
	return plate_count >= 12 and edge_count == 2 and plate_colors.size() >= 3

func set_discomfort(strength: float, threat_world_position: Vector3, delta: float) -> void:
	var target_strength = clampf(strength, 0.0, 1.0) if is_freya else 0.0
	_discomfort_strength = lerpf(
		_discomfort_strength,
		target_strength,
		clampf(delta * (7.0 if target_strength > _discomfort_strength else 4.2), 0.0, 1.0)
	)
	_discomfort_phase = fposmod(_discomfort_phase + delta * (15.0 + _discomfort_strength * 8.0), TAU)
	if _visual_root != null and is_instance_valid(_visual_root):
		var tremble = sin(_discomfort_phase) * 0.052 * _discomfort_strength
		_visual_root.rotation.z = lerpf(_visual_root.rotation.z, tremble, clampf(delta * 12.0, 0.0, 1.0))
		_visual_root.rotation.x = lerpf(_visual_root.rotation.x, 0.12 * _discomfort_strength, clampf(delta * 7.0, 0.0, 1.0))
	if _tail_pivot != null and is_instance_valid(_tail_pivot):
		_tail_pivot.rotation.x = lerpf(_tail_pivot.rotation.x, -0.82 * _discomfort_strength, clampf(delta * 7.5, 0.0, 1.0))
	if _head_pivot != null and is_instance_valid(_head_pivot):
		var away = global_position - threat_world_position
		var side_sign = 1.0 if global_transform.basis.x.dot(away) >= 0.0 else -1.0
		var glance = side_sign * (0.16 + 0.08 * sin(_discomfort_phase * 0.47)) * _discomfort_strength
		_head_pivot.rotation.y = lerpf(_head_pivot.rotation.y, glance, clampf(delta * 5.0, 0.0, 1.0))

func discomfort_strength() -> float:
	return _discomfort_strength

func _try_build_custom_model() -> bool:
	if scene_path.is_empty():
		return false
	if not FileAccess.file_exists(scene_path) and not ResourceLoader.exists(scene_path):
		return false
	var res = load(scene_path)
	if res == null or not (res is PackedScene):
		return false

	for child in get_children():
		child.queue_free()

	_leg_pivots.clear()
	_ear_pivots.clear()
	_head_pivot = null
	_tail_pivot = null
	_tail_tip_pivot = null
	_anim_player = null
	_anim_idle = ""
	_anim_walk = ""
	_anim_run = ""
	_anim_eat = ""
	_has_move_animation = false
	_model_forward_yaw_offset = PI
	_mouth_anchor_node = null
	_mouth_anchor_skeleton = null
	_mouth_anchor_bone = -1
	_hidden_leg_chains.clear()

	_visual_root = Node3D.new()
	_visual_root.position = Vector3(0.0, _base_visual_y, 0.0)
	_visual_root.scale = Vector3.ONE * model_scale
	add_child(_visual_root)

	var model_root = (res as PackedScene).instantiate()
	if not (model_root is Node3D):
		return false
	_visual_root.add_child(model_root as Node3D)
	_normalize_external_model(model_root as Node3D)

	_head_pivot = _find_named_node(model_root, ["head", "skull", "neck"])
	_tail_pivot = _find_named_node(model_root, ["tail"])
	if _tail_pivot != null:
		_tail_tip_pivot = _tail_pivot
	_resolve_mouth_anchor(model_root as Node3D)
	_anim_player = _find_animation_player(model_root)
	_resolve_animation_names()
	_infer_model_forward_axis(model_root as Node3D)
	_apply_external_breed_shape(model_root as Node3D)

	if is_freya:
		_apply_black_coat(model_root)
	else:
		_apply_custom_coat_tint(model_root)

	return true

func _find_named_node(root: Node, name_hints: Array) -> Node3D:
	var stack: Array = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		var lname := current.name.to_lower()
		for hint in name_hints:
			if lname.contains(str(hint).to_lower()) and current is Node3D:
				return current as Node3D
		for child in current.get_children():
			stack.append(child)
	return null

func _hide_leg_candidates(root: Node) -> void:
	var candidates: Array[Node3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Node3D:
			var lname := current.name.to_lower()
			if lname.contains("leg") or lname.contains("paw") or lname.contains("foot"):
				candidates.append(current as Node3D)
		for child in current.get_children():
			stack.append(child)

	if candidates.size() > 0:
		var chosen: Node3D = candidates[candidates.size() - 1]
		for n in candidates:
			var lname := n.name.to_lower()
			if (lname.contains("back") or lname.contains("hind") or lname.contains("rear")) and (
				lname.contains("leg") or lname.contains("paw") or lname.contains("foot")
			):
				chosen = n
				break
		_hide_node_branch(chosen)

	# Also collapse a hind-leg bone chain so skinned meshes stay 3-legged while animated.
	_hide_hind_leg_bone_chain(root)
	_enforce_hidden_leg_pose()

func _apply_black_coat(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			_style_freya_mesh(n as MeshInstance3D)
		elif n is Node3D:
			var node3 := n as Node3D
			var lname := node3.name.to_lower()
			if lname.contains("ear"):
				node3.scale = Vector3(node3.scale.x, node3.scale.y * 1.12, node3.scale.z)
			elif lname.contains("tail"):
				node3.scale = Vector3(node3.scale.x, node3.scale.y, node3.scale.z * 0.9)
			elif lname.contains("muzzle") or lname.contains("snout"):
				node3.scale = Vector3(node3.scale.x * 1.06, node3.scale.y * 0.98, node3.scale.z * 1.08)
		for c in n.get_children():
			stack.append(c)

func _style_freya_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance == null:
		return
	if mesh_instance.material_override != null:
		mesh_instance.material_override = _freya_styled_material(mesh_instance.material_override)
	var mesh := mesh_instance.mesh
	if mesh == null:
		return
	for surface_idx in range(mesh.get_surface_count()):
		var source: Material = mesh_instance.get_active_material(surface_idx)
		if source == null:
			source = mesh.surface_get_material(surface_idx)
		if source == null:
			continue
		mesh_instance.set_surface_override_material(surface_idx, _freya_styled_material(source))

func _freya_styled_material(source: Material) -> Material:
	if source == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = FREYA_COAT_COLOR
		fallback.roughness = 0.9
		fallback.metallic = 0.0
		return fallback
	var styled: Material = source.duplicate(true)
	if styled is BaseMaterial3D:
		var base := styled as BaseMaterial3D
		var src := base.albedo_color
		var lum := src.r * 0.2126 + src.g * 0.7152 + src.b * 0.0722
		var black_level := clampf(0.032 + lum * 0.08, 0.03, 0.12)
		base.albedo_color = Color(black_level, black_level, black_level, src.a)
		base.roughness = maxf(base.roughness, 0.86)
		base.metallic = minf(base.metallic, 0.03)
		base.clearcoat = 0.0
	return styled

func _apply_custom_coat_tint(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mesh_instance := n as MeshInstance3D
			if mesh_instance.material_override != null:
				mesh_instance.material_override = _npc_tinted_material(mesh_instance.material_override)
			var mesh := mesh_instance.mesh
			if mesh != null:
				for surface_idx in range(mesh.get_surface_count()):
					var source: Material = mesh_instance.get_active_material(surface_idx)
					if source == null:
						source = mesh.surface_get_material(surface_idx)
					if source == null:
						continue
					mesh_instance.set_surface_override_material(surface_idx, _npc_tinted_material(source))
		for c in n.get_children():
			stack.append(c)

func _npc_tinted_material(source: Material) -> Material:
	if source == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = coat_color
		fallback.roughness = 0.88
		return fallback
	var styled: Material = source.duplicate(true)
	if styled is BaseMaterial3D:
		var base := styled as BaseMaterial3D
		var src := base.albedo_color
		# All NPCs share Freya's textured voxel mesh. Multiplying that texture by a
		# breed palette color preserves its block shading while making coat families
		# legible instead of retaining the source model's original beige coat.
		var source_light = clampf(src.r * 0.2126 + src.g * 0.7152 + src.b * 0.0722, 0.55, 1.0)
		var shade = lerpf(0.88, 1.06, source_light)
		base.albedo_color = Color(
			clampf(coat_color.r * shade, 0.0, 1.0),
			clampf(coat_color.g * shade, 0.0, 1.0),
			clampf(coat_color.b * shade, 0.0, 1.0),
			src.a
		)
		base.roughness = maxf(base.roughness, 0.84)
		base.metallic = minf(base.metallic, 0.03)
	return styled

func _hide_node_branch(root: Node3D) -> void:
	if root == null:
		return
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node3D = stack.pop_back()
		n.visible = false
		for child in n.get_children():
			if child is Node3D:
				stack.append(child as Node3D)

func _hide_hind_leg_bone_chain(root: Node) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Skeleton3D:
			var skel := n as Skeleton3D
			var bone_idx := _pick_hind_leg_bone(skel)
			if bone_idx >= 0:
				_register_hidden_leg_chain(skel, bone_idx)
				_collapse_bone_chain(skel, bone_idx)
				continue
		for c in n.get_children():
			stack.append(c)

func _register_hidden_leg_chain(skel: Skeleton3D, root_bone: int) -> void:
	for i in range(_hidden_leg_chains.size()):
		var entry: Dictionary = _hidden_leg_chains[i]
		if entry.get("skeleton", null) == skel and int(entry.get("bone", -1)) == root_bone:
			return
	_hidden_leg_chains.append({"skeleton": skel, "bone": root_bone})

func _pick_hind_leg_bone(skel: Skeleton3D) -> int:
	var preferred = [
		"backleg.r",
		"hindleg.r",
		"rearleg.r",
		"back_leg_r",
		"hind_leg_r",
		"rear_leg_r",
		"thigh.r",
		"upleg.r",
		"backleg.l",
		"hindleg.l",
		"rearleg.l",
		"back_leg_l",
		"hind_leg_l",
		"rear_leg_l",
		"thigh.l",
		"upleg.l"
	]

	for needle in preferred:
		for i in range(skel.get_bone_count()):
			var bname := skel.get_bone_name(i).to_lower()
			if bname.contains(needle):
				return i

	for i in range(skel.get_bone_count()):
		var bname := skel.get_bone_name(i).to_lower()
		if (bname.contains("back") or bname.contains("hind") or bname.contains("rear")) and (
			bname.contains("leg") or bname.contains("thigh")
		):
			return i
	return -1

func _collapse_bone_chain(skel: Skeleton3D, root_bone: int) -> void:
	var pending: Array[int] = [root_bone]
	while not pending.is_empty():
		var idx: int = pending.pop_back()
		skel.set_bone_pose_scale(idx, Vector3(0.001, 0.001, 0.001))
		var kids: PackedInt32Array = skel.get_bone_children(idx)
		for child_idx in kids:
			pending.append(int(child_idx))

func _enforce_hidden_leg_pose() -> void:
	if _hidden_leg_chains.is_empty():
		return
	for i in range(_hidden_leg_chains.size() - 1, -1, -1):
		var entry: Dictionary = _hidden_leg_chains[i]
		var skel: Skeleton3D = entry.get("skeleton", null)
		var bone_idx := int(entry.get("bone", -1))
		if skel == null or not is_instance_valid(skel) or bone_idx < 0:
			_hidden_leg_chains.remove_at(i)
			continue
		_collapse_bone_chain(skel, bone_idx)

func _find_animation_player(root: Node) -> AnimationPlayer:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is AnimationPlayer:
			return n as AnimationPlayer
		for c in n.get_children():
			stack.append(c)
	return null

func _strip_scale_tracks_from_animations() -> void:
	if _anim_player == null:
		return
	var names: PackedStringArray = _anim_player.get_animation_list()
	for anim_name in names:
		var anim: Animation = _anim_player.get_animation(anim_name)
		if anim == null:
			continue
		for track_idx in range(anim.get_track_count() - 1, -1, -1):
			var path_text: String = str(anim.track_get_path(track_idx)).to_lower()
			if path_text.contains("scale"):
				anim.remove_track(track_idx)

func _resolve_animation_names() -> void:
	if _anim_player == null:
		return
	_strip_scale_tracks_from_animations()
	var names: PackedStringArray = _anim_player.get_animation_list()
	if names.is_empty():
		return

	_anim_idle = _pick_animation_name(names, ["idle", "rest", "stand", "breathe"])
	_anim_walk = _pick_animation_name(names, ["walk", "trot", "move", "run"])
	_anim_run = _pick_animation_name(names, ["run", "sprint", "gallop"])
	_anim_eat = _pick_animation_name(names, ["idle_eating", "eat", "chew", "bite"])

	if _anim_idle.is_empty():
		_anim_idle = names[0]
	if _anim_walk.is_empty():
		_anim_walk = _anim_idle
	if _anim_run.is_empty():
		_anim_run = _anim_walk
	if _anim_eat.is_empty():
		_anim_eat = _anim_idle

	_has_move_animation = (_anim_walk != _anim_idle) or (_anim_run != _anim_idle)
	for name in [_anim_idle, _anim_walk, _anim_run, _anim_eat]:
		if name.is_empty():
			continue
		var anim: Animation = _anim_player.get_animation(name)
		if anim != null and anim.loop_mode == Animation.LOOP_NONE:
			anim.loop_mode = Animation.LOOP_LINEAR

func _pick_animation_name(names: PackedStringArray, hints: Array) -> String:
	for hint in hints:
		var h := str(hint).to_lower()
		for anim_name in names:
			var name_lower := str(anim_name).to_lower()
			if name_lower.contains(h):
				return str(anim_name)
	return ""

func _aabb_corners(aabb: AABB) -> Array[Vector3]:
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

func _compute_model_bounds(root: Node3D, include_root_transform: bool = false) -> AABB:
	var initial_xf: Transform3D = root.transform if include_root_transform else Transform3D.IDENTITY
	var node_stack: Array[Node3D] = [root]
	var xf_stack: Array[Transform3D] = [initial_xf]
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
				if local_aabb.size.x > 0.000001 and local_aabb.size.y > 0.000001 and local_aabb.size.z > 0.000001:
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
				if child.name == "DogCosmetics" or child.name == "ArmyCamoCollar":
					continue
				node_stack.append(child)
				xf_stack.append(xf * child.transform)

	if not has_point:
		return AABB(Vector3(-0.3, 0.0, -0.6), Vector3(0.6, 1.0, 1.2))
	return AABB(min_v, max_v - min_v)

func _local_transform_from_root(root: Node3D, target: Node3D) -> Transform3D:
	var chain: Array[Node3D] = []
	var current: Node = target
	while current != null and current != root:
		if not (current is Node3D):
			return Transform3D.IDENTITY
		chain.append(current as Node3D)
		current = current.get_parent()
	if current != root:
		return Transform3D.IDENTITY

	var xf := Transform3D.IDENTITY
	for i in range(chain.size() - 1, -1, -1):
		xf = xf * chain[i].transform
	return xf

func _normalize_external_model(root: Node3D) -> void:
	var bounds := _compute_model_bounds(root, true)
	if bounds.size.x <= 0.0001 or bounds.size.y <= 0.0001 or bounds.size.z <= 0.0001:
		return

	if bounds.size.x > bounds.size.z * 1.12:
		root.rotation.y += PI * 0.5
		bounds = _compute_model_bounds(root, true)

	var target_len: float = model_target_length if model_target_length > 0.01 else (1.58 if is_freya else 1.30)
	var target_h: float = model_target_height if model_target_height > 0.01 else (1.08 if is_freya else 0.92)
	var s_len: float = target_len / maxf(bounds.size.x, bounds.size.z)
	var s_h: float = target_h / bounds.size.y
	var uniform: float = clampf(minf(s_len, s_h) * model_scale, 0.0004, 8.0)

	_visual_root.scale = Vector3.ONE * uniform
	_base_visual_y = 0.06 - bounds.position.y * uniform + 0.01
	_visual_root.position.y = _base_visual_y

func _infer_model_forward_axis(model_root: Node3D) -> void:
	_model_forward_yaw_offset = PI

	var dir := Vector3.ZERO
	if _head_pivot != null:
		var local_head_xf: Transform3D = _local_transform_from_root(model_root, _head_pivot)
		var local_head: Vector3 = local_head_xf.origin
		if _tail_pivot != null:
			var local_tail_xf: Transform3D = _local_transform_from_root(model_root, _tail_pivot)
			var local_tail: Vector3 = local_tail_xf.origin
			dir = local_head - local_tail
		else:
			dir = local_head
		dir.y = 0.0
		if dir.length_squared() > 0.0002:
			_model_forward_yaw_offset = atan2(dir.x, dir.z)
			_model_forward_yaw_offset = round(_model_forward_yaw_offset / (PI * 0.5)) * (PI * 0.5)
			return

	var bounds := _compute_model_bounds(model_root, true)
	if bounds.size.x > bounds.size.z * 1.08:
		_model_forward_yaw_offset = PI * 0.5
	elif bounds.size.z > bounds.size.x * 1.08:
		_model_forward_yaw_offset = PI
	else:
		_model_forward_yaw_offset = PI

func _resolve_mouth_anchor(model_root: Node3D) -> void:
	_mouth_anchor_node = _find_named_node(model_root, ["muzzle", "snout", "nose", "mouth", "jaw"])
	_mouth_anchor_skeleton = null
	_mouth_anchor_bone = -1
	if _mouth_anchor_node != null:
		return
	var skel := _find_first_skeleton(model_root)
	if skel == null:
		return
	var preferred = [
		"head_end_end",
		"head_end",
		"snout",
		"muzzle",
		"nose",
		"jaw"
	]
	for needle in preferred:
		for i in range(skel.get_bone_count()):
			var bname := skel.get_bone_name(i).to_lower()
			if bname.contains(needle):
				_mouth_anchor_skeleton = skel
				_mouth_anchor_bone = i
				return

func _set_bone_pose_scale_if_exists(skel: Skeleton3D, bone_name: String, scale_value: Vector3) -> void:
	if skel == null:
		return
	var idx = skel.find_bone(bone_name)
	if idx < 0:
		return
	skel.set_bone_pose_scale(idx, scale_value)

func _apply_external_breed_shape(model_root: Node3D) -> void:
	if is_freya:
		_breed_shape_signature = "freya"
		return
	var skel := _find_first_skeleton(model_root)
	if skel == null:
		_breed_shape_signature = "voxel_default"
		return

	var body_scale = Vector3.ONE
	var head_scale = Vector3.ONE
	var muzzle_scale = Vector3.ONE
	var leg_scale = Vector3.ONE
	var tail_scale = Vector3.ONE
	match breed_profile:
		"chihuahua":
			body_scale = Vector3(0.86, 0.88, 0.86)
			head_scale = Vector3(1.18, 1.16, 1.14)
			muzzle_scale = Vector3(0.8, 0.84, 0.84)
			leg_scale = Vector3(0.86, 0.86, 0.86)
			tail_scale = Vector3(0.9, 1.04, 1.2)
		"labrador":
			body_scale = Vector3(1.06, 1.02, 1.1)
			head_scale = Vector3(1.02, 1.0, 1.04)
			muzzle_scale = Vector3(1.06, 0.98, 1.1)
			leg_scale = Vector3(1.02, 1.02, 1.02)
			tail_scale = Vector3(1.0, 1.0, 1.08)
		"retriever":
			body_scale = Vector3(1.04, 1.03, 1.09)
			head_scale = Vector3(1.01, 1.02, 1.03)
			muzzle_scale = Vector3(1.02, 0.98, 1.06)
			leg_scale = Vector3(1.0, 1.04, 1.0)
			tail_scale = Vector3(1.08, 1.04, 1.14)
		"pitbull":
			body_scale = Vector3(1.14, 1.08, 1.0)
			head_scale = Vector3(1.12, 1.08, 1.02)
			muzzle_scale = Vector3(0.88, 0.86, 0.86)
			leg_scale = Vector3(1.08, 0.94, 1.08)
			tail_scale = Vector3(0.85, 0.92, 0.83)
		"bulldog":
			body_scale = Vector3(1.18, 1.1, 0.92)
			head_scale = Vector3(1.18, 1.12, 0.96)
			muzzle_scale = Vector3(0.76, 0.78, 0.72)
			leg_scale = Vector3(1.08, 0.82, 1.08)
			tail_scale = Vector3(0.72, 0.8, 0.68)
		"boxer":
			body_scale = Vector3(1.08, 1.08, 1.04)
			head_scale = Vector3(1.12, 1.07, 1.03)
			muzzle_scale = Vector3(0.82, 0.82, 0.8)
			leg_scale = Vector3(1.02, 1.07, 1.0)
			tail_scale = Vector3(0.9, 0.9, 0.88)
		"shepherd":
			body_scale = Vector3(0.96, 1.06, 1.1)
			head_scale = Vector3(0.98, 1.04, 1.03)
			muzzle_scale = Vector3(0.92, 0.98, 1.14)
			leg_scale = Vector3(0.95, 1.1, 0.95)
			tail_scale = Vector3(0.96, 1.0, 1.14)
		"husky":
			body_scale = Vector3(1.08, 1.06, 1.02)
			head_scale = Vector3(1.08, 1.08, 1.02)
			muzzle_scale = Vector3(0.93, 0.95, 0.94)
			leg_scale = Vector3(1.04, 1.03, 1.04)
			tail_scale = Vector3(1.1, 1.08, 1.12)
		"terrier":
			body_scale = Vector3(0.94, 0.94, 0.92)
			head_scale = Vector3(1.08, 1.05, 0.98)
			muzzle_scale = Vector3(0.88, 0.92, 0.9)
			leg_scale = Vector3(0.88, 0.92, 0.88)
			tail_scale = Vector3(0.88, 1.05, 1.08)
		"hound":
			body_scale = Vector3(0.9, 1.02, 1.14)
			head_scale = Vector3(0.92, 0.96, 1.0)
			muzzle_scale = Vector3(0.88, 0.94, 1.18)
			leg_scale = Vector3(0.88, 1.12, 0.88)
			tail_scale = Vector3(0.78, 1.02, 1.2)
		"poodle":
			body_scale = Vector3(0.88, 1.06, 0.98)
			head_scale = Vector3(1.04, 1.1, 1.0)
			muzzle_scale = Vector3(0.9, 0.96, 1.03)
			leg_scale = Vector3(0.82, 1.15, 0.82)
			tail_scale = Vector3(0.85, 1.02, 0.94)
		"mixed":
			var shape_phase = float(posmod(variant_seed, 9)) / 8.0
			body_scale = Vector3(lerpf(0.94, 1.08, shape_phase), lerpf(1.04, 0.96, shape_phase), lerpf(1.08, 0.94, shape_phase))
			head_scale = Vector3(lerpf(1.08, 0.96, shape_phase), 1.02, lerpf(0.96, 1.08, shape_phase))
			muzzle_scale = Vector3(0.94, 0.96, lerpf(0.9, 1.12, shape_phase))
			leg_scale = Vector3(0.96, lerpf(0.94, 1.08, shape_phase), 0.96)
			tail_scale = Vector3(0.94, 1.0, lerpf(0.9, 1.12, shape_phase))

	_breed_shape_signature = "%s|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f|%.2f,%.2f,%.2f" % [
		breed_profile,
		body_scale.x, body_scale.y, body_scale.z,
		head_scale.x, head_scale.y, head_scale.z,
		muzzle_scale.x, muzzle_scale.y, muzzle_scale.z
	]

	_set_bone_pose_scale_if_exists(skel, "Body", body_scale)
	_set_bone_pose_scale_if_exists(skel, "Head", head_scale)
	_set_bone_pose_scale_if_exists(skel, "Head_end", muzzle_scale)
	_set_bone_pose_scale_if_exists(skel, "FrontLeg.L", leg_scale)
	_set_bone_pose_scale_if_exists(skel, "FrontLeg.R", leg_scale)
	_set_bone_pose_scale_if_exists(skel, "BackLeg.L", leg_scale)
	_set_bone_pose_scale_if_exists(skel, "BackLeg.R", leg_scale)
	_set_bone_pose_scale_if_exists(skel, "Tail", tail_scale)
	_set_bone_pose_scale_if_exists(skel, "Tail_end", tail_scale)

func _find_first_skeleton(root: Node) -> Skeleton3D:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Skeleton3D:
			return n as Skeleton3D
		for c in n.get_children():
			stack.append(c)
	return null

func _update_external_animation(is_moving: bool, is_running: bool, is_vomiting: bool, is_eating: bool = false) -> void:
	if _anim_player == null:
		return

	var desired := ""
	if is_moving:
		if _has_move_animation:
			desired = _anim_run if is_running else _anim_walk
		else:
			desired = _anim_idle
	else:
		desired = _anim_idle

	if is_vomiting:
		desired = _anim_eat if not _anim_eat.is_empty() else _anim_idle
	elif is_eating:
		desired = _anim_eat if not _anim_eat.is_empty() else _anim_idle

	if desired.is_empty():
		return

	if _anim_player.current_animation != desired or not _anim_player.is_playing():
		_anim_player.play(desired, 0.18)

	var using_idle_for_oral_state = (desired == _anim_idle) and (is_vomiting or is_eating)
	if using_idle_for_oral_state:
		# Freeze locomotion pose so eating/vomiting reads as head action, not foot shuffle.
		_anim_player.speed_scale = 0.0
		return

	if is_vomiting:
		_anim_player.speed_scale = 0.9
	elif is_eating:
		_anim_player.speed_scale = 1.02
	elif is_moving:
		_anim_player.speed_scale = 1.38 if is_running else 1.0
	else:
		_anim_player.speed_scale = 0.85

func update_motion(delta: float, move_dir: Vector3, is_running: bool, is_vomiting: bool, is_eating: bool = false) -> void:
	var is_moving := move_dir.length_squared() > 0.0001
	if move_dir.length_squared() > 0.0001:
		_face_direction(move_dir.normalized(), delta)
		_step_time += delta * (10.5 if is_running else 7.2)
	else:
		_step_time += delta * 2.4
		rotation.x = 0.0
		rotation.z = 0.0

	_update_external_animation(is_moving, is_running, is_vomiting, is_eating)
	_enforce_hidden_leg_pose()

	var stride_amp = 0.8 if is_running else 0.5
	if is_eating or is_vomiting:
		stride_amp = 0.0
	if move_dir.length_squared() < 0.0001:
		stride_amp *= 0.25

	for i in range(_leg_pivots.size()):
		var leg = _leg_pivots[i]
		var phase = _step_time * 6.0 + (PI if i % 2 == 0 else 0.0)
		leg.rotation.x = sin(phase) * stride_amp

	for i in range(_ear_pivots.size()):
		var ear = _ear_pivots[i]
		var flap = sin(_step_time * 4.4 + i * 1.4) * 0.07
		ear.rotation.x = 0.22 + flap

	var wag_amp = 0.5 if is_freya else 0.35
	if is_eating:
		wag_amp *= 0.5
	if _tail_pivot != null:
		_tail_pivot.rotation.y = sin(_step_time * 3.8) * wag_amp
	if _tail_tip_pivot != null:
		_tail_tip_pivot.rotation.y = sin(_step_time * 5.3) * wag_amp * 0.7

	if _head_pivot != null:
		if is_vomiting:
			var retch_phase = 0.56 + 0.15 * sin(_step_time * 10.2)
			_head_pivot.rotation.x = lerp(_head_pivot.rotation.x, retch_phase, clamp(delta * 11.0, 0.0, 1.0))
		elif is_eating:
			var chew_phase = 0.3 + 0.2 * sin(_step_time * 13.4)
			_head_pivot.rotation.x = lerp(_head_pivot.rotation.x, chew_phase, clamp(delta * 13.0, 0.0, 1.0))
		else:
			_head_pivot.rotation.x = lerp(_head_pivot.rotation.x, 0.0, clamp(delta * 7.0, 0.0, 1.0))

	if _visual_root != null and _leg_pivots.is_empty():
		var gait_hz = 8.2 if is_running else 5.9
		var bob = 0.052 if is_running else 0.036
		var roll = 0.05 if is_running else 0.034
		var pitch = 0.042 if is_running else 0.03
		var fore_aft = 0.05 if is_running else 0.032
		if is_eating:
			gait_hz = 4.6
			bob = 0.006
			roll = 0.008
			pitch = 0.016
			fore_aft = 0.0
		elif not is_moving:
			gait_hz = 2.4
			bob = 0.012
			roll = 0.01
			pitch = 0.008
			fore_aft = 0.0
		elif _has_move_animation:
			bob *= 0.45
			roll *= 0.55
			pitch *= 0.45
			fore_aft *= 0.35

		var stride = sin(_step_time * gait_hz)
		_visual_root.position.y = _base_visual_y + absf(stride) * bob
		_visual_root.position.z = stride * fore_aft
		_visual_root.rotation.z = sin(_step_time * gait_hz * 0.5) * roll
		if is_moving:
			_visual_root.rotation.x = sin(_step_time * gait_hz * 0.52 + 0.8) * pitch
		else:
			_visual_root.rotation.x = 0.0
	_update_neck_accessory_poses()

func update_training_motion(delta: float, move_dir: Vector3, training_kind: String, progress: float, vertical_slope: float = 0.0) -> void:
	if not _training_pose_active:
		_training_pose_active = true
		_training_node_base_scale = scale
	var phase = clampf(progress, 0.0, 1.0)
	var running_pose = training_kind == "weave_poles" or training_kind == "jump_hurdle"
	update_motion(delta, move_dir, running_pose, false)
	scale = _training_node_base_scale

	match training_kind:
		"weave_poles":
			if _visual_root != null and is_instance_valid(_visual_root):
				_visual_root.rotation.z += sin(phase * TAU * 3.0) * 0.17
				_visual_root.rotation.x += sin(phase * TAU * 6.0) * 0.035
			if _head_pivot != null and is_instance_valid(_head_pivot):
				_head_pivot.rotation.y = sin(phase * TAU * 3.0) * 0.18
		"jump_hurdle":
			var airborne = sin(phase * PI)
			scale = _training_node_base_scale * Vector3(1.0 + airborne * 0.05, 1.0 - airborne * 0.12, 1.0 - airborne * 0.04)
			if _visual_root != null and is_instance_valid(_visual_root):
				_visual_root.rotation.x = -sin(phase * TAU) * 0.24
				_visual_root.position.y = _base_visual_y + airborne * 0.035
			for leg in _leg_pivots:
				if leg != null and is_instance_valid(leg):
					leg.rotation.x = lerpf(leg.rotation.x, 0.82, airborne)
		"a_frame":
			if _visual_root != null and is_instance_valid(_visual_root):
				_visual_root.rotation.x = clampf(-vertical_slope * 0.34, -0.36, 0.36)
				_visual_root.rotation.z += sin(phase * TAU * 2.0) * 0.025
		"crawl_tunnel":
			var crouch_blend = clampf(sin(phase * PI) * 1.45, 0.0, 1.0)
			scale = _training_node_base_scale * Vector3(1.04, lerpf(1.0, 0.66, crouch_blend), 1.08)
			if _visual_root != null and is_instance_valid(_visual_root):
				_visual_root.position.y = _base_visual_y + 0.012 * sin(phase * TAU * 5.0)
				_visual_root.rotation.x = 0.08 + 0.035 * sin(phase * TAU * 4.0)
			if _head_pivot != null and is_instance_valid(_head_pivot):
				_head_pivot.rotation.x = 0.22 * crouch_blend
		_:
			pass
	_update_neck_accessory_poses()

func clear_training_pose() -> void:
	if not _training_pose_active:
		return
	scale = _training_node_base_scale
	_training_pose_active = false
	if _visual_root != null and is_instance_valid(_visual_root):
		_visual_root.position = Vector3(0.0, _base_visual_y, 0.0)
		_visual_root.rotation.x = 0.0
		_visual_root.rotation.z = 0.0
	if _head_pivot != null and is_instance_valid(_head_pivot):
		_head_pivot.rotation.x = 0.0
		_head_pivot.rotation.y = 0.0
	for leg in _leg_pivots:
		if leg != null and is_instance_valid(leg):
			leg.rotation.x = 0.0
	_update_neck_accessory_poses()

func training_pose_active() -> bool:
	return _training_pose_active

func force_face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	_face_direction(direction.normalized(), delta)
	rotation.x = 0.0
	rotation.z = 0.0

func _face_direction(move_dir: Vector3, delta: float) -> void:
	var target_yaw: float = atan2(move_dir.x, move_dir.z)
	target_yaw -= _model_forward_yaw_offset
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 10.0, 0.0, 1.0))

func head_world_position() -> Vector3:
	if _head_pivot == null:
		return global_position + Vector3(0.0, 0.9, 0.0)
	return _head_pivot.global_position + Vector3(0.0, 0.28, 0.0)

func mouth_world_position() -> Vector3:
	if _mouth_anchor_node != null and is_instance_valid(_mouth_anchor_node):
		return _mouth_anchor_node.global_position
	if _mouth_anchor_skeleton != null and is_instance_valid(_mouth_anchor_skeleton) and _mouth_anchor_bone >= 0:
		var bone_pose: Transform3D = _mouth_anchor_skeleton.get_bone_global_pose(_mouth_anchor_bone)
		return (_mouth_anchor_skeleton.global_transform * bone_pose).origin
	if _head_pivot != null:
		return _head_pivot.to_global(Vector3(0.0, -0.02, -0.4))
	return head_world_position()

func has_move_animation() -> bool:
	# Imported static breeds receive the procedural stride/bob below, while rigs
	# with authored clips use their AnimationPlayer. Both visibly react to motion.
	return (_anim_player != null and _has_move_animation) or (_visual_root != null and is_instance_valid(_visual_root))

func visual_dimensions() -> Vector3:
	var bounds := _compute_model_bounds(self)
	return bounds.size

func _build_model() -> void:
	for child in get_children():
		child.queue_free()

	_leg_pivots.clear()
	_ear_pivots.clear()
	_head_pivot = null
	_tail_pivot = null
	_tail_tip_pivot = null
	_visual_root = null
	_base_visual_y = 0.06
	_anim_player = null
	_anim_idle = ""
	_anim_walk = ""
	_anim_run = ""
	_anim_eat = ""
	_has_move_animation = false
	_model_forward_yaw_offset = PI
	_mouth_anchor_node = null
	_mouth_anchor_skeleton = null
	_mouth_anchor_bone = -1
	_hidden_leg_chains.clear()

	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = coat_color
	body_material.roughness = 0.78
	body_material.metallic = 0.02

	var fur_dark = StandardMaterial3D.new()
	fur_dark.albedo_color = coat_color.darkened(0.18)
	fur_dark.roughness = 0.84

	var nose_material = StandardMaterial3D.new()
	nose_material.albedo_color = Color(0.05, 0.05, 0.05)
	nose_material.roughness = 0.45

	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.07, 0.07, 0.07)
	eye_material.roughness = 0.15

	var variant_rng = RandomNumberGenerator.new()
	if variant_seed != 0:
		variant_rng.seed = variant_seed
	else:
		variant_rng.randomize()

	var torso_scale = Vector3(1.25, 0.82, 1.95)
	var chest_scale = Vector3(1.15, 1.0, 1.2)
	var rump_scale = Vector3(1.2, 0.9, 1.2)
	var head_scale = Vector3(1.1, 1.0, 1.18)
	var muzzle_scale = Vector3(1.3, 0.85, 1.6)
	var ear_scale = Vector3(1.0, 1.0, 1.0)
	var leg_upper_h = 0.35
	var leg_lower_h = 0.32
	var paw_scale = Vector3(1.2, 0.7, 1.4)
	var tail_len_scale = 1.0
	var body_root_scale = Vector3(1.08, 1.02, 1.1) if is_freya else Vector3(0.96, 0.96, 0.96)
	var base_body_y = 0.58

	if not is_freya:
		match breed_profile:
			"retriever":
				torso_scale = Vector3(1.32, 0.84, 2.05)
				chest_scale = Vector3(1.2, 1.02, 1.26)
				rump_scale = Vector3(1.16, 0.9, 1.2)
				head_scale = Vector3(1.08, 0.98, 1.15)
				muzzle_scale = Vector3(1.34, 0.86, 1.74)
				ear_scale = Vector3(1.0, 1.08, 0.95)
				tail_len_scale = 1.15
			"shepherd":
				torso_scale = Vector3(1.28, 0.82, 2.15)
				chest_scale = Vector3(1.18, 1.0, 1.24)
				rump_scale = Vector3(1.22, 0.9, 1.24)
				head_scale = Vector3(1.16, 1.02, 1.2)
				muzzle_scale = Vector3(1.24, 0.84, 1.52)
				ear_scale = Vector3(0.92, 1.45, 0.9)
				leg_upper_h = 0.37
				leg_lower_h = 0.34
				tail_len_scale = 1.25
			"husky":
				torso_scale = Vector3(1.2, 0.84, 2.0)
				chest_scale = Vector3(1.18, 1.04, 1.2)
				rump_scale = Vector3(1.16, 0.92, 1.18)
				head_scale = Vector3(1.12, 1.05, 1.12)
				muzzle_scale = Vector3(1.2, 0.86, 1.44)
				ear_scale = Vector3(0.95, 1.35, 0.95)
				leg_upper_h = 0.36
				leg_lower_h = 0.33
				paw_scale = Vector3(1.18, 0.72, 1.35)
				tail_len_scale = 1.34
			"terrier":
				torso_scale = Vector3(1.08, 0.82, 1.72)
				chest_scale = Vector3(1.05, 1.02, 1.08)
				rump_scale = Vector3(1.06, 0.9, 1.05)
				head_scale = Vector3(1.03, 0.98, 1.02)
				muzzle_scale = Vector3(1.28, 0.83, 1.42)
				ear_scale = Vector3(0.88, 1.24, 0.86)
				leg_upper_h = 0.31
				leg_lower_h = 0.3
				paw_scale = Vector3(1.05, 0.72, 1.2)
				tail_len_scale = 0.95
			"hound":
				torso_scale = Vector3(1.24, 0.8, 2.14)
				chest_scale = Vector3(1.16, 0.97, 1.2)
				rump_scale = Vector3(1.18, 0.88, 1.17)
				head_scale = Vector3(1.08, 0.94, 1.15)
				muzzle_scale = Vector3(1.36, 0.82, 1.9)
				ear_scale = Vector3(1.0, 1.5, 0.94)
				leg_upper_h = 0.38
				leg_lower_h = 0.34
				tail_len_scale = 1.08
				base_body_y = 0.61
			"bulldog":
				torso_scale = Vector3(1.42, 0.93, 1.66)
				chest_scale = Vector3(1.32, 1.13, 1.13)
				rump_scale = Vector3(1.36, 0.95, 1.04)
				head_scale = Vector3(1.26, 1.13, 1.02)
				muzzle_scale = Vector3(1.28, 0.75, 1.08)
				ear_scale = Vector3(0.95, 0.92, 0.96)
				leg_upper_h = 0.25
				leg_lower_h = 0.23
				paw_scale = Vector3(1.36, 0.83, 1.44)
				tail_len_scale = 0.68
				base_body_y = 0.52
			"pitbull":
				torso_scale = Vector3(1.36, 0.9, 1.74)
				chest_scale = Vector3(1.3, 1.16, 1.12)
				rump_scale = Vector3(1.28, 0.96, 1.06)
				head_scale = Vector3(1.24, 1.14, 1.04)
				muzzle_scale = Vector3(1.08, 0.72, 1.0)
				ear_scale = Vector3(0.92, 0.88, 0.92)
				leg_upper_h = 0.28
				leg_lower_h = 0.25
				paw_scale = Vector3(1.32, 0.82, 1.42)
				tail_len_scale = 0.72
				base_body_y = 0.54
			"boxer":
				torso_scale = Vector3(1.26, 0.88, 1.9)
				chest_scale = Vector3(1.22, 1.11, 1.14)
				rump_scale = Vector3(1.18, 0.93, 1.09)
				head_scale = Vector3(1.18, 1.06, 1.03)
				muzzle_scale = Vector3(1.04, 0.75, 0.95)
				ear_scale = Vector3(0.95, 1.0, 0.92)
				leg_upper_h = 0.34
				leg_lower_h = 0.31
				paw_scale = Vector3(1.16, 0.76, 1.25)
				tail_len_scale = 0.8
				base_body_y = 0.58
			"labrador":
				torso_scale = Vector3(1.34, 0.86, 2.06)
				chest_scale = Vector3(1.22, 1.05, 1.25)
				rump_scale = Vector3(1.18, 0.92, 1.2)
				head_scale = Vector3(1.12, 1.0, 1.16)
				muzzle_scale = Vector3(1.34, 0.86, 1.66)
				ear_scale = Vector3(1.0, 1.06, 0.94)
				leg_upper_h = 0.36
				leg_lower_h = 0.34
				tail_len_scale = 1.14
			"chihuahua":
				torso_scale = Vector3(0.88, 0.74, 1.34)
				chest_scale = Vector3(0.86, 0.94, 0.9)
				rump_scale = Vector3(0.84, 0.8, 0.86)
				head_scale = Vector3(1.22, 1.15, 1.14)
				muzzle_scale = Vector3(1.02, 0.76, 1.08)
				ear_scale = Vector3(0.95, 1.48, 0.9)
				leg_upper_h = 0.22
				leg_lower_h = 0.2
				paw_scale = Vector3(0.86, 0.62, 0.92)
				tail_len_scale = 1.08
				base_body_y = 0.47
			"poodle":
				torso_scale = Vector3(1.1, 0.84, 1.86)
				chest_scale = Vector3(1.08, 1.03, 1.1)
				rump_scale = Vector3(1.08, 0.93, 1.06)
				head_scale = Vector3(1.17, 1.09, 1.05)
				muzzle_scale = Vector3(1.16, 0.84, 1.34)
				ear_scale = Vector3(1.06, 1.3, 0.9)
				leg_upper_h = 0.35
				leg_lower_h = 0.35
				paw_scale = Vector3(1.04, 0.72, 1.2)
				tail_len_scale = 1.02
			_:
				pass

		torso_scale *= Vector3(
			variant_rng.randf_range(0.93, 1.09),
			variant_rng.randf_range(0.94, 1.08),
			variant_rng.randf_range(0.92, 1.1)
		)
		chest_scale *= Vector3(
			variant_rng.randf_range(0.94, 1.08),
			variant_rng.randf_range(0.95, 1.08),
			variant_rng.randf_range(0.92, 1.09)
		)
		head_scale *= Vector3(
			variant_rng.randf_range(0.92, 1.09),
			variant_rng.randf_range(0.93, 1.1),
			variant_rng.randf_range(0.92, 1.08)
		)
		muzzle_scale *= Vector3(
			variant_rng.randf_range(0.9, 1.1),
			variant_rng.randf_range(0.92, 1.06),
			variant_rng.randf_range(0.9, 1.13)
		)
		ear_scale.y *= variant_rng.randf_range(0.84, 1.3)
		leg_upper_h *= variant_rng.randf_range(0.92, 1.1)
		leg_lower_h *= variant_rng.randf_range(0.92, 1.1)
		tail_len_scale *= variant_rng.randf_range(0.84, 1.24)
		body_root_scale *= variant_rng.randf_range(0.93, 1.08)

	var body_root = Node3D.new()
	body_root.position = Vector3(0.0, base_body_y, 0.0)
	add_child(body_root)
	_visual_root = body_root

	var torso = MeshInstance3D.new()
	var torso_mesh = SphereMesh.new()
	torso_mesh.radius = 0.34
	torso_mesh.height = 0.68
	torso.mesh = torso_mesh
	torso.scale = torso_scale
	torso.material_override = body_material
	body_root.add_child(torso)

	var chest = MeshInstance3D.new()
	var chest_mesh = SphereMesh.new()
	chest_mesh.radius = 0.26
	chest_mesh.height = 0.52
	chest.mesh = chest_mesh
	chest.position = Vector3(0.0, 0.02, -0.45)
	chest.scale = chest_scale
	chest.material_override = body_material
	body_root.add_child(chest)

	var rump = MeshInstance3D.new()
	var rump_mesh = SphereMesh.new()
	rump_mesh.radius = 0.25
	rump_mesh.height = 0.5
	rump.mesh = rump_mesh
	rump.position = Vector3(0.0, -0.03, 0.44)
	rump.scale = rump_scale
	rump.material_override = fur_dark
	body_root.add_child(rump)

	_head_pivot = Node3D.new()
	_head_pivot.position = Vector3(0.0, 0.15, -0.9)
	body_root.add_child(_head_pivot)

	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.scale = head_scale
	head.material_override = fur_dark
	_head_pivot.add_child(head)

	var muzzle = MeshInstance3D.new()
	var muzzle_mesh = SphereMesh.new()
	muzzle_mesh.radius = 0.14
	muzzle_mesh.height = 0.28
	muzzle.mesh = muzzle_mesh
	muzzle.position = Vector3(0.0, -0.02, -0.25)
	muzzle.scale = muzzle_scale
	muzzle.material_override = fur_dark
	_head_pivot.add_child(muzzle)

	var nose = MeshInstance3D.new()
	var nose_mesh = SphereMesh.new()
	nose_mesh.radius = 0.07
	nose_mesh.height = 0.14
	nose.mesh = nose_mesh
	nose.position = Vector3(0.0, -0.03, -0.43)
	nose.scale = Vector3(1.0, 0.8, 1.0)
	nose.material_override = nose_material
	_head_pivot.add_child(nose)

	for sx in [-0.12, 0.12]:
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.03
		eye_mesh.height = 0.06
		eye.mesh = eye_mesh
		eye.position = Vector3(sx, 0.05, -0.18)
		eye.material_override = eye_material
		_head_pivot.add_child(eye)

	for sx in [-0.17, 0.17]:
		var ear_pivot = Node3D.new()
		ear_pivot.position = Vector3(sx, 0.08, -0.02)
		_head_pivot.add_child(ear_pivot)
		_ear_pivots.append(ear_pivot)

		var ear = MeshInstance3D.new()
		var ear_mesh = CapsuleMesh.new()
		ear_mesh.radius = 0.06
		ear_mesh.height = 0.28
		ear.mesh = ear_mesh
		ear.position = Vector3(0.0, -0.15, 0.0)
		ear.scale = Vector3(ear_scale.x, ear_scale.y * (1.15 if is_freya else 1.0), ear_scale.z)
		ear.material_override = fur_dark
		ear_pivot.add_child(ear)

	var leg_points = [
		Vector3(-0.2, -0.2, -0.48),
		Vector3(0.2, -0.2, -0.48),
		Vector3(-0.23, -0.2, 0.43),
		Vector3(0.23, -0.2, 0.43)
	]

	for i in range(leg_points.size()):
		var pivot = Node3D.new()
		pivot.position = leg_points[i]
		body_root.add_child(pivot)
		_leg_pivots.append(pivot)

		var upper = MeshInstance3D.new()
		var upper_mesh = CylinderMesh.new()
		upper_mesh.top_radius = 0.055
		upper_mesh.bottom_radius = 0.05
		upper_mesh.height = leg_upper_h
		upper.mesh = upper_mesh
		var upper_y = -0.18
		upper.position = Vector3(0.0, upper_y, 0.0)
		upper.material_override = fur_dark
		pivot.add_child(upper)

		var lower = MeshInstance3D.new()
		var lower_mesh = CylinderMesh.new()
		lower_mesh.top_radius = 0.042
		lower_mesh.bottom_radius = 0.038
		lower_mesh.height = leg_lower_h
		lower.mesh = lower_mesh
		var lower_y = upper_y - leg_upper_h * 0.5 - leg_lower_h * 0.5
		lower.position = Vector3(0.0, lower_y, 0.0)
		lower.material_override = fur_dark
		pivot.add_child(lower)

		var paw = MeshInstance3D.new()
		var paw_mesh = SphereMesh.new()
		paw_mesh.radius = 0.055
		paw_mesh.height = 0.11
		paw.mesh = paw_mesh
		paw.position = Vector3(0.0, lower_y - leg_lower_h * 0.5 - 0.17, 0.03)
		paw.scale = paw_scale
		paw.material_override = nose_material
		pivot.add_child(paw)

	_tail_pivot = Node3D.new()
	_tail_pivot.position = Vector3(0.0, 0.08, 0.84)
	body_root.add_child(_tail_pivot)

	var tail = MeshInstance3D.new()
	var tail_mesh = CapsuleMesh.new()
	tail_mesh.radius = 0.04
	tail_mesh.height = 0.36 * tail_len_scale
	tail.mesh = tail_mesh
	tail.rotation_degrees.x = 90.0
	tail.position = Vector3(0.0, 0.04, 0.2 * tail_len_scale)
	tail.material_override = fur_dark
	_tail_pivot.add_child(tail)

	_tail_tip_pivot = Node3D.new()
	_tail_tip_pivot.position = Vector3(0.0, 0.06, 0.34 * tail_len_scale)
	_tail_pivot.add_child(_tail_tip_pivot)

	var tail_tip = MeshInstance3D.new()
	var tip_mesh = CapsuleMesh.new()
	tip_mesh.radius = 0.03
	tip_mesh.height = 0.22 * clampf(tail_len_scale, 0.84, 1.22)
	tail_tip.mesh = tip_mesh
	tail_tip.rotation_degrees.x = 90.0
	tail_tip.position = Vector3(0.0, 0.02, 0.12 * tail_len_scale)
	tail_tip.material_override = fur_dark
	_tail_tip_pivot.add_child(tail_tip)

	if is_freya:
		var collar = MeshInstance3D.new()
		var collar_mesh = TorusMesh.new()
		collar_mesh.inner_radius = 0.17
		collar_mesh.outer_radius = 0.22
		collar.mesh = collar_mesh
		collar.rotation_degrees.x = 90.0
		collar.position = Vector3(0.0, 0.08, -0.63)
		var collar_mat = StandardMaterial3D.new()
		collar_mat.albedo_color = Color(0.74, 0.22, 0.18)
		collar_mat.roughness = 0.45
		collar.material_override = collar_mat
		body_root.add_child(collar)

		var curl_mat = StandardMaterial3D.new()
		curl_mat.albedo_color = coat_color.darkened(0.14)
		curl_mat.roughness = 0.9
		for i in range(12):
			var curl = MeshInstance3D.new()
			var curl_mesh = SphereMesh.new()
			curl_mesh.radius = 0.05
			curl_mesh.height = 0.1
			curl.mesh = curl_mesh
			var angle = (TAU / 12.0) * float(i)
			curl.position = Vector3(cos(angle) * 0.27, sin(angle * 1.8) * 0.06 + 0.05, sin(angle) * 0.56)
			curl.scale = Vector3(1.0, 0.8, 1.0)
			curl.material_override = curl_mat
			body_root.add_child(curl)

	if not is_freya:
		var patch_mat = StandardMaterial3D.new()
		patch_mat.albedo_color = coat_color.lerp(Color(0.95, 0.93, 0.88), variant_rng.randf_range(0.35, 0.62))
		patch_mat.roughness = 0.84
		var patch_roll = variant_rng.randf()
		if patch_roll < 0.72:
			var chest_patch = MeshInstance3D.new()
			var chest_patch_mesh = SphereMesh.new()
			chest_patch_mesh.radius = 0.17
			chest_patch_mesh.height = 0.34
			chest_patch.mesh = chest_patch_mesh
			chest_patch.position = Vector3(0.0, -0.02, -0.55)
			chest_patch.scale = Vector3(0.8, 1.0, 0.56)
			chest_patch.material_override = patch_mat
			body_root.add_child(chest_patch)
		if patch_roll > 0.3 and patch_roll < 0.9:
			var muzzle_patch = MeshInstance3D.new()
			var muzzle_patch_mesh = SphereMesh.new()
			muzzle_patch_mesh.radius = 0.08
			muzzle_patch_mesh.height = 0.16
			muzzle_patch.mesh = muzzle_patch_mesh
			muzzle_patch.position = Vector3(0.0, -0.03, -0.33)
			muzzle_patch.scale = Vector3(0.62, 0.9, 1.3)
			muzzle_patch.material_override = patch_mat
			_head_pivot.add_child(muzzle_patch)
		if patch_roll > 0.62:
			var tail_patch = MeshInstance3D.new()
			var tail_patch_mesh = SphereMesh.new()
			tail_patch_mesh.radius = 0.035
			tail_patch_mesh.height = 0.07
			tail_patch.mesh = tail_patch_mesh
			tail_patch.position = Vector3(0.0, 0.02, 0.17 * tail_len_scale)
			tail_patch.scale = Vector3(1.0, 0.7, 1.0)
			tail_patch.material_override = patch_mat
			_tail_tip_pivot.add_child(tail_patch)

	body_root.scale = body_root_scale
