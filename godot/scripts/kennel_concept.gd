extends Node3D

const KennelBuildingScript = preload("res://scripts/kennel_building.gd")
const KennelFactoryScript = preload("res://scripts/kennel_factory.gd")
const DogAgentScript = preload("res://scripts/dog_agent.gd")

var kennel: Node3D
var preview_possessed_dogs: Array[Node3D] = []
var camera_node: Camera3D
var concept_title: Label
var concept_subtitle: Label
var entry_panel: Panel
var entry_label: Label


func _ready() -> void:
	_create_world()
	var view = OS.get_environment("FREYA_KENNEL_VIEW").strip_edges().to_lower()
	if view.is_empty():
		view = "clean"
	kennel = KennelBuildingScript.new()
	kennel.name = "PlacementReadyKennel"
	kennel.configure({
		"cutaway": view == "interior",
		"possessed": view == "possessed",
		"possessed_dog_spawn_interval": 8.0
	})
	add_child(kennel, true)
	kennel.possessed_dog_spawn_requested.connect(_on_possessed_dog_spawn_requested)
	_create_ui()
	_apply_view(view)
	if OS.get_environment("FREYA_KENNEL_VALIDATE") == "1":
		var passed = _run_validation()
		get_tree().quit(0 if passed else 1)


func _process(delta: float) -> void:
	for dog in preview_possessed_dogs:
		if dog != null and is_instance_valid(dog) and dog.has_method("update_motion"):
			dog.call("update_motion", delta, Vector3.ZERO, false, false)


func _create_world() -> void:
	var world_environment = WorldEnvironment.new()
	world_environment.name = "KennelConceptEnvironment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color8(92, 167, 214)
	sky_material.sky_horizon_color = Color8(212, 232, 224)
	sky_material.ground_bottom_color = Color8(94, 112, 95)
	sky_material.ground_horizon_color = Color8(187, 205, 179)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color(0.82, 0.88, 0.92)
	environment.ambient_light_energy = 0.66
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var sun = DirectionalLight3D.new()
	sun.name = "ConceptSun"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color8(255, 238, 205)
	sun.light_energy = 0.86
	sun.shadow_enabled = true
	add_child(sun)

	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color8(97, 154, 89)
	ground_material.roughness = 0.96
	_add_box("ConceptGrass", Vector3(26.0, 0.12, 22.0), Vector3(0.0, -0.13, 0.0), ground_material)
	var pavement_material = StandardMaterial3D.new()
	pavement_material.albedo_color = Color8(194, 194, 185)
	pavement_material.roughness = 0.92
	_add_box("ConceptSidewalk", Vector3(18.0, 0.08, 3.0), Vector3(0.0, -0.02, 5.3), pavement_material)
	var road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color8(75, 82, 87)
	road_material.roughness = 0.95
	_add_box("ConceptRoad", Vector3(26.0, 0.09, 5.4), Vector3(0.0, -0.08, 9.45), road_material)

	camera_node = Camera3D.new()
	camera_node.name = "KennelConceptCamera"
	camera_node.current = true
	camera_node.fov = 43.0
	add_child(camera_node)


func _create_ui() -> void:
	var layer = CanvasLayer.new()
	layer.name = "KennelConceptUI"
	add_child(layer)
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)

	var banner = Panel.new()
	banner.position = Vector2(24.0, 22.0)
	banner.size = Vector2(520.0, 88.0)
	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = Color(0.025, 0.045, 0.055, 0.92)
	banner_style.border_color = Color(0.35, 0.82, 0.79, 0.92)
	banner_style.set_border_width_all(2)
	banner_style.set_corner_radius_all(12)
	banner_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	banner_style.shadow_size = 7
	banner.add_theme_stylebox_override("panel", banner_style)
	overlay.add_child(banner)
	concept_title = Label.new()
	concept_title.position = Vector2(18.0, 10.0)
	concept_title.size = Vector2(490.0, 32.0)
	concept_title.text = "DOG KENNEL • PLACEMENT-READY CONCEPT"
	concept_title.add_theme_font_size_override("font_size", 20)
	concept_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.91))
	banner.add_child(concept_title)
	concept_subtitle = Label.new()
	concept_subtitle.position = Vector2(18.0, 44.0)
	concept_subtitle.size = Vector2(490.0, 28.0)
	concept_subtitle.add_theme_font_size_override("font_size", 16)
	concept_subtitle.add_theme_color_override("font_color", Color(0.92, 0.95, 0.93))
	banner.add_child(concept_subtitle)

	var not_placed = Label.new()
	not_placed.anchor_left = 1.0
	not_placed.anchor_right = 1.0
	not_placed.offset_left = -330.0
	not_placed.offset_right = -24.0
	not_placed.offset_top = 28.0
	not_placed.offset_bottom = 60.0
	not_placed.text = "CONCEPT PREVIEW • NOT PLACED ON MAP"
	not_placed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	not_placed.add_theme_font_size_override("font_size", 15)
	not_placed.add_theme_color_override("font_color", Color(1.0, 0.91, 0.62))
	overlay.add_child(not_placed)

	entry_panel = Panel.new()
	entry_panel.anchor_left = 0.5
	entry_panel.anchor_top = 1.0
	entry_panel.anchor_right = 0.5
	entry_panel.anchor_bottom = 1.0
	entry_panel.offset_left = -430.0
	entry_panel.offset_top = -156.0
	entry_panel.offset_right = 430.0
	entry_panel.offset_bottom = -42.0
	var entry_style = StyleBoxFlat.new()
	entry_style.bg_color = Color(0.035, 0.055, 0.075, 0.96)
	entry_style.border_color = Color(0.5, 1.0, 0.88, 0.92)
	entry_style.set_border_width_all(3)
	entry_style.set_corner_radius_all(14)
	entry_panel.add_theme_stylebox_override("panel", entry_style)
	overlay.add_child(entry_panel)
	var speaker = Label.new()
	speaker.position = Vector2(20.0, 10.0)
	speaker.size = Vector2(350.0, 25.0)
	speaker.text = "FREYA'S THOUGHTS"
	speaker.add_theme_font_size_override("font_size", 18)
	speaker.add_theme_color_override("font_color", Color(0.5, 1.0, 0.88))
	entry_panel.add_child(speaker)
	entry_label = Label.new()
	entry_label.position = Vector2(20.0, 40.0)
	entry_label.size = Vector2(820.0, 58.0)
	entry_label.text = KennelBuildingScript.FIRST_ENTRY_TEXT
	entry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entry_label.add_theme_font_size_override("font_size", 28)
	entry_label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96))
	entry_panel.add_child(entry_label)
	entry_panel.visible = false


func _apply_view(view: String) -> void:
	match view:
		"interior":
			kennel.set_possessed(false)
			kennel.set_cutaway(true)
			camera_node.global_position = Vector3(8.9, 5.8, 10.7)
			camera_node.fov = 48.0
			camera_node.look_at(Vector3(0.0, 0.92, -0.35), Vector3.UP)
			concept_subtitle.text = "CLEAN INTERIOR • 6 CAGED DOGS • FIRST-ENTRY PROMISE"
			entry_panel.visible = kennel.notify_freya_entered() == KennelBuildingScript.FIRST_ENTRY_TEXT
		"possessed":
			kennel.set_possessed(true)
			kennel.set_cutaway(false)
			camera_node.global_position = Vector3(10.8, 6.7, 13.4)
			camera_node.fov = 42.0
			camera_node.look_at(Vector3(0.0, 1.65, 0.25), Vector3.UP)
			concept_subtitle.text = "POSSESSED • ENTRY LOCKED • 3 / 6 DOG SPAWNS REMAIN"
			kennel.advance_spawn_clock(24.1)
			kennel.set_process(false)
		_:
			kennel.set_possessed(false)
			kennel.set_cutaway(false)
			camera_node.global_position = Vector3(10.8, 6.7, 13.4)
			camera_node.fov = 42.0
			camera_node.look_at(Vector3(0.0, 1.7, 0.1), Vector3.UP)
			concept_subtitle.text = "CLEAN EXTERIOR • ENTERABLE • TRANSPARENT FRONT GLAZING"


func _on_possessed_dog_spawn_requested(spawn_world_position: Vector3, spawn_number: int) -> void:
	var profiles = ["poodle", "husky", "dachshund", "labrador", "pitbull", "chihuahua"]
	var coat_colors = [
		Color8(45, 40, 36), Color8(91, 99, 109), Color8(177, 105, 57),
		Color8(211, 174, 112), Color8(218, 211, 194), Color8(117, 73, 48)
	]
	var target_lengths = [1.08, 1.18, 1.0, 1.24, 1.16, 0.72]
	var target_heights = [0.78, 0.82, 0.54, 0.84, 0.76, 0.48]
	var breed_index = (spawn_number - 1) % profiles.size()
	var dog = DogAgentScript.new()
	dog.name = "KennelPossessedDogPreview%02d" % spawn_number
	dog.configure({
		"is_freya": false,
		"coat_color": coat_colors[breed_index],
		"speed": 2.2,
		"scene_path": KennelFactoryScript.CANONICAL_DOG_MODEL,
		"model_scale": 1.0,
		"breed_profile": profiles[breed_index],
		"breed_id": profiles[breed_index],
		"target_length": target_lengths[breed_index],
		"target_height": target_heights[breed_index],
		"variant_seed": 7600 + spawn_number * 137
	})
	dog.set_meta("alien_possessed", true)
	dog.set_meta("alien_origin_possessed", true)
	dog.set_meta("kennel_spawned", true)
	add_child(dog, true)
	var lane = float(spawn_number - 1)
	dog.global_position = spawn_world_position + Vector3((lane - 1.0) * 1.25, 0.0, 0.45 + absf(lane - 1.0) * 0.16)
	dog.rotation.y = PI + (lane - 1.0) * 0.18
	preview_possessed_dogs.append(dog)
	kennel.confirm_possessed_dog_spawned(spawn_number)


func _run_validation() -> bool:
	var failures: Array[String] = []
	if kennel == null or str(kennel.get_meta("visual_signature", "")) != "friendly_freya_kennel_building_v1":
		failures.append("kennel_root_missing")
		return _finish_validation(failures)
	var contract: Dictionary = kennel.placement_contract()
	if str(contract.get("archetype_id", "")) != KennelFactoryScript.ARCHETYPE_ID or not bool(kennel.get_meta("placement_ready", false)):
		failures.append("kennel_placement_contract_missing")
	if contract.get("footprint_size", Vector2.ZERO) != KennelFactoryScript.FOOTPRINT_SIZE:
		failures.append("kennel_footprint_bad")
	if contract.get("entry_inside_local", Vector2.ZERO) != KennelFactoryScript.ENTRY_INSIDE_LOCAL or contract.get("entry_outside_local", Vector2.ZERO) != KennelFactoryScript.ENTRY_OUTSIDE_LOCAL:
		failures.append("kennel_entry_points_bad")
	if (contract.get("wall_blockers_local", []) as Array).size() != 5 or (contract.get("fixture_blockers_local", []) as Array).size() < 8:
		failures.append("kennel_collision_contract_bad")
	if int(contract.get("transparent_window_count", 0)) < 3:
		failures.append("kennel_transparent_windows_missing")
	if int(contract.get("caged_dog_count", 0)) != KennelFactoryScript.CAGED_DOG_COUNT:
		failures.append("kennel_caged_dog_contract_bad")
	if int(contract.get("possessed_dog_lifetime_spawn_limit", 0)) != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT or str(contract.get("spawn_signal", "")) != "possessed_dog_spawn_requested" or str(contract.get("spawn_success_method", "")) != "confirm_possessed_dog_spawned" or str(contract.get("spawn_retry_method", "")) != "reject_possessed_dog_spawn_request":
		failures.append("kennel_possessed_dog_spawn_contract_bad")
	if str(contract.get("canonical_dog_model", "")) != KennelFactoryScript.CANONICAL_DOG_MODEL or str(contract.get("kennel_cleanse_method", "")) != "cleanse_kennel_possession" or str(contract.get("caged_dog_depossession_method", "")) != "depossess_caged_dog" or not bool(contract.get("cleansing_forfeits_unspawned_dogs", false)):
		failures.append("kennel_cleanse_or_voxel_dog_contract_bad")
	if contract.has("alien_lifetime_spawn_limit") or contract.has("alien_spawn_local"):
		failures.append("kennel_legacy_alien_spawn_contract_present")
	var cages: Array = kennel.visual_data.get("cage_roots", [])
	var caged_dogs: Array = kennel.visual_data.get("caged_dogs", [])
	if cages.size() != KennelFactoryScript.CAGED_DOG_COUNT or caged_dogs.size() != KennelFactoryScript.CAGED_DOG_COUNT:
		failures.append("kennel_cage_or_dog_count_bad_%d_%d" % [cages.size(), caged_dogs.size()])
	for caged_dog in caged_dogs:
		if not (caged_dog is Node3D) or not bool(caged_dog.get_meta("kennel_captive", false)) or not bool(caged_dog.get_meta("alien_possessed", false)) or not bool(caged_dog.get_meta("alien_origin_possessed", false)):
			failures.append("kennel_captive_dog_origin_state_bad")
		elif not caged_dog.has_method("visual_style_signature") or str(caged_dog.call("visual_style_signature")) != "freya_voxel_rig":
			failures.append("kennel_captive_dog_not_shared_voxel_rig")
	for cage in cages:
		if not (cage is Node3D) or str(cage.get_meta("visual_signature", "")) != "friendly_freya_kennel_cage_v1" or cage.find_children("CageDoorVerticalBar*", "MeshInstance3D", true, false).size() != 7 or not bool(cage.get_meta("contains_dog", false)):
			failures.append("kennel_cage_visual_incomplete")

	kennel.reset_for_new_level()
	if int(kennel.get_meta("caged_dogs_possessed", -1)) != KennelFactoryScript.CAGED_DOG_COUNT or not kennel.depossess_caged_dog(0) or kennel.depossess_caged_dog(0):
		failures.append("kennel_caged_dog_depossession_hook_bad")
	elif bool(caged_dogs[0].get_meta("alien_possessed", true)) or not bool(caged_dogs[0].get_meta("alien_expelled", false)) or int(kennel.get_meta("caged_dogs_depossessed", 0)) != 1:
		failures.append("kennel_caged_dog_depossession_state_bad")
	kennel.reset_for_new_level()
	if not bool(caged_dogs[0].get_meta("alien_possessed", false)) or bool(caged_dogs[0].get_meta("alien_expelled", true)):
		failures.append("kennel_caged_dog_new_level_reset_bad")
	if not kennel.enterable or not bool(contract.get("clean_enterable", false)):
		failures.append("clean_kennel_not_enterable")
	var first_message = kennel.notify_freya_entered()
	var repeat_message = kennel.notify_freya_entered()
	if first_message != KennelBuildingScript.FIRST_ENTRY_TEXT or first_message != "I'll find a way to free you!" or not repeat_message.is_empty():
		failures.append("kennel_first_entry_dialogue_bad")

	kennel.reset_for_new_level()
	kennel.set_possessed(true)
	if kennel.enterable or bool(contract.get("possessed_enterable", true)):
		failures.append("possessed_kennel_still_enterable")
	var overlay: Node3D = kennel.visual_data.get("possession_overlay", null)
	var clean_details: Node3D = kennel.visual_data.get("clean_details", null)
	if overlay == null or not overlay.visible or clean_details == null or clean_details.visible:
		failures.append("possessed_kennel_visual_state_bad")
	var spawn_handler = Callable(self, "_on_possessed_dog_spawn_requested")
	kennel.possessed_dog_spawn_requested.disconnect(spawn_handler)
	var rejected_request_count = kennel.advance_spawn_clock(kennel.possessed_dog_spawn_interval + 0.1)
	if rejected_request_count != 1 or not kennel.spawn_request_pending or kennel.total_possessed_dogs_spawned != 0:
		failures.append("kennel_unconfirmed_spawn_consumed_capacity")
	kennel.reject_possessed_dog_spawn_request(0.5)
	if kennel.spawn_request_pending or kennel.total_possessed_dogs_spawned != 0 or kennel.remaining_possessed_dog_spawn_capacity() != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT:
		failures.append("kennel_rejected_spawn_not_preserved")
	kennel.possessed_dog_spawn_requested.connect(spawn_handler)
	var partial_requested_before = preview_possessed_dogs.size()
	var partial_emitted = kennel.advance_spawn_clock(kennel.possessed_dog_spawn_interval * 2.0 + 0.1)
	if partial_emitted != 2 or kennel.total_possessed_dogs_spawned != 2 or preview_possessed_dogs.size() != partial_requested_before + 2:
		failures.append("kennel_partial_spawn_setup_bad")
	if not kennel.cleanse_kennel_possession() or not kennel.spawn_budget_closed or kennel.forfeited_possessed_dog_spawn_count() != 4 or kennel.remaining_possessed_dog_spawn_capacity() != 0:
		failures.append("kennel_cleanse_did_not_forfeit_unspawned_dogs")
	kennel.set_possessed(true)
	if kennel.advance_spawn_clock(kennel.possessed_dog_spawn_interval * 50.0) != 0 or kennel.total_possessed_dogs_spawned != 2:
		failures.append("kennel_spawned_after_partial_cleanse")

	kennel.reset_for_new_level()
	kennel.set_possessed(true)
	var requested_before = preview_possessed_dogs.size()
	var emitted = kennel.advance_spawn_clock(kennel.possessed_dog_spawn_interval * float(KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT) + 0.6)
	if emitted != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT or kennel.total_possessed_dogs_spawned != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT or kennel.remaining_possessed_dog_spawn_capacity() != 0:
		failures.append("kennel_spawn_cap_not_reached_exactly_%d_%d" % [emitted, kennel.total_possessed_dogs_spawned])
	if preview_possessed_dogs.size() != requested_before + KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT:
		failures.append("kennel_spawn_signal_count_bad")
	for spawned_dog in preview_possessed_dogs:
		if not bool(spawned_dog.get_meta("kennel_spawned", false)) or not bool(spawned_dog.get_meta("alien_possessed", false)) or not spawned_dog.has_method("visual_style_signature") or str(spawned_dog.call("visual_style_signature")) != "freya_voxel_rig":
			failures.append("kennel_spawned_dog_not_possessed")
			break
	if kennel.advance_spawn_clock(kennel.possessed_dog_spawn_interval * 50.0) != 0 or kennel.total_possessed_dogs_spawned != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT:
		failures.append("kennel_spawn_cap_exceeded")
	var capacity_pods: Array = kennel.visual_data.get("capacity_pods", [])
	if capacity_pods.size() != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT:
		failures.append("kennel_capacity_pod_count_bad_%d" % capacity_pods.size())
	else:
		for pod in capacity_pods:
			if pod is Node3D and pod.visible:
				failures.append("kennel_depleted_capacity_pod_still_visible")
				break
	kennel.cleanse_kennel_possession()
	if kennel.advance_spawn_clock(100.0) != 0:
		failures.append("clean_kennel_spawned_possessed_dog")
	kennel.set_possessed(true)
	if kennel.advance_spawn_clock(100.0) != 0 or kennel.total_possessed_dogs_spawned != KennelBuildingScript.POSSESSED_DOG_SPAWN_LIMIT:
		failures.append("kennel_lifetime_dog_cap_reset_after_repossession")
	return _finish_validation(failures)


func _finish_validation(failures: Array[String]) -> bool:
	if failures.is_empty():
		print("KENNEL_OK: shared voxel rig, 6 de-possessable caged dogs, exact first-entry promise, possessed lockout, partial-cleanse forfeiture, and lifetime 6-possessed-dog cap validated")
		return true
	push_error("KENNEL_FAIL: " + ", ".join(failures))
	return false


func _add_box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var item = MeshInstance3D.new()
	item.name = node_name
	var mesh = BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = position
	item.material_override = material
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(item)
	return item
