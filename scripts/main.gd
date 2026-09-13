extends Node2D

@onready var player: Player = $Player
@onready var health_label: Label = $HUD/HealthPanel/HealthLabel
@onready var game_over_panel: Panel = $HUD/GameOverPanel

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)

func _on_player_health_changed(current_health: float, maximum_health: float) -> void:
	health_label.text = "Health: %d / %d" % [current_health, maximum_health]

func _on_player_died() -> void:
	$EnemySpawner.set_process(false)
	game_over_panel.visible = true
