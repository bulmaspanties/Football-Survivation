extends Node2D

const RUN_DURATION_SECONDS := 300.0
const ESCALATION_START_SECONDS := 30.0

@onready var player: Player = $Player
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel
@onready var experience_label: Label = $HUD/ExperiencePanel/ExperienceLabel
@onready var survival_label: Label = $HUD/SurvivalPanel/SurvivalLabel
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

const UPGRADE_OPTIONS := [
	{"id": "tackle_unlock", "label": "Unlock Tackle Burst (close-range damage)", "category": "weapon"},
	{"id": "hail_mary_unlock", "label": "Unlock Hail Mary (long-range power shot)", "category": "weapon"},
	{"id": "stiff_arm_unlock", "label": "Unlock Stiff Arm (melee arc)", "category": "weapon"},
	{"id": "football_damage", "label": "Powerful kicks (+8 football damage)"},
	{"id": "attack_cooldown", "label": "Quick feet (fire 0.12s faster)"},
	{"id": "projectile_speed", "label": "Long pass (+80 football speed)"},
	{"id": "max_health", "label": "Tougher player (+20 max health)"},
	{"id": "movement_speed", "label": "Sprint training (+30 movement speed)"},
]

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.experience_changed.connect(_on_player_experience_changed)
	player.level_up.connect(_on_player_level_up)
	player.died.connect(_on_player_died)
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
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_on_upgrade_selected.bind(index))
	player.set_physics_process(false)
	auto_weapon.set_process(false)
	tackle_weapon.set_process(false)
	hail_mary_weapon.set_process(false)
	stiff_arm.set_process(false)
	enemy_spawner.set_process(false)
	get_tree().paused = true

func _process(delta: float) -> void:
	if get_tree().paused or not run_started or run_finished:
		return
	survival_time = minf(survival_time + delta, RUN_DURATION_SECONDS)
	survival_label.text = "Survive: %s / %s" % [_format_time(survival_time), _format_time(RUN_DURATION_SECONDS)]
	var pressure := 1.0 + maxf(survival_time - ESCALATION_START_SECONDS, 0.0) / RUN_DURATION_SECONDS
	enemy_spawner.set_pressure(pressure)
	if survival_time >= RUN_DURATION_SECONDS:
		_finish_victory()

func _format_time(seconds: float) -> String:
	var whole_seconds := int(seconds)
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]

func _on_player_health_changed(current_health: float, maximum_health: float) -> void:
	health_label.text = "Health: %d / %d" % [current_health, maximum_health]

func _on_player_experience_changed(current_experience: int, experience_to_next_level: int, current_level: int) -> void:
	experience_label.text = "Level %d  |  XP: %d / %d" % [current_level, current_experience, experience_to_next_level]

func _on_player_level_up(new_level: int) -> void:
	upgrade_title.text = "Level %d - Choose an upgrade" % new_level
	var options := _available_upgrade_options()
	var start_index := (new_level - 1) % options.size()
	for index in upgrade_buttons.size():
		var option: Dictionary = options[(start_index + index) % options.size()]
		upgrade_buttons[index].text = option["label"]
		upgrade_buttons[index].set_meta("upgrade_id", option["id"])
	upgrade_panel.visible = true
	get_tree().paused = true

func _available_upgrade_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option in UPGRADE_OPTIONS:
		if option["id"] == "tackle_unlock" and player.tackle_unlocked:
			continue
		options.append(option)
	if player.tackle_unlocked:
		options.append({"id": "tackle_damage", "label": "Tackle training (+10 burst damage)", "category": "weapon"})
		options.append({"id": "tackle_cooldown", "label": "Fast tackle (-0.3s burst cooldown)", "category": "weapon"})
	if player.hail_mary_unlocked:
		options.append({"id": "hail_mary_damage", "label": "Hail Mary power (+20 shot damage)", "category": "weapon"})
		options.append({"id": "hail_mary_cooldown", "label": "Quick release (-0.5s Hail Mary cooldown)", "category": "weapon"})
	if player.stiff_arm_unlocked:
		options.append({"id": "stiff_arm_damage", "label": "Stronger stiff arm (+10 arc damage)", "category": "weapon"})
		options.append({"id": "stiff_arm_cooldown", "label": "Fast hands (-0.25s stiff arm cooldown)", "category": "weapon"})
	return options

func _on_upgrade_selected(button_index: int) -> void:
	var upgrade_id: String = upgrade_buttons[button_index].get_meta("upgrade_id", "")
	if upgrade_id.is_empty():
		return
	player.apply_upgrade(upgrade_id)
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
	survival_time = 0.0
	title_panel.visible = false
	profile_panel.visible = false
	ProfileManager.mark_played()
	player.apply_profile_upgrades(ProfileManager.selected_unlocks())
	enemy_spawner.reset_run()
	player.set_physics_process(true)
	auto_weapon.set_process(true)
	tackle_weapon.set_process(player.tackle_unlocked)
	hail_mary_weapon.set_process(player.hail_mary_unlocked)
	stiff_arm.set_process(player.stiff_arm_unlocked)
	enemy_spawner.set_process(true)
	get_tree().paused = false

func _on_player_died() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	upgrade_panel.visible = false
	pause_panel.visible = false
	settings_panel.visible = false
	_grant_run_reward(false)
	get_tree().paused = false
	game_over_panel.visible = true
	game_over_currency.text = "Profile reward: +%d coins\nTotal coins: %d" % [last_run_reward, ProfileManager.currency()]

func _finish_victory() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	player.set_physics_process(false)
	upgrade_panel.visible = false
	pause_panel.visible = false
	settings_panel.visible = false
	_grant_run_reward(true)
	victory_panel.visible = true
	victory_currency.text = "Profile reward: +%d coins\nTotal coins: %d" % [last_run_reward, ProfileManager.currency()]
	get_tree().paused = true

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
		meta_status.text = "Purchased. Applies on the next run.\nCoins: %d" % ProfileManager.currency()
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
