class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval := 2.5
@export var max_enemies := 12
@export var spawn_x := 520.0
@export var spawn_y := 270.0

var _spawn_timer := 0.0

func _ready() -> void:
	_spawn_timer = spawn_interval

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = spawn_interval
	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return
	_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return
	enemy.position = _perimeter_position()
	enemy.add_to_group("enemy")
	get_parent().add_child(enemy)

func _perimeter_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0:
			return Vector2(randf_range(-spawn_x, spawn_x), -spawn_y)
		1:
			return Vector2(randf_range(-spawn_x, spawn_x), spawn_y)
		2:
			return Vector2(-spawn_x, randf_range(-spawn_y, spawn_y))
		_:
			return Vector2(spawn_x, randf_range(-spawn_y, spawn_y))
