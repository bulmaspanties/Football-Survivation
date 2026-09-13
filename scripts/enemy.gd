class_name Enemy
extends CharacterBody2D

@export var speed := 90.0
@export var max_health := 30.0
@export var contact_damage := 10.0
@export var contact_range := 34.0
@export var contact_cooldown := 0.8
@export var experience_reward := 2
@export var experience_scene: PackedScene
@export var death_burst_scene: PackedScene
@export_enum("defender", "thrower", "blocker") var role := "defender"
@export var preferred_distance := 260.0
@export var ranged_cooldown := 2.8
@export var ranged_damage := 12.0
@export var ranged_projectile_speed := 220.0
@export var ranged_projectile_scene: PackedScene
@export var knockback_force := 0.0

var health := max_health
var _contact_cooldown_remaining := 0.0
var _target: Player
var _hit_flash_remaining := 0.0
var _ranged_cooldown_remaining := 0.0
@onready var _visual: CanvasItem = $Visual

func _ready() -> void:
	health = max_health

func apply_pressure(multiplier: float) -> void:
	speed *= multiplier
	max_health *= multiplier
	health = max_health
	contact_damage *= multiplier

func _physics_process(delta: float) -> void:
	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	_visual.modulate = Color(1.0, 1.0, 1.0, 1.0) if _hit_flash_remaining <= 0.0 else Color(1.0, 0.72, 0.72, 1.0)
	_contact_cooldown_remaining = maxf(_contact_cooldown_remaining - delta, 0.0)
	_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(_target) or _target.health <= 0.0:
		velocity = Vector2.ZERO
		return

	var distance_to_target := global_position.distance_to(_target.global_position)
	var direction := global_position.direction_to(_target.global_position)
	if role == "thrower":
		if distance_to_target < preferred_distance - 24.0:
			direction = -direction
		elif distance_to_target <= preferred_distance + 24.0:
			direction = Vector2.ZERO
		_throw_at_player()
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(_target.global_position) <= contact_range:
		if _contact_cooldown_remaining <= 0.0:
			_target.take_damage(contact_damage)
			if knockback_force > 0.0:
				_target.apply_knockback(direction * knockback_force)
			_contact_cooldown_remaining = contact_cooldown

func take_damage(amount: float) -> void:
	if amount <= 0.0 or health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		_drop_experience()
		_spawn_death_burst()
		queue_free()
	else:
		_hit_flash_remaining = 0.1

func _throw_at_player() -> void:
	if ranged_projectile_scene == null or _ranged_cooldown_remaining > 0.0:
		return
	var projectile: EnemyFootball = ranged_projectile_scene.instantiate() as EnemyFootball
	if projectile == null:
		return
	projectile.damage = ranged_damage
	projectile.speed = ranged_projectile_speed
	projectile.global_position = global_position
	get_tree().current_scene.add_child(projectile)
	projectile.launch(global_position.direction_to(_target.global_position))
	_ranged_cooldown_remaining = ranged_cooldown

func _drop_experience() -> void:
	if experience_scene == null or get_parent() == null:
		return
	var pickup := experience_scene.instantiate() as ExperiencePickup
	if pickup == null:
		return
	pickup.amount = experience_reward
	pickup.global_position = global_position
	get_parent().add_child(pickup)

func _spawn_death_burst() -> void:
	if death_burst_scene == null or get_parent() == null:
		return
	var burst := death_burst_scene.instantiate() as Node2D
	if burst == null:
		return
	burst.global_position = global_position
	get_parent().add_child(burst)
	burst.setup(Color(1.0, 0.3, 0.22, 1.0))
