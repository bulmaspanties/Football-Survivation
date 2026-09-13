class_name Player
extends CharacterBody2D

@export var speed := 260.0
@export var max_health := 100.0
@export var damage_cooldown := 0.45

signal health_changed(current_health: float, maximum_health: float)
signal experience_changed(current_experience: int, experience_to_next_level: int, level: int)
signal level_up(level: int)
signal died

var health := max_health
var experience := 0
var level := 1
var experience_to_next_level := 5
var tackle_unlocked := false
var _damage_cooldown_remaining := 0.0

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_to_next_level, level)

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

func collect_experience(amount: int) -> void:
	if amount <= 0 or health <= 0.0:
		return
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = 5 + level * 2
		level_up.emit(level)
	experience_changed.emit(experience, experience_to_next_level, level)

func apply_upgrade(upgrade_id: String) -> void:
	var weapon := $AutoWeapon as AutoWeapon
	var tackle := $TackleWeapon as TackleWeapon
	match upgrade_id:
		"football_damage":
			weapon.upgrade_damage(8.0)
		"attack_cooldown":
			weapon.upgrade_attack_speed(0.12)
		"projectile_speed":
			weapon.upgrade_projectile_speed(80.0)
		"max_health":
			max_health += 20.0
			health = minf(health + 20.0, max_health)
			health_changed.emit(health, max_health)
		"movement_speed":
			speed += 30.0
		"tackle_unlock":
			if not tackle_unlocked:
				tackle_unlocked = true
				tackle.unlock()
		"tackle_damage":
			if tackle_unlocked:
				tackle.upgrade_damage(10.0)
		"tackle_cooldown":
			if tackle_unlocked:
				tackle.upgrade_cooldown(0.3)
