class_name HailMaryWeapon
extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown := 3.5
@export var target_range := 900.0
@export var projectile_damage := 55.0
@export var projectile_speed := 260.0

var unlocked := false
var _cooldown_remaining := 0.0
var _player: Player

func _ready() -> void:
	_player = get_parent() as Player
	set_process(false)

func _process(delta: float) -> void:
	if not unlocked or not is_instance_valid(_player) or _player.health <= 0.0:
		return
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _cooldown_remaining > 0.0:
		return
	var target: Enemy = _nearest_enemy()
	if target == null or projectile_scene == null:
		return
	var projectile: HailMary = projectile_scene.instantiate() as HailMary
	if projectile == null:
		return
	projectile.damage = projectile_damage
	projectile.speed = projectile_speed
	projectile.global_position = _player.global_position
	get_tree().current_scene.add_child(projectile)
	projectile.launch(_player.global_position.direction_to(target.global_position))
	AudioManager.play_cue("hail_mary_throw")
	_cooldown_remaining = cooldown

func _nearest_enemy() -> Enemy:
	var nearest: Enemy
	var nearest_distance := target_range
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		if not is_instance_valid(enemy):
			continue
		var distance := _player.global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func unlock() -> void:
	unlocked = true
	set_process(true)

func activate() -> void:
	unlocked = true
	set_process(true)

func upgrade_damage(amount: float) -> void:
	projectile_damage += amount

func upgrade_cooldown(reduction: float) -> void:
	cooldown = maxf(cooldown - reduction, 1.2)
