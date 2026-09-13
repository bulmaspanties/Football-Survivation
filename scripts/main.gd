extends Node2D

const RUN_DURATION_SECONDS := 300.0
const ESCALATION_START_SECONDS := 30.0
const HALFTIME_BOSS_SECONDS := 150.0
const HALFTIME_WARNING_SECONDS := 3.0

@onready var player: Player = $Player
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel
@onready var experience_label: Label = $HUD/ExperiencePanel/ExperienceLabel
@onready var survival_label: Label = $HUD/SurvivalPanel/SurvivalLabel
@onready var boss_status: Label = $HUD/BossStatus
@onready var wave_status: Label = $HUD/WaveStatus
@onready var loadout_label: Label = $HUD/LoadoutPanel/LoadoutLabel
@onready var upgrade_panel: Panel = $HUD/UpgradePanel
@onready var upgrade_title: Label = $HUD/UpgradePanel/UpgradeTitle
@onready var upgrade_buttons: Array[Button] = [
	$HUD/UpgradePanel/UpgradeButton1,
	$HUD/UpgradePanel/UpgradeButton2,
	$HUD/UpgradePanel/UpgradeButton3,
]
@onready var game_over_panel: Panel = $HUD/GameOverPanel
@onready var victory_panel: Panel = $HUD/VictoryPanel
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var title_panel: Panel = $HUD/TitlePanel
@onready var profile_panel: Panel = $HUD/ProfilePanel
@onready var meta_panel: Panel = $HUD/MetaPanel
@onready var meta_status: Label = $HUD/MetaPanel/Status
@onready var meta_buttons: Array[Button] = [
	$HUD/MetaPanel/UpgradeButton1,
	$HUD/MetaPanel/UpgradeButton2,
	$HUD/MetaPanel/UpgradeButton3,
]
@onready var pause_panel: Panel = $HUD/PausePanel
@onready var settings_panel: Panel = $HUD/SettingsPanel
@onready var volume_slider: HSlider = $HUD/SettingsPanel/VolumeSlider
@onready var mute_check: CheckButton = $HUD/SettingsPanel/MuteCheck
@onready var fullscreen_check: CheckButton = $HUD/SettingsPanel/FullscreenCheck
@onready var auto_weapon: AutoWeapon = $Player/AutoWeapon
@onready var tackle_weapon: TackleWeapon = $Player/TackleWeapon
@onready var hail_mary_weapon: HailMaryWeapon = $Player/HailMaryWeapon
@onready var stiff_arm: StiffArm = $Player/StiffArm
@onready var victory_currency: Label = $HUD/VictoryPanel/Currency
@onready var game_over_currency: Label = $HUD/GameOverPanel/Currency

var survival_time := 0.0
var run_finished := false
var run_started := false
var reward_granted := false
var last_run_reward := 0
var boss_event_triggered := false
var boss_active := false
var boss_warning_remaining := 0.0
var boss_reward_granted := false
var wave_banner_remaining := 0.0
var enemies_defeated := 0
var xp_earned := 0
var damage_events := 0
var weapon_hits: Dictionary = {}

const UPGRADE_OPTIONS := [
	{"id": "tackle_unlock", "label": "Unlock Tackle Burst (close-range damage)", "category": "weapon"},
	{"id": "hail_mary_unlock", "label": "Unlock Hail Mary (long-range power shot)", "category": "weapon"},
	{"id": "stiff_arm_unlock", "label": "Unlock Stiff Arm (melee arc)", "category": "weapon"},
	{"id": "football_damage", "label": "Power Run (+8 football damage)"},
	{"id": "attack_cooldown", "label": "Quick Snap (fire 0.12s faster)"},
	{"id": "projectile_speed", "label": "Long Bomb (+80 football speed)"},
	{"id": "max_health", "label": "Goal Line Stand (+20 max health)"},
	{"id": "movement_speed", "label": "Open Field Sprint (+30 movement speed)"},
]

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.damage_taken.connect(_on_player_damage_taken)
	player.experience_collected.connect(_on_player_experience_collected)
	player.experience_changed.connect(_on_player_experience_changed)
	player.level_up.connect(_on_player_level_up)
	player.died.connect(_on_player_died)
	enemy_spawner.phase_changed.connect(_on_wave_phase_changed)
	$HUD/TitlePanel/StartButton.pressed.connect(_start_run)
	$HUD/ProfilePanel/Slot1.pressed.connect(_select_profile.bind(0))
	$HUD/ProfilePanel/Slot2.pressed.connect(_select_profile.bind(1))
	$HUD/ProfilePanel/Slot3.pressed.connect(_select_profile.bind(2))
	$HUD/ProfilePanel/MetaButton.pressed.connect(_open_meta_upgrades)
	$HUD/MetaPanel/BackButton.pressed.connect(_close_meta_upgrades)
	for index in meta_buttons.size():
		meta_buttons[index].pressed.connect(_purchase_meta_upgrade.bind(index))
	$HUD/GameOverPanel/RestartButton.pressed.connect(_restart_run)
	$HUD/VictoryPanel/RestartButton.pressed.connect(_restart_run)
	$HUD/PausePanel/ResumeButton.pressed.connect(_resume_run)
	$HUD/PausePanel/RestartButton.pressed.connect(_restart_run)
	$HUD/PausePanel/TitleButton.pressed.connect(_return_to_title)
	$HUD/PausePanel/ProfileButton.pressed.connect(_return_to_profiles)
	$HUD/PausePanel/SettingsButton.pressed.connect(_open_settings)
	$HUD/SettingsPanel/BackButton.pressed.connect(_close_settings)
	$HUD/SettingsPanel/ResetButton.pressed.connect(_reset_settings)
	volume_slider.value_changed.connect(_on_volume_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	SettingsManager.settings_changed.connect(_sync_settings_controls)
	_sync_settings_controls()
	_refresh_profile_buttons()
	profile_panel.visible = ProfileManager.profile_selection_requested or ProfileManager.selected_slot < 0
	title_panel.visible = not profile_panel.visible
	meta_panel.visible = false
	_refresh_meta_upgrades()
	_refresh_loadout_hud()
	_configure_focus()
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_on_upgrade_selected.bind(index))
	player.set_physics_process(false)
	auto_weapon.set_process(false)
	tackle_weapon.set_process(false)
	hail_mary_weapon.set_process(false)
	stiff_arm.set_process(false)
	enemy_spawner.set_process(false)
	get_tree().paused = true
	call_deferred("_focus_front_overlay")

func _configure_focus() -> void:
	_set_vertical_focus([
		$HUD/TitlePanel/StartButton,
	])
	_set_vertical_focus([
		$HUD/ProfilePanel/Slot1,
		$HUD/ProfilePanel/Slot2,
		$HUD/ProfilePanel/Slot3,
		$HUD/ProfilePanel/MetaButton,
	])
	_set_vertical_focus(meta_buttons + [$HUD/MetaPanel/BackButton])
	_set_vertical_focus(upgrade_buttons)
	_set_vertical_focus([
		$HUD/PausePanel/ResumeButton,
		$HUD/PausePanel/RestartButton,
		$HUD/PausePanel/TitleButton,
		$HUD/PausePanel/SettingsButton,
		$HUD/PausePanel/ProfileButton,
	])
	_set_vertical_focus([
		$HUD/SettingsPanel/VolumeSlider,
		$HUD/SettingsPanel/MuteCheck,
		$HUD/SettingsPanel/FullscreenCheck,
		$HUD/SettingsPanel/ResetButton,
		$HUD/SettingsPanel/BackButton,
	])
	_set_vertical_focus([$HUD/GameOverPanel/RestartButton])
	_set_vertical_focus([$HUD/VictoryPanel/RestartButton])

func _set_vertical_focus(controls: Array) -> void:
	for index in controls.size():
		var control := controls[index] as Control
		if control == null:
			continue
		var previous: Control = controls[(index - 1 + controls.size()) % controls.size()]
		var next: Control = controls[(index + 1) % controls.size()]
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(next)

func _focus_front_overlay() -> void:
	if profile_panel.visible:
		$HUD/ProfilePanel/Slot1.grab_focus()
	elif title_panel.visible:
		$HUD/TitlePanel/StartButton.grab_focus()

func _on_wave_phase_changed(title: String, details: String) -> void:
	if not run_started or run_finished:
		return
	wave_status.text = "%s\n%s" % [title, details]
	wave_status.visible = true
	wave_banner_remaining = 4.0

func _on_enemy_defeated() -> void:
	enemies_defeated += 1

func _on_weapon_hit(weapon_name: String) -> void:
	weapon_hits[weapon_name] = int(weapon_hits.get(weapon_name, 0)) + 1

func _on_enemy_damaged(position: Vector2, amount: float) -> void:
	damage_events += 1
	var damage_label := Label.new()
	damage_label.text = "-%d" % int(round(amount))
	damage_label.position = position
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.z_index = 20
	get_tree().current_scene.add_child(damage_label)
	var tween := create_tween()
	tween.tween_property(damage_label, "position", position + Vector2(0.0, -28.0), 0.45)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(damage_label.queue_free)

func _on_player_damage_taken(_amount: float) -> void:
	boss_status.text = "CONTACT! Protect the pocket."

func _on_player_experience_collected(amount: int) -> void:
	xp_earned += amount

func _on_boss_defeated() -> void:
	if boss_reward_granted:
		return
	boss_reward_granted = true
	boss_active = false
	boss_status.text = "HALFTIME ELITE DEFEATED - BALL RECOVERED"
	ProfileManager.add_currency(50)

func _process(delta: float) -> void:
	if get_tree().paused or not run_started or run_finished:
		return
	if wave_banner_remaining > 0.0:
		wave_banner_remaining = maxf(wave_banner_remaining - delta, 0.0)
		if wave_banner_remaining <= 0.0:
			wave_status.visible = false
	survival_time = minf(survival_time + delta, RUN_DURATION_SECONDS)
	survival_label.text = "DRIVE CLOCK  %s / %s" % [_format_time(survival_time), _format_time(RUN_DURATION_SECONDS)]
	var pressure := 1.0 + maxf(survival_time - ESCALATION_START_SECONDS, 0.0) / RUN_DURATION_SECONDS
	enemy_spawner.update_director(survival_time, pressure)
	if not boss_event_triggered and survival_time >= HALFTIME_BOSS_SECONDS:
		_trigger_halftime_boss()
	if boss_warning_remaining > 0.0:
		boss_warning_remaining = maxf(boss_warning_remaining - delta, 0.0)
		if boss_warning_remaining <= 0.0 and boss_active:
			boss_status.text = "HALFTIME ELITE ACTIVE - PROTECT THE BALL"
	if survival_time >= RUN_DURATION_SECONDS:
		_finish_victory()

func _trigger_halftime_boss() -> void:
	boss_event_triggered = true
	boss_active = true
	boss_warning_remaining = HALFTIME_WARNING_SECONDS
	boss_status.text = "HALFTIME WARNING - ELITE TAKING THE FIELD"
	enemy_spawner.spawn_boss()

func _format_time(seconds: float) -> String:
	var whole_seconds := int(seconds)
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]

func _on_player_health_changed(current_health: float, maximum_health: float) -> void:
	health_label.text = "QB Health: %d / %d" % [current_health, maximum_health]

func _on_player_experience_changed(current_experience: int, experience_to_next_level: int, current_level: int) -> void:
	experience_label.text = "DRIVE XP  |  Level %d  |  %d / %d" % [current_level, current_experience, experience_to_next_level]

func _on_player_level_up(new_level: int) -> void:
	upgrade_title.text = "HALFTIME HUDDLE - Call a play (Level %d)" % new_level
	var options := _available_upgrade_options()
	var start_index := (new_level - 1) % options.size()
	for index in upgrade_buttons.size():
		var option: Dictionary = options[(start_index + index) % options.size()]
		upgrade_buttons[index].text = _format_upgrade_option(option)
		upgrade_buttons[index].set_meta("upgrade_id", option["id"])
	upgrade_panel.visible = true
	get_tree().paused = true
	upgrade_buttons[0].grab_focus()

func _available_upgrade_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option in UPGRADE_OPTIONS:
		if option["id"] == "tackle_unlock" and player.tackle_unlocked:
			continue
		if option["id"] == "hail_mary_unlock" and player.hail_mary_unlocked:
			continue
		if option["id"] == "stiff_arm_unlock" and player.stiff_arm_unlocked:
			continue
		var choice: Dictionary = option.duplicate()
		choice["category"] = "PLAYER STAT" if not option.has("category") else "WEAPON UNLOCK"
		options.append(choice)
	if player.tackle_unlocked:
		options.append({"id": "tackle_damage", "label": "Tackle Drill", "category": "WEAPON UPGRADE"})
		options.append({"id": "tackle_cooldown", "label": "Quick Tackle", "category": "WEAPON UPGRADE"})
	if player.hail_mary_unlocked:
		options.append({"id": "hail_mary_damage", "label": "Hail Mary Power", "category": "WEAPON UPGRADE"})
		options.append({"id": "hail_mary_cooldown", "label": "Quick Release", "category": "WEAPON UPGRADE"})
	if player.stiff_arm_unlocked:
		options.append({"id": "stiff_arm_damage", "label": "Stiff Arm Drill", "category": "WEAPON UPGRADE"})
		options.append({"id": "stiff_arm_cooldown", "label": "Fast Hands", "category": "WEAPON UPGRADE"})
	return options

func _format_upgrade_option(option: Dictionary) -> String:
	var upgrade_id := str(option["id"])
	match upgrade_id:
		"tackle_unlock":
			return "WEAPON UNLOCK\nTackle Burst  |  LOCKED -> UNLOCKED\nRadius damage: %d" % int(tackle_weapon.damage)
		"hail_mary_unlock":
			return "WEAPON UNLOCK\nHail Mary  |  LOCKED -> UNLOCKED\nShot damage: %d" % int(hail_mary_weapon.projectile_damage)
		"stiff_arm_unlock":
			return "WEAPON UNLOCK\nStiff Arm  |  LOCKED -> UNLOCKED\nArc damage: %d" % int(stiff_arm.damage)
		"football_damage":
			return "PLAYER STAT\nFootball power  |  %d -> %d damage" % [int(auto_weapon.projectile_damage), int(auto_weapon.projectile_damage + 8.0)]
		"attack_cooldown":
			return "PLAYER STAT\nFootball snap  |  %.2fs -> %.2fs cooldown" % [auto_weapon.fire_interval, maxf(auto_weapon.fire_interval - 0.12, 0.2)]
		"projectile_speed":
			return "PLAYER STAT\nFootball range  |  %d -> %d speed" % [int(auto_weapon.projectile_speed), int(auto_weapon.projectile_speed + 80.0)]
		"max_health":
			return "PLAYER STAT\nGoal line health  |  %d -> %d max" % [int(player.max_health), int(player.max_health + 20.0)]
		"movement_speed":
			return "PLAYER STAT\nOpen field speed  |  %d -> %d" % [int(player.speed), int(player.speed + 30.0)]
		"tackle_damage":
			return "WEAPON UPGRADE\nTackle Burst  |  %d -> %d damage" % [int(tackle_weapon.damage), int(tackle_weapon.damage + 10.0)]
		"tackle_cooldown":
			return "WEAPON UPGRADE\nTackle Burst  |  %.2fs -> %.2fs cooldown" % [tackle_weapon.cooldown, maxf(tackle_weapon.cooldown - 0.3, 0.8)]
		"hail_mary_damage":
			return "WEAPON UPGRADE\nHail Mary  |  %d -> %d damage" % [int(hail_mary_weapon.projectile_damage), int(hail_mary_weapon.projectile_damage + 20.0)]
		"hail_mary_cooldown":
			return "WEAPON UPGRADE\nHail Mary  |  %.2fs -> %.2fs cooldown" % [hail_mary_weapon.cooldown, maxf(hail_mary_weapon.cooldown - 0.5, 1.2)]
		"stiff_arm_damage":
			return "WEAPON UPGRADE\nStiff Arm  |  %d -> %d damage" % [int(stiff_arm.damage), int(stiff_arm.damage + 10.0)]
		"stiff_arm_cooldown":
			return "WEAPON UPGRADE\nStiff Arm  |  %.2fs -> %.2fs cooldown" % [stiff_arm.cooldown, maxf(stiff_arm.cooldown - 0.25, 0.7)]
	return "PLAYER STAT\n%s" % option["label"]

func _on_upgrade_selected(button_index: int) -> void:
	var upgrade_id: String = upgrade_buttons[button_index].get_meta("upgrade_id", "")
	if upgrade_id.is_empty():
		return
	player.apply_upgrade(upgrade_id)
	_refresh_loadout_hud()
	upgrade_panel.visible = false
	get_tree().paused = false

func _on_pause_requested() -> void:
	if not run_started or run_finished or title_panel.visible or upgrade_panel.visible:
		return
	if settings_panel.visible:
		_close_settings()
	elif pause_panel.visible:
		_resume_run()
	else:
		pause_panel.visible = true
		get_tree().paused = true
		$HUD/PausePanel/ResumeButton.grab_focus()

func _resume_run() -> void:
	settings_panel.visible = false
	pause_panel.visible = false
	get_tree().paused = false

func _open_settings() -> void:
	settings_panel.visible = true
	pause_panel.visible = false
	volume_slider.grab_focus()

func _close_settings() -> void:
	settings_panel.visible = false
	pause_panel.visible = true
	$HUD/PausePanel/SettingsButton.grab_focus()

func _reset_settings() -> void:
	SettingsManager.reset_defaults()
	_sync_settings_controls()
	volume_slider.grab_focus()

func _on_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)

func _on_mute_toggled(value: bool) -> void:
	SettingsManager.set_muted(value)

func _on_fullscreen_toggled(value: bool) -> void:
	SettingsManager.set_fullscreen(value)

func _sync_settings_controls() -> void:
	volume_slider.set_value_no_signal(SettingsManager.master_volume)
	mute_check.set_pressed_no_signal(SettingsManager.muted)
	fullscreen_check.set_pressed_no_signal(SettingsManager.fullscreen)

func _start_run() -> void:
	if run_started:
		return
	run_started = true
	run_finished = false
	reward_granted = false
	last_run_reward = 0
	boss_event_triggered = false
	boss_active = false
	boss_warning_remaining = 0.0
	boss_reward_granted = false
	survival_time = 0.0
	enemies_defeated = 0
	xp_earned = 0
	damage_events = 0
	weapon_hits = {}
	title_panel.visible = false
	profile_panel.visible = false
	ProfileManager.mark_played()
	player.apply_profile_upgrades(ProfileManager.selected_unlocks())
	enemy_spawner.reset_run()
	boss_status.text = ""
	wave_status.visible = false
	player.set_physics_process(true)
	auto_weapon.set_process(true)
	tackle_weapon.set_process(player.tackle_unlocked)
	hail_mary_weapon.set_process(player.hail_mary_unlocked)
	stiff_arm.set_process(player.stiff_arm_unlocked)
	_refresh_loadout_hud()
	enemy_spawner.set_process(true)
	get_tree().paused = false

func _refresh_loadout_hud() -> void:
	if not is_instance_valid(loadout_label):
		return
	var tackle_state := "READY" if player.tackle_unlocked else "LOCKED"
	var hail_state := "READY" if player.hail_mary_unlocked else "LOCKED"
	var stiff_state := "READY" if player.stiff_arm_unlocked else "LOCKED"
	loadout_label.text = "LOADOUT\n" \
		+ "Football   %d dmg / %.2fs\n" % [int(auto_weapon.projectile_damage), auto_weapon.fire_interval] \
		+ "Tackle Burst  [%s]  %d / %.2fs\n" % [tackle_state, int(tackle_weapon.damage), tackle_weapon.cooldown] \
		+ "Hail Mary  [%s]  %d / %.2fs\n" % [hail_state, int(hail_mary_weapon.projectile_damage), hail_mary_weapon.cooldown] \
		+ "Stiff Arm  [%s]  %d / %.2fs" % [stiff_state, int(stiff_arm.damage), stiff_arm.cooldown]

func _on_player_died() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	upgrade_panel.visible = false
	pause_panel.visible = false
	settings_panel.visible = false
	_grant_run_reward(false)
	get_tree().paused = false
	game_over_panel.visible = true
	game_over_currency.text = _terminal_summary("Profile reward: +%d coins\nTotal coins: %d" % [last_run_reward, ProfileManager.currency()])
	$HUD/GameOverPanel/RestartButton.grab_focus()

func _finish_victory() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	player.set_physics_process(false)
	upgrade_panel.visible = false
	pause_panel.visible = false
	settings_panel.visible = false
	_grant_run_reward(true)
	victory_panel.visible = true
	victory_currency.text = _terminal_summary("Profile reward: +%d coins\nTotal coins: %d" % [last_run_reward, ProfileManager.currency()])
	get_tree().paused = true
	$HUD/VictoryPanel/RestartButton.grab_focus()

func _terminal_summary(reward_text: String) -> String:
	var summary := "%s\nDrive: %s  |  Defeated: %d\nXP earned: %d  |  Impact plays: %d" % [
		reward_text,
		_format_time(survival_time),
		enemies_defeated,
		xp_earned,
		damage_events,
	]
	var hit_summary := "  ".join([
		"Football %d" % int(weapon_hits.get("Football", 0)),
		"Tackle %d" % int(weapon_hits.get("Tackle Burst", 0)),
		"Hail Mary %d" % int(weapon_hits.get("Hail Mary", 0)),
		"Stiff Arm %d" % int(weapon_hits.get("Stiff Arm", 0)),
	])
	return "%s\nWeapon hits: %s" % [summary, hit_summary]

func _grant_run_reward(victory: bool) -> void:
	if reward_granted:
		return
	reward_granted = true
	last_run_reward = 100 if victory else min(50, 10 + int(survival_time / 30.0))
	ProfileManager.add_currency(last_run_reward)

func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _return_to_title() -> void:
	get_tree().paused = false
	ProfileManager.profile_selection_requested = false
	get_tree().reload_current_scene()

func _return_to_profiles() -> void:
	get_tree().paused = false
	ProfileManager.profile_selection_requested = true
	get_tree().reload_current_scene()

func _select_profile(slot: int) -> void:
	ProfileManager.select_slot(slot)
	profile_panel.visible = false
	title_panel.visible = true
	$HUD/TitlePanel/StartButton.grab_focus()

func _open_meta_upgrades() -> void:
	profile_panel.visible = false
	title_panel.visible = false
	meta_panel.visible = true
	_refresh_meta_upgrades()
	meta_buttons[0].grab_focus()

func _close_meta_upgrades() -> void:
	meta_panel.visible = false
	profile_panel.visible = ProfileManager.selected_slot < 0
	title_panel.visible = not profile_panel.visible
	if profile_panel.visible:
		$HUD/ProfilePanel/Slot1.grab_focus()
	else:
		$HUD/TitlePanel/StartButton.grab_focus()

func _purchase_meta_upgrade(index: int) -> void:
	var upgrade_id: String = ProfileManager.META_UPGRADES[index]["id"]
	if ProfileManager.purchase_upgrade(upgrade_id):
		meta_status.text = "Signed. Applies on the next kickoff.\nCoins: %d" % ProfileManager.currency()
	else:
		meta_status.text = "Cannot purchase: already owned or insufficient coins.\nCoins: %d" % ProfileManager.currency()
	_refresh_meta_upgrades()

func _refresh_meta_upgrades() -> void:
	if not is_instance_valid(meta_panel):
		return
	meta_status.text = "Permanent coins: %d\nPurchased upgrades apply on your next run." % ProfileManager.currency()
	for index in meta_buttons.size():
		var upgrade: Dictionary = ProfileManager.META_UPGRADES[index]
		var owned := ProfileManager.has_unlock(upgrade["id"])
		meta_buttons[index].text = "%s%s" % [upgrade["label"], "  [OWNED]" if owned else "  Cost: %d" % upgrade["cost"]]

func _refresh_profile_buttons() -> void:
	var buttons: Array[Button] = [
		$HUD/ProfilePanel/Slot1,
		$HUD/ProfilePanel/Slot2,
		$HUD/ProfilePanel/Slot3,
	]
	for index in buttons.size():
		buttons[index].text = "SLOT %d\n%s" % [index + 1, ProfileManager.profile_summary(index)]
