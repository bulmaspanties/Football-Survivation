extends Node

const SLOT_COUNT := 3
const PROFILE_PATH := "user://football_survivation_profiles.json"

var selected_slot := -1
var profile_selection_requested := true
var profiles: Array[Dictionary] = []

const META_UPGRADES := [
	{"id": "iron_body", "label": "Goal Line Body: +20 starting max health", "cost": 50},
	{"id": "speed_training", "label": "Combine Speed: +30 starting movement speed", "cost": 50},
	{"id": "passing_game", "label": "Passing Game: +8 starting football damage", "cost": 75},
	{"id": "tackle_signing", "label": "Two-Way Signing: start with Tackle Burst unlocked", "cost": 100},
	{"id": "hail_mary_scout", "label": "Deep Threat Scout: start with Hail Mary unlocked", "cost": 120},
	{"id": "extra_muscle", "label": "Extra Muscle: +10 starting Tackle Burst & Stiff Arm damage", "cost": 70},
	{"id": "film_study", "label": "Film Study: +15% XP gained", "cost": 90},
	{"id": "unlock_running_back", "label": "Sign Running Back (playable character)", "cost": 70},
	{"id": "unlock_linebacker", "label": "Sign Linebacker (playable character)", "cost": 90},
	{"id": "unlock_bluegrass_field", "label": "Bluegrass Turf (arena theme unlock)", "cost": 80},
]

const STARTING_CHARACTER_ID := "quarterback"
const STARTING_MAP_ID := "classic_field"

const MAPS := [
	{
		"id": "classic_field",
		"label": "Classic Field",
		"unlock_id": "",
		"blurb": "Traditional green turf stadium with standard yard markings and gold end zones.",
		"turf_color": Color(0.06, 0.34, 0.16, 1.0),
		"end_zone_color": Color(0.04, 0.25, 0.13, 1.0),
		"sideline_color": Color(1.0, 0.82, 0.3, 0.9),
		"goalpost_color": Color(1.0, 0.86, 0.35, 1.0),
		"yard_line_color": Color(0.75, 0.95, 0.73, 0.72),
		"boundary_color": Color(0.92, 0.97, 0.86, 1.0),
		"center_mark_color": Color(0.9, 0.98, 0.84, 0.9),
		"crowd_color": Color(0.15, 0.19, 0.27, 0.9),
		"end_zone_label_color": Color(1.0, 0.82, 0.35, 0.8),
	},
	{
		"id": "bluegrass_field",
		"label": "Bluegrass Field",
		"unlock_id": "unlock_bluegrass_field",
		"blurb": "Vibrant royal bluegrass field with ice-blue yard lines and golden sidelines.",
		"turf_color": Color(0.08, 0.22, 0.42, 1.0),
		"end_zone_color": Color(0.05, 0.15, 0.32, 1.0),
		"sideline_color": Color(0.95, 0.85, 0.35, 0.9),
		"goalpost_color": Color(1.0, 0.9, 0.45, 1.0),
		"yard_line_color": Color(0.65, 0.88, 0.98, 0.75),
		"boundary_color": Color(0.9, 0.95, 1.0, 1.0),
		"center_mark_color": Color(0.85, 0.95, 1.0, 0.9),
		"crowd_color": Color(0.12, 0.16, 0.25, 0.9),
		"end_zone_label_color": Color(1.0, 0.88, 0.4, 0.85),
	},
]

const CHARACTERS := [
	{
		"id": "quarterback",
		"label": "Quarterback",
		"tag": "QB",
		"unlock_id": "",
		"color": Color(0.12, 0.72, 0.95, 1),
		"blurb": "Balanced all-around playmaker. No stat changes.",
		"health_bonus": 0.0,
		"speed_bonus": 0.0,
		"football_damage_bonus": 0.0,
		"tackle_damage_bonus": 0.0,
		"stiff_arm_damage_bonus": 0.0,
	},
	{
		"id": "running_back",
		"label": "Running Back",
		"tag": "RB",
		"unlock_id": "unlock_running_back",
		"color": Color(0.95, 0.62, 0.12, 1),
		"blurb": "+40 speed, -15 max health. Elusive playmaker built for evasion.",
		"health_bonus": -15.0,
		"speed_bonus": 40.0,
		"football_damage_bonus": 0.0,
		"tackle_damage_bonus": 0.0,
		"stiff_arm_damage_bonus": 0.0,
	},
	{
		"id": "linebacker",
		"label": "Linebacker",
		"tag": "LB",
		"unlock_id": "unlock_linebacker",
		"color": Color(0.75, 0.18, 0.2, 1),
		"blurb": "+30 max health, -20 speed, +8 Tackle Burst & Stiff Arm damage. Built to punish contact.",
		"health_bonus": 30.0,
		"speed_bonus": -20.0,
		"football_damage_bonus": 0.0,
		"tackle_damage_bonus": 8.0,
		"stiff_arm_damage_bonus": 8.0,
	},
]

func _ready() -> void:
	_load_profiles()

func select_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= SLOT_COUNT:
		return {}
	selected_slot = slot
	profile_selection_requested = false
	var profile := profiles[slot]
	if profile.is_empty():
		profile = _new_profile()
		profiles[slot] = profile
		_save_profiles()
	return profile

func mark_played() -> void:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return
	profiles[selected_slot]["last_played"] = Time.get_datetime_string_from_system()
	_save_profiles()

func currency() -> int:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return 0
	return int(profiles[selected_slot].get("permanent_currency", 0))

func add_currency(amount: int) -> void:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT or amount <= 0:
		return
	profiles[selected_slot]["permanent_currency"] = currency() + amount
	_save_profiles()

func is_pro_difficulty() -> bool:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return false
	return bool(profiles[selected_slot].get("pro_difficulty", false))

func set_pro_difficulty(enabled: bool) -> void:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return
	profiles[selected_slot]["pro_difficulty"] = enabled
	_save_profiles()

func character_data(character_id: String) -> Dictionary:
	for character in CHARACTERS:
		if character["id"] == character_id:
			return character
	return {}

func character_unlock_cost(character_id: String) -> int:
	var character := character_data(character_id)
	if character.is_empty():
		return 0
	var unlock_id := str(character["unlock_id"])
	if unlock_id.is_empty():
		return 0
	for upgrade in META_UPGRADES:
		if upgrade["id"] == unlock_id:
			return int(upgrade["cost"])
	return 0

func is_character_unlocked(character_id: String) -> bool:
	var character := character_data(character_id)
	if character.is_empty():
		return false
	var unlock_id := str(character["unlock_id"])
	if unlock_id.is_empty():
		return true
	return has_unlock(unlock_id)

func selected_character() -> String:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return STARTING_CHARACTER_ID
	var stored := str(profiles[selected_slot].get("selected_character", STARTING_CHARACTER_ID))
	if character_data(stored).is_empty() or not is_character_unlocked(stored):
		return STARTING_CHARACTER_ID
	return stored

func set_selected_character(character_id: String) -> bool:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return false
	if not is_character_unlocked(character_id):
		return false
	profiles[selected_slot]["selected_character"] = character_id
	_save_profiles()
	return true

func map_data(map_id: String) -> Dictionary:
	for map in MAPS:
		if map["id"] == map_id:
			return map
	return {}

func map_unlock_cost(map_id: String) -> int:
	var map := map_data(map_id)
	if map.is_empty():
		return 0
	var unlock_id := str(map["unlock_id"])
	if unlock_id.is_empty():
		return 0
	for upgrade in META_UPGRADES:
		if upgrade["id"] == unlock_id:
			return int(upgrade["cost"])
	return 0

func is_map_unlocked(map_id: String) -> bool:
	var map := map_data(map_id)
	if map.is_empty():
		return false
	var unlock_id := str(map["unlock_id"])
	if unlock_id.is_empty():
		return true
	return has_unlock(unlock_id)

func selected_map() -> String:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return STARTING_MAP_ID
	var stored := str(profiles[selected_slot].get("selected_map", STARTING_MAP_ID))
	if map_data(stored).is_empty() or not is_map_unlocked(stored):
		return STARTING_MAP_ID
	return stored

func set_selected_map(map_id: String) -> bool:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return false
	if not is_map_unlocked(map_id):
		return false
	profiles[selected_slot]["selected_map"] = map_id
	_save_profiles()
	return true

func has_unlock(upgrade_id: String) -> bool:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return false
	return upgrade_id in profiles[selected_slot].get("unlocks", [])

func selected_unlocks() -> Array:
	if selected_slot < 0 or selected_slot >= SLOT_COUNT:
		return []
	return profiles[selected_slot].get("unlocks", []).duplicate()

func purchase_upgrade(upgrade_id: String) -> bool:
	for upgrade in META_UPGRADES:
		if upgrade["id"] != upgrade_id:
			continue
		if has_unlock(upgrade_id) or currency() < int(upgrade["cost"]):
			return false
		profiles[selected_slot]["permanent_currency"] = currency() - int(upgrade["cost"])
		profiles[selected_slot]["unlocks"].append(upgrade_id)
		_save_profiles()
		return true
	return false

func profile_summary(slot: int) -> String:
	if slot < 0 or slot >= SLOT_COUNT or profiles[slot].is_empty():
		return "Empty slot\nSelect to create profile"
	var profile := profiles[slot]
	var character_id := str(profile.get("selected_character", STARTING_CHARACTER_ID))
	var character := character_data(character_id)
	var character_label := str(character.get("label", "Quarterback")) if not character.is_empty() else "Quarterback"
	var map_id := str(profile.get("selected_map", STARTING_MAP_ID))
	var map := map_data(map_id)
	var map_label := str(map.get("label", "Classic Field")) if not map.is_empty() else "Classic Field"
	return "Created: %s\nLast played: %s\nCoins: %d\nDifficulty: %s\nPlayer: %s  |  Field: %s" % [
		profile.get("created", "Unknown"),
		profile.get("last_played", "Never"),
		int(profile.get("permanent_currency", 0)),
		"PRO" if bool(profile.get("pro_difficulty", false)) else "NORMAL",
		character_label,
		map_label,
	]

func _new_profile() -> Dictionary:
	var now := Time.get_datetime_string_from_system()
	return {
		"schema_version": 1,
		"created": now,
		"last_played": "Never",
		"permanent_currency": 0,
		"unlocks": [],
		"pro_difficulty": false,
		"selected_character": STARTING_CHARACTER_ID,
		"selected_map": STARTING_MAP_ID,
	}

func _load_profiles() -> void:
	profiles.clear()
	for index in SLOT_COUNT:
		profiles.append({})
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open profile save file; using empty slots.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or int(parsed.get("schema_version", 0)) != 1 or not (parsed.has("slots") and parsed["slots"] is Array):
		push_error("Profile save is invalid; using empty slots.")
		return
	var slots: Array = parsed["slots"]
	for index in min(slots.size(), SLOT_COUNT):
		if slots[index] is Dictionary and int(slots[index].get("schema_version", 0)) == 1:
			var normalized := _normalize_profile(slots[index])
			if normalized.is_empty():
				push_error("Profile slot %d is invalid; leaving it empty." % (index + 1))
			else:
				profiles[index] = normalized
		else:
			push_error("Profile slot %d is invalid; leaving it empty." % (index + 1))

func _normalize_profile(raw: Dictionary) -> Dictionary:
	var created = raw.get("created", "")
	var last_played = raw.get("last_played", "Never")
	var currency = raw.get("permanent_currency", 0)
	var unlocks = raw.get("unlocks", [])
	if not (created is String and last_played is String and currency is int and unlocks is Array):
		return {}
	var normalized := _new_profile()
	normalized["created"] = created
	normalized["last_played"] = last_played
	normalized["permanent_currency"] = max(currency, 0)
	normalized["unlocks"] = unlocks.duplicate()
	var pro_difficulty = raw.get("pro_difficulty", false)
	normalized["pro_difficulty"] = pro_difficulty if pro_difficulty is bool else false
	var selected_character_raw = raw.get("selected_character", STARTING_CHARACTER_ID)
	normalized["selected_character"] = selected_character_raw if selected_character_raw is String else STARTING_CHARACTER_ID
	var selected_map_raw = raw.get("selected_map", STARTING_MAP_ID)
	normalized["selected_map"] = selected_map_raw if selected_map_raw is String else STARTING_MAP_ID
	return normalized

func _save_profiles() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save profiles to %s." % PROFILE_PATH)
		return
	file.store_string(JSON.stringify({"schema_version": 1, "slots": profiles}))
