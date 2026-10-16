extends SceneTree

# Experimental input route. This controller may read live world geometry and
# progress to choose keys, but it must never set gameplay progress, move nodes
# directly, or call the game's action/claim/occupation methods.
# FREYA_NATURAL_DEEP=1 continues through one dog recruit and first claim.
# FREYA_NATURAL_STRONGHOLD=1 adds an occupied chapter hold after that claim.
# FREYA_NATURAL_STRONGHOLD_ONLY=1 skips the first claim for wall diagnostics.
# The stronghold modes log live claim state every five seconds while Space is held.
# FREYA_NATURAL_CAMPAIGN=1 attempts all three chapters using the same input
# controller. FREYA_NATURAL_STOP_AFTER_CHAPTER=1 or 2 ends at a chapter result.
# FREYA_NATURAL_STOP_AFTER_STAGE=lodge stops after all six cage interactions.
# In Resume mode, two_allies_protected stops after chapter 2's medicine check.
# FREYA_NATURAL_KEEP_SAVE=1 preserves only this harness's isolated save.
# FREYA_NATURAL_RESUME=1 selects Startup Resume by input from that save.
const GameSaveScript = preload("res://scripts/game_save.gd")
const TEST_SAVE_PATH = "user://friendly_freya_natural_route_test.json"
const CELL_SIZE = 0.5
const MAX_LEG_SECONDS = 80.0

var game: Node
var nav_grid: AStarGrid2D
var held_keys: Dictionary = {}
var route_started_ms = 0
var failures: Array[String] = []
var steer_x_credit = 0.0
var steer_y_credit = 0.0


func _initialize() -> void:
	if bool(get_meta("freya_natural_route_initialized", false)):
		return
	set_meta("freya_natural_route_initialized", true)
	set_meta("freya_flow_validation", true)
	var extended = OS.get_environment("FREYA_NATURAL_STRONGHOLD") == "1" or OS.get_environment("FREYA_NATURAL_STRONGHOLD_ONLY") == "1"
	var campaign = OS.get_environment("FREYA_NATURAL_CAMPAIGN") == "1"
	create_timer(5400.0 if campaign else (360.0 if extended else 180.0)).timeout.connect(_watchdog_timeout)
	call_deferred("_run")


func _watchdog_timeout() -> void:
	_release_movement()
	_cleanup_save()
	push_error("NATURAL_ROUTE_FAIL: controller timed out")
	quit(1)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("NATURAL_ROUTE: " + message)


func _cleanup_save() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH + suffix))


func _set_key(code: Key, down: bool) -> void:
	if bool(held_keys.get(code, false)) == down:
		return
	held_keys[code] = down
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _release_movement() -> void:
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_R]:
		_set_key(code, false)


func _frames(count: int = 2) -> void:
	for i in range(count):
		await process_frame


func _capture(label: String) -> void:
	var capture_dir = OS.get_environment("FREYA_NATURAL_CAPTURE_DIR")
	if capture_dir.is_empty():
		return
	var error = DirAccess.make_dir_recursive_absolute(capture_dir)
	if error != OK:
		_fail("could not make review capture directory")
		return
	await _frames(4)
	var image = root.get_texture().get_image()
	var path = capture_dir.path_join(label + ".png")
	if image.save_png(path) != OK:
		_fail("could not save review capture " + path)
	else:
		print("NATURAL_ROUTE_CAPTURE %s %s" % [path, image.get_size()])


func _tap(code: Key) -> void:
	_set_key(code, true)
	await _frames(2)
	_set_key(code, false)
	await _frames(2)


func _world_position() -> Vector2:
	var p: Vector3 = game.freya.global_position
	return Vector2(p.x, p.z)


func _grid_id(position: Vector2) -> Vector2i:
	return Vector2i(roundi(position.x / CELL_SIZE), roundi(position.y / CELL_SIZE))


func _grid_position(id: Vector2i) -> Vector2:
	return Vector2(id.x * CELL_SIZE, id.y * CELL_SIZE)


func _closest_open_id(target: Vector2, range: float) -> Vector2i:
	var center = _grid_id(target)
	var best = Vector2i(-1, -1)
	var best_distance = INF
	var cells = ceili(range / CELL_SIZE)
	for dz in range(-cells, cells + 1):
		for dx in range(-cells, cells + 1):
			var id = center + Vector2i(dx, dz)
			if not nav_grid.is_in_boundsv(id) or nav_grid.is_point_solid(id):
				continue
			var distance = _grid_position(id).distance_to(target)
			if distance <= range and distance < best_distance:
				best_distance = distance
				best = id
	return best


func _reachable_open_id(from_id: Vector2i, target: Vector2, range: float) -> Vector2i:
	if from_id.x < 0:
		return Vector2i(-1, -1)
	var closest = _closest_open_id(target, range)
	if closest.x < 0 or not nav_grid.get_id_path(from_id, closest).is_empty():
		return closest
	var center = _grid_id(target)
	var cells = ceili(range / CELL_SIZE)
	var best = Vector2i(-1, -1)
	var best_score = INF
	for dz in range(-cells, cells + 1):
		for dx in range(-cells, cells + 1):
			var id = center + Vector2i(dx, dz)
			if not nav_grid.is_in_boundsv(id) or nav_grid.is_point_solid(id):
				continue
			var distance = _grid_position(id).distance_to(target)
			if distance > range:
				continue
			var path: Array[Vector2i] = nav_grid.get_id_path(from_id, id)
			if path.is_empty():
				continue
			var score = distance * 4.0 + float(path.size()) * CELL_SIZE
			if score < best_score:
				best_score = score
				best = id
	return best


func _build_navigation() -> void:
	nav_grid = AStarGrid2D.new()
	nav_grid.region = Rect2i(0, 0, roundi(float(game.MAP_W) / CELL_SIZE) + 1, roundi(float(game.MAP_H) / CELL_SIZE) + 1)
	nav_grid.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_grid.update()
	for z in range(nav_grid.region.size.y):
		for x in range(nav_grid.region.size.x):
			var id = Vector2i(x, z)
			var point = _grid_position(id)
			if not game._is_walkable(point.x, point.y, game.FREYA_COLLISION_RADIUS):
				nav_grid.set_point_solid(id)


func _drive_toward(world_target: Vector2, run: bool = false, defend: bool = false, spare_clean_dog_index: int = -1) -> void:
	var desired = (world_target - _world_position()).normalized()
	var basis: Basis = game.camera_node.global_basis
	var right = Vector2(basis.x.x, basis.x.z).normalized()
	var forward = Vector2(-basis.z.x, -basis.z.z).normalized()
	var screen_x = desired.dot(right)
	var screen_y = desired.dot(forward)
	# Keyboard input has only eight headings. Pulse the smaller screen component
	# to follow a world-cardinal aisle without drifting into its door frame.
	var scale = maxf(absf(screen_x), absf(screen_y))
	var use_x = false
	var use_y = false
	if scale > 0.0001:
		steer_x_credit += absf(screen_x) / scale
		steer_y_credit += absf(screen_y) / scale
		use_x = steer_x_credit >= 1.0
		use_y = steer_y_credit >= 1.0
		if use_x:
			steer_x_credit -= 1.0
		if use_y:
			steer_y_credit -= 1.0
	_set_key(KEY_A, use_x and screen_x < 0.0)
	_set_key(KEY_D, use_x and screen_x > 0.0)
	_set_key(KEY_W, use_y and screen_y > 0.0)
	_set_key(KEY_S, use_y and screen_y < 0.0)
	_set_key(KEY_SHIFT, run)
	var threat = game._nearest_possessed_dog_threat(4.0) if defend else {"found": false}
	var bark = bool(threat.get("found", false))
	if bark and spare_clean_dog_index >= 0 and spare_clean_dog_index < game.dogs.size():
		var spare_state: Dictionary = game.dogs[spare_clean_dog_index]
		var spare_dog: Node3D = spare_state.get("node", null)
		if not bool(spare_state.get("alien_possessed", false)) and spare_dog != null and is_instance_valid(spare_dog):
			# R also frightens clean dogs. Release it before entering the
			# candidate's social range, even if another dog is possessed.
			bark = spare_dog.global_position.distance_to(game.freya.global_position) > game.SOCIALIZE_RANGE + 0.55
	_set_key(KEY_R, bark)


func _walk_to(goal: Vector2, goal_range: float = 0.55, defend: bool = false, recover_occupied_building_index: int = -1, spare_clean_dog_index: int = -1) -> bool:
	var origin = _world_position()
	var leg_started_ms = Time.get_ticks_msec()
	# The straight-line distance can badly understate a cross-map route around
	# buildings. Allow time for the actual grid path, including each replan;
	# waypoint stall detection below still rejects blocked movement.
	var leg_limit_seconds = MAX_LEG_SECONDS
	for replan in range(20):
		var from_id = _closest_open_id(_world_position(), 1.2)
		if from_id.x < 0:
			_build_navigation()
			from_id = _closest_open_id(_world_position(), 2.0)
		var to_id = _reachable_open_id(from_id, goal, goal_range)
		if from_id.x < 0 or to_id.x < 0:
			if recover_occupied_building_index >= 0 and bool(game.buildings[recover_occupied_building_index].get("alien_occupied", false)):
				_release_movement()
				print("NATURAL_ROUTE_ENTRY_REOCCUPIED index=%d at=%s goal=%s kennel_possessed=%s" % [recover_occupied_building_index, _world_position(), goal, game.kennel.possessed])
				return false
			_fail("no open path endpoint from %s toward %s" % [_world_position(), goal])
			return false
		var path: Array[Vector2i] = nav_grid.get_id_path(from_id, to_id)
		if path.is_empty():
			if recover_occupied_building_index >= 0 and bool(game.buildings[recover_occupied_building_index].get("alien_occupied", false)):
				_release_movement()
				print("NATURAL_ROUTE_ENTRY_REOCCUPIED index=%d at=%s goal=%s kennel_possessed=%s" % [recover_occupied_building_index, _world_position(), goal, game.kennel.possessed])
				return false
			_fail("no path from %s toward %s" % [_world_position(), goal])
			return false
		var path_distance = 0.0
		var cursor: Vector2 = _world_position()
		for id in path:
			var next_point: Vector2 = _grid_position(id)
			path_distance += cursor.distance_to(next_point)
			cursor = next_point
		path_distance += cursor.distance_to(goal)
		var elapsed_seconds = float(Time.get_ticks_msec() - leg_started_ms) / 1000.0
		leg_limit_seconds = maxf(leg_limit_seconds, elapsed_seconds + path_distance * 2.5)
		var stalled = false
		for id in path:
			var waypoint = _grid_position(id)
			var last_distance = INF
			var stuck_frames = 0
			while _world_position().distance_to(waypoint) > 0.34:
				if game.possessed_dog_tutorial_active:
					_release_movement()
					await _tap(KEY_SPACE)
				if game.first_exit_abduction_active:
					_release_movement()
					stuck_frames = 0
					if game.first_exit_continue_button != null and game.first_exit_continue_button.visible:
						await _tap(KEY_SPACE)
					else:
						await process_frame
					continue
				if game.freya_eat_timer > 0.0 or game.freya_vomit_timer > 0.0:
					_release_movement()
					stuck_frames = 0
					await process_frame
					continue
				if float(Time.get_ticks_msec() - leg_started_ms) / 1000.0 > leg_limit_seconds:
					_release_movement()
					_fail("timed out walking from %s toward %s near %s" % [origin, goal, _world_position()])
					return false
				var distance = _world_position().distance_to(waypoint)
				if distance >= last_distance - 0.008:
					stuck_frames += 1
				else:
					stuck_frames = 0
				if stuck_frames > 100:
					_release_movement()
					print("NATURAL_ROUTE_NAV_REPLAN at=%s blocked=%s goal=%s attempt=%d walkable=%s waypoint_walkable=%s occupied_block=%s building_block=%s lodge_occupied=%s kennel_possessed=%s threat=%s inside=%d world_time=%.2f tree_paused=%s tutorial=%s first_exit=%s result=%s victory=%s pause=%s eat=%.2f vomit=%.2f move_dir=%s action_axes=%.1f,%.1f,%.1f,%.1f" % [_world_position(), waypoint, goal, replan + 1, game._is_walkable(_world_position().x, _world_position().y, game.FREYA_COLLISION_RADIUS), game._is_walkable(waypoint.x, waypoint.y, game.FREYA_COLLISION_RADIUS), game._point_in_occupied_store(waypoint, game.FREYA_COLLISION_RADIUS), game._point_in_blocking_building(waypoint, game.FREYA_COLLISION_RADIUS + game.BUILDING_COLLISION_PAD), bool(game.buildings[game.kennel_building_index].get("alien_occupied", false)), game.kennel.possessed, game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS), game._store_index_for_interior_point(_world_position()), game.world_time, paused, game.possessed_dog_tutorial_active, game.first_exit_abduction_active, game.chapter_complete_panel != null and game.chapter_complete_panel.visible, game.victory_panel != null and game.victory_panel.visible, game.pause_menu_open, game.freya_eat_timer, game.freya_vomit_timer, game.freya_move_dir, Input.get_action_strength("move_up"), Input.get_action_strength("move_left"), Input.get_action_strength("move_down"), Input.get_action_strength("move_right")])
					if recover_occupied_building_index >= 0 and bool(game.buildings[recover_occupied_building_index].get("alien_occupied", false)):
						print("NATURAL_ROUTE_ENTRY_REOCCUPIED index=%d at=%s goal=%s" % [recover_occupied_building_index, _world_position(), goal])
						return false
					if game._is_walkable(waypoint.x, waypoint.y, game.FREYA_COLLISION_RADIUS):
						# A walkable grid center can still be unreachable around a
						# narrow corner with keyboard steering. Avoid that cell.
						nav_grid.set_point_solid(id)
					else:
						# An imp can occupy a building after this leg's grid was
						# built. Refresh every changed collision cell at once.
						_build_navigation()
					stalled = true
					break
				last_distance = distance
				_drive_toward(waypoint, false, defend, spare_clean_dog_index)
				await process_frame
			if stalled:
				break
		_release_movement()
		await _frames(2)
		if _world_position().distance_to(goal) <= goal_range + 0.35:
			return true
		if not stalled:
			_fail("path finished short of %s near %s" % [goal, _world_position()])
			return false
	_fail("navigation exhausted replans from %s toward %s near %s" % [origin, goal, _world_position()])
	return false


func _first_dog_candidate() -> int:
	var best = -1
	var best_score = INF
	for index in range(game.dogs.size()):
		var state: Dictionary = game.dogs[index]
		if not bool(state.get("alien_possessed", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		var score = _world_position().distance_to(Vector2(dog.global_position.x, dog.global_position.z)) + (20.0 if bool(state.get("park", false)) else 0.0)
		if score < best_score:
			best_score = score
			best = index
	return best


func _recruit_first_ally(preferred_index: int = -1) -> bool:
	var dog_index = preferred_index if preferred_index >= 0 else _first_dog_candidate()
	if dog_index < 0:
		_fail("no possessed dog candidate")
		return false
	var dog: Node3D = game.dogs[dog_index].get("node", null)
	for approach in range(8):
		if dog == null or not is_instance_valid(dog):
			_fail("dog candidate disappeared")
			return false
		if _world_position().distance_to(Vector2(dog.global_position.x, dog.global_position.z)) < 3.5:
			break
		var destination = Vector2(dog.global_position.x, dog.global_position.z)
		if not await _walk_to(destination, 2.8, true):
			print("NATURAL_ROUTE_DOG_REPATH near=%s dog=%s" % [_world_position(), destination])
	if game.possessed_dog_tutorial_active:
		await _tap(KEY_SPACE)
	var started_ms = Time.get_ticks_msec()
	while bool(game.dogs[dog_index].get("alien_possessed", false)) and Time.get_ticks_msec() - started_ms < 15000:
		if game.possessed_dog_tutorial_active:
			_release_movement()
			await _tap(KEY_SPACE)
		var dog_pos = Vector2(dog.global_position.x, dog.global_position.z)
		if _world_position().distance_to(dog_pos) > 3.4:
			_drive_toward(dog_pos, false, true)
		else:
			for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT]:
				_set_key(code, false)
			_set_key(KEY_R, true)
		await process_frame
	_release_movement()
	if bool(game.dogs[dog_index].get("alien_possessed", false)):
		_fail("R did not cleanse the dog near %s" % _world_position())
		return false
	print("NATURAL_ROUTE_DOG_CLEANSED index=%d pos=%s elapsed=%.1f" % [dog_index, _world_position(), float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	if bool(game.dogs[dog_index].get("army_aligned", false)):
		print("NATURAL_ROUTE_ALLY_RECOVERED index=%d allies=%d" % [dog_index, game._chapter_real_ally_count()])
		return true
	started_ms = Time.get_ticks_msec()
	_set_key(KEY_C, true)
	while not bool(game.dogs[dog_index].get("army_aligned", false)) and Time.get_ticks_msec() - started_ms < 18000:
		var dog_pos = Vector2(dog.global_position.x, dog.global_position.z)
		if _world_position().distance_to(dog_pos) > 3.5:
			_drive_toward(dog_pos)
		else:
			_release_movement()
		await process_frame
	_set_key(KEY_C, false)
	_release_movement()
	if not bool(game.dogs[dog_index].get("army_aligned", false)):
		_fail("C did not recruit the cleansed dog")
		return false
	print("NATURAL_ROUTE_DOG_RECRUITED index=%d allies=%d elapsed=%.1f" % [dog_index, game._chapter_real_ally_count(), float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	return true


func _claim_mark(target_type: int, target_index: int) -> bool:
	if game._entry_is_claimed_by(game._claim_entry_for_target(target_type, target_index), game.CLAIM_OWNER_FREYA):
		return true
	var world: Vector3 = game._claim_target_base_world_position(target_type, target_index)
	var position = Vector2(world.x, world.z)
	for attempt in range(3):
		if not await _walk_to(position, 1.2, true):
			return false
		var started_ms = Time.get_ticks_msec()
		_set_key(KEY_SPACE, true)
		while Time.get_ticks_msec() - started_ms < 12000:
			if game._entry_is_claimed_by(game._claim_entry_for_target(target_type, target_index), game.CLAIM_OWNER_FREYA):
				break
			await process_frame
		_set_key(KEY_SPACE, false)
		await _frames(2)
		if game._entry_is_claimed_by(game._claim_entry_for_target(target_type, target_index), game.CLAIM_OWNER_FREYA):
			return true
		print("NATURAL_ROUTE_MARK_RETRY type=%d index=%d pos=%s selected=%s" % [target_type, target_index, _world_position(), game._find_nearest_claim_target()])
	_fail("could not mark nearby target %d/%d" % [target_type, target_index])
	return false


func _claim_first_site() -> bool:
	var first = -1
	var best_distance = INF
	for index in game.chapter_target_indices:
		if bool(game.buildings[index].get("alien_occupied", false)) or not game._building_has_adjacent_freya_control(index):
			continue
		var center: Vector2 = game.buildings[index].get("footprint", Rect2()).get_center()
		var distance = center.distance_to(_world_position())
		if distance < best_distance:
			best_distance = distance
			first = index
	if first < 0:
		_fail("no clean connected first chapter site")
		return false
	var marks = game._building_surrounding_claimables(first)
	print("NATURAL_ROUTE_FIRST_SITE index=%d name=%s marks=%d distance=%.1f" % [first, game.buildings[first].get("building_display_name", "Residence"), marks.size(), best_distance])
	for item in marks:
		if not await _claim_mark(int(item.get("type", -1)), int(item.get("index", -1))):
			return false
	if bool(game.buildings[first].get("alien_occupied", false)):
		if not await _clear_occupied_wall(first):
			return false
	var status: Dictionary = game._building_claim_status(first)
	if not bool(status.get("eligible", false)):
		_fail("marked first site is still ineligible: " + str(status))
		return false
	var layout: Dictionary = game.buildings[first].get("store_layout", {})
	var entry: Vector2 = layout.get("entry_inside_pos", game.buildings[first].get("store_interior_rect", Rect2()).get_center())
	var inward = Vector2(0.0, -float(layout.get("front_sign", 1.0)))
	var claim_position = entry + inward * 0.8
	if not await _enter_site_for_claim(first, claim_position):
		_fail("could not enter first site")
		return false
	var inside_index = game._store_index_for_interior_point(_world_position())
	var selected_target: Dictionary = game._find_nearest_claim_target()
	print("NATURAL_ROUTE_INTERIOR pos=%s entry=%s claim_point=%s inside=%d target=%s" % [_world_position(), entry, claim_position, inside_index, selected_target])
	if inside_index != first or not bool(selected_target.get("found", false)) or int(selected_target.get("type", -1)) != game.CLAIM_TARGET_BUILDING or int(selected_target.get("index", -1)) != first:
		_fail("first site input approach did not reach its claimable interior")
		return false
	var started_ms = Time.get_ticks_msec()
	_set_key(KEY_SPACE, true)
	while not game._building_is_controlled_by_freya(first) and Time.get_ticks_msec() - started_ms < 17000:
		await process_frame
	_set_key(KEY_SPACE, false)
	if not game._building_is_controlled_by_freya(first):
		_fail("10-second interior claim did not secure first site: " + str(game._building_claim_status(first)))
		return false
	print("NATURAL_ROUTE_FIRST_CLAIM index=%d chapter_claimed=%d elapsed=%.1f" % [first, game._chapter_claimed_target_count(), float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	return true


func _alien_wall_approach(building_index: int) -> Vector2:
	var footprint: Rect2 = game.buildings[building_index].get("footprint", Rect2())
	var origin_id = _closest_open_id(_world_position(), 1.2)
	var best = Vector2(-1.0, -1.0)
	var best_score = INF
	if origin_id.x < 0:
		return best
	var start = _grid_id(footprint.position - Vector2.ONE * 2.0)
	var finish = _grid_id(footprint.end + Vector2.ONE * 2.0)
	for z in range(maxi(0, start.y), mini(nav_grid.region.size.y - 1, finish.y) + 1):
		for x in range(maxi(0, start.x), mini(nav_grid.region.size.x - 1, finish.x) + 1):
			var id = Vector2i(x, z)
			if nav_grid.is_point_solid(id):
				continue
			var position = _grid_position(id)
			var wall_distance = game._point_distance_to_rect(position, footprint)
			if wall_distance > 1.4 or wall_distance < 0.3:
				continue
			var path: Array[Vector2i] = nav_grid.get_id_path(origin_id, id)
			if path.is_empty():
				continue
			var nearby_marks = 0
			for item in game._building_surrounding_claimables(building_index):
				var item_type = int(item.get("type", -1))
				var item_index = int(item.get("index", -1))
				if game._entry_is_claimed_by(game._claim_entry_for_target(item_type, item_index), game.CLAIM_OWNER_FREYA):
					continue
				var item_world: Vector3 = game._claim_target_base_world_position(item_type, item_index)
				if position.distance_to(Vector2(item_world.x, item_world.z)) < game.CLAIM_RANGE:
					nearby_marks += 1
			var score = float(path.size()) + float(nearby_marks) * 24.0 + wall_distance * 3.0
			if score < best_score:
				best_score = score
				best = position
	return best


func _break_first_stronghold() -> bool:
	var stronghold_index = -1
	for index in game.chapter_target_indices:
		if bool(game.buildings[index].get("alien_occupied", false)):
			stronghold_index = index
			break
	if stronghold_index < 0:
		_fail("no occupied first-chapter strategic property")
		return false
	var approach = _alien_wall_approach(stronghold_index)
	if approach.x < 0.0:
		_fail("no reachable approach to occupied strategic property %d" % stronghold_index)
		return false
	print("NATURAL_ROUTE_STRONGHOLD index=%d name=%s approach=%s distance=%.1f" % [stronghold_index, game.buildings[stronghold_index].get("building_display_name", "Residence"), approach, _world_position().distance_to(approach)])
	if not await _walk_to(approach, 0.2, true):
		_fail("could not walk to occupied strategic property %d" % stronghold_index)
		return false
	var initial_target: Dictionary = game._find_nearest_claim_target()
	print("NATURAL_ROUTE_STRONGHOLD_WALL pos=%s target=%s" % [_world_position(), initial_target])
	var started_ms = Time.get_ticks_msec()
	var next_report_ms = started_ms + 5000
	_set_key(KEY_R, true)
	_set_key(KEY_SPACE, true)
	while bool(game.buildings[stronghold_index].get("alien_occupied", false)) and Time.get_ticks_msec() - started_ms < 45000:
		if game.possessed_dog_tutorial_active:
			_set_key(KEY_SPACE, false)
			await _frames(2)
			await _tap(KEY_SPACE)
			_set_key(KEY_SPACE, true)
		if Time.get_ticks_msec() >= next_report_ms:
			var building: Dictionary = game.buildings[stronghold_index]
			var selected: Dictionary = game._find_nearest_claim_target()
			print("NATURAL_ROUTE_STRONGHOLD_PROGRESS sec=%.1f pos=%s integrity=%.4f reinforcement=%.2f hunger=%.1f cleared=%d complete=%s selected=%s active=%d/%d space=%s bark=%s tutorial=%s first_exit=%s result=%s victory=%s paused=%s flee=%s" % [float(Time.get_ticks_msec() - started_ms) / 1000.0, _world_position(), float(building.get("alien_integrity", 1.0)), float(building.get("alien_reinforcement_strength", 0.0)), game.freya_hunger, game.chapter_occupations_cleared, game.chapter_complete, selected, game.active_claim_target_type, game.active_claim_target_index, Input.is_action_pressed("claim"), Input.is_action_pressed("aggressive_social"), game.possessed_dog_tutorial_active, game.first_exit_abduction_active, game.chapter_complete_panel != null and game.chapter_complete_panel.visible, game.victory_panel != null and game.victory_panel.visible, game.pause_menu_open, game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS)])
			next_report_ms += 5000
		await process_frame
	_set_key(KEY_SPACE, false)
	_set_key(KEY_R, false)
	if bool(game.buildings[stronghold_index].get("alien_occupied", false)):
		_fail("Space at reachable wall did not break alien hold %d; selected=%s" % [stronghold_index, game._find_nearest_claim_target()])
		return false
	if game.chapter_occupations_cleared < 1:
		_fail("cleared stronghold did not count toward chapter")
		return false
	print("NATURAL_ROUTE_STRONGHOLD_CLEARED index=%d chapter_cleared=%d elapsed=%.1f" % [stronghold_index, game.chapter_occupations_cleared, float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	return true


func _stage(label: String) -> void:
	print("NATURAL_ROUTE_STAGE %s chapter=%d claims=%d/%d holds=%d/%d generators=%d allies=%d rescued=%d protected=%d assisted=%s hunger=%.1f elapsed=%.1f" % [
		label, game.campaign_chapter, game._chapter_claimed_target_count(), game.chapter_target_indices.size(),
		game.chapter_occupations_cleared, game.chapter_required_occupation_clears,
		game._chapter_active_generator_count(), game._chapter_real_ally_count(),
		game.kennel_released_count(), game._chapter_protected_ally_count(), game.chapter_assisted_stronghold,
		game.freya_hunger, float(Time.get_ticks_msec() - route_started_ms) / 1000.0
	])


func _clear_occupied_wall(building_index: int, assist: bool = false) -> bool:
	if not bool(game.buildings[building_index].get("alien_occupied", false)):
		return true
	for attempt in range(3):
		var approach = _alien_wall_approach(building_index)
		if approach.x < 0.0:
			_fail("no reachable wall approach for occupied building %d" % building_index)
			return false
		if not await _walk_to(approach, 0.2, true):
			return false
		var target: Dictionary = game._find_nearest_claim_target()
		if bool(target.get("found", false)) and int(target.get("type", -1)) == game.CLAIM_TARGET_ALIEN_BUILDING and int(target.get("index", -1)) == building_index:
			break
		print("NATURAL_ROUTE_WALL_RETRY index=%d pos=%s selected=%s" % [building_index, _world_position(), target])
		var mark_type = int(target.get("type", -1))
		var mark_index = int(target.get("index", -1))
		if mark_type in [game.CLAIM_TARGET_TREE, game.CLAIM_TARGET_LIGHT_POLE, game.CLAIM_TARGET_FIRE_HYDRANT, game.CLAIM_TARGET_MAILBOX] and mark_index >= 0:
			if not await _claim_mark(mark_type, mark_index):
				return false
		else:
			_fail("wall approach selects a different target at building %d: %s" % [building_index, target])
			return false
	var chosen: Dictionary = game._find_nearest_claim_target()
	if not bool(chosen.get("found", false)) or int(chosen.get("type", -1)) != game.CLAIM_TARGET_ALIEN_BUILDING or int(chosen.get("index", -1)) != building_index:
		_fail("could not select alien wall %d after input approach: %s" % [building_index, chosen])
		return false
	if assist:
		await _tap(KEY_3)
		var assist_start = Time.get_ticks_msec()
		while game._pack_assist_count(building_index) < 1 and Time.get_ticks_msec() - assist_start < 30000:
			await process_frame
		print("NATURAL_ROUTE_ASSIST index=%d count=%d order=%s" % [building_index, game._pack_assist_count(building_index), game.pack_order])
	var started_ms = Time.get_ticks_msec()
	var next_report_ms = started_ms + 5000
	_set_key(KEY_R, true)
	_set_key(KEY_SPACE, true)
	while bool(game.buildings[building_index].get("alien_occupied", false)) and Time.get_ticks_msec() - started_ms < 45000:
		if game.possessed_dog_tutorial_active:
			_set_key(KEY_SPACE, false)
			await _frames(2)
			await _tap(KEY_SPACE)
			_set_key(KEY_SPACE, true)
		if Time.get_ticks_msec() >= next_report_ms:
			print("NATURAL_ROUTE_WALL_PROGRESS index=%d pos=%s integrity=%.4f selected=%s threat=%s bark=%s" % [building_index, _world_position(), float(game.buildings[building_index].get("alien_integrity", 1.0)), game._find_nearest_claim_target(), game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS), Input.is_action_pressed("aggressive_social")])
			next_report_ms += 5000
		await process_frame
	_set_key(KEY_SPACE, false)
	_set_key(KEY_R, false)
	if bool(game.buildings[building_index].get("alien_occupied", false)):
		_fail("Space did not clear occupied wall %d; target=%s integrity=%.4f" % [building_index, game._find_nearest_claim_target(), float(game.buildings[building_index].get("alien_integrity", 1.0))])
		return false
	_build_navigation()
	print("NATURAL_ROUTE_WALL_CLEARED index=%d assist=%s seconds=%.1f pos=%s world_time=%.2f paused=%s tutorial=%s eat=%.2f vomit=%.2f" % [building_index, game.chapter_assisted_stronghold, float(Time.get_ticks_msec() - started_ms) / 1000.0, _world_position(), game.world_time, paused, game.possessed_dog_tutorial_active, game.freya_eat_timer, game.freya_vomit_timer])
	return true


func _enter_site_for_claim(building_index: int, claim_position: Vector2) -> bool:
	for attempt in range(5):
		if bool(game.buildings[building_index].get("alien_occupied", false)):
			if not await _clear_occupied_wall(building_index, game.campaign_chapter == 3 and building_index == game.chapter_final_stronghold_index):
				return false
		_build_navigation()
		# The walk grid is 0.5 m, so an arbitrary interior point can be up to
		# 0.354 m from its closest cell. Keep the endpoint tolerance below the
		# game's 1.8 m claim range; the caller verifies interior target selection.
		if await _walk_to(claim_position, 0.4, true, building_index):
			return true
		if not bool(game.buildings[building_index].get("alien_occupied", false)):
			return false
		print("NATURAL_ROUTE_SITE_REOCCUPIED index=%d entry_attempt=%d pos=%s" % [building_index, attempt + 1, _world_position()])
	_fail("site %d reoccupied through five input-clearing attempts" % building_index)
	return false


func _claim_site(building_index: int) -> bool:
	if game._building_is_controlled_by_freya(building_index):
		return true
	if bool(game.buildings[building_index].get("alien_occupied", false)):
		var final_assist = game.campaign_chapter == 3 and building_index == game.chapter_final_stronghold_index
		if not await _clear_occupied_wall(building_index, final_assist):
			return false
	for item in game._building_surrounding_claimables(building_index):
		if not await _claim_mark(int(item.get("type", -1)), int(item.get("index", -1))):
			return false
	if bool(game.buildings[building_index].get("alien_occupied", false)):
		if not await _clear_occupied_wall(building_index, game.campaign_chapter == 3 and building_index == game.chapter_final_stronghold_index):
			return false
	var status: Dictionary = game._building_claim_status(building_index)
	if not bool(status.get("eligible", false)):
		_fail("site %d remains ineligible after marks: %s" % [building_index, status])
		return false
	var building: Dictionary = game.buildings[building_index]
	var layout: Dictionary = building.get("store_layout", {})
	var entry: Vector2 = layout.get("entry_inside_pos", building.get("store_interior_rect", Rect2()).get_center())
	var inward = Vector2(0.0, -float(layout.get("front_sign", 1.0)))
	var claim_position = entry + inward * 0.8
	for claim_attempt in range(3):
		if not await _enter_site_for_claim(building_index, claim_position):
			return false
		var selected: Dictionary = game._find_nearest_claim_target()
		if game._store_index_for_interior_point(_world_position()) != building_index or not bool(selected.get("found", false)) or int(selected.get("type", -1)) != game.CLAIM_TARGET_BUILDING or int(selected.get("index", -1)) != building_index:
			_fail("site %d interior approach did not select its claim: pos=%s target=%s" % [building_index, _world_position(), selected])
			return false
		var started_ms = Time.get_ticks_msec()
		var next_report_ms = started_ms + 5000
		_set_key(KEY_SPACE, true)
		while not game._building_is_controlled_by_freya(building_index) and Time.get_ticks_msec() - started_ms < 20000:
			if game.possessed_dog_tutorial_active:
				_set_key(KEY_SPACE, false)
				await _frames(2)
				await _tap(KEY_SPACE)
				_set_key(KEY_SPACE, true)
			if bool(game.buildings[building_index].get("alien_occupied", false)):
				break
			if Time.get_ticks_msec() >= next_report_ms:
				print("NATURAL_ROUTE_INTERIOR_PROGRESS index=%d attempt=%d progress=%.3f selected=%s active=%d:%d input_space=%s world_time=%.2f tutorial=%s paused=%s occupied=%s pos=%s" % [building_index, claim_attempt + 1, float(game.buildings[building_index].get("claim_progress", 0.0)), game._find_nearest_claim_target(), game.active_claim_target_type, game.active_claim_target_index, Input.is_action_pressed("claim"), game.world_time, game.possessed_dog_tutorial_active, paused, bool(game.buildings[building_index].get("alien_occupied", false)), _world_position()])
				next_report_ms += 5000
			await process_frame
		_set_key(KEY_SPACE, false)
		if game._building_is_controlled_by_freya(building_index):
			break
		if bool(game.buildings[building_index].get("alien_occupied", false)):
			print("NATURAL_ROUTE_INTERIOR_REOCCUPIED index=%d attempt=%d world_time=%.2f" % [building_index, claim_attempt + 1, game.world_time])
			continue
		print("NATURAL_ROUTE_INTERIOR_RETRY index=%d attempt=%d progress=%.3f selected=%s active=%d:%d world_time=%.2f tutorial=%s paused=%s" % [building_index, claim_attempt + 1, float(game.buildings[building_index].get("claim_progress", 0.0)), game._find_nearest_claim_target(), game.active_claim_target_type, game.active_claim_target_index, game.world_time, game.possessed_dog_tutorial_active, paused])
	if not game._building_is_controlled_by_freya(building_index):
		_fail("Space did not claim interior %d: status=%s progress=%.3f selected=%s active=%d:%d world_time=%.2f tutorial=%s paused=%s occupied=%s" % [building_index, game._building_claim_status(building_index), float(game.buildings[building_index].get("claim_progress", 0.0)), game._find_nearest_claim_target(), game.active_claim_target_type, game.active_claim_target_index, game.world_time, game.possessed_dog_tutorial_active, paused, bool(game.buildings[building_index].get("alien_occupied", false))])
		return false
	print("NATURAL_ROUTE_SITE_CLAIMED chapter=%d index=%d count=%d/%d" % [game.campaign_chapter, building_index, game._chapter_claimed_target_count(), game.chapter_target_indices.size()])
	return true


func _claim_connected_chapter_sites() -> bool:
	var planned = 0
	while game._chapter_claimed_target_count() < game.chapter_target_indices.size() and planned < 30:
		var best = -1
		var best_score = INF
		for index in game.chapter_target_indices:
			if game._building_is_controlled_by_freya(index) or not game._building_has_adjacent_freya_control(index):
				continue
			var footprint: Rect2 = game.buildings[index].get("footprint", Rect2())
			var score = _world_position().distance_to(footprint.get_center()) + (8.0 if bool(game.buildings[index].get("alien_occupied", false)) else 0.0)
			if score < best_score:
				best = index
				best_score = score
		if best < 0:
			_fail("no connected unclaimed chapter target; claimed=%d/%d" % [game._chapter_claimed_target_count(), game.chapter_target_indices.size()])
			return false
		_stage("site_%d_start" % best)
		if not await _claim_site(best):
			return false
		planned += 1
	if game._chapter_claimed_target_count() < game.chapter_target_indices.size():
		_fail("connected-site planner exhausted %d visits at %d/%d" % [planned, game._chapter_claimed_target_count(), game.chapter_target_indices.size()])
		return false
	return true


func _kennel_cage_approach(cage_index: int) -> Vector2:
	var captives: Array = game.kennel.visual_data.get("caged_dogs", [])
	if cage_index < 0 or cage_index >= captives.size():
		return Vector2(-1.0, -1.0)
	var dog: Node3D = captives[cage_index]
	var dog_pos = Vector2(dog.global_position.x, dog.global_position.z)
	var start_id = _closest_open_id(_world_position(), 1.2)
	var center = _grid_id(dog_pos)
	var best = Vector2(-1.0, -1.0)
	var best_score = INF
	if start_id.x < 0:
		return best
	for dz in range(-5, 6):
		for dx in range(-5, 6):
			var id = center + Vector2i(dx, dz)
			if not nav_grid.is_in_boundsv(id) or nav_grid.is_point_solid(id):
				continue
			var pos = _grid_position(id)
			var dog_distance = pos.distance_to(dog_pos)
			if dog_distance > 2.1 or not game._is_inside_store_interior(game.kennel_building_index, pos):
				continue
			var path: Array[Vector2i] = nav_grid.get_id_path(start_id, id)
			if path.is_empty():
				continue
			var score = float(path.size()) * CELL_SIZE + dog_distance * 3.0
			if score < best_score:
				best_score = score
				best = pos
	return best


func _enter_clean_lodge() -> bool:
	var index: int = game.kennel_building_index
	if index < 0 or game.kennel == null:
		_fail("lodge is missing from the live neighborhood")
		return false
	var entry: Vector2 = game.buildings[index].get("store_layout", {}).get("entry_inside_pos", Vector2.ZERO)
	for attempt in range(5):
		if bool(game.buildings[index].get("alien_occupied", false)):
			if not await _clear_occupied_wall(index):
				return false
		_build_navigation()
		if await _walk_to(entry + Vector2(0.0, -0.8), 0.5, true, index):
			return true
		if not bool(game.buildings[index].get("alien_occupied", false)):
			return false
		print("NATURAL_ROUTE_LODGE_RETRY entry_attempt=%d world_time=%.2f" % [attempt + 1, game.world_time])
	_fail("lodge reoccupied through five input-clearing attempts")
	return false


func _rescue_lodge() -> bool:
	var index: int = game.kennel_building_index
	if not await _enter_clean_lodge():
		return false
	var entry: Vector2 = game.buildings[index].get("store_layout", {}).get("entry_inside_pos", Vector2.ZERO)
	var captives: Array = game.kennel.visual_data.get("caged_dogs", [])
	for cage_index in range(captives.size()):
		var captive: Node3D = captives[cage_index]
		if bool(captive.get_meta("kennel_released", false)):
			continue
		for cage_attempt in range(5):
			if bool(game.buildings[index].get("alien_occupied", false)) and not await _enter_clean_lodge():
				return false
			var approach = _kennel_cage_approach(cage_index)
			if approach.x < 0.0:
				_fail("no walkable interior approach to lodge cage %d" % cage_index)
				return false
			print("NATURAL_ROUTE_CAGE_APPROACH index=%d from=%s goal=%s dog=%s entry=%s" % [cage_index, _world_position(), approach, captive.global_position, entry])
			if not await _walk_to(approach, 0.35, true, index):
				if bool(game.buildings[index].get("alien_occupied", false)):
					continue
				return false
			if bool(captive.get_meta("alien_possessed", false)):
				var started_ms = Time.get_ticks_msec()
				var started_world_time = game.world_time
				var next_report_ms = started_ms + 1000
				_set_key(KEY_R, false)
				await _frames(2)
				_set_key(KEY_R, true)
				while bool(captive.get_meta("alien_possessed", false)) and Time.get_ticks_msec() - started_ms < 15000 and game.world_time - started_world_time < 7.0:
					if game.possessed_dog_tutorial_active:
						_set_key(KEY_R, false)
						await _tap(KEY_SPACE)
						_set_key(KEY_R, true)
					if bool(game.buildings[index].get("alien_occupied", false)):
						break
					if Time.get_ticks_msec() >= next_report_ms:
						print("NATURAL_ROUTE_CAGE_BARK index=%d pos=%s nearest=%s bark_index=%d bark_progress=%.3f input_r=%s kennel_possessed=%s captive_possessed=%s released=%s world_time=%.2f threat=%s tutorial=%s paused=%s" % [cage_index, _world_position(), game._nearest_caged_kennel_dog(), game.kennel_caged_bark_index, game.kennel_caged_bark_progress, Input.is_action_pressed("aggressive_social"), game.kennel.possessed, bool(captive.get_meta("alien_possessed", false)), bool(captive.get_meta("kennel_released", false)), game.world_time, game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS), game.possessed_dog_tutorial_active, paused])
						next_report_ms += 1000
					await process_frame
				_set_key(KEY_R, false)
				if bool(game.buildings[index].get("alien_occupied", false)):
					continue
				if bool(captive.get_meta("alien_possessed", false)):
					_fail("R did not cleanse lodge cage %d from %s; selected=%s bark_index=%d bark_progress=%.3f input_r=%s kennel_possessed=%s world_time=%.2f tutorial=%s paused=%s" % [cage_index, _world_position(), game._nearest_caged_kennel_dog(), game.kennel_caged_bark_index, game.kennel_caged_bark_progress, Input.is_action_pressed("aggressive_social"), game.kennel.possessed, game.world_time, game.possessed_dog_tutorial_active, paused])
					return false
			for release_attempt in range(3):
				if game.possessed_dog_tutorial_active:
					await _tap(KEY_SPACE)
				var nearest_before: Dictionary = game._nearest_caged_kennel_dog()
				await _tap(KEY_F)
				if not bool(captive.get_meta("kennel_released", false)):
					print("NATURAL_ROUTE_CAGE_RELEASE_RETRY index=%d attempt=%d pos=%s inside=%s nearest_before=%d nearest_after=%d distance_before=%.3f captive_possessed=%s kennel_possessed=%s occupied=%s tutorial=%s paused=%s eat=%.2f vomit=%.2f world_time=%.2f" % [cage_index, release_attempt + 1, _world_position(), game._is_inside_store_interior(index, _world_position()), int(nearest_before.get("index", -1)), int(game._nearest_caged_kennel_dog().get("index", -1)), sqrt(float(nearest_before.get("distance_sq", INF))), bool(captive.get_meta("alien_possessed", false)), game.kennel.possessed, bool(game.buildings[index].get("alien_occupied", false)), game.possessed_dog_tutorial_active, paused, game.freya_eat_timer, game.freya_vomit_timer, game.world_time])
					if game.possessed_dog_tutorial_active:
						await _tap(KEY_SPACE)
				if bool(captive.get_meta("kennel_released", false)) or bool(game.buildings[index].get("alien_occupied", false)):
					break
			if bool(captive.get_meta("kennel_released", false)):
				break
			if not bool(game.buildings[index].get("alien_occupied", false)):
				print("NATURAL_ROUTE_CAGE_REAPPROACH index=%d attempt=%d pos=%s nearest=%s" % [cage_index, cage_attempt + 1, _world_position(), game._nearest_caged_kennel_dog()])
		if not bool(captive.get_meta("kennel_released", false)):
			_fail("lodge cage %d was still closed after five input retries" % cage_index)
			return false
		print("NATURAL_ROUTE_CAGE_RELEASED index=%d rescued=%d/6" % [cage_index, game.kennel_released_count()])
	if not game.kennel_rescue_complete():
		_fail("six lodge cages were visited but rescue is incomplete")
		return false
	_stage("lodge_rescued")
	return true


func _service_of_type(service_type: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score = INF
	for service in game.building_services:
		if str(service.get("service_type", "")) != service_type:
			continue
		var position: Vector2 = service.get("pos", Vector2.ZERO)
		var score = position.distance_to(_world_position())
		if bool(game.buildings[int(service.get("building_index", -1))].get("alien_occupied", false)):
			score += 12.0
		if score < best_score:
			best = service
			best_score = score
	return best


func _service_approach(building_index: int, service_position: Vector2) -> Vector2:
	var from_id = _closest_open_id(_world_position(), 1.2)
	if from_id.x < 0:
		return Vector2(-1.0, -1.0)
	var center = _grid_id(service_position)
	var best = Vector2(-1.0, -1.0)
	var best_score = INF
	for dz in range(-4, 5):
		for dx in range(-4, 5):
			var id = center + Vector2i(dx, dz)
			if not nav_grid.is_in_boundsv(id) or nav_grid.is_point_solid(id):
				continue
			var point = _grid_position(id)
			var service_distance = point.distance_to(service_position)
			# Stop well inside the 1.55 m F range, allowing for the controller's
			# movement tolerance. The service prop itself may block movement.
			if service_distance > 1.0 or not game._is_inside_store_index(building_index, point):
				continue
			var path: Array[Vector2i] = nav_grid.get_id_path(from_id, id)
			if path.is_empty():
				continue
			var score = float(path.size()) * CELL_SIZE + service_distance * 2.0
			if score < best_score:
				best_score = score
				best = point
	return best


func _use_service(service_type: String) -> bool:
	var service = _service_of_type(service_type)
	if service.is_empty():
		_fail("no %s service exists in this layout" % service_type)
		return false
	var building_index = int(service.get("building_index", -1))
	var point: Vector2 = service.get("pos", Vector2.ZERO)
	for attempt in range(4):
		if bool(game.buildings[building_index].get("alien_occupied", false)):
			if not await _clear_occupied_wall(building_index):
				return false
		_build_navigation()
		var approach = _service_approach(building_index, point)
		if approach.x < 0.0:
			_fail("no reachable interior F approach for %s at %s" % [service_type, point])
			return false
		print("NATURAL_ROUTE_SERVICE_APPROACH type=%s prop=%s goal=%s prop_distance=%.3f" % [service_type, point, approach, approach.distance_to(point)])
		if not await _walk_to(approach, 0.45, true, building_index):
			if bool(game.buildings[building_index].get("alien_occupied", false)):
				continue
			return false
		if game._is_inside_store_index(building_index, _world_position()) and _world_position().distance_to(point) <= game.BUILDING_SERVICE_RANGE:
			break
		if not bool(game.buildings[building_index].get("alien_occupied", false)):
			_fail("F service approach missed %s: pos=%s prop=%s distance=%.3f" % [service_type, _world_position(), point, _world_position().distance_to(point)])
			return false
	if not game._is_inside_store_index(building_index, _world_position()) or _world_position().distance_to(point) > game.BUILDING_SERVICE_RANGE:
		_fail("F service approach did not reach %s after retries" % service_type)
		return false
	await _tap(KEY_F)
	if service_type == "infinite_dog_food" and game.freya_hunger > 1.0:
		_fail("F at grocery did not feed Freya; hunger=%.1f" % game.freya_hunger)
		return false
	if service_type == "possession_immunity_medicine" and not game.freya_carries_immunity_dose:
		_fail("F at pharmacy did not collect medicine")
		return false
	return true


func _eat_if_hungry() -> bool:
	if game.freya_hunger < 82.0:
		return true
	_stage("food_trip")
	return await _use_service("infinite_dog_food")


func _clean_recruit_snapshot(index: int) -> String:
	if index < 0 or index >= game.dogs.size():
		return "dog=%d missing" % index
	var state: Dictionary = game.dogs[index]
	var dog: Node3D = state.get("node", null)
	var position = Vector2(dog.global_position.x, dog.global_position.z) if dog != null and is_instance_valid(dog) else Vector2.ZERO
	var threat: Dictionary = game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS)
	return "dog=%d freya=%s dog_pos=%s distance=%.2f possessed=%s aligned=%s flee=%.2f social=%.2f hunger=%.1f threat=%s C=%s R=%s" % [
		index, _world_position(), position, _world_position().distance_to(position),
		bool(state.get("alien_possessed", false)), bool(state.get("army_aligned", false)),
		float(state.get("flee_timer", 0.0)), float(state.get("socialization_progress", 0.0)),
		game.freya_hunger, threat, Input.is_action_pressed("friendly_social"), Input.is_action_pressed("aggressive_social")
	]


func _recruit_clean_ally() -> bool:
	if not await _eat_if_hungry():
		return false
	var attempted: Dictionary = {}
	var last_snapshot = ""
	for candidate_attempt in range(3):
		_build_navigation()
		var from_id = _closest_open_id(_world_position(), 1.2)
		if from_id.x < 0:
			from_id = _closest_open_id(_world_position(), 2.0)
		if from_id.x < 0:
			_fail("no walkable recruitment starting point near %s" % _world_position())
			return false
		var best_index = -1
		var best_score = INF
		for index in range(game.dogs.size()):
			var state: Dictionary = game.dogs[index]
			if attempted.has(index) or bool(state.get("army_aligned", false)) or bool(state.get("alien_possessed", false)):
				continue
			var candidate: Node3D = state.get("node", null)
			if candidate == null or not is_instance_valid(candidate):
				continue
			var candidate_pos = Vector2(candidate.global_position.x, candidate.global_position.z)
			var approach_id = _reachable_open_id(from_id, candidate_pos, 2.4)
			if approach_id.x < 0:
				print("NATURAL_ROUTE_ALLY_SKIP index=%d reason=no_reachable_approach pos=%s" % [index, candidate_pos])
				continue
			var route: Array[Vector2i] = nav_grid.get_id_path(from_id, approach_id)
			if route.is_empty():
				print("NATURAL_ROUTE_ALLY_SKIP index=%d reason=no_path pos=%s" % [index, candidate_pos])
				continue
			var score = float(route.size()) * CELL_SIZE + float(state.get("flee_timer", 0.0)) * 2.0
			# A clean dog among possessed dogs makes Freya flee whenever C
			# releases R. Prefer one with room for four seconds of socializing.
			for other_index in range(game.dogs.size()):
				if other_index == index or not bool(game.dogs[other_index].get("alien_possessed", false)):
					continue
				var other: Node3D = game.dogs[other_index].get("node", null)
				if other != null and is_instance_valid(other) and candidate.global_position.distance_to(other.global_position) < 4.5:
					score += 8.0
			if score < best_score:
				best_score = score
				best_index = index
		if best_index < 0:
			if attempted.is_empty():
				print("NATURAL_ROUTE_ALLY_FALLBACK: no clean stray is available; seek a possessed dog with R then C")
				return await _recruit_first_ally()
			break

		attempted[best_index] = true
		var dog: Node3D = game.dogs[best_index].get("node", null)
		var started_ms = Time.get_ticks_msec()
		var next_report_ms = started_ms + 5000
		var repaths = 0
		var barked_near_clean = false
		print("NATURAL_ROUTE_ALLY_TRY attempt=%d score=%.1f %s" % [candidate_attempt + 1, best_score, _clean_recruit_snapshot(best_index)])
		while Time.get_ticks_msec() - started_ms < 30000:
			if dog == null or not is_instance_valid(dog):
				break
			var state: Dictionary = game.dogs[best_index]
			if bool(state.get("army_aligned", false)) and not bool(state.get("alien_possessed", false)):
				_set_key(KEY_C, false)
				_release_movement()
				print("NATURAL_ROUTE_ALLY_RECRUITED index=%d allies=%d" % [best_index, game._chapter_real_ally_count()])
				return true
			if game.possessed_dog_tutorial_active:
				_set_key(KEY_C, false)
				_release_movement()
				await _tap(KEY_SPACE)
				continue
			var dog_pos = Vector2(dog.global_position.x, dog.global_position.z)
			var distance = _world_position().distance_to(dog_pos)
			var threat: Dictionary = game._nearest_possessed_dog_threat(game.POSSESSED_DOG_SCARE_RADIUS)
			if float(state.get("flee_timer", 0.0)) > 0.0 and not bool(state.get("alien_possessed", false)):
				# One accidental bark is recoverable. Let the dog settle before
				# navigating back, rather than repeatedly frightening it.
				barked_near_clean = true
				_set_key(KEY_C, false)
				_release_movement()
				await process_frame
				continue
			if bool(state.get("alien_possessed", false)) or bool(threat.get("found", false)):
				_set_key(KEY_C, false)
				_release_movement()
				if distance > 3.2 and bool(state.get("alien_possessed", false)):
					if repaths >= 5:
						break
					print("NATURAL_ROUTE_ALLY_REPATH reason=repossessed %s" % _clean_recruit_snapshot(best_index))
					if not await _walk_to(dog_pos, 2.4, true):
						return false
					repaths += 1
					continue
				if not bool(state.get("alien_possessed", false)) and barked_near_clean:
					print("NATURAL_ROUTE_ALLY_RETRY reason=threat_persisted_after_bark %s" % _clean_recruit_snapshot(best_index))
					break
				if not bool(state.get("alien_possessed", false)) and distance < game.SOCIALIZE_RANGE + 0.55:
					barked_near_clean = true
				_set_key(KEY_R, true)
				var bark_started_ms = Time.get_ticks_msec()
				while Time.get_ticks_msec() - bark_started_ms < 1400:
					await process_frame
				_set_key(KEY_R, false)
				print("NATURAL_ROUTE_ALLY_DEFEND %s" % _clean_recruit_snapshot(best_index))
				continue
			if distance > 3.2:
				_set_key(KEY_C, false)
				if repaths >= 5:
					break
				print("NATURAL_ROUTE_ALLY_REPATH reason=moving %s" % _clean_recruit_snapshot(best_index))
				if not await _walk_to(dog_pos, 2.4, true, -1, best_index):
					return false
				repaths += 1
				continue
			_release_movement()
			_set_key(KEY_C, true)
			if Time.get_ticks_msec() >= next_report_ms:
				print("NATURAL_ROUTE_ALLY_PROGRESS %s" % _clean_recruit_snapshot(best_index))
				next_report_ms += 5000
			await process_frame
		_set_key(KEY_C, false)
		_release_movement()
		last_snapshot = _clean_recruit_snapshot(best_index)
		print("NATURAL_ROUTE_ALLY_RETRY attempt=%d repaths=%d %s" % [candidate_attempt + 1, repaths, last_snapshot])
		if game.freya_hunger >= 82.0 and not await _eat_if_hungry():
			return false
	_fail("C did not recruit a clean dog after %d candidates; %s" % [attempted.size(), last_snapshot])
	return false


func _recover_real_ally() -> bool:
	if game._chapter_real_ally_count() > 0:
		return true
	_stage("ally_recovery")
	var possessed_aligned = -1
	var best_distance = INF
	for dog_index in range(game.dogs.size()):
		var state: Dictionary = game.dogs[dog_index]
		if not bool(state.get("army_aligned", false)) or not bool(state.get("alien_possessed", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		var distance = _world_position().distance_to(Vector2(dog.global_position.x, dog.global_position.z))
		if distance < best_distance:
			best_distance = distance
			possessed_aligned = dog_index
	if possessed_aligned >= 0:
		print("NATURAL_ROUTE_ALLY_RECOVERY_R index=%d distance=%.2f" % [possessed_aligned, best_distance])
		return await _recruit_first_ally(possessed_aligned)
	print("NATURAL_ROUTE_ALLY_RECOVERY_C no aligned possessed dog; recruiting a clean stray")
	return await _recruit_clean_ally()


func _unprotected_ally_index() -> int:
	var best = -1
	var best_distance = INF
	for index in range(game.dogs.size()):
		var state: Dictionary = game.dogs[index]
		if not bool(state.get("army_aligned", false)) or bool(state.get("alien_possessed", false)) or bool(state.get("possession_immune", false)) or bool(state.get("has_dog_armor", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		var distance = _world_position().distance_to(Vector2(dog.global_position.x, dog.global_position.z))
		if distance < best_distance:
			best = index
			best_distance = distance
	return best


func _ally_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for index in range(game.dogs.size()):
		var state: Dictionary = game.dogs[index]
		if not bool(state.get("army_aligned", false)):
			continue
		var dog: Node3D = state.get("node", null)
		snapshot.append({
			"index": index,
			"possessed": bool(state.get("alien_possessed", false)),
			"immune": bool(state.get("possession_immune", false)),
			"armor": bool(state.get("has_dog_armor", false)),
			"pos": dog.global_position if dog != null and is_instance_valid(dog) else Vector3.ZERO
		})
	return snapshot


func _give_carried_medicine_to_ally(index: int) -> bool:
	var dog: Node3D = game.dogs[index].get("node", null)
	if dog == null or not is_instance_valid(dog):
		_fail("medicine target dog %d has no live node" % index)
		return false
	for attempt in range(12):
		var position = Vector2(dog.global_position.x, dog.global_position.z)
		# A dog can stand beside an occupied wall where its center is legal for
		# its smaller radius but no Freya-width grid cell exists within 0.45 m.
		# The F action itself accepts a dog within BUILDING_SERVICE_RANGE.
		if not await _walk_to(position, 1.1, true):
			return false
		var live_position = Vector2(dog.global_position.x, dog.global_position.z)
		if _world_position().distance_to(live_position) > 1.45:
			await _frames(2)
			continue
		var supply_target: Dictionary = game._select_carried_supply_target()
		var nearest = int(supply_target.get("dog_index", -1))
		var supply_kind = str(supply_target.get("kind", ""))
		if nearest == index and supply_kind == "medicine":
			var protected_before: int = game._chapter_protected_ally_count()
			var immune_before: Dictionary = {}
			for dog_index in range(game.dogs.size()):
				if bool(game.dogs[dog_index].get("possession_immune", false)):
					immune_before[dog_index] = true
			await _tap(KEY_F)
			if bool(game.dogs[index].get("possession_immune", false)):
				print("NATURAL_ROUTE_ALLY_PROTECTED index=%d protected=%d/2" % [index, game._chapter_protected_ally_count()])
				return true
			if not game.freya_carries_immunity_dose:
				var recipients: Array[int] = []
				for dog_index in range(game.dogs.size()):
					if bool(game.dogs[dog_index].get("possession_immune", false)) and not immune_before.has(dog_index):
						recipients.append(dog_index)
				var protected_after: int = game._chapter_protected_ally_count()
				print("NATURAL_ROUTE_MEDICINE_REDIRECTED intended=%d actual=%s protected=%d->%d allies=%s" % [index, recipients, protected_before, protected_after, _ally_snapshot()])
				if recipients.is_empty():
					print("NATURAL_ROUTE_MEDICINE_WASTED intended=%d target_after=%s; retrying pharmacy by input" % [index, game._select_carried_supply_target()])
				return true
		elif nearest >= 0 and nearest < game.dogs.size() and supply_kind != "medicine":
			var protected_before = game._chapter_protected_ally_count()
			await _tap(KEY_F)
			print("NATURAL_ROUTE_OTHER_SUPPLY kind=%s dog=%d protected=%d->%d" % [supply_kind, nearest, protected_before, game._chapter_protected_ally_count()])
			if game._chapter_protected_ally_count() > protected_before:
				return true
			continue
		elif nearest >= 0 and nearest < game.dogs.size():
			var other_state: Dictionary = game.dogs[nearest]
			if not bool(other_state.get("alien_possessed", false)) and not bool(other_state.get("possession_immune", false)) and not bool(other_state.get("has_dog_armor", false)):
				if bool(other_state.get("army_aligned", false)):
					print("NATURAL_ROUTE_MEDICINE_RETARGET old=%d new=%d" % [index, nearest])
					index = nearest
					dog = other_state.get("node", null)
					continue
				print("NATURAL_ROUTE_MEDICINE_RECRUIT_NEARBY intended=%d stray=%d pos=%s" % [index, nearest, _world_position()])
				if not await _recruit_clean_ally():
					return false
				return true
			var other: Node3D = game.dogs[nearest].get("node", null)
			if other != null and is_instance_valid(other):
				var other_pos = Vector2(other.global_position.x, other.global_position.z)
				var away = (position - other_pos).normalized()
				if away.length_squared() > 0.01:
					var clear_side = position + away * 0.85
					if game._is_walkable(clear_side.x, clear_side.y, game.FREYA_COLLISION_RADIUS):
						await _walk_to(clear_side, 0.35, true)
		await _frames(6)
	_fail("could not select ally %d for F medicine; target=%s pos=%s" % [index, game._select_carried_supply_target(), _world_position()])
	return false


func _protect_two_allies() -> bool:
	var attempts = 0
	while game._chapter_protected_ally_count() < 2 and attempts < 8:
		if game._chapter_real_ally_count() <= game._chapter_protected_ally_count():
			if not await _recruit_clean_ally():
				return false
		if not await _eat_if_hungry():
			return false
		if not game.freya_carries_immunity_dose:
			if not await _use_service("possession_immunity_medicine"):
				return false
		var target = _unprotected_ally_index()
		if target < 0:
			print("NATURAL_ROUTE_ALLY_RECOVERY: no unprotected ally after medicine pickup; real=%d protected=%d carried=%s world_time=%.2f allies=%s" % [game._chapter_real_ally_count(), game._chapter_protected_ally_count(), game.freya_carries_immunity_dose, game.world_time, _ally_snapshot()])
			if not await _recruit_clean_ally():
				return false
			target = _unprotected_ally_index()
			if target < 0:
				_fail("no unprotected real ally after recruiting with medicine: %s" % [_ally_snapshot()])
				return false
		if not await _give_carried_medicine_to_ally(target):
			return false
		attempts += 1
	if game._chapter_protected_ally_count() < 2:
		_fail("Chapter 2 still needs protected allies after %d medicine trips" % attempts)
		return false
	_stage("two_allies_protected")
	return true


func _clear_active_generators() -> bool:
	var clears = 0
	while game._chapter_active_generator_count() > 0 and clears < 12:
		var nearest = game._nearest_active_generator_index()
		if nearest < 0:
			_fail("active generator count has no reachable index")
			return false
		if not await _clear_occupied_wall(nearest):
			return false
		clears += 1
	if game._chapter_active_generator_count() > 0:
		_fail("generator clear planner exhausted %d visits with %d sources active" % [clears, game._chapter_active_generator_count()])
		return false
	return true


func _final_site_pack_snapshot() -> String:
	var index: int = game.chapter_final_stronghold_index
	var footprint: Rect2 = game.buildings[index].get("footprint", Rect2())
	var allies: Array[Dictionary] = []
	var active: Array[int] = game._active_pack_dog_indices()
	for dog_index in range(game.dogs.size()):
		var state: Dictionary = game.dogs[dog_index]
		if not bool(state.get("army_aligned", false)):
			continue
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		var pos = Vector2(dog.global_position.x, dog.global_position.z)
		allies.append({"index": dog_index, "pos": pos, "dist": snappedf(game._point_distance_to_rect(pos, footprint), 0.01), "active": active.has(dog_index), "possessed": bool(state.get("alien_possessed", false)), "immune": bool(state.get("possession_immune", false))})
	return "site=%d footprint=%s occupied=%s real_allies=%d order=%s guard=%s guard_dist=%.2f assist_target=%d freya=%s active=%s allies=%s world_time=%.2f paused=%s tutorial=%s" % [index, footprint, bool(game.buildings[index].get("alien_occupied", false)), game._chapter_real_ally_count(), game.pack_order, game.pack_guard_position, game._point_distance_to_rect(game.pack_guard_position, footprint), game.pack_assist_target_index, _world_position(), active, allies, game.world_time, paused, game.possessed_dog_tutorial_active]


func _secure_chapter() -> bool:
	_stage("chapter_start")
	if not await _clear_active_generators():
		return false
	if game.campaign_chapter == 1 and not game.kennel_rescue_complete():
		if not await _rescue_lodge():
			return false
	if game.campaign_chapter == 2 and game._chapter_protected_ally_count() < 2:
		if not await _protect_two_allies():
			return false
	if game.campaign_chapter == 3 and game._chapter_real_ally_count() < 1:
		if not await _recover_real_ally():
			return false
	if not await _claim_connected_chapter_sites():
		return false
	if not await _clear_active_generators():
		return false
	if game._chapter_real_ally_count() < 1:
		if not await _recover_real_ally():
			return false
	if game.campaign_chapter == 3 and not game.chapter_assisted_stronghold:
		var final_index: int = game.chapter_final_stronghold_index
		if final_index < 0:
			_fail("final signal site is missing")
			return false
		var approach = _alien_wall_approach(final_index)
		if approach.x < 0.0:
			_fail("no guard approach at cleared final signal")
			return false
		if not await _walk_to(approach, 0.4, true):
			return false
		await _tap(KEY_2)
		print("NATURAL_ROUTE_GUARD_START %s" % _final_site_pack_snapshot())
		var started_ms = Time.get_ticks_msec()
		var next_report_ms = started_ms + 5000
		while not game.chapter_assisted_stronghold and Time.get_ticks_msec() - started_ms < 30000:
			if Time.get_ticks_msec() >= next_report_ms:
				print("NATURAL_ROUTE_GUARD_PROGRESS %s" % _final_site_pack_snapshot())
				next_report_ms += 5000
			await process_frame
		if not game.chapter_assisted_stronghold:
			_fail("guard order at final signal did not register an active ally: %s" % _final_site_pack_snapshot())
			return false
	await _frames(4)
	# A lone ally can be re-possessed during the final interior claim. Recover
	# through normal R/C input before treating the chapter result as missing.
	for recovery_attempt in range(3):
		if game.campaign_chapter != 1 or game.chapter_complete or game._chapter_real_ally_count() > 0:
			break
		print("NATURAL_ROUTE_RESULT_ALLY_RECOVERY attempt=%d allies=%d" % [recovery_attempt + 1, game._chapter_real_ally_count()])
		if not await _recover_real_ally():
			return false
		await _frames(4)
	_stage("chapter_result")
	if not game.chapter_complete or game.chapter_complete_panel == null or not game.chapter_complete_panel.visible:
		_fail("chapter %d objectives did not open the result panel; %s" % [game.campaign_chapter, game._chapter_objectives_text()])
		return false
	return true


func _run_campaign() -> bool:
	var stop_after = clampi(int(OS.get_environment("FREYA_NATURAL_STOP_AFTER_CHAPTER")), 1, 3) if not OS.get_environment("FREYA_NATURAL_STOP_AFTER_CHAPTER").is_empty() else 3
	for chapter in range(game.campaign_chapter, stop_after + 1):
		if game.campaign_chapter != chapter:
			_fail("expected chapter %d before input route, got %d" % [chapter, game.campaign_chapter])
			return false
		if not await _secure_chapter():
			return false
		if chapter == stop_after and stop_after < 3:
			print("NATURAL_ROUTE_CHAPTER_CHECKPOINT_OK chapter=%d" % chapter)
			return true
		await _tap(KEY_N)
		var started_ms = Time.get_ticks_msec()
		if chapter < 3:
			while game.campaign_chapter == chapter and Time.get_ticks_msec() - started_ms < 5000:
				await process_frame
			if game.campaign_chapter != chapter + 1:
				_fail("N did not advance chapter %d" % chapter)
				return false
			_stage("story_continued")
		else:
			while current_scene != null and current_scene.scene_file_path != "res://scenes/CampaignEnding.tscn" and Time.get_ticks_msec() - started_ms < 8000:
				await process_frame
			if current_scene == null or current_scene.scene_file_path != "res://scenes/CampaignEnding.tscn":
				_fail("N did not open the campaign ending")
				return false
			var ending: Node = current_scene
			for page in range(1, 4):
				await _tap(KEY_RIGHT)
				if current_scene != ending or int(ending.get("_page")) != page:
					_fail("Right did not advance ending to page %d" % (page + 1))
					return false
			var ending_heading: Label = ending.get("heading")
			var ending_explore: Button = ending.get("explore_button")
			var ending_replay: Button = ending.get("replay_button")
			if ending_heading.text != "Thank you for playing" or not ending_explore.visible or not ending_replay.visible:
				_fail("ending page 4 did not show credits and story choices")
				return false
			print("NATURAL_ROUTE_CREDITS_OK summary=%s elapsed=%.1f" % [ending.get("_summary"), float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
			await _capture("credits_960")
			ending.set("resume_save_path", TEST_SAVE_PATH)
			await _tap(KEY_ESCAPE)
			started_ms = Time.get_ticks_msec()
			while current_scene == ending and Time.get_ticks_msec() - started_ms < 8000:
				await process_frame
			if current_scene == null or current_scene.scene_file_path != "res://scenes/Main.tscn":
				_fail("Keep Exploring did not return to the saved neighborhood")
				return false
			game = current_scene
			if not game.campaign_complete or not game.chapter_result_dismissed or paused:
				_fail("Keep Exploring restored an incomplete or paused neighborhood")
				return false
			print("NATURAL_ROUTE_KEEP_EXPLORING_OK chapter=%d campaign_complete=%s elapsed=%.1f" % [game.campaign_chapter, game.campaign_complete, float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	return true


func _run() -> void:
	var keep_save = OS.get_environment("FREYA_NATURAL_KEEP_SAVE") == "1"
	var resume = OS.get_environment("FREYA_NATURAL_RESUME") == "1"
	if resume:
		if not GameSaveScript.has_resume(TEST_SAVE_PATH):
			_fail("isolated natural-route save is unavailable for Startup Resume")
			quit(1)
			return
		OS.set_environment("FREYA_STARTUP_VIEW", "resume")
	else:
		_cleanup_save()
	route_started_ms = Time.get_ticks_msec()
	if change_scene_to_file("res://scenes/Startup.tscn") != OK:
		_fail("could not open Startup")
		quit(1)
		return
	await scene_changed
	await _frames(3)
	await _capture("startup_960")
	if resume:
		current_scene.resume_save_path = TEST_SAVE_PATH
		current_scene._refresh_resume_button()
		current_scene.resume_game_button.grab_focus()
	else:
		current_scene.skip_to_game_button.grab_focus()
	await _tap(KEY_ENTER)
	if resume:
		OS.set_environment("FREYA_STARTUP_VIEW", "")
	if current_scene.scene_file_path != "res://scenes/Main.tscn":
		_fail("Startup selection did not reach Main")
		quit(1)
		return
	game = current_scene
	game.game_save_test_path = TEST_SAVE_PATH
	if resume:
		print("NATURAL_ROUTE_RESUMED chapter=%d claims=%d/%d save=%s" % [game.campaign_chapter, game._chapter_claimed_target_count(), game.chapter_target_indices.size(), TEST_SAVE_PATH])
		_build_navigation()
		if OS.get_environment("FREYA_NATURAL_STOP_AFTER_STAGE") == "lodge":
			if game.campaign_chapter != 1 or not await _rescue_lodge():
				if failures.is_empty():
					_fail("lodge checkpoint did not complete")
			else:
				print("NATURAL_ROUTE_LODGE_CHECKPOINT_OK rescued=%d/6" % game.kennel_released_count())
		elif OS.get_environment("FREYA_NATURAL_STOP_AFTER_STAGE") == "two_allies_protected":
			if game.campaign_chapter != 2 or not await _protect_two_allies():
				if failures.is_empty():
					_fail("chapter-2 medicine checkpoint did not complete")
			else:
				print("NATURAL_ROUTE_MEDICINE_CHECKPOINT_OK protected=%d/2 carried=%s" % [game._chapter_protected_ally_count(), game.freya_carries_immunity_dose])
		else:
			await _run_campaign()
		_release_movement()
		if not keep_save:
			_cleanup_save()
		if failures.is_empty():
			print("NATURAL_ROUTE_RESUME_OK: isolated Startup Resume and later campaign objectives used live controls")
			quit()
		else:
			push_error("NATURAL_ROUTE_FAIL: " + ", ".join(failures))
			quit(1)
		return
	var occupied_count = 0
	for building in game.buildings:
		if bool(building.get("alien_occupied", false)):
			occupied_count += 1
	print("NATURAL_ROUTE_START seed=%s home=%s chapter=%d targets=%d occupied=%d" % [game.rng.seed, _world_position(), game.campaign_chapter, game.chapter_target_indices.size(), occupied_count])
	if occupied_count < 3:
		_fail("normal start did not seed the two chapter holds and the lodge")
	await _capture("home_960")
	await _tap(KEY_F)
	if game.freya_hunger > 1.0:
		_fail("F at skip spawn did not eat home food")
	_build_navigation()
	var home: Dictionary = game.buildings[game.freya_home_index]
	var outside: Vector2 = home.get("home_layout", {}).get("entry_outside_pos", Vector2.ZERO)
	if not await _walk_to(outside, 0.9):
		_fail("could not walk out of the home by input")
	print("NATURAL_ROUTE_HOME_EXIT pos=%s inside=%s elapsed=%.1f" % [_world_position(), game.freya_inside_home, float(Time.get_ticks_msec() - route_started_ms) / 1000.0])
	if game.freya_inside_home:
		_fail("home exit did not change indoor state")
	if not OS.get_environment("FREYA_NATURAL_CAPTURE_DIR").is_empty():
		await _capture("home_exit_960")
		_set_key(KEY_TAB, true)
		await _capture("goals_960")
		_set_key(KEY_TAB, false)
		await _tap(KEY_ESCAPE)
		game.pause_controls_button.grab_focus()
		await _tap(KEY_ENTER)
		await _capture("pause_controls_960")
		await _tap(KEY_ESCAPE)
	var stronghold_only = OS.get_environment("FREYA_NATURAL_STRONGHOLD_ONLY") == "1"
	var campaign = OS.get_environment("FREYA_NATURAL_CAMPAIGN") == "1"
	var stop_after_stage = OS.get_environment("FREYA_NATURAL_STOP_AFTER_STAGE")
	var deep = OS.get_environment("FREYA_NATURAL_DEEP") == "1" or OS.get_environment("FREYA_NATURAL_STRONGHOLD") == "1" or stronghold_only or campaign
	if deep:
		if await _recruit_first_ally():
			if stronghold_only:
				await _break_first_stronghold()
			elif await _claim_first_site():
				if campaign:
					if stop_after_stage == "lodge":
						var lodge_ok: bool = await _clear_active_generators()
						if lodge_ok:
							lodge_ok = await _rescue_lodge()
						if not lodge_ok and failures.is_empty():
							_fail("lodge checkpoint ended without completing rescue")
					else:
						var campaign_ok: bool = await _run_campaign()
						if not campaign_ok and failures.is_empty():
							_fail("campaign route ended before its selected checkpoint")
				elif OS.get_environment("FREYA_NATURAL_STRONGHOLD") == "1":
					await _break_first_stronghold()
	_release_movement()
	if not keep_save:
		_cleanup_save()
	if failures.is_empty():
		if campaign and stop_after_stage == "lodge":
			print("NATURAL_ROUTE_LODGE_CHECKPOINT_OK: startup, first claim, lodge cleanse, and six cage rescues used live controls")
		elif campaign:
			print("NATURAL_ROUTE_CAMPAIGN_OK: chapter objectives, lodge rescue, medicine, pack help, and story navigation used live controls")
		elif stronghold_only:
			print("NATURAL_ROUTE_STRONGHOLD_ONLY_OK: startup, meal, home exit, dog recruit, and alien hold clear used live controls")
		elif OS.get_environment("FREYA_NATURAL_STRONGHOLD") == "1":
			print("NATURAL_ROUTE_STRONGHOLD_OK: startup, meal, home exit, dog recruit, first claim, and alien hold clear used live controls")
		elif deep:
			print("NATURAL_ROUTE_DEEP_OK: startup, meal, home exit, dog recruit, and first building claim used live controls")
		else:
			print("NATURAL_ROUTE_EARLY_OK: startup skip, bowl, and walkable home exit used live controls")
		quit()
	else:
		push_error("NATURAL_ROUTE_FAIL: " + ", ".join(failures))
		quit(1)
