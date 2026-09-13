extends Node

const SLOT_COUNT := 3
const PROFILE_PATH := "user://football_survivation_profiles.json"

var selected_slot := -1
var profile_selection_requested := true
var profiles: Array[Dictionary] = []

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

func profile_summary(slot: int) -> String:
	if slot < 0 or slot >= SLOT_COUNT or profiles[slot].is_empty():
		return "Empty slot\nSelect to create profile"
	var profile := profiles[slot]
	return "Created: %s\nLast played: %s\nCoins: %d" % [
		profile.get("created", "Unknown"),
		profile.get("last_played", "Never"),
		int(profile.get("permanent_currency", 0)),
	]

func _new_profile() -> Dictionary:
	var now := Time.get_datetime_string_from_system()
	return {
		"schema_version": 1,
		"created": now,
		"last_played": "Never",
		"permanent_currency": 0,
		"unlocks": [],
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
	return normalized

func _save_profiles() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save profiles to %s." % PROFILE_PATH)
		return
	file.store_string(JSON.stringify({"schema_version": 1, "slots": profiles}))
