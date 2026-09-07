extends RefCounted

const SETTINGS_PATH = "user://friendly_freya_settings.cfg"
const SECTION_AUDIO = "audio"
const KEY_MASTER_VOLUME = "master_volume"
const DEFAULT_MASTER_VOLUME = 0.85


static func load_master_volume() -> float:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_PATH)
	if error != OK:
		return DEFAULT_MASTER_VOLUME
	return clampf(float(config.get_value(SECTION_AUDIO, KEY_MASTER_VOLUME, DEFAULT_MASTER_VOLUME)), 0.0, 1.0)


static func save_master_volume(volume: float) -> void:
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION_AUDIO, KEY_MASTER_VOLUME, clampf(volume, 0.0, 1.0))
	config.save(SETTINGS_PATH)


static func apply_master_volume(volume: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	var clamped = clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, clamped <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(clamped, 0.001)))


static func load_and_apply_master_volume() -> float:
	var volume = load_master_volume()
	apply_master_volume(volume)
	return volume


static func display_percent(volume: float) -> String:
	return "%d%%" % int(round(clampf(volume, 0.0, 1.0) * 100.0))
