extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("PACK_SQUAD: " + message)


func _straight_sidewalk(scene) -> Dictionary:
	for xi in range(5, int(scene.MAP_W) - 6):
		for zi in range(5, int(scene.MAP_H) - 6):
			var start = Vector2(float(xi) + 0.5, float(zi) + 0.5)
			if scene.dog_park.grow(1.0).has_point(start):
				continue
			for axis in [Vector2.RIGHT, Vector2.DOWN]:
				var clear = true
				for step in range(9):
					var point = start + axis * float(step) * 0.5
					if scene._surface_at(point) != "sidewalk" or not scene._is_walkable(point.x, point.y, scene.FREYA_COLLISION_RADIUS):
						clear = false
						break
				if clear:
					return {"start": start, "end": start + axis * 4.0}
	return {}


func _test_blocked_guard_route() -> void:
	# In the input route, two active dogs stayed near this point for 30 seconds
	# while the cleared final signal was 23 m away. A normal guard order must
	# navigate around the intervening world collision without moving the dog
	# directly or relying on the route's private save file.
	OS.set_environment("FREYA_WORLD_SEED", "20260831")
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not load blocked-guard seed")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	var start = Vector2(39.46, 7.94)
	var guard = Vector2(62.026, 17.625)
	var footprint: Rect2 = scene.buildings[33].get("footprint", Rect2())
	_check(footprint.position.distance_to(Vector2(62.04, 11.445)) < 0.05, "blocked-guard seed layout changed")
	_check(scene._is_walkable(start.x, start.y, scene.DOG_COLLISION_RADIUS), "blocked-guard start is not walkable")
	_check(scene._is_walkable(guard.x, guard.y, scene.DOG_COLLISION_RADIUS), "blocked-guard guard point is not walkable")
	var selected: Array[int] = []
	for dog_index in range(scene.dogs.size()):
		var state: Dictionary = scene.dogs[dog_index]
		state["army_aligned"] = false
		scene.dogs[dog_index] = state
		if not bool(state.get("park", false)) and selected.size() < 4:
			selected.append(dog_index)
	_check(selected.size() == 4, "blocked-guard seed has fewer than four city dogs")
	if selected.size() < 4 or not failures.is_empty():
		return
	var index: int = selected[0]
	var state: Dictionary = scene.dogs[index]
	var dog: Node3D = state["node"]
	dog.global_position = Vector3(start.x, 0.0, start.y)
	state["army_aligned"] = true
	state["alien_possessed"] = false
	state["flee_timer"] = 0.0
	state["speed"] = 2.0
	state["pack_detour_timer"] = 0.0
	state["pack_route"] = []
	scene.dogs[index] = state
	scene.pack_order = scene.PACK_ORDER_GUARD
	scene.pack_guard_position = guard
	var reached = false
	var arrived_at_guard = false
	var max_update_us = 0
	for step in range(450):
		var update_started_us = Time.get_ticks_usec()
		scene._update_dogs(0.1)
		max_update_us = maxi(max_update_us, Time.get_ticks_usec() - update_started_us)
		var position = Vector2(dog.global_position.x, dog.global_position.z)
		if not reached and scene._point_distance_to_rect(position, footprint) <= scene.PACK_ASSIST_RADIUS:
			reached = true
			print("PACK_SQUAD_PATH_REACHED seconds=%.1f pos=%s route=%d" % [float(step + 1) * 0.1, position, (scene.dogs[index].get("pack_route", []) as Array).size()])
		if position.distance_to(guard) <= 1.65:
			arrived_at_guard = true
			print("PACK_SQUAD_GUARD_ARRIVED seconds=%.1f pos=%s max_update_ms=%.2f" % [float(step + 1) * 0.1, position, float(max_update_us) / 1000.0])
			break
	_check(reached, "active guard dog did not navigate around seed-20260831 blocker: pos=%s" % Vector2(dog.global_position.x, dog.global_position.z))
	_check(arrived_at_guard, "active guard dog did not finish within its reachable 1.6 m arrival radius: pos=%s" % Vector2(dog.global_position.x, dog.global_position.z))
	# A reserve that is already at the cleared signal can finish the guard
	# objective, but does not add an active wall-clearing speed bonus.
	for dog_index in selected.slice(1, 4):
		var ally: Dictionary = scene.dogs[dog_index]
		ally["army_aligned"] = true
		ally["alien_possessed"] = false
		ally["flee_timer"] = 0.0
		ally["node"].global_position = Vector3(start.x, 0.0, start.y) if dog_index != selected[3] else Vector3(guard.x, 0.0, guard.y)
		scene.dogs[dog_index] = ally
	dog.global_position = Vector3(start.x, 0.0, start.y)
	_check(scene._active_pack_dog_indices() == selected.slice(0, 3), "blocked-guard reserve entered the active squad")
	scene.pack_order = scene.PACK_ORDER_ASSIST
	scene.pack_assist_target_index = 33
	_check(scene._pack_assist_count(33) == 0, "blocked-guard reserve added a wall-clearing bonus")
	scene.pack_order = scene.PACK_ORDER_GUARD
	scene.pack_guard_position = guard
	scene.campaign_chapter = 3
	scene.chapter_complete = false
	scene.chapter_assisted_stronghold = false
	scene.chapter_final_stronghold_index = 33
	scene._update_chapter_three_recovery()
	_check(scene.chapter_assisted_stronghold, "clean reserve at cleared final signal did not satisfy guard objective")


func _run() -> void:
	_check(change_scene_to_file("res://scenes/Main.tscn") == OK, "could not load Main")
	await scene_changed
	var scene = current_scene
	scene.set_process(false)
	var selected: Array[int] = []
	for dog_index in range(scene.dogs.size()):
		var state: Dictionary = scene.dogs[dog_index]
		state["army_aligned"] = false
		scene.dogs[dog_index] = state
		if not bool(state.get("park", false)) and selected.size() < 4:
			selected.append(dog_index)
	_check(selected.size() == 4, "fewer than four city dogs")
	var route = _straight_sidewalk(scene)
	_check(not route.is_empty(), "no clear sidewalk route")
	if selected.size() == 4 and not route.is_empty():
		var start: Vector2 = route["start"]
		var destination: Vector2 = route["end"]
		for dog_index in selected:
			var state: Dictionary = scene.dogs[dog_index]
			var dog: Node3D = state["node"]
			dog.global_position = Vector3(start.x, 0.0, start.y)
			state["army_aligned"] = true
			state["alien_possessed"] = false
			state["flee_timer"] = 0.0
			state["speed"] = 2.0
			state["pack_guard_position"] = start
			scene.dogs[dog_index] = state
		scene.freya.global_position = Vector3(destination.x, 0.0, destination.y)
		_check(scene._active_pack_dog_indices() == selected.slice(0, 3), "active squad is not first three eligible dogs")
		scene.pack_order = scene.PACK_ORDER_FOLLOW
		scene._update_dogs(0.2)
		for dog_index in selected.slice(0, 3):
			var dog: Node3D = scene.dogs[dog_index]["node"]
			_check(Vector2(dog.global_position.x, dog.global_position.z).distance_to(start) > 0.05, "active follower did not move: %d" % dog_index)
		var reserve: Node3D = scene.dogs[selected[3]]["node"]
		_check(Vector2(reserve.global_position.x, reserve.global_position.z).distance_to(start) < 0.01, "reserve followed Freya")

		var farthest_index = -1
		var farthest_distance = 0.0
		for building_index in range(scene.buildings.size()):
			var footprint: Rect2 = scene.buildings[building_index]["footprint"]
			var distance = footprint.get_center().distance_to(start)
			if distance > farthest_distance:
				farthest_distance = distance
				farthest_index = building_index
		_check(farthest_index >= 0, "no assist target")
		if farthest_index >= 0:
			scene.pack_order = scene.PACK_ORDER_ASSIST
			scene.pack_assist_target_index = farthest_index
			for dog_index in selected:
				var dog: Node3D = scene.dogs[dog_index]["node"]
				dog.global_position = Vector3(start.x, 0.0, start.y)
			scene._update_dogs(0.2)
			reserve = scene.dogs[selected[3]]["node"]
			_check(Vector2(reserve.global_position.x, reserve.global_position.z).distance_to(start) < 0.01, "reserve moved to assist target")
			for dog_index in selected.slice(0, 3):
				var state: Dictionary = scene.dogs[dog_index]
				_check((state.get("dir", Vector3.ZERO) as Vector3).length() > 0.1, "active assistant did not head for target: %d" % dog_index)

			var center: Vector2 = scene.buildings[farthest_index]["footprint"].get_center()
			for dog_index in [selected[0], selected[1], selected[3]]:
				var dog: Node3D = scene.dogs[dog_index]["node"]
				dog.global_position = Vector3(center.x, 0.0, center.y)
			var third_active: Node3D = scene.dogs[selected[2]]["node"]
			third_active.global_position = Vector3(start.x, 0.0, start.y)
			_check(scene._pack_assist_count(farthest_index) == 2, "reserve counted as active assistant")

		scene.pack_order = scene.PACK_ORDER_FOLLOW
		var reserve_post = Vector3(start.x, 0.0, start.y)
		reserve.global_position = reserve_post
		for dog_index in selected.slice(0, 3):
			var dog: Node3D = scene.dogs[dog_index]["node"]
			dog.global_position = Vector3(destination.x, 0.0, destination.y)
		_check(scene._imp_has_pack_defender(reserve_post), "reserve did not defend its post during follow")
		_check(not scene._imp_has_pack_defender(Vector3(destination.x, 0.0, destination.y)), "active follower defended during follow")

		var saved: Dictionary = scene._snapshot_game_state()
		var reserve_id = str(scene.dogs[selected[3]].get("stable_id", "base:%d" % selected[3]))
		var record: Dictionary = saved.get("collections", {}).get("dogs", {}).get(reserve_id, {})
		_check(record.get("pack_guard_position", []) == [start.x, start.y], "reserve post missing from save")
		var reserve_state: Dictionary = scene.dogs[selected[3]]
		reserve_state["pack_guard_position"] = Vector2.ZERO
		scene.dogs[selected[3]] = reserve_state
		scene._restore_dog_states({reserve_id: record})
		_check(scene.dogs[selected[3]].get("pack_guard_position", Vector2.ZERO) == start, "reserve post not restored")
	await _test_blocked_guard_route()
	if failures.is_empty():
		print("PACK_SQUAD_OK: active three and reserve posts, saved guard, blocked-guard path and reserve final-site recovery")
		quit()
	else:
		push_error("PACK_SQUAD_FAIL: " + ", ".join(failures))
		quit(1)
