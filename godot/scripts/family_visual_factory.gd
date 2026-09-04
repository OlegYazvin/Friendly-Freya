extends RefCounted

## Native low-poly visuals for the family half of the intro. Gene and Zoe are
## intentionally stylized to match Ryah and the procedural home rather than
## attempting photorealism.


static func create_adult(person_id: String) -> Node3D:
	var is_gene = person_id.to_lower() == "gene"
	var root = Node3D.new()
	root.name = "Gene" if is_gene else "Zoe"
	root.set_meta("visual_signature", "friendly_freya_family_adult_v1")
	root.set_meta("reference_traits", "dark_hair_beard_glasses" if is_gene else "curly_light_brown_hair_black_top")

	var skin = _material(Color8(224, 181, 151), 0.84)
	var eye = _material(Color8(42, 31, 28), 0.5)
	var hair = _material(Color8(50, 31, 25) if is_gene else Color8(126, 91, 68), 0.92)
	var hair_light = _material(Color8(72, 48, 38) if is_gene else Color8(174, 137, 102), 0.9)
	var shirt = _material(Color8(70, 76, 82) if is_gene else Color8(30, 28, 31), 0.88)
	var pants = _material(Color8(116, 125, 128) if is_gene else Color8(52, 67, 86), 0.9)
	var shoes = _material(Color8(91, 56, 35) if is_gene else Color8(45, 40, 43), 0.82)
	var mouth = _material(Color8(118, 55, 55), 0.72)

	_box(root, "Torso", Vector3(0.62, 0.82, 0.34), Vector3(0.0, 1.16, 0.0), shirt)
	_box(root, "Waist", Vector3(0.56, 0.22, 0.31), Vector3(0.0, 0.71, 0.0), pants)
	for side in [-1.0, 1.0]:
		_box(root, "Leg", Vector3(0.22, 0.72, 0.25), Vector3(side * 0.17, 0.35, 0.0), pants)
		_box(root, "Shoe", Vector3(0.25, 0.13, 0.4), Vector3(side * 0.17, 0.065, -0.075), shoes)
		var arm = Node3D.new()
		arm.name = "LeftArmPivot" if side < 0.0 else "RightArmPivot"
		arm.position = Vector3(side * 0.39, 1.39, 0.0)
		arm.rotation.z = side * -0.08
		arm.set_meta("neutral_rotation", arm.rotation)
		root.add_child(arm)
		_box(arm, "Sleeve", Vector3(0.2, 0.33, 0.25), Vector3(0.0, -0.14, 0.0), shirt)
		_box(arm, "Forearm", Vector3(0.16, 0.43, 0.18), Vector3(0.0, -0.5, 0.0), skin)
		_sphere(arm, "Hand", 0.105, Vector3(0.0, -0.75, -0.01), skin, Vector3(0.9, 1.1, 0.8))

	_box(root, "Neck", Vector3(0.2, 0.2, 0.2), Vector3(0.0, 1.62, 0.0), skin)
	_sphere(root, "Head", 0.29, Vector3(0.0, 1.84, 0.0), skin, Vector3(0.92, 1.08, 0.92))
	for side in [-1.0, 1.0]:
		_sphere(root, "Eye", 0.025, Vector3(side * 0.095, 1.88, -0.268), eye, Vector3.ONE)
	_box(root, "Smile", Vector3(0.14, 0.025, 0.022), Vector3(0.0, 1.73, -0.278), mouth)

	if is_gene:
		_create_gene_hair_beard_and_glasses(root, hair, hair_light, eye)
	else:
		_create_zoe_curls(root, hair, hair_light)
	return root


static func create_pedestrian(pedestrian_index: int) -> Node3D:
	var root = Node3D.new()
	root.name = "DogWalker%02d" % pedestrian_index
	root.set_meta("visual_signature", "friendly_freya_dog_walker_v1")
	var skin_colors = [Color8(224, 181, 151), Color8(170, 117, 86), Color8(232, 198, 171), Color8(112, 76, 58)]
	var shirt_colors = [Color8(67, 123, 158), Color8(202, 104, 79), Color8(104, 142, 91), Color8(125, 93, 151)]
	var pants_colors = [Color8(52, 64, 82), Color8(82, 70, 58), Color8(48, 78, 76), Color8(78, 72, 91)]
	var hair_colors = [Color8(67, 43, 31), Color8(38, 31, 29), Color8(176, 125, 69), Color8(102, 72, 55)]
	var skin = _material(skin_colors[pedestrian_index % skin_colors.size()], 0.84)
	var shirt = _material(shirt_colors[pedestrian_index % shirt_colors.size()], 0.86)
	var pants = _material(pants_colors[pedestrian_index % pants_colors.size()], 0.9)
	var hair = _material(hair_colors[pedestrian_index % hair_colors.size()], 0.92)
	var shoe = _material(Color8(47, 43, 40), 0.88)
	_box(root, "Torso", Vector3(0.5, 0.72, 0.3), Vector3(0.0, 1.08, 0.0), shirt)
	for side in [-1.0, 1.0]:
		_box(root, "Leg", Vector3(0.18, 0.65, 0.22), Vector3(side * 0.14, 0.38, 0.0), pants)
		_box(root, "Shoe", Vector3(0.21, 0.12, 0.34), Vector3(side * 0.14, 0.06, -0.06), shoe)
		var arm = Node3D.new()
		arm.name = "LeashArm" if side > 0.0 else "FreeArm"
		arm.position = Vector3(side * 0.31, 1.3, 0.0)
		arm.rotation.z = side * (0.32 if side > 0.0 else -0.12)
		root.add_child(arm)
		_box(arm, "Sleeve", Vector3(0.16, 0.28, 0.22), Vector3(0.0, -0.13, 0.0), shirt)
		_box(arm, "Forearm", Vector3(0.13, 0.38, 0.15), Vector3(0.0, -0.43, 0.0), skin)
		_sphere(arm, "Hand", 0.09, Vector3(0.0, -0.66, 0.0), skin, Vector3(0.9, 1.05, 0.82))
	_box(root, "Neck", Vector3(0.16, 0.16, 0.16), Vector3(0.0, 1.52, 0.0), skin)
	_sphere(root, "Head", 0.25, Vector3(0.0, 1.73, 0.0), skin, Vector3(0.92, 1.08, 0.92))
	_sphere(root, "Hair", 0.255, Vector3(0.0, 1.86, 0.045), hair, Vector3(1.02, 0.52 + float(pedestrian_index % 2) * 0.18, 1.0))
	return root


static func create_pill_reveal() -> Node3D:
	var root = Node3D.new()
	root.name = "GenePillBottleReveal"
	root.set_meta("visual_signature", "friendly_freya_pill_reveal_v1")
	var bottle_materials = [
		_transparent_material(Color(0.72, 0.35, 0.12, 0.82)),
		_transparent_material(Color(0.87, 0.52, 0.16, 0.82)),
		_transparent_material(Color(0.56, 0.25, 0.1, 0.82))
	]
	var cap = _material(Color8(242, 239, 225), 0.66)
	var label_colors = [
		_material(Color8(230, 224, 195), 0.82),
		_material(Color8(198, 224, 224), 0.82),
		_material(Color8(232, 198, 211), 0.82)
	]
	for bottle_index in range(9):
		var bottle = Node3D.new()
		bottle.name = "PillBottle%02d" % bottle_index
		var column = bottle_index % 5
		var row = bottle_index / 5
		bottle.position = Vector3((float(column) - 2.0) * 0.16 + float(row) * 0.07, float(row) * 0.18, float(row) * 0.08)
		bottle.rotation.z = deg_to_rad(float((bottle_index % 3) - 1) * 7.0)
		root.add_child(bottle)
		_cylinder(bottle, "AmberBottle", 0.07, 0.1, 0.28, Vector3(0.0, 0.14, 0.0), bottle_materials[bottle_index % bottle_materials.size()])
		_cylinder(bottle, "WhiteCap", 0.078, 0.078, 0.07, Vector3(0.0, 0.315, 0.0), cap)
		_box(bottle, "PharmacyLabel", Vector3(0.145, 0.105, 0.012), Vector3(0.0, 0.16, -0.094), label_colors[bottle_index % label_colors.size()])
	return root


static func create_dropped_pills() -> Node3D:
	var root = Node3D.new()
	root.name = "DroppedPharmacyPills"
	root.set_meta("visual_signature", "friendly_freya_dropped_pills_v1")
	root.set_meta("bottle_count", 9)
	var bottle_materials = [
		_transparent_material(Color(0.72, 0.35, 0.12, 0.84)),
		_transparent_material(Color(0.87, 0.52, 0.16, 0.84)),
		_transparent_material(Color(0.56, 0.25, 0.1, 0.84))
	]
	var cap = _material(Color8(242, 239, 225), 0.66)
	var label_colors = [
		_material(Color8(230, 224, 195), 0.82),
		_material(Color8(198, 224, 224), 0.82),
		_material(Color8(232, 198, 211), 0.82)
	]
	for bottle_index in range(9):
		var bottle = Node3D.new()
		bottle.name = "DroppedPillBottle%02d" % bottle_index
		var angle = TAU * float(bottle_index) / 9.0 + float(bottle_index % 2) * 0.23
		var radius = 0.18 + float(bottle_index % 3) * 0.12
		bottle.position = Vector3(cos(angle) * radius, 0.105 + float(bottle_index % 2) * 0.015, sin(angle) * radius * 0.72)
		bottle.rotation = Vector3(
			deg_to_rad(float((bottle_index % 3) - 1) * 8.0),
			angle + float(bottle_index % 4) * 0.17,
			deg_to_rad(72.0 + float(bottle_index % 3) * 9.0)
		)
		root.add_child(bottle)
		_cylinder(bottle, "AmberBottle", 0.07, 0.1, 0.28, Vector3.ZERO, bottle_materials[bottle_index % bottle_materials.size()])
		_cylinder(bottle, "WhiteCap", 0.078, 0.078, 0.07, Vector3(0.0, 0.175, 0.0), cap)
		_box(bottle, "PharmacyLabel", Vector3(0.145, 0.105, 0.012), Vector3(0.0, 0.0, -0.094), label_colors[bottle_index % label_colors.size()])

	# A few loose capsules make the landing read as a comic spill rather than a
	# second neatly held bundle.
	var capsule_colors = [
		_material(Color8(245, 213, 82), 0.68),
		_material(Color8(111, 203, 216), 0.68),
		_material(Color8(236, 124, 156), 0.68)
	]
	for capsule_index in range(7):
		var capsule = _box(
			root,
			"LooseCapsule%02d" % capsule_index,
			Vector3(0.08, 0.035, 0.035),
			Vector3(-0.38 + float(capsule_index) * 0.13, 0.035, 0.29 + sin(float(capsule_index) * 1.8) * 0.09),
			capsule_colors[capsule_index % capsule_colors.size()]
		)
		capsule.rotation.y = float(capsule_index) * 0.73
	return root


static func create_pill_convulsion_effect() -> Node3D:
	var root = Node3D.new()
	root.name = "FreyaPillConvulsionEffect"
	root.set_meta("visual_signature", "friendly_freya_pill_convulsion_v1")
	var cyan = _emissive_transparent_material(Color(0.22, 0.95, 1.0, 0.82), Color(0.22, 0.95, 1.0), 2.8)
	var pink = _emissive_transparent_material(Color(1.0, 0.35, 0.76, 0.84), Color(1.0, 0.35, 0.76), 2.8)
	var yellow = _emissive_transparent_material(Color(1.0, 0.88, 0.24, 0.88), Color(1.0, 0.88, 0.24), 3.0)
	for ring_index in range(3):
		var ring = _torus(root, "WobbleRing%d" % ring_index, 0.62 + float(ring_index) * 0.17, 0.68 + float(ring_index) * 0.17, Vector3(0.0, 0.5 + float(ring_index) * 0.26, 0.0), cyan if ring_index % 2 == 0 else pink)
		ring.rotation = Vector3(0.2 + float(ring_index) * 0.42, 0.0, 0.34 - float(ring_index) * 0.27)
		ring.set_meta("reaction_phase", float(ring_index) * 0.8)
	for star_index in range(8):
		var star = Node3D.new()
		star.name = "ComicStar%d" % star_index
		star.set_meta("reaction_phase", TAU * float(star_index) / 8.0)
		root.add_child(star)
		var star_material = yellow if star_index % 3 == 0 else (pink if star_index % 3 == 1 else cyan)
		_box(star, "StarBarA", Vector3(0.24, 0.055, 0.055), Vector3.ZERO, star_material)
		var cross = _box(star, "StarBarB", Vector3(0.055, 0.24, 0.055), Vector3.ZERO, star_material)
		cross.rotation.z = PI * 0.25
	root.visible = false
	return root


static func create_abduction_effect(effect_name: String, color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = effect_name
	root.set_meta("visual_signature", "friendly_freya_abduction_rings_v1")
	var beam_material = _emissive_transparent_material(Color(color.r, color.g, color.b, 0.17), color, 1.8)
	var ring_material = _emissive_transparent_material(Color(color.r, color.g, color.b, 0.9), color, 3.2)
	_cylinder(root, "AbductionBeam", 0.53, 0.53, 2.45, Vector3(0.0, 1.2, 0.0), beam_material, 24)
	for ring_index in range(2):
		var ring = _torus(root, "AbductionRing%d" % ring_index, 0.48, 0.56, Vector3(0.0, 0.55 + ring_index * 1.15, 0.0), ring_material)
		ring.rotation.x = 0.08 if ring_index == 0 else -0.08
	root.visible = false
	return root


static func create_bark_wave(wave_name: String, color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = wave_name
	root.set_meta("visual_signature", "friendly_freya_bark_wave_v1")
	var wave_material = _emissive_transparent_material(Color(color.r, color.g, color.b, 0.82), color, 2.7)
	for ring_index in range(3):
		var ring = _torus(root, "BarkWaveRing%d" % ring_index, 0.25, 0.29, Vector3.ZERO, wave_material)
		ring.rotation.x = PI * 0.5
		ring.set_meta("ring_index", ring_index)
	root.visible = false
	return root


static func _create_gene_hair_beard_and_glasses(root: Node3D, hair: Material, hair_light: Material, glasses: Material) -> void:
	_sphere(root, "HairCap", 0.305, Vector3(0.0, 2.04, 0.035), hair, Vector3(1.02, 0.48, 1.0))
	for tuft_index in range(6):
		var angle = lerpf(-1.1, 1.1, float(tuft_index) / 5.0)
		_sphere(root, "HairTuft", 0.095, Vector3(sin(angle) * 0.22, 2.10 + cos(angle) * 0.035, -0.02 + cos(angle) * 0.08), hair_light if tuft_index % 2 else hair, Vector3(0.9, 1.15, 0.85))
	# Full facial hair and mustache are Gene's strongest readable likeness cues.
	_sphere(root, "BeardChin", 0.225, Vector3(0.0, 1.68, -0.12), hair, Vector3(1.05, 0.72, 0.72))
	for side in [-1.0, 1.0]:
		_sphere(root, "BeardSide", 0.11, Vector3(side * 0.19, 1.75, -0.19), hair, Vector3(0.7, 1.3, 0.6))
	_box(root, "Mustache", Vector3(0.2, 0.045, 0.04), Vector3(0.0, 1.79, -0.278), hair_light)
	# Rectangular glasses based on the supplied references.
	for side in [-1.0, 1.0]:
		var lens_x = side * 0.105
		_box(root, "GlassesTop", Vector3(0.17, 0.018, 0.018), Vector3(lens_x, 1.94, -0.294), glasses)
		_box(root, "GlassesBottom", Vector3(0.17, 0.018, 0.018), Vector3(lens_x, 1.855, -0.294), glasses)
		_box(root, "GlassesSide", Vector3(0.018, 0.1, 0.018), Vector3(lens_x + side * 0.085, 1.898, -0.294), glasses)
		_box(root, "GlassesNoseSide", Vector3(0.018, 0.1, 0.018), Vector3(lens_x - side * 0.085, 1.898, -0.294), glasses)
	_box(root, "GlassesBridge", Vector3(0.04, 0.018, 0.018), Vector3(0.0, 1.905, -0.296), glasses)


static func _create_zoe_curls(root: Node3D, hair: Material, hair_light: Material) -> void:
	_sphere(root, "HairBase", 0.31, Vector3(0.0, 1.98, 0.05), hair, Vector3(1.05, 0.72, 1.0))
	for curl_index in range(20):
		var side = -1.0 if curl_index % 2 == 0 else 1.0
		var row = curl_index / 6
		var lane = curl_index % 6
		var x = side * (0.22 + float(lane % 3) * 0.035)
		var y = 2.07 - float(row) * 0.16 + sin(float(curl_index) * 1.7) * 0.035
		var z = 0.035 + float((lane + row) % 3) * 0.07
		_sphere(root, "CurlyHair", 0.105, Vector3(x, y, z), hair_light if curl_index % 3 == 0 else hair, Vector3(0.92, 1.08, 0.92))
	for top_index in range(7):
		var angle = TAU * float(top_index) / 7.0
		_sphere(root, "TopCurl", 0.105, Vector3(cos(angle) * 0.2, 2.11 + sin(angle) * 0.045, sin(angle) * 0.11), hair_light if top_index % 2 else hair, Vector3.ONE)


static func _material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


static func _transparent_material(color: Color) -> StandardMaterial3D:
	var material = _material(color, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _emissive_transparent_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material = _transparent_material(color)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material


static func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item


static func _sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, material: Material, scale: Vector3) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	item.mesh = mesh
	item.position = position
	item.scale = scale
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item


static func _cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float, height: float, position: Vector3, material: Material, segments: int = 12) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item


static func _torus(parent: Node3D, node_name: String, inner_radius: float, outer_radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 20
	mesh.ring_segments = 8
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item)
	return item
