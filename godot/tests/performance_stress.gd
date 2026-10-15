extends SceneTree

# Graphical production-scene stress sample. Run without FREYA_PERF_BENCHMARK:
#   FREYA_WORLD_SEED=20260831 flatpak run org.godotengine.Godot \
#     --path godot --script res://tests/performance_stress.gd
# The live Main._process loop continues throughout the sample.

const WARMUP_SECONDS := 15.0
const SAMPLE_SECONDS := 135.0
const REPORT_SECONDS := 5.0

class ProcessMarker:
	extends Node
	var callback: Callable

	func _process(_delta: float) -> void:
		callback.call()

var warmup_seconds := WARMUP_SECONDS
var sample_seconds := SAMPLE_SECONDS
var frame_ms: Array[float] = []
var window_frames := 0
var window_start_usec := 0
var window_process_ms := 0.0
var game_process_start_usec := 0
var game_process_total_usec := 0
var game_process_frames := 0
var total_game_process_usec := 0
var total_game_process_frames := 0
var window_min_fps := INF
var window_max_fps := 0.0
var memory_start_mb := 0.0
var memory_end_mb := 0.0
var memory_peak_mb := 0.0
var rss_start_mb := 0.0
var rss_end_mb := 0.0
var rss_peak_mb := 0.0
var initial_world_time := 0.0
var initial_kennel_spawns := 0
var initial_dog_count := 0
var initial_freya_position := Vector3.ZERO
var furthest_freya_distance := 0.0
var recruited_count := 0
var occupied_store_count := 0


func _initialize() -> void:
	var requested_warmup := OS.get_environment("FREYA_PERF_STRESS_WARMUP_SECONDS")
	if requested_warmup.is_valid_float():
		warmup_seconds = maxf(0.0, float(requested_warmup))
	var requested_sample := OS.get_environment("FREYA_PERF_STRESS_SAMPLE_SECONDS")
	if requested_sample.is_valid_float():
		sample_seconds = maxf(1.0, float(requested_sample))
	call_deferred("_run")


func _memory_mb() -> float:
	return float(OS.get_static_memory_usage()) / 1048576.0


func _rss_mb() -> float:
	# procfs files often report a zero length. Stream lines rather than using
	# get_file_as_string(), which can return an empty string for /proc/self/status.
	var status := FileAccess.open("/proc/self/status", FileAccess.READ)
	if status == null:
		return -1.0
	for line_index in range(128):
		if status.eof_reached():
			break
		var line := status.get_line()
		if line.begins_with("VmRSS:"):
			var value := line.substr(6).strip_edges().split(" ", false)
			if not value.is_empty() and value[0].is_valid_int():
				return float(int(value[0])) / 1024.0
	return -1.0


func _set_movement(phase: int) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if phase % 2 == 0:
		Input.action_press("move_left")
	else:
		Input.action_press("move_right")


func _stop_movement() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")


func _mark_game_process_start() -> void:
	game_process_start_usec = Time.get_ticks_usec()


func _mark_game_process_end() -> void:
	if game_process_start_usec <= 0:
		return
	var elapsed_usec := Time.get_ticks_usec() - game_process_start_usec
	game_process_total_usec += elapsed_usec
	game_process_frames += 1
	total_game_process_usec += elapsed_usec
	total_game_process_frames += 1


func _stage(scene) -> bool:
	if scene.kennel == null or not scene.kennel.possessed:
		push_error("PERF_STRESS: live possessed kennel is missing")
		return false
	# The skipped-intro meal hint and first dog warning are presentation gates.
	# Complete the hint and acknowledge the warning so the normal update loop runs.
	scene._complete_post_intro_meal_tutorial()
	scene.possessed_dog_tutorial_seen = true
	scene.game_autosave_timer = 1000000.0
	for store_index in scene.store_building_indices:
		if not bool(scene.buildings[store_index].get("alien_occupied", false)):
			if not scene._occupy_building_with_alien(store_index, 8000 + store_index):
				continue
		var store: Dictionary = scene.buildings[store_index]
		store["alien_spawn_cooldown"] = 0.0
		scene.buildings[store_index] = store
		occupied_store_count += 1
	if occupied_store_count < 2:
		push_error("PERF_STRESS: fewer than two occupied storefront generators")
		return false
	var store_index: int = scene.store_building_indices[0]
	var target: Dictionary = scene.buildings[store_index]
	var footprint: Rect2 = target.get("footprint", Rect2())
	var center: Vector2 = footprint.get_center()
	var layout: Dictionary = target.get("store_layout", {})
	var entry: Vector2 = layout.get("entry_outside_pos", center)
	var outward: Vector2 = (entry - center).normalized()
	if outward.length_squared() < 0.001:
		outward = Vector2.DOWN if bool(target.get("front_is_south", true)) else Vector2.UP
	var start: Vector2 = entry + outward * 6.0
	if not scene._is_walkable(start.x, start.y, scene.FREYA_COLLISION_RADIUS):
		start = entry + outward * 4.0
	if not scene._is_walkable(start.x, start.y, scene.FREYA_COLLISION_RADIUS):
		push_error("PERF_STRESS: no walkable storefront start")
		return false
	scene.freya.global_position = Vector3(start.x, 0.0, start.y)
	scene.camera_orbit_angle = 0.0 if outward.y > 0.0 else PI
	scene.camera_zoom_target = 12.0
	scene.camera_planar_distance = 12.0
	scene.pack_order = scene.PACK_ORDER_FOLLOW
	for dog_index in range(scene.dogs.size()):
		var state: Dictionary = scene.dogs[dog_index]
		var dog: Node3D = state.get("node", null)
		if dog == null or not is_instance_valid(dog):
			continue
		# Every base NPC starts possessed. Stage the late-game roster after
		# de-possession and recruitment, leaving the normal pack AI active.
		state["alien_possessed"] = false
		state["alien_expelled"] = true
		state["army_aligned"] = true
		state["pack_guard_position"] = Vector2(dog.global_position.x, dog.global_position.z)
		if recruited_count < scene.PACK_MAX_ACTIVE_ASSISTANTS:
			var side := float(recruited_count - 1)
			var dog_spot: Vector2 = start + Vector2(side * 1.35, outward.y * 1.65)
			if scene._is_walkable(dog_spot.x, dog_spot.y, scene.DOG_COLLISION_RADIUS):
				dog.global_position = Vector3(dog_spot.x, 0.0, dog_spot.y)
		state["pack_guard_position"] = Vector2(dog.global_position.x, dog.global_position.z)
		if dog.has_method("set_army_aligned"):
			dog.call("set_army_aligned", true)
		scene.dogs[dog_index] = state
		recruited_count += 1
	if recruited_count <= scene.PACK_MAX_ACTIVE_ASSISTANTS:
		push_error("PERF_STRESS: roster does not exceed the active squad cap")
		return false
	scene._update_camera(0.0)
	var hide_lane_dashes := OS.get_environment("FREYA_PERF_STRESS_HIDE_LANE_DASHES") == "1"
	var traffic_controls: Node = scene.static_root.get_node_or_null("TrafficControls")
	if traffic_controls == null:
		push_error("PERF_STRESS: traffic controls are missing")
		return false
	var lane_dashes_seen := 0
	var lane_dashes_hidden := 0
	for child in traffic_controls.get_children():
		if not (child is MeshInstance3D) or not str(child.name).begins_with("CenterYellowLaneDash"):
			continue
		lane_dashes_seen += 1
		if hide_lane_dashes:
			(child as MeshInstance3D).visible = false
			lane_dashes_hidden += 1
	if lane_dashes_seen != scene.road_centerline_mark_count or (hide_lane_dashes and lane_dashes_hidden != lane_dashes_seen):
		push_error("PERF_STRESS: lane-dash count mismatch: seen=%d hidden=%d expected=%d" % [
			lane_dashes_seen, lane_dashes_hidden, scene.road_centerline_mark_count
		])
		return false
	print("PERF_STRESS_VARIANT hide_lane_dashes=%s hidden_lane_dashes=%d total_lane_dashes=%d" % [
		"1" if hide_lane_dashes else "0", lane_dashes_hidden, lane_dashes_seen
	])
	initial_world_time = scene.world_time
	initial_kennel_spawns = scene.kennel.total_possessed_dogs_spawned
	initial_dog_count = scene.dogs.size()
	initial_freya_position = scene.freya.global_position
	print("PERF_STRESS_START pid=%d seed=%s renderer=%s dogs=%d recruited=%d active=%d stores=%d kennel=%d free_aliens=%d" % [
		OS.get_process_id(), OS.get_environment("FREYA_WORLD_SEED"), RenderingServer.get_current_rendering_method(),
		scene.dogs.size(), recruited_count, scene._active_pack_dog_indices().size(), occupied_store_count,
		scene.kennel.total_possessed_dogs_spawned, scene.free_aliens.size()
	])
	return true


func _report(scene, elapsed: float, fps: float) -> void:
	var memory_mb := _memory_mb()
	var rss_mb := _rss_mb()
	memory_end_mb = memory_mb
	memory_peak_mb = maxf(memory_peak_mb, memory_mb)
	rss_end_mb = rss_mb
	rss_peak_mb = maxf(rss_peak_mb, rss_mb)
	window_min_fps = minf(window_min_fps, fps)
	window_max_fps = maxf(window_max_fps, fps)
	var active: int = scene._active_pack_dog_indices().size()
	var freya_distance: float = scene.freya.global_position.distance_to(initial_freya_position)
	furthest_freya_distance = maxf(furthest_freya_distance, freya_distance)
	print("PERF_STRESS_WINDOW t=%.1f fps=%.1f game_process_ms=%.2f monitor_ms=%.2f mem_mb=%.1f rss_mb=%.1f nodes=%d draw_calls=%d world=%.1f dogs=%d recruited=%d active=%d free_aliens=%d kennel_spawns=%d freya_distance=%.2f" % [
		elapsed, fps, float(game_process_total_usec) / maxf(1.0, float(game_process_frames)) / 1000.0,
		window_process_ms / maxf(1.0, float(window_frames)), memory_mb, rss_mb,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		scene.world_time, scene.dogs.size(), scene._chapter_real_ally_count(),
		active, scene.free_aliens.size(), scene.kennel.total_possessed_dogs_spawned, freya_distance
	])


func _run() -> void:
	if OS.get_environment("FREYA_PERF_BENCHMARK") == "1":
		push_error("PERF_STRESS: FREYA_PERF_BENCHMARK must be unset")
		quit(1)
		return
	if change_scene_to_file("res://scenes/Main.tscn") != OK:
		push_error("PERF_STRESS: could not load Main")
		quit(1)
		return
	await scene_changed
	var scene = current_scene
	if not _stage(scene):
		quit(1)
		return
	var start_marker := ProcessMarker.new()
	start_marker.process_priority = -1000
	start_marker.callback = Callable(self, "_mark_game_process_start")
	scene.add_child(start_marker)
	var end_marker := ProcessMarker.new()
	end_marker.process_priority = 1000
	end_marker.callback = Callable(self, "_mark_game_process_end")
	scene.add_child(end_marker)
	var warmup_start := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - warmup_start) / 1000000.0 < warmup_seconds:
		await process_frame
		if scene.possessed_dog_tutorial_active:
			scene._dismiss_possessed_dog_tutorial()
	print("PERF_STRESS_WARMUP_DONE world=%.1f dogs=%d free_aliens=%d kennel_spawns=%d" % [
		scene.world_time, scene.dogs.size(), scene.free_aliens.size(), scene.kennel.total_possessed_dogs_spawned
	])
	memory_start_mb = _memory_mb()
	memory_peak_mb = memory_start_mb
	rss_start_mb = _rss_mb()
	rss_peak_mb = rss_start_mb
	game_process_total_usec = 0
	game_process_frames = 0
	total_game_process_usec = 0
	total_game_process_frames = 0
	# Keep profiled categories on the same sample window as the frame counters.
	scene.perf_profile_usec.clear()
	scene.perf_profile_frames = 0
	var start_usec := Time.get_ticks_usec()
	var previous_usec := start_usec
	window_start_usec = start_usec
	var previous_phase := -1
	while true:
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var elapsed := float(now_usec - start_usec) / 1000000.0
		var duration_ms := float(now_usec - previous_usec) / 1000.0
		previous_usec = now_usec
		frame_ms.append(duration_ms)
		window_frames += 1
		window_process_ms += float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
		var phase := int(elapsed / 1.5)
		if phase != previous_phase:
			_set_movement(phase)
			previous_phase = phase
		if scene.possessed_dog_tutorial_active:
			scene._dismiss_possessed_dog_tutorial()
		if float(now_usec - window_start_usec) / 1000000.0 >= REPORT_SECONDS:
			var seconds := float(now_usec - window_start_usec) / 1000000.0
			_report(scene, elapsed, float(window_frames) / seconds)
			window_frames = 0
			window_process_ms = 0.0
			game_process_total_usec = 0
			game_process_frames = 0
			window_start_usec = now_usec
		if elapsed >= sample_seconds:
			break
	_stop_movement()
	frame_ms.sort()
	var count := frame_ms.size()
	var elapsed_seconds := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var p95_ms: float = frame_ms[clampi(int(ceil(float(count) * 0.95)) - 1, 0, count - 1)]
	var p99_ms: float = frame_ms[clampi(int(ceil(float(count) * 0.99)) - 1, 0, count - 1)]
	print("PERF_STRESS_RESULT seconds=%.1f avg_fps=%.1f game_process_ms=%.2f min_5s_fps=%.1f max_5s_fps=%.1f p95_frame_ms=%.1f p99_frame_ms=%.1f p1_fps=%.1f mem_start_mb=%.1f mem_end_mb=%.1f mem_peak_mb=%.1f rss_start_mb=%.1f rss_end_mb=%.1f rss_peak_mb=%.1f world_advanced=%.1f kennel_spawns=%d dog_growth=%d furthest_freya_m=%.2f" % [
		elapsed_seconds, float(count) / elapsed_seconds,
		float(total_game_process_usec) / maxf(1.0, float(total_game_process_frames)) / 1000.0,
		window_min_fps, window_max_fps, p95_ms, p99_ms,
		1000.0 / maxf(p99_ms, 0.001), memory_start_mb, memory_end_mb, memory_peak_mb,
		rss_start_mb, rss_end_mb, rss_peak_mb,
		scene.world_time - initial_world_time,
		scene.kennel.total_possessed_dogs_spawned - initial_kennel_spawns,
		scene.dogs.size() - initial_dog_count, furthest_freya_distance
	])
	if OS.get_environment("FREYA_PERF_PROFILE_GAMEPLAY") == "1":
		for category in scene.perf_profile_usec.keys():
			print("PERF_STRESS_PROFILE category=%s ms_per_frame=%.3f" % [
				category, float(scene.perf_profile_usec[category]) / maxf(1.0, float(total_game_process_frames)) / 1000.0
			])
	if scene.world_time - initial_world_time < warmup_seconds + sample_seconds - 10.0:
		push_error("PERF_STRESS: live gameplay world did not advance")
		quit(1)
		return
	if warmup_seconds + sample_seconds >= 55.0 and scene.kennel.total_possessed_dogs_spawned - initial_kennel_spawns < 6:
		push_error("PERF_STRESS: kennel production did not reach its finite cap")
		quit(1)
		return
	if furthest_freya_distance < 0.5:
		push_error("PERF_STRESS: movement input did not move Freya")
		quit(1)
		return
	if furthest_freya_distance > 10.0:
		push_error("PERF_STRESS: player drifted away from occupied storefront")
		quit(1)
		return
	quit()
