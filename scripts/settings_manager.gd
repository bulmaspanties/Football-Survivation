extends Node

signal settings_changed
signal palette_changed
signal text_size_changed

const DEFAULT_VOLUME := 1.0

enum TextSize { SMALL = 0, NORMAL = 1, LARGE = 2 }
const TEXT_SIZE_NAMES: Array[String] = ["Small", "Normal", "Large"]
const TEXT_SIZE_SCALES: Array[float] = [0.88, 1.0, 1.15]

const REMAPPABLE_ACTIONS: Array[String] = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"pause_game",
	"audible_ability",
]

const ACTION_DISPLAY_NAMES := {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"pause_game": "Pause",
	"audible_ability": "Call Audible",
}

const DEFAULT_KEY_BINDINGS := {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"pause_game": KEY_ESCAPE,
	"audible_ability": KEY_SPACE,
}

const PALETTES := {
	"default": {
		"player_quarterback": Color(0.18, 0.35, 0.68, 1.0),
		"player_running_back": Color(0.2, 0.65, 0.35, 1.0),
		"player_linebacker": Color(0.68, 0.2, 0.25, 1.0),
		"enemy_defender": Color(0.9, 0.23, 0.25, 1.0),
		"enemy_runner": Color(0.98, 0.52, 0.16, 1.0),
		"enemy_thrower": Color(0.68, 0.18, 0.38, 1.0),
		"enemy_blocker": Color(0.28, 0.42, 0.56, 1.0),
		"enemy_support": Color(0.22, 0.78, 0.32, 1.0),
		"enemy_referee": Color(0.92, 0.92, 0.92, 1.0),
		"penalty_zone": Color(1.0, 0.85, 0.2, 0.85),
		"enemy_boss": Color(0.58, 0.12, 0.18, 1.0),
		"enemy_boss_border": Color(1.0, 0.82, 0.25, 1.0),
		"xp_pickup": Color(0.45, 0.95, 0.55, 1.0),
		"enemy_projectile": Color(0.78, 0.2, 0.12, 1.0),
		"enemy_telegraph": Color(1.0, 0.5, 0.2, 0.8),
		"hud_health": Color(0.82, 0.96, 0.86, 1.0),
		"hud_xp": Color(0.7, 1.0, 0.75, 1.0),
	},
	"colorblind": {
		"player_quarterback": Color(0.12, 0.45, 0.95, 1.0),
		"player_running_back": Color(0.95, 0.75, 0.12, 1.0),
		"player_linebacker": Color(0.75, 0.2, 0.85, 1.0),
		"enemy_defender": Color(0.95, 0.45, 0.1, 1.0),
		"enemy_runner": Color(0.98, 0.88, 0.2, 1.0),
		"enemy_thrower": Color(0.5, 0.2, 0.85, 1.0),
		"enemy_blocker": Color(0.15, 0.65, 0.75, 1.0),
		"enemy_support": Color(0.2, 0.85, 0.95, 1.0),
		"enemy_referee": Color(0.96, 0.96, 0.96, 1.0),
		"penalty_zone": Color(0.95, 0.9, 0.25, 0.9),
		"enemy_boss": Color(0.9, 0.15, 0.65, 1.0),
		"enemy_boss_border": Color(1.0, 0.92, 0.3, 1.0),
		"xp_pickup": Color(0.98, 0.85, 0.2, 1.0),
		"enemy_projectile": Color(0.95, 0.2, 0.65, 1.0),
		"enemy_telegraph": Color(1.0, 0.85, 0.2, 0.9),
		"hud_health": Color(0.4, 0.85, 1.0, 1.0),
		"hud_xp": Color(1.0, 0.9, 0.35, 1.0),
	}
}

var master_volume := DEFAULT_VOLUME
var muted := false
var fullscreen := false
var vibration_enabled := true
var colorblind_mode := false
var text_size: int = TextSize.NORMAL

var key_bindings: Dictionary = {}

func _ready() -> void:
	key_bindings = DEFAULT_KEY_BINDINGS.duplicate()
	_apply_audio()
	_apply_display()
	_apply_input_mappings()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	settings_changed.emit()

func set_muted(value: bool) -> void:
	muted = value
	_apply_audio()
	settings_changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	settings_changed.emit()

func set_vibration_enabled(value: bool) -> void:
	vibration_enabled = value
	if not vibration_enabled:
		stop_rumble()
	settings_changed.emit()

func rumble(weak: float = 0.3, strong: float = 0.5, duration: float = 0.15) -> void:
	if not vibration_enabled:
		return
	Input.start_joy_vibration(0, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), maxf(duration, 0.01))

func stop_rumble() -> void:
	Input.stop_joy_vibration(0)

func set_colorblind_mode(value: bool) -> void:
	colorblind_mode = value
	palette_changed.emit()
	settings_changed.emit()

func get_color(key: String, fallback: Color = Color.WHITE) -> Color:
	var mode_key := "colorblind" if colorblind_mode else "default"
	var palette: Dictionary = PALETTES.get(mode_key, PALETTES["default"])
	return palette.get(key, fallback)

func get_character_color(character_id: String, fallback: Color = Color.WHITE) -> Color:
	return get_color("player_" + character_id, fallback)

func set_text_size(value: int) -> void:
	text_size = clampi(value, 0, TextSize.LARGE)
	text_size_changed.emit()
	settings_changed.emit()

func cycle_text_size() -> void:
	set_text_size((text_size + 1) % 3)

func get_text_size_name() -> String:
	return TEXT_SIZE_NAMES[text_size]

func get_text_scale() -> float:
	return TEXT_SIZE_SCALES[text_size]

func get_action_display_name(action_name: String) -> String:
	return ACTION_DISPLAY_NAMES.get(action_name, action_name)

func get_primary_key(action_name: String) -> Key:
	return key_bindings.get(action_name, KEY_NONE) as Key

func get_key_label(action_name: String) -> String:
	var keycode: Key = get_primary_key(action_name)
	if keycode == KEY_NONE:
		return "None"
	return OS.get_keycode_string(keycode)

func get_key_bound_action(keycode: Key) -> String:
	for action in REMAPPABLE_ACTIONS:
		if get_primary_key(action) == keycode:
			return action
	return ""

func rebind_key(action_name: String, new_keycode: Key) -> Dictionary:
	if not REMAPPABLE_ACTIONS.has(action_name):
		return {"success": false, "error": "Unknown action: %s" % action_name}
	if new_keycode == KEY_NONE or new_keycode == 0:
		return {"success": false, "error": "Invalid key pressed."}

	var conflict := get_key_bound_action(new_keycode)
	if conflict != "" and conflict != action_name:
		return {
			"success": false,
			"error": "Key '%s' is already bound to %s." % [OS.get_keycode_string(new_keycode), get_action_display_name(conflict)]
		}

	key_bindings[action_name] = new_keycode
	_apply_input_mappings()
	settings_changed.emit()
	return {"success": true, "error": ""}

func reset_key_bindings() -> void:
	key_bindings = DEFAULT_KEY_BINDINGS.duplicate()
	_apply_input_mappings()
	settings_changed.emit()

func reset_defaults() -> void:
	master_volume = DEFAULT_VOLUME
	muted = false
	fullscreen = false
	vibration_enabled = true
	colorblind_mode = false
	text_size = TextSize.NORMAL
	reset_key_bindings()
	_apply_audio()
	_apply_display()
	palette_changed.emit()
	text_size_changed.emit()
	settings_changed.emit()

func _apply_audio() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master_bus, muted)

func _apply_display() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _apply_input_mappings() -> void:
	for action in REMAPPABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var preserved_events: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if not (event is InputEventKey):
				preserved_events.append(event)
		InputMap.action_erase_events(action)
		for event in preserved_events:
			InputMap.action_add_event(action, event)

		var primary: Key = get_primary_key(action)
		if primary != KEY_NONE:
			var k1 := InputEventKey.new()
			k1.physical_keycode = primary
			k1.keycode = primary
			InputMap.action_add_event(action, k1)

		var secondary: Key = KEY_NONE
		if primary == DEFAULT_KEY_BINDINGS.get(action, KEY_NONE):
			match action:
				"move_up": secondary = KEY_UP
				"move_down": secondary = KEY_DOWN
				"move_left": secondary = KEY_LEFT
				"move_right": secondary = KEY_RIGHT
				"pause_game": secondary = KEY_P
		if secondary != KEY_NONE and secondary != primary:
			var k2 := InputEventKey.new()
			k2.physical_keycode = secondary
			k2.keycode = secondary
			InputMap.action_add_event(action, k2)
