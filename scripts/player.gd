class_name Player
extends CharacterBody2D

@export var speed := 260.0
@export var max_health := 100.0
@export var damage_cooldown := 0.45

signal health_changed(current_health: float, maximum_health: float)
signal died

var health := max_health
var _damage_cooldown_remaining := 0.0

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	_damage_cooldown_remaining = maxf(_damage_cooldown_remaining - delta, 0.0)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	move_and_slide()

func take_damage(amount: float) -> void:
	if amount <= 0.0 or _damage_cooldown_remaining > 0.0 or health <= 0.0:
		return
	_damage_cooldown_remaining = damage_cooldown
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		died.emit()
