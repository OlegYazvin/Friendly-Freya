extends RefCounted
class_name KennelFactory

const DogAgentScript = preload("res://scripts/dog_agent.gd")

const CANONICAL_DOG_MODEL = "res://assets/models/freya_portuguese_water_dog.glb"
const ARCHETYPE_ID = "dog_kennel"
const DISPLAY_NAME = "Northbrook Dog Lodge"
const FOOTPRINT_SIZE = Vector2(10.8, 7.6)
const INTERIOR_RECT_LOCAL = Rect2(-5.05, -3.42, 10.1, 6.62)
const ENTRY_INSIDE_LOCAL = Vector2(0.0, 2.92)
const ENTRY_OUTSIDE_LOCAL = Vector2(0.0, 4.34)
const POSSESSED_DOG_SPAWN_LOCAL = Vector3(3.85, 0.0, 4.28)
const CAGED_DOG_COUNT = 6
const POSSESSED_DOG_LIFETIME_SPAWN_LIMIT = 6


static func create_kennel(cutaway: bool = false) -> Dictionary:
	var root = Node3D.new()
	root.name = "DogKennel"
	root.set_meta("visual_signature", "friendly_freya_dog_kennel_v1")
	root.set_meta("building_archetype", ARCHETYPE_ID)
	root.set_meta("placement_ready", true)

	var materials = _create_materials()
	var structure = Node3D.new()
	structure.name = "KennelStructure"
	root.add_child(structure, true)
	var facade = Node3D.new()
	facade.name = "KennelFrontFacade"
	structure.add_child(facade, true)
	var interior = Node3D.new()
	interior.name = "KennelInterior"
	root.add_child(interior, true)
	var clean_details = Node3D.new()
	clean_details.name = "CleanKennelDetails"
	root.add_child(clean_details, true)
	var possession_overlay = Node3D.new()
	possession_overlay.name = "PossessedKennelOverlay"
	possession_overlay.visible = false
	root.add_child(possession_overlay, true)

	_build_shell(structure, facade, materials)
	var interior_result = _build_interior(interior, materials)
	_build_clean_details(clean_details, materials)
	var possession_result = _build_possession_overlay(possession_overlay, materials)

	var roof_root: Node3D = structure.get_node_or_null("Roof")
	var front_roof: Node3D = structure.get_node_or_null("Roof/FrontRoofPanel")
	var cutaway_side_wall: Node3D = structure.get_node_or_null("RightWall")
	facade.visible = not cutaway
	if roof_root != null:
		roof_root.visible = not cutaway
	if cutaway_side_wall != null:
		cutaway_side_wall.visible = not cutaway
	root.set_meta("cutaway_enabled", cutaway)

	var wall_blockers = [
		Rect2(-5.4, -3.8, 10.8, 0.24),
		Rect2(-5.4, -3.8, 0.24, 7.6),
		Rect2(5.16, -3.8, 0.24, 7.6),
		Rect2(-5.4, 3.56, 4.68, 0.24),
		Rect2(0.72, 3.56, 4.68, 0.24)
	]
	var cage_blockers: Array = interior_result.get("cage_blockers", [])
	return {
		"node": root,
		"archetype_id": ARCHETYPE_ID,
		"display_name": DISPLAY_NAME,
		"footprint_size": FOOTPRINT_SIZE,
		"interior_rect_local": INTERIOR_RECT_LOCAL,
		"entry_inside_local": ENTRY_INSIDE_LOCAL,
		"entry_outside_local": ENTRY_OUTSIDE_LOCAL,
		"possessed_dog_spawn_local": POSSESSED_DOG_SPAWN_LOCAL,
		"wall_blockers_local": wall_blockers,
		"fixture_blockers_local": cage_blockers,
		"cage_roots": interior_result.get("cage_roots", []),
		"caged_dogs": interior_result.get("dogs", []),
		"clean_details": clean_details,
		"possession_overlay": possession_overlay,
		"capacity_pods": possession_result.get("capacity_pods", []),
		"facade": facade,
		"roof_root": roof_root,
		"front_roof": front_roof,
		"cutaway_side_wall": cutaway_side_wall,
		"transparent_window_count": 3,
		"caged_dog_count": CAGED_DOG_COUNT,
		"possessed_dog_lifetime_spawn_limit": POSSESSED_DOG_LIFETIME_SPAWN_LIMIT
	}


static func _create_materials() -> Dictionary:
	return {
		"brick": _material(Color8(164, 92, 66), 0.9),
		"brick_dark": _material(Color8(120, 62, 51), 0.92),
		"cream": _material(Color8(234, 226, 205), 0.82),
		"teal": _material(Color8(49, 128, 132), 0.7),
		"teal_dark": _material(Color8(29, 83, 88), 0.76),
		"roof": _material(Color8(72, 78, 82), 0.94),
		"floor": _material(Color8(192, 202, 194), 0.9),
		"rubber": _material(Color8(70, 79, 76), 0.96),
		"steel": _material(Color8(143, 154, 157), 0.42, 0.64),
		"steel_dark": _material(Color8(66, 74, 78), 0.48, 0.58),
		"wood": _material(Color8(133, 96, 62), 0.84),
		"white": _material(Color8(242, 240, 228), 0.76),
		"glass": _transparent_material(Color(0.42, 0.75, 0.79, 0.24), 0.14, 0.12),
		"warm_light": _emissive_material(Color8(255, 224, 142), Color(1.0, 0.72, 0.3), 1.5),
		"alien": _emissive_material(Color(0.56, 0.16, 0.9), Color(0.72, 0.16, 1.0), 3.4),
		"alien_hot": _emissive_material(Color(0.95, 0.18, 0.73), Color(1.0, 0.12, 0.7), 3.8),
		"alien_glass": _transparent_emissive_material(Color(0.42, 0.08, 0.62, 0.56), Color(0.72, 0.12, 1.0), 2.4),
		"turf": _material(Color8(71, 136, 77), 0.96)
	}


static func _build_shell(structure: Node3D, facade: Node3D, materials: Dictionary) -> void:
	_box(structure, "Foundation", Vector3(10.9, 0.18, 7.7), Vector3(0.0, 0.0, 0.0), materials["brick_dark"])
	_box(structure, "InteriorFloor", Vector3(10.35, 0.08, 7.02), Vector3(0.0, 0.1, -0.02), materials["floor"])
	_box(structure, "BackWall", Vector3(10.8, 3.2, 0.24), Vector3(0.0, 1.68, -3.68), materials["brick"])
	_box(structure, "LeftWall", Vector3(0.24, 3.2, 7.36), Vector3(-5.28, 1.68, 0.0), materials["brick"])
	_box(structure, "RightWall", Vector3(0.24, 3.2, 7.36), Vector3(5.28, 1.68, 0.0), materials["brick"])

	_box(facade, "FrontHeader", Vector3(10.8, 0.64, 0.24), Vector3(0.0, 2.88, 3.68), materials["brick"])
	_box(facade, "FrontLeftPier", Vector3(1.12, 2.56, 0.24), Vector3(-4.72, 1.42, 3.68), materials["brick"])
	_box(facade, "FrontRightPier", Vector3(1.12, 2.56, 0.24), Vector3(4.72, 1.42, 3.68), materials["brick"])
	_box(facade, "DoorLeftMullion", Vector3(0.16, 2.56, 0.24), Vector3(-0.76, 1.42, 3.68), materials["teal_dark"])
	_box(facade, "DoorRightMullion", Vector3(0.16, 2.56, 0.24), Vector3(0.76, 1.42, 3.68), materials["teal_dark"])
	_box(facade, "FrontLeftGlass", Vector3(3.78, 2.28, 0.055), Vector3(-2.76, 1.47, 3.71), materials["glass"], false)
	_box(facade, "FrontRightGlass", Vector3(3.78, 2.28, 0.055), Vector3(2.76, 1.47, 3.71), materials["glass"], false)
	_box(facade, "GlassEntryDoor", Vector3(1.34, 2.48, 0.065), Vector3(0.0, 1.36, 3.72), materials["glass"], false)
	_box(facade, "EntryDoorBottomRail", Vector3(1.46, 0.13, 0.12), Vector3(0.0, 0.18, 3.74), materials["teal_dark"])
	_box(facade, "EntryDoorTopRail", Vector3(1.46, 0.13, 0.12), Vector3(0.0, 2.55, 3.74), materials["teal_dark"])
	_box(facade, "EntryDoorHandle", Vector3(0.055, 0.46, 0.08), Vector3(0.48, 1.35, 3.82), materials["steel"])
	for window_x in [-4.12, -1.4, 1.4, 4.12]:
		_box(facade, "WindowMullion", Vector3(0.07, 2.36, 0.08), Vector3(window_x, 1.48, 3.75), materials["teal_dark"])

	var roof = Node3D.new()
	roof.name = "Roof"
	structure.add_child(roof, true)
	var run = 4.12
	var rise = 1.18
	var slope_length = sqrt(run * run + rise * rise)
	var angle = atan2(rise, run)
	var front_panel = _box(roof, "FrontRoofPanel", Vector3(11.25, 0.18, slope_length), Vector3(0.0, 3.66 + rise * 0.5, 2.03), materials["roof"])
	front_panel.rotation.x = angle
	var back_panel = _box(roof, "BackRoofPanel", Vector3(11.25, 0.18, slope_length), Vector3(0.0, 3.66 + rise * 0.5, -2.03), materials["roof"])
	back_panel.rotation.x = -angle
	_box(roof, "RoofRidge", Vector3(11.35, 0.18, 0.22), Vector3(0.0, 4.86, 0.0), materials["roof"])

	var sign_back = _box(facade, "KennelSignBack", Vector3(5.5, 0.78, 0.16), Vector3(0.0, 3.0, 3.94), materials["cream"])
	sign_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var sign = Label3D.new()
	sign.name = "KennelNameSign"
	sign.text = "NORTHBROOK DOG LODGE"
	sign.font_size = 42
	sign.modulate = Color8(25, 94, 99)
	sign.outline_modulate = Color8(235, 226, 202)
	sign.outline_size = 4
	sign.position = Vector3(0.0, 3.0, 4.04)
	sign.no_depth_test = true
	facade.add_child(sign, true)
	_add_paw_logo(facade, Vector3(-3.42, 3.0, 4.05), materials["teal"])
	_add_paw_logo(facade, Vector3(3.42, 3.0, 4.05), materials["teal"])

	_box(structure, "FrontWalk", Vector3(3.0, 0.08, 1.55), Vector3(0.0, 0.04, 4.32), materials["cream"])
	_box(structure, "EntryMat", Vector3(1.55, 0.035, 0.72), Vector3(0.0, 0.1, 3.94), materials["rubber"])


static func _build_interior(interior: Node3D, materials: Dictionary) -> Dictionary:
	var cage_roots: Array[Node3D] = []
	var dog_nodes: Array[Node3D] = []
	var blockers: Array[Rect2] = []
	_box(interior, "ReceptionDesk", Vector3(2.6, 1.0, 0.72), Vector3(-2.1, 0.59, 2.42), materials["wood"])
	_box(interior, "ReceptionDeskTop", Vector3(2.8, 0.12, 0.86), Vector3(-2.1, 1.12, 2.42), materials["cream"])
	_box(interior, "ReceptionMonitor", Vector3(0.62, 0.48, 0.12), Vector3(-2.1, 1.48, 2.25), materials["steel_dark"])
	_box(interior, "ReceptionKeyboard", Vector3(0.54, 0.04, 0.22), Vector3(-2.1, 1.21, 2.62), materials["steel"])
	blockers.append(Rect2(-3.5, 2.0, 2.8, 0.86))

	# A central aisle leaves every kennel door reachable from the public entry.
	var cage_z_positions = [-2.25, -0.25, 1.75]
	var coat_colors = [
		Color8(43, 39, 35), Color8(196, 151, 93), Color8(224, 218, 201),
		Color8(116, 76, 48), Color8(85, 91, 99), Color8(183, 121, 91)
	]
	var profiles = ["labrador", "poodle", "chihuahua", "pitbull", "husky", "dachshund"]
	for side_index in range(2):
		var side = -1.0 if side_index == 0 else 1.0
		for row_index in range(3):
			var cage_index = side_index * 3 + row_index
			var cage = _create_cage("KennelCage%02d" % cage_index, materials)
			cage.position = Vector3(side * 4.12, 0.14, cage_z_positions[row_index])
			cage.rotation.y = PI * 0.5 if side < 0.0 else -PI * 0.5
			cage.set_meta("cage_index", cage_index)
			cage.set_meta("contains_dog", true)
			interior.add_child(cage, true)
			cage_roots.append(cage)
			var dog = DogAgentScript.new()
			dog.name = "CagedDog%02d" % cage_index
			dog.configure({
				"is_freya": false,
				"coat_color": coat_colors[cage_index],
				"speed": 0.0,
				"scene_path": CANONICAL_DOG_MODEL,
				"model_scale": 1.0,
				"breed_profile": profiles[cage_index],
				"breed_id": profiles[cage_index],
				"target_length": 1.02 if cage_index != 2 else 0.72,
				"target_height": 0.72 if cage_index != 2 else 0.5,
				"variant_seed": 4100 + cage_index * 97
			})
			dog.position = Vector3(0.0, 0.0, -0.05)
			dog.rotation.y = PI
			dog.set_meta("kennel_captive", true)
			dog.set_meta("alien_possessed", true)
			dog.set_meta("alien_origin_possessed", true)
			cage.add_child(dog, true)
			dog_nodes.append(dog)
			var blocker_center = Vector2(cage.position.x, cage.position.z)
			blockers.append(Rect2(blocker_center - Vector2(0.86, 0.76), Vector2(1.72, 1.52)))

	_box(interior, "WashStation", Vector3(2.2, 0.74, 0.95), Vector3(0.0, 0.5, -2.65), materials["teal_dark"])
	_box(interior, "WashBasin", Vector3(1.9, 0.2, 0.72), Vector3(0.0, 0.94, -2.65), materials["steel"])
	_box(interior, "DrainChannel", Vector3(0.18, 0.025, 5.1), Vector3(0.0, 0.15, -0.3), materials["steel_dark"])
	blockers.append(Rect2(-1.1, -3.12, 2.2, 0.95))

	for light_index in range(4):
		var light_x = lerpf(-3.6, 3.6, (float(light_index) + 0.5) / 4.0)
		_box(interior, "KennelCeilingLight%02d" % light_index, Vector3(1.2, 0.06, 0.22), Vector3(light_x, 3.02, 0.0), materials["warm_light"], false)

	return {"cage_roots": cage_roots, "dogs": dog_nodes, "cage_blockers": blockers}


static func _create_cage(cage_name: String, materials: Dictionary) -> Node3D:
	var cage = Node3D.new()
	cage.name = cage_name
	cage.set_meta("visual_signature", "friendly_freya_kennel_cage_v1")
	_box(cage, "CageTray", Vector3(1.5, 0.08, 1.65), Vector3(0.0, 0.02, -0.05), materials["rubber"])
	for side in [-1.0, 1.0]:
		for side_bar_index in range(5):
			var side_z = lerpf(-0.82, 0.78, float(side_bar_index) / 4.0)
			_cylinder(cage, "CageSideVerticalBar", 0.016, 0.016, 1.22, Vector3(side * 0.75, 0.68, side_z), materials["steel"], 8)
		for side_rail_y in [0.14, 0.68, 1.24]:
			_box(cage, "CageSideRail", Vector3(0.05, 0.05, 1.68), Vector3(side * 0.75, side_rail_y, -0.04), materials["steel"])
	for bar_index in range(7):
		var bar_x = lerpf(-0.68, 0.68, float(bar_index) / 6.0)
		_cylinder(cage, "CageDoorVerticalBar%02d" % bar_index, 0.018, 0.018, 1.22, Vector3(bar_x, 0.68, 0.8), materials["steel"], 8)
		_cylinder(cage, "CageBackVerticalBar%02d" % bar_index, 0.018, 0.018, 1.22, Vector3(bar_x, 0.68, -0.86), materials["steel"], 8)
	for rail_y in [0.14, 0.68, 1.24]:
		_box(cage, "CageDoorRail", Vector3(1.48, 0.055, 0.055), Vector3(0.0, rail_y, 0.8), materials["steel"])
		_box(cage, "CageBackRail", Vector3(1.48, 0.055, 0.055), Vector3(0.0, rail_y, -0.86), materials["steel"])
	for top_z in [-0.84, 0.8]:
		_box(cage, "CageTopCrossRail", Vector3(1.52, 0.055, 0.055), Vector3(0.0, 1.35, top_z), materials["steel"])
	for top_x in [-0.74, 0.74]:
		_box(cage, "CageTopSideRail", Vector3(0.055, 0.055, 1.66), Vector3(top_x, 1.35, -0.03), materials["steel"])
	_box(cage, "CageLatch", Vector3(0.12, 0.2, 0.1), Vector3(0.42, 0.75, 0.88), materials["teal"])
	var bowl = _cylinder(cage, "CageWaterBowl", 0.14, 0.1, 0.08, Vector3(-0.48, 0.13, 0.47), materials["teal"], 16)
	bowl.rotation.x = 0.0
	return cage


static func _build_clean_details(clean_details: Node3D, materials: Dictionary) -> void:
	var status = Label3D.new()
	status.name = "KennelServicesSign"
	status.text = "BOARDING  •  DAYCARE  •  RESCUE"
	status.font_size = 28
	status.modulate = Color8(235, 229, 209)
	status.outline_modulate = Color8(25, 94, 99)
	status.outline_size = 6
	status.position = Vector3(0.0, 2.54, 3.86)
	status.no_depth_test = true
	clean_details.add_child(status, true)
	var open_sign = Label3D.new()
	open_sign.name = "OpenSign"
	open_sign.text = "OPEN"
	open_sign.font_size = 30
	open_sign.modulate = Color8(255, 232, 150)
	open_sign.outline_modulate = Color8(29, 83, 88)
	open_sign.outline_size = 5
	open_sign.position = Vector3(2.76, 1.42, 3.83)
	open_sign.no_depth_test = true
	clean_details.add_child(open_sign, true)
	_box(clean_details, "WelcomePlanter", Vector3(0.72, 0.45, 0.72), Vector3(-1.15, 0.31, 4.1), materials["teal"])
	_sphere(clean_details, "WelcomePlant", 0.45, Vector3(-1.15, 0.78, 4.1), materials["turf"], Vector3(1.0, 0.8, 1.0))


static func _build_possession_overlay(overlay: Node3D, materials: Dictionary) -> Dictionary:
	_box(overlay, "LeftWindowMembrane", Vector3(3.78, 2.28, 0.07), Vector3(-2.76, 1.47, 3.76), materials["alien_glass"], false)
	_box(overlay, "RightWindowMembrane", Vector3(3.78, 2.28, 0.07), Vector3(2.76, 1.47, 3.76), materials["alien_glass"], false)
	var lock_a = _box(overlay, "AlienDoorLockA", Vector3(0.14, 2.1, 0.14), Vector3(0.0, 1.38, 3.9), materials["alien_hot"])
	lock_a.rotation.z = 0.62
	var lock_b = _box(overlay, "AlienDoorLockB", Vector3(0.14, 2.1, 0.14), Vector3(0.0, 1.38, 3.91), materials["alien"])
	lock_b.rotation.z = -0.62

	for vein_index in range(7):
		var vein = _box(
			overlay,
			"AlienFacadeVein%02d" % vein_index,
			Vector3(0.08, 1.0 + float(vein_index % 3) * 0.28, 0.09),
			Vector3(-4.6 + float(vein_index) * 1.52, 1.25 + float(vein_index % 2) * 0.45, 3.86),
			materials["alien"]
		)
		vein.rotation.z = -0.55 + float(vein_index % 3) * 0.48

	for spike_index in range(7):
		var spike = _cylinder(
			overlay,
			"AlienRoofSpire%02d" % spike_index,
			0.025,
			0.16,
			0.9 + float(spike_index % 3) * 0.18,
			Vector3(-4.35 + float(spike_index) * 1.45, 4.72 + float(spike_index % 2) * 0.12, 0.05),
			materials["alien"]
		)
		spike.rotation.z = -0.18 + float(spike_index % 3) * 0.18

	var capacity_pods: Array[Node3D] = []
	for pod_index in range(POSSESSED_DOG_LIFETIME_SPAWN_LIMIT):
		var row = pod_index / 6
		var column = pod_index % 6
		var pod = _sphere(
			overlay,
			"SpawnCapacityPod%02d" % pod_index,
			0.13,
			Vector3(-1.05 + float(column) * 0.42, 3.33 - float(row) * 0.34, 4.08),
			materials["alien_hot"] if pod_index % 2 == 0 else materials["alien"],
			Vector3(1.0, 1.25, 0.66)
		)
		pod.set_meta("spawn_number", pod_index + 1)
		capacity_pods.append(pod)

	var aperture = Node3D.new()
	aperture.name = "PossessedDogSpawnAperture"
	aperture.position = POSSESSED_DOG_SPAWN_LOCAL
	overlay.add_child(aperture, true)
	for ring_index in range(3):
		var ring = _torus(aperture, "SpawnApertureRing%d" % ring_index, 0.32 + float(ring_index) * 0.12, 0.38 + float(ring_index) * 0.12, Vector3(0.0, 0.04 + float(ring_index) * 0.025, 0.0), materials["alien_hot"] if ring_index == 1 else materials["alien"])
		ring.rotation.x = PI * 0.5
	_box(aperture, "SpawnPad", Vector3(1.18, 0.06, 1.18), Vector3(0.0, -0.01, 0.0), materials["alien_glass"], false)

	var warning = Label3D.new()
	warning.name = "InfestedKennelWarning"
	warning.text = "%d POSSESSED DOGS MAX" % POSSESSED_DOG_LIFETIME_SPAWN_LIMIT
	warning.font_size = 28
	warning.modulate = Color(1.0, 0.42, 0.82)
	warning.outline_modulate = Color(0.18, 0.02, 0.25)
	warning.outline_size = 7
	warning.position = Vector3(0.0, 2.54, 4.02)
	warning.no_depth_test = true
	overlay.add_child(warning, true)
	return {"capacity_pods": capacity_pods}


static func _add_paw_logo(parent: Node3D, position: Vector3, material: Material) -> void:
	var paw = Node3D.new()
	paw.name = "PawLogo"
	paw.position = position
	parent.add_child(paw, true)
	_sphere(paw, "PawPad", 0.13, Vector3(0.0, -0.04, 0.0), material, Vector3(1.2, 0.95, 0.35))
	for toe_index in range(3):
		var toe_x = (float(toe_index) - 1.0) * 0.13
		_sphere(paw, "PawToe", 0.07, Vector3(toe_x, 0.13 + absf(toe_x) * 0.22, 0.0), material, Vector3(0.9, 1.1, 0.35))


static func _material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _transparent_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material = _material(color, roughness, metallic)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material


static func _emissive_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material = _material(color, 0.35, 0.08)
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material


static func _transparent_emissive_material(color: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material = _transparent_material(color, 0.22, 0.04)
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material


static func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material, cast_shadow: bool = true) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item, true)
	return item


static func _sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, material: Material, scale: Vector3) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	item.mesh = mesh
	item.position = position
	item.scale = scale
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item, true)
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
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(item, true)
	return item


static func _torus(parent: Node3D, node_name: String, inner_radius: float, outer_radius: float, position: Vector3, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 16
	mesh.ring_segments = 8
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(item, true)
	return item
