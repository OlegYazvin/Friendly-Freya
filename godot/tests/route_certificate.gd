extends SceneTree

const RouteCertificateScript = preload("res://scripts/route_certificate.gd")
const SEED = 1
const FALLBACK_SEED = 20260831
var failures: Array[String] = []


func _initialize() -> void:
	set_meta("freya_flow_validation", true)
	create_timer(180.0).timeout.connect(func():
		push_error("ROUTE_CERTIFICATE_FAIL: timeout")
		quit(1)
	)
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("ROUTE_CERTIFICATE: " + message)


func _layout_signature(scene) -> String:
	var parts: Array[String] = [
		str(scene.freya_home_index), str(scene.kennel_building_index),
		str(scene.chapter_target_indices), str(scene.rng.state)
	]
	for building in scene.buildings:
		parts.append("%s:%s:%d" % [str(building.get("footprint", Rect2())), str(building.get("building_type", "")), int(building.get("floors", 0))])
	for service in scene.building_services:
		parts.append("service:%s:%d:%s" % [str(service.get("service_type", "")), int(service.get("building_index", -1)), str(service.get("pos", Vector2.ZERO))])
	for collection in [scene.trees, scene.street_poles, scene.fire_hydrants, scene.mailboxes, scene.dumpsters]:
		for item in collection:
			parts.append(str(item.get("pos", Vector2.ZERO)))
	return "|".join(parts)


func run() -> void:
	OS.set_environment("FREYA_WORLD_SEED", str(SEED))
	OS.set_environment("FREYA_ROUTE_CERT_TEST", "0")
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "uncertified baseline Main load failed")
	await scene_changed
	var baseline = current_scene
	baseline.set_process(false)
	baseline.game_save_incompatible = true
	var baseline_signature = _layout_signature(baseline)
	check(baseline.route_certificate_last_result.is_empty(), "headless baseline unexpectedly ran production certificate")

	OS.set_environment("FREYA_ROUTE_CERT_TEST", "1")
	check(change_scene_to_file("res://scenes/Main.tscn") == OK, "certified Main load failed")
	await scene_changed
	var scene = current_scene
	if scene == null or not scene.has_method("_check_world_route_certificate"):
		check(false, "certified Main did not load")
		quit(1)
		return
	scene.set_process(false)
	scene.game_save_incompatible = true
	check(bool(scene.route_certificate_last_result.get("ok", false)), "seed 1 production certificate rejected a reachable layout")
	check(_layout_signature(scene) == baseline_signature, "accepted certificate changed layout, chapter targets, props, or RNG state")
	check(int(scene.rng.seed) == SEED, "accepted certificate changed world seed")
	check(int(scene.route_certificate_last_result.get("cages", 0)) == 6, "accepted certificate missed lodge cages")
	check(int(scene.route_certificate_last_result.get("service_count", 0)) == 4 and int(scene.route_certificate_last_result.get("services", 0)) == 4, "accepted certificate missed four reachable F services")

	var grocery_index = -1
	for index in range(scene.building_services.size()):
		if str(scene.building_services[index].get("service_type", "")) == "infinite_dog_food":
			grocery_index = index
			break
	check(grocery_index >= 0, "seed 1 has no grocery service for synthetic tests")
	if grocery_index >= 0:
		var service: Dictionary = scene.building_services[grocery_index]
		var before_service_diagnostic = _layout_signature(scene)
		scene.building_services.remove_at(grocery_index)
		var omitted: Dictionary = RouteCertificateScript.evaluate(scene)
		check(not bool(omitted.get("ok", true)) and int(omitted.get("service_count", -1)) == 3 and omitted.get("issues", []).has("service_missing:infinite_dog_food"), "certificate accepted an omitted grocery service")
		scene.building_services.insert(grocery_index, service)
		var position: Vector2 = service.get("pos", Vector2.ZERO)
		var service_blocker = Rect2(position - Vector2(1.6, 1.6), Vector2(3.2, 3.2))
		var blocked: Dictionary = RouteCertificateScript.evaluate(scene, [service_blocker])
		check(not bool(blocked.get("ok", true)) and int(blocked.get("service_count", -1)) == 4 and blocked.get("issues", []).has("service_unreachable:infinite_dog_food"), "certificate accepted a blocked grocery F approach")
		check(_layout_signature(scene) == before_service_diagnostic and int(scene.building_services.size()) == 4, "service diagnostics mutated layout or service records")

	var home_layout: Dictionary = scene.buildings[scene.freya_home_index].get("home_layout", {})
	var home_outside: Vector2 = home_layout.get("entry_outside_pos", Vector2.ZERO)
	var blocker = Rect2(home_outside - Vector2(0.3, 0.3), Vector2(0.6, 0.6))
	var blockers: Array[Rect2] = [blocker]
	var before_diagnostic = _layout_signature(scene)
	check(scene._check_world_route_certificate(true, false, blockers), "legacy-save diagnostic should continue without reroll")
	check(not bool(scene.route_certificate_last_result.get("ok", true)), "synthetic legacy obstruction was not diagnosed")
	check(_layout_signature(scene) == before_diagnostic and int(scene.rng.seed) == SEED, "legacy-save diagnostic mutated world")
	check(not has_meta(scene.ROUTE_CERT_RETRY_META), "legacy-save diagnostic scheduled a fallback")

	check(not scene._check_world_route_certificate(false, false, blockers), "synthetic fresh obstruction did not reject seed")
	check(scene.game_save_incompatible, "rejected fresh seed still permits saving")
	scene.game_save_test_path = "user://friendly_freya_route_certificate_test.json"
	check(not scene._write_game_save(), "rejected fresh seed wrote a save")
	check(has_meta(scene.ROUTE_CERT_RETRY_META), "rejected fresh seed did not schedule fallback")
	await scene_changed
	var recovered = current_scene
	if recovered == null or not recovered.has_method("_check_world_route_certificate"):
		check(false, "fallback Main did not load")
		quit(1)
		return
	recovered.set_process(false)
	recovered.game_save_incompatible = true
	check(int(recovered.rng.seed) == FALLBACK_SEED, "fallback did not use canonical seed")
	check(bool(recovered.route_certificate_last_result.get("ok", false)), "canonical fallback was not certified")
	check(not has_meta(recovered.ROUTE_CERT_RETRY_META), "one-shot fallback metadata survived reload")
	check(recovered.game_resume_pending.is_empty(), "fallback accidentally entered Resume")
	OS.set_environment("FREYA_ROUTE_CERT_TEST", "0")
	OS.set_environment("FREYA_WORLD_SEED", "")
	if failures.is_empty():
		print("ROUTE_CERTIFICATE_OK: accepted seed preserved layout/RNG and four services; omitted/blocked services rejected; legacy diagnostic did not reroll; synthetic fresh obstruction retried once to certified seed")
		quit()
	else:
		push_error("ROUTE_CERTIFICATE_FAIL: %d findings" % failures.size())
		quit(1)
