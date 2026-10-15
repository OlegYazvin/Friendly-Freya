extends RefCounted

# A save is one self-contained JSON envelope. The payload is a JSON string so
# its SHA-256 covers the exact bytes parsed on load, independent of key order.
const SAVE_PATH = "user://friendly_freya_save.json"
const RESUME_META = "friendly_freya_resume_pending"
const VERSION = 1
const MAX_SAVE_BYTES = 8 * 1024 * 1024


static func point_id(kind: String, position: Vector2) -> String:
	return "%s@%d,%d" % [kind, roundi(position.x * 100.0), roundi(position.y * 100.0)]


static func building_id(footprint: Rect2) -> String:
	return "building@%d,%d,%d,%d" % [
		roundi(footprint.position.x * 100.0),
		roundi(footprint.position.y * 100.0),
		roundi(footprint.size.x * 100.0),
		roundi(footprint.size.y * 100.0)
	]


static func read_save(path: String = SAVE_PATH) -> Dictionary:
	var primary = _read_file(path)
	if bool(primary.get("ok", false)):
		primary["source"] = "primary"
		return primary
	if _is_unsupported_save(primary):
		primary["source"] = "primary"
		return primary
	var backup = _read_file(path + ".bak")
	if bool(backup.get("ok", false)):
		backup["source"] = "backup"
		backup["recovered"] = true
		return backup
	if _is_unsupported_save(backup):
		backup["source"] = "backup"
		return backup
	return {"ok": false, "error": str(primary.get("error", "missing")), "backup_error": str(backup.get("error", "missing"))}


static func has_resume(path: String = SAVE_PATH) -> bool:
	return bool(read_save(path).get("ok", false))


static func inspect_slots(path: String = SAVE_PATH) -> Dictionary:
	# A valid primary can hide an incompatible backup from read_save(), while
	# write_save() correctly refuses to replace either future-version file.
	# Check both slots before offering any route that will need autosave.
	var primary = _read_file(path)
	var backup = _read_file(path + ".bak")
	var primary_error = str(primary.get("error", ""))
	var backup_error = str(backup.get("error", ""))
	var incompatible = _is_unsupported_save(primary) or _is_unsupported_save(backup)
	var newer = false
	for error in [primary_error, backup_error]:
		if error.begins_with("unsupported_version_") and int(error.trim_prefix("unsupported_version_")) > VERSION:
			newer = true
	return {
		"has_files": FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"),
		"has_valid_save": bool(primary.get("ok", false)) or bool(backup.get("ok", false)),
		"incompatible": incompatible,
		"newer": newer
	}


static func write_save(state: Dictionary, path: String = SAVE_PATH) -> bool:
	var normalized = _normalize_state(state)
	if not bool(normalized.get("ok", false)):
		push_warning("Game save rejected: %s" % str(normalized.get("error", "invalid state")))
		return false
	# A valid save from another schema version may contain newer progress. Keep
	# both slots untouched until that version can read or migrate it.
	if _is_unsupported_save(_read_file(path)) or _is_unsupported_save(_read_file(path + ".bak")):
		push_warning("Game save blocked: an incompatible save version is already present")
		return false
	var payload = JSON.stringify(normalized["state"])
	var digest = _sha256(payload)
	var envelope = JSON.stringify({"format": "friendly_freya", "payload": payload, "sha256": digest})
	if envelope.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return false
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(envelope)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or not bool(_read_file(temporary).get("ok", false)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false

	var global_path = ProjectSettings.globalize_path(path)
	var global_backup = ProjectSettings.globalize_path(path + ".bak")
	var global_temporary = ProjectSettings.globalize_path(temporary)
	var old_primary_valid = bool(_read_file(path).get("ok", false))
	var moved_primary = false
	if old_primary_valid:
		if FileAccess.file_exists(path + ".bak"):
			if DirAccess.remove_absolute(global_backup) != OK:
				DirAccess.remove_absolute(global_temporary)
				return false
		if DirAccess.rename_absolute(global_path, global_backup) != OK:
			DirAccess.remove_absolute(global_temporary)
			return false
		moved_primary = true
	elif FileAccess.file_exists(path):
		# A corrupt primary is never promoted over a known-good backup.
		if DirAccess.remove_absolute(global_path) != OK:
			DirAccess.remove_absolute(global_temporary)
			return false
	if DirAccess.rename_absolute(global_temporary, global_path) == OK:
		return true
	if moved_primary:
		DirAccess.rename_absolute(global_backup, global_path)
	DirAccess.remove_absolute(global_temporary)
	return false


static func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "missing"}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "unreadable"}
	if file.get_length() <= 0 or file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return {"ok": false, "error": "invalid_size"}
	var content = file.get_as_text()
	file.close()
	var parser = JSON.new()
	if parser.parse(content) != OK:
		return {"ok": false, "error": "invalid_json"}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {"ok": false, "error": "invalid_json"}
	var envelope: Dictionary = parsed
	if str(envelope.get("format", "")) != "friendly_freya":
		return {"ok": false, "error": "unknown_format"}
	var payload = envelope.get("payload", null)
	if not payload is String or str(envelope.get("sha256", "")) != _sha256(payload):
		return {"ok": false, "error": "checksum"}
	if parser.parse(payload) != OK:
		return {"ok": false, "error": "invalid_payload"}
	var state = parser.data
	if not state is Dictionary:
		return {"ok": false, "error": "invalid_payload"}
	return _normalize_state(state)


static func _normalize_state(value: Dictionary) -> Dictionary:
	var state = value.duplicate(true)
	var version = int(state.get("version", -1))
	if version == 0:
		# The first private save prototype had no campaign or kennel section. Only
		# those optional sections receive defaults; its world state remains intact.
		state["version"] = VERSION
		state["campaign"] = state.get("campaign", {})
		state["kennel"] = state.get("kennel", {})
		state["story"] = state.get("story", {})
	elif version != VERSION:
		return {"ok": false, "error": "unsupported_version_%d" % version}
	if not state.get("world_seed", null) is String or not str(state["world_seed"]).is_valid_int():
		return {"ok": false, "error": "invalid_seed"}
	for section in ["player", "story", "campaign", "kennel", "collections"]:
		if not state.get(section, null) is Dictionary:
			return {"ok": false, "error": "invalid_%s" % section}
	var collections: Dictionary = state["collections"]
	for category in ["buildings", "trees", "street_poles", "fire_hydrants", "mailboxes", "dogs"]:
		if not collections.get(category, null) is Dictionary:
			return {"ok": false, "error": "invalid_%s" % category}
	var player: Dictionary = state["player"]
	var position = player.get("position", null)
	if not position is Array or position.size() != 2:
		return {"ok": false, "error": "invalid_player_position"}
	for coordinate in position:
		if not coordinate is float and not coordinate is int:
			return {"ok": false, "error": "invalid_player_position"}
		if not is_finite(float(coordinate)) or absf(float(coordinate)) > 10000.0:
			return {"ok": false, "error": "invalid_player_position"}
	return {"ok": true, "state": state}


static func _is_unsupported_save(result: Dictionary) -> bool:
	return str(result.get("error", "")).begins_with("unsupported_version_")


static func _sha256(content: String) -> String:
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(content.to_utf8_buffer())
	return context.finish().hex_encode()
