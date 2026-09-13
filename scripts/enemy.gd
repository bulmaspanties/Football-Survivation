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
@export_enum("defender", "thrower", "blocker", "support") var role := "defender"
@export var preferred_distance := 260.0
@export var ranged_cooldown := 2.8
@export var ranged_damage := 12.0
@export var ranged_projectile_speed := 220.0
@export var ranged_projectile_scene: PackedScene
@export var knockback_force := 0.0
@export var support_radius := 180.0
@export var support_cooldown := 3.5
@export var support_duration := 4.0
@export var support_speed_multiplier := 1.2
@export var support_damage_multiplier := 1.15

var health := max_health
var _contact_cooldown_remaining := 0.0
var _target: Player
var _hit_flash_remaining := 0.0
var _ranged_cooldown_remaining := 0.0
var _support_cooldown_remaining := 0.0
var _support_sources: Dictionary = {}
var _support_base_speed := 0.0
var _support_base_contact_damage := 0.0
var _support_feedback_remaining := 0.0
@onready var _visual: CanvasItem = $Visual

func _ready() -> void:
	health = max_health
	_support_base_speed = speed
	_support_base_contact_damage = contact_damage

func apply_pressure(multiplier: float) -> void:
	speed *= multiplier
	max_health *= multiplier
	health = max_health
	contact_damage *= multiplier

func _physics_process(delta: float) -> void:
	_hit_flash_remaining = maxf(_hit_flash_remaining - delta, 0.0)
	if _hit_flash_remaining > 0.0:
		_visual.modulate = Color(1.0, 0.72, 0.72, 1.0)
	elif role == "support" and _support_feedback_remaining > 0.0:
		_visual.modulate = Color(0.8, 1.0, 0.7, 1.0)
	else:
		_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_contact_cooldown_remaining = maxf(_contact_cooldown_remaining - delta, 0.0)
	_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)
	_support_cooldown_remaining = maxf(_support_cooldown_remaining - delta, 0.0)
	_support_feedback_remaining = maxf(_support_feedback_remaining - delta, 0.0)
	_prune_support_sources()
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
	elif role == "support":
		if distance_to_target < preferred_distance - 35.0:
			direction = -direction
		elif distance_to_target <= preferred_distance + 35.0:
			direction = Vector2.ZERO
		_support_nearby_enemies()
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
		_clear_support_buffs()
		_drop_experience()
		_spawn_death_burst()
		queue_free()
	else:
		_hit_flash_remaining = 0.1

func apply_support_buff(source: Node, duration: float, speed_multiplier: float, damage_multiplier: float) -> void:
	if source == self:
		return
	_support_sources[source] = {
		"expires_at": Time.get_ticks_msec() / 1000.0 + duration,
		"speed_multiplier": speed_multiplier,
		"damage_multiplier": damage_multiplier,
	}
	_recalculate_support_buffs()

func clear_support_buff(source: Node) -> void:
	if source in _support_sources:
		_support_sources.erase(source)
		_recalculate_support_buffs()

func _prune_support_sources() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for source in _support_sources.keys():
		if not is_instance_valid(source) or _support_sources[source]["expires_at"] <= now:
			_support_sources.erase(source)
	_recalculate_support_buffs()

func _recalculate_support_buffs() -> void:
	speed = _support_base_speed
	contact_damage = _support_base_contact_damage
	for buff in _support_sources.values():
		speed = maxf(speed, _support_base_speed * buff["speed_multiplier"])
		contact_damage = maxf(contact_damage, _support_base_contact_damage * buff["damage_multiplier"])

func _support_nearby_enemies() -> void:
	if _support_cooldown_remaining > 0.0:
		return
	_support_cooldown_remaining = support_cooldown
	_support_feedback_remaining = 0.45
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		if is_instance_valid(enemy) and enemy != self and global_position.distance_to(enemy.global_position) <= support_radius:
			enemy.apply_support_buff(self, support_duration, support_speed_multiplier, support_damage_multiplier)

func _clear_support_buffs() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		if is_instance_valid(enemy) and enemy != self:
			enemy.clear_support_buff(self)

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
