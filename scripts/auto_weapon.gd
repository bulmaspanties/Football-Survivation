class_name AutoWeapon
extends Node2D

@export var projectile_scene: PackedScene
@export var fire_interval := 0.8
@export var target_range := 520.0
@export var projectile_damage := 20.0
@export var projectile_speed := 520.0

var _fire_timer := 0.0
var _player: Player

func _ready() -> void:
	_player = get_parent() as Player

func _process(delta: float) -> void:
	if not is_instance_valid(_player) or _player.health <= 0.0:
		return
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _fire_timer > 0.0:
		return
	var target: Enemy = _nearest_enemy()
	if target == null:
		return
	_fire_timer = fire_interval
	_fire_at(target)

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

func _fire_at(target: Enemy) -> void:
	if projectile_scene == null:
		return
	var football: Football = projectile_scene.instantiate() as Football
	if football == null:
		return
	get_tree().current_scene.add_child(football)
	football.global_position = _player.global_position
	football.damage = projectile_damage
	football.speed = projectile_speed
	football.launch(_player.global_position.direction_to(target.global_position))

func upgrade_damage(amount: float) -> void:
	projectile_damage += amount

func upgrade_attack_speed(cooldown_reduction: float) -> void:
	fire_interval = maxf(fire_interval - cooldown_reduction, 0.2)

func upgrade_projectile_speed(amount: float) -> void:
	projectile_speed += amount
