class_name EnemySpawner
extends Node2D

@export var enemy_scene: PackedScene
@export var runner_scene: PackedScene
@export var thrower_scene: PackedScene
@export var blocker_scene: PackedScene
@export var coach_scene: PackedScene
@export var spawn_interval := 2.5
@export var max_enemies := 12
@export var spawn_x := 520.0
@export var spawn_y := 270.0
@export var runner_chance_start := 0.0
@export var runner_chance_max := 0.3
@export var thrower_chance_max := 0.16
@export var blocker_chance_max := 0.12
@export var coach_chance_max := 0.08

var _spawn_timer := 0.0
var pressure := 1.0

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	pressure = 1.0
	spawn_interval = 2.5
	max_enemies = 12
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
	var scene_to_spawn := enemy_scene
	var runner_chance := clampf((pressure - 1.0) * 0.75, runner_chance_start, runner_chance_max)
	var thrower_chance := clampf((pressure - 1.0) * 0.35, 0.0, thrower_chance_max)
	var blocker_chance := clampf((pressure - 1.0) * 0.25, 0.0, blocker_chance_max)
	var coach_chance := clampf((pressure - 1.0) * 0.16, 0.0, coach_chance_max)
	if runner_scene != null and randf() < runner_chance:
		scene_to_spawn = runner_scene
	elif thrower_scene != null and randf() < thrower_chance:
		scene_to_spawn = thrower_scene
	elif blocker_scene != null and randf() < blocker_chance:
		scene_to_spawn = blocker_scene
	elif coach_scene != null and randf() < coach_chance:
		scene_to_spawn = coach_scene
	if scene_to_spawn == null:
		return
	var enemy: Enemy = scene_to_spawn.instantiate() as Enemy
	if enemy == null:
		return
	enemy.position = _perimeter_position()
	enemy.apply_pressure(pressure)
	enemy.add_to_group("enemy")
	get_parent().add_child(enemy)

func set_pressure(value: float) -> void:
	pressure = maxf(value, 1.0)
	spawn_interval = maxf(2.5 / pressure, 0.65)
	max_enemies = 12 + int((pressure - 1.0) * 10.0)

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
