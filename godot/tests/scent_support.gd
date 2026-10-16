extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	call_deferred("run")


func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error("SCENT_SUPPORT: " + description)


func run() -> void:
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	var target_index = -1
	var support_index = -1
	for target in range(scene.buildings.size()):
		if target == scene.freya_home_index or target == scene.kennel_building_index or scene._building_is_controlled_by_freya(target):
			continue
		var target_center: Vector2 = scene.buildings[target].get("footprint", Rect2()).get_center()
		for support in range(scene.buildings.size()):
			if support == target or support == scene.freya_home_index or support == scene.kennel_building_index or scene._building_is_controlled_by_freya(support):
				continue
			var support_center: Vector2 = scene.buildings[support].get("footprint", Rect2()).get_center()
			if target_center.distance_to(support_center) <= scene.FREYA_SCENT_SUPPORT_RADIUS:
				target_index = target
				support_index = support
				break
		if target_index >= 0:
			break
	check(target_index >= 0, "no neighboring neutral sites for scent support")
	if target_index < 0:
		quit(1)
		return
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, support_index, scene.CLAIM_OWNER_FREYA)
	check(scene._claimed_scent_support(target_index) >= scene.FREYA_SCENT_SUPPORT_PER_BUILDING, "claimed neighbor did not provide scent support")
	check(scene._occupy_building_with_alien(target_index, 99221), "could not occupy comparison site")
	var held: Dictionary = scene.buildings[target_index]
	var start_integrity = float(held.get("alien_integrity", 1.0))
	scene._weaken_alien_building(target_index, 0.5)
	var supported_damage = start_integrity - float(scene.buildings[target_index].get("alien_integrity", 1.0))
	var visual: Node3D = scene.buildings[target_index].get("alien_visual_root", null)
	var label: Label3D = visual.get_node_or_null("AlienCrown/AlienOccupantCount") if visual != null else null
	check(label != null and label.text.contains("FREYA SCENT"), "alien hold did not display scent help")
	held = scene.buildings[target_index]
	held["alien_integrity"] = start_integrity
	held["alien_pee_exposure"] = 0.0
	scene.buildings[target_index] = held
	scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, support_index, scene.CLAIM_OWNER_NONE)
	check(scene._claimed_scent_support(target_index) == 0.0, "unclaimed neighbor still provides support")
	scene._weaken_alien_building(target_index, 0.5)
	var unsupported_damage = start_integrity - float(scene.buildings[target_index].get("alien_integrity", 1.0))
	check(supported_damage > unsupported_damage * 1.1, "claimed scent did not materially speed weakening")
	scene._update_alien_building_label(target_index)
	check(label != null and not label.text.contains("FREYA SCENT"), "scent label stayed after claim was removed")
	if failures.is_empty():
		print("SCENT_SUPPORT_OK: a claimed neighbor speeds alien weakening and updates the hold label")
		quit()
	else:
		push_error("SCENT_SUPPORT_FAIL: " + ", ".join(failures))
		quit(1)
