extends SceneTree

# Focused generated-layout guard. These are local walkability probes, plus
# sequential territory checks; they do not replace a complete input playtest.
const SEEDS = [20260831, 1, 42, 20260916, 20261014]
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(120.0).timeout.connect(func():
		push_error("CAMPAIGN_REACHABILITY_FAIL: timed out")
		quit(1)
	)
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("CAMPAIGN_REACHABILITY: " + message)


func mark_has_approach(scene, item: Dictionary) -> bool:
	var target_type = int(item.get("type", -1))
	var target_index = int(item.get("index", -1))
	var world: Vector3 = scene._claim_target_base_world_position(target_type, target_index)
	var mark = Vector2(world.x, world.z)
	for radius in [0.55, 0.85, 1.2, 1.55]:
		for angle_index in range(24):
			var angle = TAU * float(angle_index) / 24.0
			var point = mark + Vector2.RIGHT.rotated(angle) * radius
			if scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS):
				return true
	return false


func wall_has_approach(scene, index: int) -> bool:
	var footprint: Rect2 = scene.buildings[index].get("footprint", Rect2())
	for fraction in [0.2, 0.4, 0.6, 0.8]:
		var x = lerpf(footprint.position.x, footprint.end.x, fraction)
		var z = lerpf(footprint.position.y, footprint.end.y, fraction)
		for distance in [0.65, 1.0, 1.35, 1.65]:
			for point in [
				Vector2(footprint.position.x - distance, z),
				Vector2(footprint.end.x + distance, z),
				Vector2(x, footprint.position.y - distance),
				Vector2(x, footprint.end.y + distance)
			]:
				if scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS) and scene._point_distance_to_rect(point, footprint) < scene.CLAIM_RANGE:
					return true
	return false


func check_sites(scene, seed: int, chapter: int) -> void:
	var expected = 8 if chapter == 1 else (5 if chapter == 2 else 4)
	check(scene.chapter_target_indices.size() == expected, "seed %d chapter %d has %d/%d sites" % [seed, chapter, scene.chapter_target_indices.size(), expected])
	for index in scene.chapter_target_indices:
		var building: Dictionary = scene.buildings[index]
		var layout: Dictionary = building.get("store_layout", {})
		var inside: Vector2 = layout.get("entry_inside_pos", Vector2.ZERO)
		var outside: Vector2 = layout.get("entry_outside_pos", Vector2.ZERO)
		if bool(building.get("alien_occupied", false)):
			check(wall_has_approach(scene, index), "seed %d chapter %d site %d alien wall has no Freya approach" % [seed, chapter, index])
			scene._clear_alien_occupation(index)
		check(bool(scene.buildings[index].get("enterable", false)), "seed %d chapter %d site %d cannot open" % [seed, chapter, index])
		for step in range(9):
			var point = outside.lerp(inside, float(step) / 8.0)
			check(scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS), "seed %d chapter %d site %d doorway step %d blocked" % [seed, chapter, index, step])
		for item in scene._building_surrounding_claimables(index):
			check(mark_has_approach(scene, item), "seed %d chapter %d site %d mark %d:%d inaccessible" % [seed, chapter, index, int(item.get("type", -1)), int(item.get("index", -1))])
		check(scene._building_has_adjacent_freya_control(index), "seed %d chapter %d site %d claim sequence disconnected" % [seed, chapter, index])
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)


func check_kennel(scene, seed: int) -> void:
	check(scene.kennel != null and scene.kennel_building_index >= 0, "seed %d has no lodge" % seed)
	if scene.kennel == null:
		return
	check(wall_has_approach(scene, scene.kennel_building_index), "seed %d lodge wall inaccessible" % seed)
	scene._clear_alien_occupation(scene.kennel_building_index)
	var center: Vector2 = scene.buildings[scene.kennel_building_index].get("footprint", Rect2()).get_center()
	var original: Vector3 = scene.freya.global_position
	for cage_index in range(6):
		var side = -1.0 if cage_index < 3 else 1.0
		var row = cage_index % 3
		var z = [-2.25, -0.25, 1.75][row]
		var reachable = false
		for x_offset in [2.1, 2.4, 2.7, 3.0]:
			for z_offset in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				var point = center + Vector2(side * x_offset, z + z_offset)
				if not scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS):
					continue
				scene.freya.global_position = Vector3(point.x, 0.0, point.y)
				if int(scene._nearest_caged_kennel_dog().get("index", -1)) == cage_index:
					reachable = true
					break
			if reachable:
				break
		check(reachable, "seed %d cage %d cannot be targeted by R/F from a walkable point" % [seed, cage_index])
	scene.freya.global_position = original


func run() -> void:
	for seed in SEEDS:
		OS.set_environment("FREYA_WORLD_SEED", str(seed))
		check(change_scene_to_file("res://scenes/Main.tscn") == OK, "seed %d Main failed" % seed)
		await scene_changed
		var scene = current_scene
		scene.set_process(false)
		# Chapter staging should not write a player's save from this geometry test.
		scene.game_save_incompatible = true
		scene._seed_chapter_strongholds()
		check_kennel(scene, seed)
		check_sites(scene, seed, 1)
		scene._start_campaign_chapter(2)
		check_sites(scene, seed, 2)
		scene._start_campaign_chapter(3)
		check_sites(scene, seed, 3)
		await process_frame
	if failures.is_empty():
		print("CAMPAIGN_REACHABILITY_OK: five seeds, 8/5/4 sites, entrances, marks, walls, and six lodge cages")
		quit()
	else:
		push_error("CAMPAIGN_REACHABILITY_FAIL: %d findings" % failures.size())
		quit(1)
