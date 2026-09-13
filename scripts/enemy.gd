class_name Enemy
extends CharacterBody2D

@export var speed := 90.0
@export var max_health := 30.0
@export var contact_damage := 10.0
@export var contact_range := 34.0
@export var contact_cooldown := 0.8

var health := max_health
var _contact_cooldown_remaining := 0.0
var _target: Player

func _ready() -> void:
	health = max_health

func _physics_process(delta: float) -> void:
	_contact_cooldown_remaining = maxf(_contact_cooldown_remaining - delta, 0.0)
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Player
	if not is_instance_valid(_target) or _target.health <= 0.0:
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(_target.global_position)
	velocity = direction * speed
	move_and_slide()
	if global_position.distance_to(_target.global_position) <= contact_range:
		if _contact_cooldown_remaining <= 0.0:
			_target.take_damage(contact_damage)
			_contact_cooldown_remaining = contact_cooldown

func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		queue_free()
