extends SceneTree

# Compare two normal-input approaches to the same occupied wall from one
# staged in-memory snapshot. Only checkpoint creation assigns gameplay state;
# each branch moves Freya and issues orders/claims through keyboard events.
# The nearby scent marks are ready in BOTH branches. This isolates the choice
# between a quick pack order and claiming a prepared neighboring property.
# Claims can autosave, so route any write to an isolated disposable QA slot.
const TEST_SAVE_PATH = "user://friendly_freya_tactical_routes_test.json"
const SEED = 20260831
const SUPPORT_INDEX = 24
const HOLD_INDEX = 22
const CELL = 0.5

var game: Node
var nav: AStarGrid2D
var held: Dictionary = {}
var failures: Array[String] = []
var checkpoint: Dictionary = {}
var checkpoint_position = Vector2.ZERO
var ally_index = -1
var steer_x_credit = 0.0
var steer_y_credit = 0.0


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	OS.set_environment("FREYA_WORLD_SEED", str(SEED))
	create_timer(240.0).timeout.connect(_timeout)
	call_deferred("_run")


func _timeout() -> void:
	_release_keys()
	_fail("watchdog reached 240 seconds")
	_finish()


func _check(ok: bool, message: String) -> bool:
	if not ok:
		_fail(message)
	return ok


func _fail(message: String) -> void:
	failures.append(message)
	push_error("TACTICAL_ROUTES: " + message)


func _finish() -> void:
	_release_keys()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH + suffix))
	if failures.is_empty():
		print("TACTICAL_ROUTES_OK: pack assist and prepared scent/guard routes both broke the same occupied wall using keyboard input")
		quit()
	else:
		push_error("TACTICAL_ROUTES_FAIL: " + ", ".join(failures))
		quit(1)


func _frames(count: int = 2) -> void:
	for index in range(count):
		await process_frame


func _key(code: Key, down: bool) -> void:
	if bool(held.get(code, false)) == down:
		return
	held[code] = down
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(2)
	_key(code, false)
	await _frames(2)


func _release_keys() -> void:
	for code in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_SPACE, KEY_2, KEY_3]:
		_key(code, false)


func _position() -> Vector2:
	var p: Vector3 = game.freya.global_position
	return Vector2(p.x, p.z)


func _grid_id(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x / CELL), roundi(p.y / CELL))


func _grid_position(id: Vector2i) -> Vector2:
	return Vector2(id.x * CELL, id.y * CELL)


func _build_navigation() -> void:
	nav = AStarGrid2D.new()
	nav.region = Rect2i(0, 0, roundi(float(game.MAP_W) / CELL) + 1, roundi(float(game.MAP_H) / CELL) + 1)
	nav.cell_size = Vector2(CELL, CELL)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.update()
	for z in range(nav.region.size.y):
		for x in range(nav.region.size.x):
			var id = Vector2i(x, z)
			var point = _grid_position(id)
			if not game._is_walkable(point.x, point.y, game.FREYA_COLLISION_RADIUS):
				nav.set_point_solid(id)


func _open_id(target: Vector2, radius: float, from_id: Vector2i = Vector2i(-1, -1)) -> Vector2i:
	var center = _grid_id(target)
	var count = ceili(radius / CELL)
	var best = Vector2i(-1, -1)
	var best_score = INF
	for dz in range(-count, count + 1):
		for dx in range(-count, count + 1):
			var id = center + Vector2i(dx, dz)
			if not nav.is_in_boundsv(id) or nav.is_point_solid(id):
				continue
			var distance = _grid_position(id).distance_to(target)
			if distance > radius:
				continue
			var path_length = 0
			if from_id.x >= 0:
				var path: Array[Vector2i] = nav.get_id_path(from_id, id)
				if path.is_empty():
					continue
				path_length = path.size()
			var score = distance * 4.0 + float(path_length) * CELL
			if score < best_score:
				best = id
				best_score = score
	return best


func _drive_toward(target: Vector2) -> void:
	var desired = (target - _position()).normalized()
	var basis: Basis = game.camera_node.global_basis
	var right = Vector2(basis.x.x, basis.x.z).normalized()
	var forward = Vector2(-basis.z.x, -basis.z.z).normalized()
	var screen_x = desired.dot(right)
	var screen_y = desired.dot(forward)
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
	_key(KEY_A, use_x and screen_x < 0.0)
	_key(KEY_D, use_x and screen_x > 0.0)
	_key(KEY_W, use_y and screen_y > 0.0)
	_key(KEY_S, use_y and screen_y < 0.0)


func _walk_to(goal: Vector2, range_to_goal: float) -> bool:
	var started_ms = Time.get_ticks_msec()
	var origin = _position()
	for replan in range(12):
		var from_id = _open_id(_position(), 1.5)
		var to_id = _open_id(goal, range_to_goal, from_id)
		if from_id.x < 0 or to_id.x < 0:
			return _check(false, "no walkable route from %s to %s" % [origin, goal])
		var path: Array[Vector2i] = nav.get_id_path(from_id, to_id)
		if path.is_empty():
			return _check(false, "A* returned no path from %s to %s" % [origin, goal])
		var stalled = false
		for id in path:
			var waypoint = _grid_position(id)
			var last_distance = INF
			var stuck_frames = 0
			while _position().distance_to(waypoint) > 0.34:
				if Time.get_ticks_msec() - started_ms > 45000:
					_release_keys()
					return _check(false, "movement timeout from %s to %s near %s" % [origin, goal, _position()])
				var distance = _position().distance_to(waypoint)
				stuck_frames = stuck_frames + 1 if distance >= last_distance - 0.008 else 0
				if stuck_frames > 110:
					_release_keys()
					if game._is_walkable(waypoint.x, waypoint.y, game.FREYA_COLLISION_RADIUS):
						nav.set_point_solid(id)
					else:
						_build_navigation()
					stalled = true
					break
				last_distance = distance
				_drive_toward(waypoint)
				await process_frame
			if stalled:
				break
		_release_keys()
		await _frames(2)
		if _position().distance_to(goal) <= range_to_goal + 0.35:
			return true
		if not stalled:
			return _check(false, "route ended short of %s near %s" % [goal, _position()])
	return _check(false, "replans exhausted from %s to %s" % [origin, goal])


func _wall_approach(index: int) -> Vector2:
	var footprint: Rect2 = game.buildings[index].get("footprint", Rect2())
	var from_id = _open_id(_position(), 1.5)
	var best = Vector2(-1.0, -1.0)
	var best_score = INF
	var first = _grid_id(footprint.position - Vector2.ONE * 2.0)
	var last = _grid_id(footprint.end + Vector2.ONE * 2.0)
	for z in range(maxi(0, first.y), mini(nav.region.size.y - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(nav.region.size.x - 1, last.x) + 1):
			var id = Vector2i(x, z)
			if nav.is_point_solid(id):
				continue
			var point = _grid_position(id)
			var wall_distance = game._point_distance_to_rect(point, footprint)
			if wall_distance < 0.35 or wall_distance > 1.2:
				continue
			var path: Array[Vector2i] = nav.get_id_path(from_id, id)
			if path.is_empty():
				continue
			var score = float(path.size()) + wall_distance * 3.0
			if score < best_score:
				best = point
				best_score = score
	return best


func _open_main() -> bool:
	if not _check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not open Main"):
		return false
	await scene_changed
	game = current_scene
	game.game_save_test_path = TEST_SAVE_PATH
	await _frames(2)
	return true


func _stage_checkpoint() -> bool:
	if not _check(SUPPORT_INDEX < game.buildings.size() and HOLD_INDEX < game.buildings.size(), "seeded comparison sites missing"):
		return false
	var support: Dictionary = game.buildings[SUPPORT_INDEX]
	var hold: Dictionary = game.buildings[HOLD_INDEX]
	var support_center: Vector2 = support.get("footprint", Rect2()).get_center()
	var hold_center: Vector2 = hold.get("footprint", Rect2()).get_center()
	if not _check(support_center.distance_to(hold_center) <= game.FREYA_SCENT_SUPPORT_RADIUS and game._building_has_adjacent_freya_control(SUPPORT_INDEX), "seeded sites are not a connected scent pair"):
		return false
	if not _check(not bool(support.get("alien_occupied", false)) and not bool(hold.get("alien_occupied", false)), "seeded sites are unexpectedly occupied"):
		return false
	game._complete_post_intro_meal_tutorial()
	game.freya_hunger = 0.0
	game.possessed_dog_behavior_enabled = false
	game.possessed_dog_tutorial_seen = true
	game.chapter_guide_hidden = true
	for index in [SUPPORT_INDEX, HOLD_INDEX]:
		for item in game._building_surrounding_claimables(index):
			game._set_claim_owner(int(item.get("type", -1)), int(item.get("index", -1)), game.CLAIM_OWNER_FREYA)
	if not _check(bool(game._building_claim_status(SUPPORT_INDEX).get("eligible", false)), "prepared neighbor cannot be claimed"):
		return false
	if not _check(game._occupy_building_with_alien(HOLD_INDEX, -88022, false), "could not stage the occupied hold"):
		return false
	var outside: Vector2 = support.get("store_layout", {}).get("entry_outside_pos", support_center)
	var outward = (outside - support_center).normalized()
	if outward.length_squared() < 0.01:
		outward = Vector2.DOWN
	checkpoint_position = game._nearest_walkable_position(outside + outward * 1.0, game.FREYA_COLLISION_RADIUS)
	if not _check(game._is_walkable(checkpoint_position.x, checkpoint_position.y, game.FREYA_COLLISION_RADIUS), "checkpoint is not walkable"):
		return false
	game.freya.global_position = Vector3(checkpoint_position.x, 0.0, checkpoint_position.y)
	game.freya_inside_home = false
	game.camera_focus = game.freya.global_position + Vector3(0.0, 0.95, 0.0)
	game._update_camera(0.0)
	for index in range(game.dogs.size()):
		if not bool(game.dogs[index].get("park", false)):
			ally_index = index
			break
	if not _check(ally_index >= 0, "no city dog to stage as ally"):
		return false
	var ally: Dictionary = game.dogs[ally_index]
	var ally_pos: Vector2 = game._nearest_walkable_position(checkpoint_position + Vector2(1.2, 0.0), game.DOG_COLLISION_RADIUS)
	ally["node"].global_position = Vector3(ally_pos.x, 0.0, ally_pos.y)
	ally["army_aligned"] = true
	ally["alien_possessed"] = false
	ally["possession_immune"] = true
	ally["flee_timer"] = 0.0
	ally["socialization_progress"] = 1.0
	game.dogs[ally_index] = ally
	ally["node"].call("set_army_aligned", true)
	game.pack_order = game.PACK_ORDER_FOLLOW
	game.pack_guard_dog_index = -1
	game.pack_assist_target_index = -1
	game._update_alien_reinforcement_fields()
	game._update_ui()
	checkpoint = game._snapshot_game_state()
	_build_navigation()
	print("TACTICAL_ROUTES_CHECKPOINT seed=%d support=%d hold=%d marks_ready=%d origin=%s ally=%d scent=%.2f" % [SEED, SUPPORT_INDEX, HOLD_INDEX, game._building_surrounding_claimables(SUPPORT_INDEX).size(), checkpoint_position, ally_index, game._claimed_scent_support(HOLD_INDEX)])
	return _assert_checkpoint()


func _assert_checkpoint() -> bool:
	var ok = true
	ok = _check(_position().distance_to(checkpoint_position) < 0.5, "branch did not restore Freya's checkpoint position") and ok
	ok = _check(bool(game.buildings[HOLD_INDEX].get("alien_occupied", false)) and absf(float(game.buildings[HOLD_INDEX].get("alien_integrity", 0.0)) - 1.0) < 0.001, "branch did not restore the same full-strength hold") and ok
	ok = _check(not game._building_is_controlled_by_freya(SUPPORT_INDEX) and game._claimed_scent_support(HOLD_INDEX) == 0.0, "branch started with scent support") and ok
	ok = _check(bool(game.dogs[ally_index].get("army_aligned", false)) and not bool(game.dogs[ally_index].get("alien_possessed", true)), "branch lost its clean ally") and ok
	ok = _check(game.pack_order == game.PACK_ORDER_FOLLOW, "branch did not start in Follow order") and ok
	return ok


func _claim_prepared_neighbor() -> bool:
	var building: Dictionary = game.buildings[SUPPORT_INDEX]
	var layout: Dictionary = building.get("store_layout", {})
	var entry: Vector2 = layout.get("entry_inside_pos", building.get("store_interior_rect", Rect2()).get_center())
	var inward = Vector2(0.0, -float(layout.get("front_sign", 1.0)))
	var claim_point = entry + inward * 0.8
	if not await _walk_to(claim_point, 0.4):
		return false
	var target: Dictionary = game._find_nearest_claim_target()
	if not _check(game._store_index_for_interior_point(_position()) == SUPPORT_INDEX and int(target.get("type", -1)) == game.CLAIM_TARGET_BUILDING and int(target.get("index", -1)) == SUPPORT_INDEX, "neighbor interior is not selected: %s" % target):
		return false
	var started_ms = Time.get_ticks_msec()
	_key(KEY_SPACE, true)
	while not game._building_is_controlled_by_freya(SUPPORT_INDEX) and Time.get_ticks_msec() - started_ms < 18000:
		await process_frame
	_key(KEY_SPACE, false)
	await _frames(2)
	if not _check(game._building_is_controlled_by_freya(SUPPORT_INDEX), "Space did not claim the prepared neighbor"):
		return false
	print("TACTICAL_ROUTES_NEIGHBOR_CLAIMED seconds=%.2f world_time=%.2f" % [float(Time.get_ticks_msec() - started_ms) / 1000.0, game.world_time])
	return true


func _run_branch(kind: String) -> Dictionary:
	var branch_started_ms = Time.get_ticks_msec()
	var start_world_time = game.world_time
	if kind == "prepared":
		if not await _claim_prepared_neighbor():
			return {}
	var wall_point = _wall_approach(HOLD_INDEX)
	if not _check(wall_point.x >= 0.0, "%s has no reachable wall approach" % kind):
		return {}
	if not await _walk_to(wall_point, 0.25):
		return {}
	var selected: Dictionary = game._find_nearest_claim_target()
	if not _check(int(selected.get("type", -1)) == game.CLAIM_TARGET_ALIEN_BUILDING and int(selected.get("index", -1)) == HOLD_INDEX, "%s approach selected another target: %s" % [kind, selected]):
		return {}
	if kind == "quick":
		await _tap(KEY_3)
		if not _check(game.pack_order == game.PACK_ORDER_ASSIST and game.pack_assist_target_index == HOLD_INDEX, "3 did not assign the target hold"):
			return {}
		var assist_started_ms = Time.get_ticks_msec()
		while game._pack_assist_count(HOLD_INDEX) < 1 and Time.get_ticks_msec() - assist_started_ms < 20000:
			await process_frame
		if not _check(game._pack_assist_count(HOLD_INDEX) >= 1, "assistant did not reach the hold"):
			return {}
	else:
		await _tap(KEY_2)
		if not _check(game.pack_order == game.PACK_ORDER_GUARD and game._point_distance_to_rect(game.pack_guard_position, game.buildings[HOLD_INDEX].get("footprint", Rect2())) <= game.PACK_ASSIST_RADIUS, "2 did not guard the hold"):
			return {}
		var guard_started_ms = Time.get_ticks_msec()
		while game._point_distance_to_rect(Vector2(game.dogs[ally_index]["node"].global_position.x, game.dogs[ally_index]["node"].global_position.z), game.buildings[HOLD_INDEX].get("footprint", Rect2())) > game.PACK_ASSIST_RADIUS and Time.get_ticks_msec() - guard_started_ms < 20000:
			await process_frame
		if not _check(game._point_distance_to_rect(Vector2(game.dogs[ally_index]["node"].global_position.x, game.dogs[ally_index]["node"].global_position.z), game.buildings[HOLD_INDEX].get("footprint", Rect2())) <= game.PACK_ASSIST_RADIUS, "guard ally did not reach the hold"):
			return {}
		if not _check(game._claimed_scent_support(HOLD_INDEX) >= game.FREYA_SCENT_SUPPORT_PER_BUILDING, "prepared route has no scent bonus"):
			return {}
	var prewall_seconds = float(Time.get_ticks_msec() - branch_started_ms) / 1000.0
	var wall_started_ms = Time.get_ticks_msec()
	_key(KEY_SPACE, true)
	while bool(game.buildings[HOLD_INDEX].get("alien_occupied", false)) and Time.get_ticks_msec() - wall_started_ms < 30000:
		await process_frame
	_key(KEY_SPACE, false)
	await _frames(2)
	if not _check(not bool(game.buildings[HOLD_INDEX].get("alien_occupied", false)), "%s could not clear the occupied wall" % kind):
		return {}
	var result = {
		"route": kind,
		"prewall_seconds": prewall_seconds,
		"wall_seconds": float(Time.get_ticks_msec() - wall_started_ms) / 1000.0,
		"total_seconds": float(Time.get_ticks_msec() - branch_started_ms) / 1000.0,
		"world_seconds": game.world_time - start_world_time,
		"support_claimed": game._building_is_controlled_by_freya(SUPPORT_INDEX),
		"assist_count": game._pack_assist_count(HOLD_INDEX),
		"scent_bonus": game._claimed_scent_support(HOLD_INDEX)
	}
	print("TACTICAL_ROUTES_RESULT %s" % JSON.stringify(result))
	return result


func _run() -> void:
	if not await _open_main():
		_finish()
		return
	if not _stage_checkpoint():
		_finish()
		return
	var quick: Dictionary = await _run_branch("quick")
	_release_keys()
	if quick.is_empty() or not failures.is_empty():
		_finish()
		return
	if not await _open_main():
		_finish()
		return
	if not _check(game._restore_game_state(checkpoint), "could not restore the shared checkpoint"):
		_finish()
		return
	_build_navigation()
	if not _assert_checkpoint():
		_finish()
		return
	var prepared: Dictionary = await _run_branch("prepared")
	if not prepared.is_empty():
		_check(not bool(quick.get("support_claimed", true)) and int(quick.get("assist_count", 0)) >= 1 and float(quick.get("scent_bonus", 1.0)) == 0.0, "quick branch did not use only pack assistance")
		_check(bool(prepared.get("support_claimed", false)) and int(prepared.get("assist_count", 1)) == 0 and float(prepared.get("scent_bonus", 0.0)) >= game.FREYA_SCENT_SUPPORT_PER_BUILDING, "prepared branch did not use scent and guarding")
	_finish()
