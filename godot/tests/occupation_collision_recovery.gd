extends SceneTree

# Run with FREYA_WORLD_SEED=20260831. Building 24's exterior margin is the
# position where an input-driven campaign run stopped after an imp transfer.
const TRAPPED_POSITION = Vector2(52.43164, 53.68871)
const TRAPPED_BUILDING_INDEX = 24

var failures: Array[String] = []

func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _walkable(scene: Node, node: Node3D, radius: float) -> bool:
	return scene._is_walkable(node.global_position.x, node.global_position.z, radius)

func _run() -> void:
	change_scene_to_file("res://scenes/Main.tscn")
	await scene_changed
	var scene = current_scene
	var building: Dictionary = scene.buildings[TRAPPED_BUILDING_INDEX]
	var footprint: Rect2 = building.get("footprint", Rect2())
	_check(absf(footprint.end.x - 52.32) < 0.02, "seed_layout_changed")
	_check(not bool(building.get("alien_occupied", false)), "test_building_already_occupied")
	_check(scene._is_walkable(TRAPPED_POSITION.x, TRAPPED_POSITION.y, scene.FREYA_COLLISION_RADIUS), "exterior_margin_not_initially_walkable")
	_check(scene._is_walkable(TRAPPED_POSITION.x, TRAPPED_POSITION.y, scene.DOG_COLLISION_RADIUS), "dog_margin_not_initially_walkable")
	if not failures.is_empty():
		_finish()
		return

	var freya: Node3D = scene.freya
	var dog: Node3D = scene.dogs[0].get("node", null)
	var untouched_dog: Node3D = scene.dogs[1].get("node", null)
	_check(dog != null and untouched_dog != null, "test_dogs_missing")
	if not failures.is_empty():
		_finish()
		return
	var freya_y = freya.global_position.y
	var dog_y = dog.global_position.y
	var untouched_position = untouched_dog.global_position
	freya.global_position = Vector3(TRAPPED_POSITION.x, freya_y, TRAPPED_POSITION.y)
	dog.global_position = Vector3(TRAPPED_POSITION.x, dog_y, TRAPPED_POSITION.y)
	_check(scene._occupy_building_with_alien(TRAPPED_BUILDING_INDEX, 99999, false), "occupation_rejected")
	_check(_walkable(scene, freya, scene.FREYA_COLLISION_RADIUS), "freya_still_trapped")
	_check(_walkable(scene, dog, scene.DOG_COLLISION_RADIUS), "dog_still_trapped")
	_check(Vector2(freya.global_position.x, freya.global_position.z).distance_to(TRAPPED_POSITION) < 0.5, "freya_recovery_too_far")
	_check(Vector2(dog.global_position.x, dog.global_position.z).distance_to(TRAPPED_POSITION) < 0.5, "dog_recovery_too_far")
	_check(is_equal_approx(freya.global_position.y, freya_y) and is_equal_approx(dog.global_position.y, dog_y), "recovery_changed_height")
	_check(untouched_dog.global_position == untouched_position, "unaffected_dog_moved")
	var before_move = freya.global_position.x
	scene._move_freya_with_collisions(Vector3.RIGHT, scene.FREYA_BASE_SPEED, 0.12, false)
	_check(freya.global_position.x > before_move + 0.01, "freya_cannot_move_after_recovery")

	# Simulate an old save made at the trapped point and exercise the full restore.
	freya.global_position = Vector3(TRAPPED_POSITION.x, freya_y, TRAPPED_POSITION.y)
	dog.global_position = Vector3(TRAPPED_POSITION.x, dog_y, TRAPPED_POSITION.y)
	var old_save: Dictionary = scene._snapshot_game_state()
	_check(scene._restore_game_state(old_save), "old_save_restore_failed")
	freya = scene.freya
	dog = scene.dogs[0].get("node", null)
	_check(_walkable(scene, freya, scene.FREYA_COLLISION_RADIUS), "restored_freya_still_trapped")
	_check(dog != null and _walkable(scene, dog, scene.DOG_COLLISION_RADIUS), "restored_dog_still_trapped")
	_check(Vector2(freya.global_position.x, freya.global_position.z).distance_to(TRAPPED_POSITION) < 0.5, "restored_freya_recovery_too_far")
	if dog != null:
		_check(Vector2(dog.global_position.x, dog.global_position.z).distance_to(TRAPPED_POSITION) < 0.5, "restored_dog_recovery_too_far")

	# Interior ejection is already part of occupation; its exit must be walkable.
	var interior_store_index = -1
	var interior_position = Vector2.ZERO
	for store_index in scene.store_building_indices:
		var store: Dictionary = scene.buildings[store_index]
		if bool(store.get("alien_occupied", false)) or not bool(store.get("enterable", false)):
			continue
		var layout: Dictionary = store.get("store_layout", {})
		var candidate: Vector2 = layout.get("entry_inside_pos", store.get("store_interior_rect", store.get("footprint", Rect2())).get_center())
		if scene._is_walkable(candidate.x, candidate.y, scene.FREYA_COLLISION_RADIUS):
			interior_store_index = store_index
			interior_position = candidate
			break
	_check(interior_store_index >= 0, "walkable_store_interior_missing")
	if interior_store_index >= 0:
		freya.global_position = Vector3(interior_position.x, freya.global_position.y, interior_position.y)
		_check(scene._occupy_building_with_alien(interior_store_index, 99998, false), "interior_occupation_rejected")
		_check(_walkable(scene, freya, scene.FREYA_COLLISION_RADIUS), "interior_ejection_blocked")
		_check(not scene._is_inside_store_index(interior_store_index, Vector2(freya.global_position.x, freya.global_position.z)), "freya_left_inside_occupied_store")

	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("OCCUPATION_COLLISION_RECOVERY PASS")
		quit()
	else:
		for failure in failures:
			push_error("OCCUPATION_COLLISION_RECOVERY %s" % failure)
		quit(1)
