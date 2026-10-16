extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(90.0).timeout.connect(func():
		push_error("SUPPLY_TARGETING_FAIL: timed out")
		quit(1)
	)
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("SUPPLY_TARGETING: " + message)


func _place_dog(scene: Node3D, index: int, position: Vector3, recruited: bool, immune: bool, armored: bool) -> void:
	var state: Dictionary = scene.dogs[index]
	state["army_aligned"] = recruited
	state["alien_possessed"] = false
	state["possession_immune"] = immune
	state["has_dog_armor"] = armored
	state["flee_timer"] = 0.0
	var dog: Node3D = state.get("node", null)
	dog.global_position = position
	scene.dogs[index] = state


func _run() -> void:
	root.size = Vector2i(960, 540)
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main")
	await scene_changed
	var scene: Node3D = current_scene
	scene.set_process(false)
	_check(scene.dogs.size() >= 2, "two dogs are required for supply targeting")
	if scene.dogs.size() < 2:
		quit(1)
		return
	var two_dogs: Array = [scene.dogs[0].duplicate(), scene.dogs[1].duplicate()]
	scene.dogs = two_dogs
	scene.campaign_chapter = 2
	scene.chapter_complete = false
	var park_center: Vector2 = scene.dog_park.get_center()
	scene.freya.global_position = Vector3(park_center.x, 0.0, park_center.y)
	_place_dog(scene, 0, scene.freya.global_position + Vector3(0.65, 0.0, 0.0), true, true, false)
	_place_dog(scene, 1, scene.freya.global_position + Vector3(1.2, 0.0, 0.0), true, false, false)
	scene.freya_carries_immunity_dose = true
	scene.freya_carries_dog_armor = false
	scene.freya_carries_clinic_kit = false
	var selected: Dictionary = scene._select_carried_supply_target()
	_check(str(selected.get("kind", "")) == "medicine" and int(selected.get("dog_index", -1)) == 1, "nearest already-immune dog blocked the unprotected ally")
	scene.interact_highlight_update_timer = 0.0
	scene._update_interactable_highlights(0.0)
	var protected_dog: Node3D = scene.dogs[0].get("node", null)
	var target_dog: Node3D = scene.dogs[1].get("node", null)
	var expected_ring = "dog_supply_%d" % target_dog.get_instance_id()
	var wrong_ring = "dog_supply_%d" % protected_dog.get_instance_id()
	_check(scene.interact_highlights.has(expected_ring) and bool(scene.interact_highlights[expected_ring]["node"].visible), "supply ring does not mark the F target")
	_check(not scene.interact_highlights.has(wrong_ring) or not bool(scene.interact_highlights[wrong_ring]["node"].visible), "supply ring still marks the protected nearer dog")
	_check(scene._try_apply_carried_dog_upgrade(), "medicine did not apply to the selected ally")
	_check(bool(scene.dogs[1].get("possession_immune", false)) and not scene.freya_carries_immunity_dose and scene._chapter_protected_ally_count() == 2, "medicine failed to advance the two-ally goal")

	# With no useful supply target, F may still use other nearby interactions.
	scene.sticks.clear()
	scene.bones.clear()
	scene.store_foods.clear()
	scene.poops.clear()
	scene.dog_park_training_items.clear()
	scene.freya_carries_immunity_dose = true
	_check(scene._select_carried_supply_target().is_empty() and not scene._try_apply_carried_dog_upgrade() and scene.freya_carries_immunity_dose, "identical protection consumed another medicine dose")
	scene._try_interact()
	_check("already immune" in scene.status_label.text and scene.freya_carries_immunity_dose, "F gave generic or consuming feedback at an already-protected dog")

	_place_dog(scene, 1, scene.freya.global_position + Vector3(1.2, 0.0, 0.0), false, false, false)
	_check(int(scene._select_carried_supply_target().get("dog_index", -1)) == 1, "independent dog cannot receive protection")
	_check(scene._try_apply_carried_dog_upgrade() and scene._chapter_protected_ally_count() == 1, "independent-dog protection incorrectly advanced chapter goal")
	_check("Hold C" in scene.status_label.text, "independent-dog feedback did not explain recruitment")
	var recruited_state: Dictionary = scene.dogs[1]
	recruited_state["army_aligned"] = true
	scene.dogs[1] = recruited_state
	_check(scene._chapter_protected_ally_count() == 2, "recruiting a protected dog did not count")

	_place_dog(scene, 0, scene.freya.global_position + Vector3(0.65, 0.0, 0.0), true, true, true)
	_place_dog(scene, 1, scene.freya.global_position + Vector3(1.2, 0.0, 0.0), true, true, false)
	scene.freya_carries_immunity_dose = false
	scene.freya_carries_dog_armor = true
	selected = scene._select_carried_supply_target()
	_check(selected.is_empty() and not scene._try_apply_carried_dog_upgrade() and scene.freya_carries_dog_armor, "armor was consumed on a permanently immune dog")
	_place_dog(scene, 1, scene.freya.global_position + Vector3(1.2, 0.0, 0.0), true, false, false)
	_check(str(scene._select_carried_supply_target().get("kind", "")) == "armor" and scene._try_apply_carried_dog_upgrade() and not scene.freya_carries_dog_armor and bool(scene.dogs[1].get("has_dog_armor", false)), "vest did not protect an eligible nonimmune ally")
	scene.freya_carries_clinic_kit = true
	scene.freya_carries_immunity_dose = true
	selected = scene._select_carried_supply_target()
	_check(str(selected.get("kind", "")) == "medicine", "unusable clinic kit blocked useful carried medicine")
	_check(scene._try_apply_carried_dog_upgrade() and scene.freya_carries_clinic_kit and not scene.freya_carries_immunity_dose, "F did not use medicine after skipping unusable clinic kit")
	_place_dog(scene, 0, scene.freya.global_position + Vector3(3.9, 0.0, 0.0), false, true, true)
	var frightened_state: Dictionary = scene.dogs[0]
	frightened_state["flee_timer"] = 2.0
	scene.dogs[0] = frightened_state
	_place_dog(scene, 1, scene.freya.global_position + Vector3(0.8, 0.0, 0.0), true, false, false)
	scene.freya_carries_immunity_dose = true
	selected = scene._select_carried_supply_target()
	_check(str(selected.get("kind", "")) == "medicine" and int(selected.get("dog_index", -1)) == 1, "distant frightened dog consumed care kit ahead of nearby unprotected ally")
	frightened_state = scene.dogs[0]
	frightened_state["army_aligned"] = true
	frightened_state["alien_possessed"] = true
	scene.dogs[0] = frightened_state
	selected = scene._select_carried_supply_target()
	_check(str(selected.get("kind", "")) == "clinic" and int(selected.get("dog_index", -1)) == 0, "retaken ally was not urgent while two supplies were carried")

	scene.freya_carries_immunity_dose = false
	scene.freya_carries_dog_armor = false
	scene.freya_carries_clinic_kit = true
	_place_dog(scene, 0, scene.freya.global_position + Vector3(0.65, 0.0, 0.0), true, true, true)
	_place_dog(scene, 1, scene.freya.global_position + Vector3(1.2, 0.0, 0.0), true, true, true)
	_check("taken ally or scared dog" in scene._carried_supply_status(), "clinic-only carried hint suggests any dog")
	_check(scene._select_carried_supply_target().is_empty(), "healthy dogs became clinic-care targets")
	scene._try_interact()
	_check("Care kit needs" in scene.status_label.text and scene.freya_carries_clinic_kit, "F on a healthy dog hid the clinic requirement")
	scene.status_label.text = scene._carried_supply_status()
	scene._update_status_presentation()
	await process_frame
	_check(root.get_visible_rect().encloses(scene.status_panel.get_global_rect()), "clinic carrying hint clips at 960x540")

	# At a grocery bowl, F must feed Freya before using a carried kit on a dog.
	var grocery: Dictionary = {}
	for service in scene.building_services:
		if str(service.get("service_type", "")) == "infinite_dog_food":
			grocery = service
			break
	_check(not grocery.is_empty(), "grocery service missing")
	if not grocery.is_empty():
		var grocery_index = int(grocery.get("building_index", -1))
		if bool(scene.buildings[grocery_index].get("alien_occupied", false)):
			scene._clear_alien_occupation(grocery_index)
		var food_pos: Vector2 = grocery.get("pos", Vector2.ZERO)
		scene.freya.global_position = Vector3(food_pos.x, 0.0, food_pos.y)
		_place_dog(scene, 0, scene.freya.global_position + Vector3(0.8, 0.0, 0.0), true, false, false)
		var taken_state: Dictionary = scene.dogs[0]
		taken_state["alien_possessed"] = true
		scene.dogs[0] = taken_state
		_place_dog(scene, 1, scene.freya.global_position + Vector3(20.0, 0.0, 0.0), true, true, true)
		scene.freya_hunger = 83.0
		scene.interact_highlight_update_timer = 0.0
		scene._update_interactable_highlights(0.0)
		var supply_ring = "dog_supply_%d" % scene.dogs[0]["node"].get_instance_id()
		_check(not scene.interact_highlights.has(supply_ring) or not bool(scene.interact_highlights[supply_ring]["node"].visible), "supply ring ignored grocery F priority")
		scene._try_interact()
		_check(scene.freya_hunger <= 0.001 and scene.freya_carries_clinic_kit, "F at grocery spent kit instead of feeding Freya")
		scene.freya_carries_clinic_kit = false

	# A protected dog cannot swallow F when a usable building service is nearby.
	scene.freya_carries_clinic_kit = false
	scene.freya_carries_dog_armor = true
	var pharmacy: Dictionary = {}
	for service in scene.building_services:
		if str(service.get("service_type", "")) == "possession_immunity_medicine":
			pharmacy = service
			break
	_check(not pharmacy.is_empty(), "pharmacy service missing")
	if not pharmacy.is_empty():
		var pharmacy_index = int(pharmacy.get("building_index", -1))
		if bool(scene.buildings[pharmacy_index].get("alien_occupied", false)):
			scene._clear_alien_occupation(pharmacy_index)
		var service_pos: Vector2 = pharmacy.get("pos", Vector2.ZERO)
		scene.freya.global_position = Vector3(service_pos.x, 0.0, service_pos.y)
		_place_dog(scene, 0, scene.freya.global_position + Vector3(0.7, 0.0, 0.0), true, true, true)
		_place_dog(scene, 1, scene.freya.global_position + Vector3(20.0, 0.0, 0.0), true, true, true)
		scene._try_interact()
		_check(scene.freya_carries_immunity_dose and "Picked up one medicine" in scene.status_label.text, "protected dog blocked a useful F service")
	# Lodge cages also take F before a carried supply does.
	if scene.kennel != null and scene.kennel_building_index >= 0:
		if bool(scene.buildings[scene.kennel_building_index].get("alien_occupied", false)):
			scene._clear_alien_occupation(scene.kennel_building_index)
		var caged_dogs: Array = scene.kennel.visual_data.get("caged_dogs", [])
		_check(not caged_dogs.is_empty(), "lodge has no caged dogs")
		if not caged_dogs.is_empty():
			var captive: Node3D = caged_dogs[0]
			scene.freya.global_position = captive.global_position
			_place_dog(scene, 0, scene.freya.global_position + Vector3(0.6, 0.0, 0.0), true, false, false)
			_place_dog(scene, 1, scene.freya.global_position + Vector3(20.0, 0.0, 0.0), true, true, true)
			scene.freya_carries_immunity_dose = true
			_check(not scene._nearest_caged_kennel_dog().is_empty(), "captive did not take F at its own cage")
			scene.interact_highlight_update_timer = 0.0
			scene._update_interactable_highlights(0.0)
			var cage_supply_ring = "dog_supply_%d" % scene.dogs[0]["node"].get_instance_id()
			_check(not scene.interact_highlights.has(cage_supply_ring) or not bool(scene.interact_highlights[cage_supply_ring]["node"].visible), "supply ring ignored lodge F priority")
			scene._try_interact()
			_check(scene.freya_carries_immunity_dose, "lodge F consumed medicine before cage interaction")
	await process_frame
	if failures.is_empty():
		print("SUPPLY_TARGETING_OK: one ring/F target, duplicate protection retained, chapter-two allies, independent dogs, second supply, clinic hint, and service fallback")
	quit(0 if failures.is_empty() else 1)
