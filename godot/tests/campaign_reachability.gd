extends SceneTree

# Generated-layout guard. A conservative four-neighbor grid follows the live
# Freya-radius collision rules from the home entrance. Occupied walls are
# checked before their strongholds are cleared; entrances, marks, and cages are
# checked afterward so a locked wall cannot produce a false route to them.
const SEEDS = [20260831, 1, 42, 20260916, 20261014, 2, 7, 17, 20261015, 314159]
const MAX_RANGE_SEEDS = 100
const MAX_RANGE_SEED = 2147483647
const GRID_STEP = 0.5
const CARDINAL_OFFSETS = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
var failures: Array[String] = []
var probe_counts = {"sites": 0, "marks": 0, "walls": 0, "entrances": 0, "cages": 0}
var test_seeds: Array[int] = []
var range_mode = false
var current_seed = -1
var completed_seeds = 0


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	if not _configure_seeds():
		quit(1)
		return
	var timeout_seconds = 240.0 if not range_mode else maxf(240.0, float(test_seeds.size()) * 30.0)
	create_timer(timeout_seconds).timeout.connect(func():
		push_error("CAMPAIGN_REACHABILITY_FAIL: timed out during seed %d after %d/%d completed seeds" % [current_seed, completed_seeds, test_seeds.size()])
		quit(1)
	)
	call_deferred("run")


func _configure_seeds() -> bool:
	# Set both variables for an extended deterministic sweep. With neither set,
	# predeploy keeps its original ten fixed regression seeds.
	var start_text = OS.get_environment("FREYA_REACHABILITY_SEED_START")
	var count_text = OS.get_environment("FREYA_REACHABILITY_SEED_COUNT")
	if start_text.is_empty() and count_text.is_empty():
		for seed in SEEDS:
			test_seeds.append(seed)
		return true
	if not start_text.is_valid_int() or not count_text.is_valid_int():
		push_error("CAMPAIGN_REACHABILITY_FAIL: set integer FREYA_REACHABILITY_SEED_START and FREYA_REACHABILITY_SEED_COUNT together")
		return false
	var seed_start = int(start_text)
	var seed_count = int(count_text)
	if seed_count < 1 or seed_count > MAX_RANGE_SEEDS or seed_start < 0 or seed_start > MAX_RANGE_SEED - (seed_count - 1):
		push_error("CAMPAIGN_REACHABILITY_FAIL: range requires 1-%d seeds between 0 and %d" % [MAX_RANGE_SEEDS, MAX_RANGE_SEED])
		return false
	range_mode = true
	for offset in range(seed_count):
		test_seeds.append(seed_start + offset)
	print("CAMPAIGN_REACHABILITY_RANGE start=%d end=%d count=%d" % [seed_start, seed_start + seed_count - 1, seed_count])
	return true


func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error("CAMPAIGN_REACHABILITY: " + message)


func _grid_point(x: int, z: int) -> Vector2:
	return Vector2(float(x) * GRID_STEP, float(z) * GRID_STEP)


func _segment_walkable(scene, from: Vector2, to: Vector2) -> bool:
	for step in range(1, 5):
		var point = from.lerp(to, float(step) / 4.0)
		if not scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS):
			return false
	return true


func _home_start(scene) -> Vector2:
	var home: Dictionary = scene.buildings[scene.freya_home_index]
	return home.get("home_layout", {}).get("entry_outside_pos", Vector2.ZERO)


func _connected_grid(scene, start: Vector2, seed: int, phase: String) -> Dictionary:
	var width = int(ceilf(scene.MAP_W / GRID_STEP)) + 1
	var height = int(ceilf(scene.MAP_H / GRID_STEP)) + 1
	var seen = PackedByteArray()
	seen.resize(width * height)
	var walkable = PackedByteArray()
	walkable.resize(width * height)
	var queue = PackedInt32Array()
	check(scene._is_walkable(start.x, start.y, scene.FREYA_COLLISION_RADIUS), "seed %d %s home entrance is blocked at %s" % [seed, phase, start])
	var start_id = Vector2i(roundi(start.x / GRID_STEP), roundi(start.y / GRID_STEP))
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var id = start_id + Vector2i(dx, dz)
			if id.x < 0 or id.y < 0 or id.x >= width or id.y >= height:
				continue
			var point = _grid_point(id.x, id.y)
			if point.distance_to(start) > GRID_STEP * 1.8 or not _segment_walkable(scene, start, point):
				continue
			var key = id.y * width + id.x
			seen[key] = 1
			walkable[key] = 1
			queue.append(key)
	var cursor = 0
	while cursor < queue.size():
		var key = queue[cursor]
		cursor += 1
		var x = key % width
		var z = int(key / width)
		var point = _grid_point(x, z)
		for offset in CARDINAL_OFFSETS:
			var next_x = x + offset.x
			var next_z = z + offset.y
			if next_x < 0 or next_z < 0 or next_x >= width or next_z >= height:
				continue
			var next_key = next_z * width + next_x
			if seen[next_key] == 1 or walkable[next_key] == 2:
				continue
			var next_point = _grid_point(next_x, next_z)
			if walkable[next_key] == 0:
				walkable[next_key] = 1 if scene._is_walkable(next_point.x, next_point.y, scene.FREYA_COLLISION_RADIUS) else 2
			if walkable[next_key] == 1 and scene._is_walkable((point.x + next_point.x) * 0.5, (point.y + next_point.y) * 0.5, scene.FREYA_COLLISION_RADIUS):
				seen[next_key] = 1
				queue.append(next_key)
	check(not queue.is_empty(), "seed %d %s has no connected grid node from home entrance" % [seed, phase])
	return {"seen": seen, "width": width, "height": height, "nodes": queue.size()}


func _connected_point(scene, grid: Dictionary, target: Vector2) -> bool:
	if not scene._is_walkable(target.x, target.y, scene.FREYA_COLLISION_RADIUS):
		return false
	var width: int = grid["width"]
	var height: int = grid["height"]
	var seen: PackedByteArray = grid["seen"]
	var center = Vector2i(roundi(target.x / GRID_STEP), roundi(target.y / GRID_STEP))
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var id = center + Vector2i(dx, dz)
			if id.x < 0 or id.y < 0 or id.x >= width or id.y >= height or seen[id.y * width + id.x] == 0:
				continue
			var point = _grid_point(id.x, id.y)
			if point.distance_to(target) <= GRID_STEP * 1.8 and _segment_walkable(scene, target, point):
				return true
	return false


func mark_has_approach(scene, grid: Dictionary, item: Dictionary) -> bool:
	var target_type = int(item.get("type", -1))
	var target_index = int(item.get("index", -1))
	var world: Vector3 = scene._claim_target_base_world_position(target_type, target_index)
	var mark = Vector2(world.x, world.z)
	for radius in [0.55, 0.85, 1.2, 1.55]:
		for angle_index in range(24):
			var angle = TAU * float(angle_index) / 24.0
			var point = mark + Vector2.RIGHT.rotated(angle) * radius
			if _connected_point(scene, grid, point):
				return true
	return false


func wall_has_approach(scene, grid: Dictionary, index: int) -> bool:
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
				if scene._point_distance_to_rect(point, footprint) < scene.CLAIM_RANGE and _connected_point(scene, grid, point):
					return true
	return false


func _check_occupied_walls(scene, grid: Dictionary, seed: int, chapter: int) -> void:
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			probe_counts["walls"] += 1
			check(wall_has_approach(scene, grid, index), "seed %d chapter %d site %d alien wall has no home-connected Freya approach" % [seed, chapter, index])


func _clear_tested_strongholds(scene) -> void:
	for index in scene.chapter_target_indices:
		if bool(scene.buildings[index].get("alien_occupied", false)):
			scene._clear_alien_occupation(index)


func check_sites(scene, grid: Dictionary, seed: int, chapter: int) -> void:
	var expected = 8 if chapter == 1 else (5 if chapter == 2 else 4)
	check(scene.chapter_target_indices.size() == expected, "seed %d chapter %d has %d/%d sites" % [seed, chapter, scene.chapter_target_indices.size(), expected])
	for index in scene.chapter_target_indices:
		probe_counts["sites"] += 1
		var building: Dictionary = scene.buildings[index]
		var layout: Dictionary = building.get("store_layout", {})
		var inside: Vector2 = layout.get("entry_inside_pos", Vector2.ZERO)
		var outside: Vector2 = layout.get("entry_outside_pos", Vector2.ZERO)
		check(bool(building.get("enterable", false)), "seed %d chapter %d site %d cannot open" % [seed, chapter, index])
		probe_counts["entrances"] += 1
		var outside_connected = _connected_point(scene, grid, outside)
		check(outside_connected, "seed %d chapter %d site %d outside entrance is not home-connected" % [seed, chapter, index])
		check(outside_connected and _segment_walkable(scene, outside, inside), "seed %d chapter %d site %d inside entrance has no connected doorway route" % [seed, chapter, index])
		for step in range(9):
			var point = outside.lerp(inside, float(step) / 8.0)
			check(scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS), "seed %d chapter %d site %d doorway step %d blocked" % [seed, chapter, index, step])
		for item in scene._building_surrounding_claimables(index):
			probe_counts["marks"] += 1
			check(mark_has_approach(scene, grid, item), "seed %d chapter %d site %d mark %d:%d has no home-connected Freya approach" % [seed, chapter, index, int(item.get("type", -1)), int(item.get("index", -1))])
		check(scene._building_has_adjacent_freya_control(index), "seed %d chapter %d site %d claim sequence disconnected" % [seed, chapter, index])
		scene._set_claim_owner(scene.CLAIM_TARGET_BUILDING, index, scene.CLAIM_OWNER_FREYA)


func _needs_cleared_grid(scene, occupied_grid: Dictionary) -> bool:
	# Reuse the occupied-world route when every exterior target was already
	# connected. Only flood again if clearing a stronghold can reveal a route.
	for index in scene.chapter_target_indices:
		var building: Dictionary = scene.buildings[index]
		var outside: Vector2 = building.get("store_layout", {}).get("entry_outside_pos", Vector2.ZERO)
		if not _connected_point(scene, occupied_grid, outside):
			return true
		for item in scene._building_surrounding_claimables(index):
			if not mark_has_approach(scene, occupied_grid, item):
				return true
	return false


func check_kennel(scene, grid: Dictionary, seed: int) -> void:
	check(scene.kennel != null and scene.kennel_building_index >= 0, "seed %d has no lodge" % seed)
	if scene.kennel == null:
		return
	var center: Vector2 = scene.buildings[scene.kennel_building_index].get("footprint", Rect2()).get_center()
	var original: Vector3 = scene.freya.global_position
	for cage_index in range(6):
		probe_counts["cages"] += 1
		var side = -1.0 if cage_index < 3 else 1.0
		var row = cage_index % 3
		var z = [-2.25, -0.25, 1.75][row]
		var reachable = false
		for x_offset in [2.1, 2.4, 2.7, 3.0]:
			for z_offset in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				var point = center + Vector2(side * x_offset, z + z_offset)
				if not _connected_point(scene, grid, point):
					continue
				scene.freya.global_position = Vector3(point.x, 0.0, point.y)
				if int(scene._nearest_caged_kennel_dog().get("index", -1)) == cage_index:
					reachable = true
					break
			if reachable:
				break
		check(reachable, "seed %d cage %d has no home-connected R/F targeting point" % [seed, cage_index])
	scene.freya.global_position = original


func run() -> void:
	for seed in test_seeds:
		current_seed = seed
		if range_mode:
			print("CAMPAIGN_REACHABILITY_BEGIN seed=%d progress=%d/%d" % [seed, completed_seeds, test_seeds.size()])
		OS.set_environment("FREYA_WORLD_SEED", str(seed))
		check(change_scene_to_file("res://scenes/Main.tscn") == OK, "seed %d Main failed" % seed)
		await scene_changed
		var scene = current_scene
		scene.set_process(false)
		# Chapter staging should not write a player's save from this geometry test.
		scene.game_save_incompatible = true
		var start = _home_start(scene)
		var home_layout: Dictionary = scene.buildings[scene.freya_home_index].get("home_layout", {})
		var home_inside: Vector2 = home_layout.get("entry_inside_pos", Vector2.ZERO)
		check(scene._is_walkable(home_inside.x, home_inside.y, scene.FREYA_COLLISION_RADIUS), "seed %d home inside entrance is blocked" % seed)
		check(_segment_walkable(scene, home_inside, start), "seed %d home inside-to-outside doorway has no Freya route" % seed)
		scene._seed_chapter_strongholds()
		var occupied_grid = _connected_grid(scene, start, seed, "chapter 1 occupied")
		check(scene.kennel != null and scene.kennel_building_index >= 0, "seed %d has no lodge" % seed)
		if scene.kennel != null:
			probe_counts["walls"] += 1
			check(wall_has_approach(scene, occupied_grid, scene.kennel_building_index), "seed %d lodge wall has no home-connected Freya approach" % seed)
		_check_occupied_walls(scene, occupied_grid, seed, 1)
		if scene.kennel != null:
			scene._clear_alien_occupation(scene.kennel_building_index)
		_clear_tested_strongholds(scene)
		var cleared_grid = _connected_grid(scene, start, seed, "chapter 1 cleared")
		check_kennel(scene, cleared_grid, seed)
		check_sites(scene, cleared_grid, seed, 1)
		for chapter in [2, 3]:
			scene._start_campaign_chapter(chapter)
			occupied_grid = _connected_grid(scene, start, seed, "chapter %d occupied" % chapter)
			_check_occupied_walls(scene, occupied_grid, seed, chapter)
			_clear_tested_strongholds(scene)
			cleared_grid = _connected_grid(scene, start, seed, "chapter %d cleared" % chapter) if _needs_cleared_grid(scene, occupied_grid) else occupied_grid
			check_sites(scene, cleared_grid, seed, chapter)
		print("CAMPAIGN_REACHABILITY_SEED seed=%d occupied_walls_and_cleared_destinations chapters=3 home_start=%s chapter_sites=8/5/4 chapter_3_connected_nodes=%d" % [seed, start, int(cleared_grid.get("nodes", 0))])
		completed_seeds += 1
		await process_frame
	if failures.is_empty():
		print("CAMPAIGN_REACHABILITY_OK: %d seeds, %d sequential sites, %d surrounding marks, %d occupied walls, %d outside-to-inside entrances, %d lodge cages; all home-connected on 0.5m Freya-radius grid" % [test_seeds.size(), probe_counts["sites"], probe_counts["marks"], probe_counts["walls"], probe_counts["entrances"], probe_counts["cages"]])
		quit()
	else:
		push_error("CAMPAIGN_REACHABILITY_FAIL: %d findings" % failures.size())
		quit(1)
