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
	return "Created: %s\nLast played: %s\nCoins: %d\nDifficulty: %s" % [
		profile.get("created", "Unknown"),
		profile.get("last_played", "Never"),
		int(profile.get("permanent_currency", 0)),
		"PRO" if bool(profile.get("pro_difficulty", false)) else "NORMAL",
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
	return normalized

func _save_profiles() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save profiles to %s." % PROFILE_PATH)
		return
	file.store_string(JSON.stringify({"schema_version": 1, "slots": profiles}))
