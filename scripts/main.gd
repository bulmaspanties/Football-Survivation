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

var survival_time := 0.0
var run_finished := false

const UPGRADE_OPTIONS := [
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
	$HUD/GameOverPanel/RestartButton.pressed.connect(_restart_run)
	$HUD/VictoryPanel/RestartButton.pressed.connect(_restart_run)
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_on_upgrade_selected.bind(index))

func _process(delta: float) -> void:
	if run_finished:
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
	var start_index := (new_level - 1) % UPGRADE_OPTIONS.size()
	for index in upgrade_buttons.size():
		var option: Dictionary = UPGRADE_OPTIONS[(start_index + index) % UPGRADE_OPTIONS.size()]
		upgrade_buttons[index].text = option["label"]
		upgrade_buttons[index].set_meta("upgrade_id", option["id"])
	upgrade_panel.visible = true
	get_tree().paused = true

func _on_upgrade_selected(button_index: int) -> void:
	var upgrade_id: String = upgrade_buttons[button_index].get_meta("upgrade_id", "")
	if upgrade_id.is_empty():
		return
	player.apply_upgrade(upgrade_id)
	upgrade_panel.visible = false
	get_tree().paused = false

func _on_player_died() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	upgrade_panel.visible = false
	get_tree().paused = false
	game_over_panel.visible = true

func _finish_victory() -> void:
	run_finished = true
	enemy_spawner.set_process(false)
	player.set_physics_process(false)
	upgrade_panel.visible = false
	victory_panel.visible = true
	get_tree().paused = true

func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
