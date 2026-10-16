extends RefCounted

const SETTINGS_PATH = "user://friendly_freya_settings.cfg"
const SECTION_CONTROLS = "controls"
const KEY_PRESS_TO_CONTINUE = "press_to_continue"


static func load_press_to_continue(path: String = SETTINGS_PATH) -> bool:
	var config = ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(SECTION_CONTROLS, KEY_PRESS_TO_CONTINUE, false))


static func save_press_to_continue(enabled: bool, path: String = SETTINGS_PATH) -> bool:
	var config = ConfigFile.new()
	config.load(path)
	config.set_value(SECTION_CONTROLS, KEY_PRESS_TO_CONTINUE, enabled)
	return config.save(path) == OK
