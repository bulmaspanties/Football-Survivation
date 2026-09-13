extends Node2D

@onready var player: Player = $Player
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel
@onready var experience_label: Label = $HUD/ExperiencePanel/ExperienceLabel
@onready var upgrade_panel: Panel = $HUD/UpgradePanel
@onready var upgrade_title: Label = $HUD/UpgradePanel/UpgradeTitle
@onready var upgrade_buttons: Array[Button] = [
	$HUD/UpgradePanel/UpgradeButton1,
	$HUD/UpgradePanel/UpgradeButton2,
	$HUD/UpgradePanel/UpgradeButton3,
]
@onready var game_over_panel: Panel = $HUD/GameOverPanel

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
	for index in upgrade_buttons.size():
		upgrade_buttons[index].pressed.connect(_on_upgrade_selected.bind(index))

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
	$EnemySpawner.set_process(false)
	upgrade_panel.visible = false
	get_tree().paused = false
	game_over_panel.visible = true
