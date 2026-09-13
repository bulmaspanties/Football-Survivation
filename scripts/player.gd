class_name Player
extends CharacterBody2D

@export var speed := 260.0
@export var max_health := 100.0
@export var damage_cooldown := 0.45

signal health_changed(current_health: float, maximum_health: float)
signal damage_taken(amount: float)
signal experience_collected(amount: int)
signal experience_changed(current_experience: int, experience_to_next_level: int, level: int)
signal level_up(level: int)
signal died

var health := max_health
var experience := 0
var level := 1
var experience_to_next_level := 5
var tackle_unlocked := false
var hail_mary_unlocked := false
var stiff_arm_unlocked := false
var xp_multiplier := 1.0
var _character_data: Dictionary = {}
var _knockback_velocity := Vector2.ZERO
var _damage_cooldown_remaining := 0.0
var _feedback_remaining := 0.0
@onready var _visual: CanvasItem = $Visual
@onready var _role_label: Label = $RoleLabel

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_to_next_level, level)
	SettingsManager.palette_changed.connect(_update_character_visual)

func _physics_process(delta: float) -> void:
	_feedback_remaining = maxf(_feedback_remaining - delta, 0.0)
	_visual.modulate = Color(1.0, 0.45, 0.45, 1.0) if _feedback_remaining > 0.0 else Color.WHITE
	_damage_cooldown_remaining = maxf(_damage_cooldown_remaining - delta, 0.0)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	velocity = input_vector * speed + _knockback_velocity
	move_and_slide()

func take_damage(amount: float) -> void:
	if amount <= 0.0 or _damage_cooldown_remaining > 0.0 or health <= 0.0:
		return
	_damage_cooldown_remaining = damage_cooldown
	health = maxf(health - amount, 0.0)
	_feedback_remaining = 0.22
	SettingsManager.rumble(0.4, 0.7, 0.2)
	damage_taken.emit(amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		SettingsManager.rumble(0.5, 0.7, 0.35)
		died.emit()

func apply_knockback(force: Vector2) -> void:
	if health > 0.0:
		_knockback_velocity += force

func collect_experience(amount: int) -> void:
	if amount <= 0 or health <= 0.0:
		return
	var gained := int(round(amount * xp_multiplier))
	experience += gained
	experience_collected.emit(gained)
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		experience_to_next_level = 5 + level * 2
		level_up.emit(level)
	experience_changed.emit(experience, experience_to_next_level, level)

func apply_upgrade(upgrade_id: String) -> void:
	var weapon := $AutoWeapon as AutoWeapon
	var tackle := $TackleWeapon as TackleWeapon
	var hail_mary := $HailMaryWeapon as HailMaryWeapon
	var stiff_arm := $StiffArm as StiffArm
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
				tackle.activate()
		"tackle_damage":
			if tackle_unlocked:
				tackle.upgrade_damage(10.0)
		"tackle_cooldown":
			if tackle_unlocked:
				tackle.upgrade_cooldown(0.3)
		"hail_mary_unlock":
			if not hail_mary_unlocked:
				hail_mary_unlocked = true
				hail_mary.activate()
		"hail_mary_damage":
			if hail_mary_unlocked:
				hail_mary.upgrade_damage(20.0)
		"hail_mary_cooldown":
			if hail_mary_unlocked:
				hail_mary.upgrade_cooldown(0.5)
		"stiff_arm_unlock":
			if not stiff_arm_unlocked:
				stiff_arm_unlocked = true
				stiff_arm.activate()
		"stiff_arm_damage":
			if stiff_arm_unlocked:
				stiff_arm.upgrade_damage(10.0)
		"stiff_arm_cooldown":
			if stiff_arm_unlocked:
				stiff_arm.upgrade_cooldown(0.25)

func apply_profile_upgrades(unlocks: Array) -> void:
	for unlock in unlocks:
		match str(unlock):
			"iron_body":
				max_health += 20.0
				health = max_health
			"speed_training":
				speed += 30.0
			"passing_game":
				($AutoWeapon as AutoWeapon).upgrade_damage(8.0)
			"tackle_signing":
				tackle_unlocked = true
			"hail_mary_scout":
				hail_mary_unlocked = true
			"extra_muscle":
				($TackleWeapon as TackleWeapon).upgrade_damage(10.0)
				($StiffArm as StiffArm).upgrade_damage(10.0)
			"film_study":
				xp_multiplier += 0.15
	health_changed.emit(health, max_health)

func apply_character(character: Dictionary) -> void:
	if character.is_empty():
		return
	_character_data = character
	max_health += float(character.get("health_bonus", 0.0))
	max_health = maxf(max_health, 10.0)
	health = max_health
	speed = maxf(speed + float(character.get("speed_bonus", 0.0)), 60.0)
	var football_bonus := float(character.get("football_damage_bonus", 0.0))
	if football_bonus != 0.0:
		($AutoWeapon as AutoWeapon).upgrade_damage(football_bonus)
	var tackle_bonus := float(character.get("tackle_damage_bonus", 0.0))
	if tackle_bonus != 0.0:
		($TackleWeapon as TackleWeapon).upgrade_damage(tackle_bonus)
	var stiff_arm_bonus := float(character.get("stiff_arm_damage_bonus", 0.0))
	if stiff_arm_bonus != 0.0:
		($StiffArm as StiffArm).upgrade_damage(stiff_arm_bonus)
	health_changed.emit(health, max_health)
	_update_character_visual()

func _update_character_visual() -> void:
	if _character_data.is_empty():
		return
	if _visual is Panel:
		var style: StyleBoxFlat = (_visual as Panel).get_theme_stylebox("panel").duplicate()
		var char_id: String = str(_character_data.get("id", "quarterback"))
		var default_col: Color = _character_data.get("color", Color.WHITE) as Color
		style.bg_color = SettingsManager.get_character_color(char_id, default_col)
		(_visual as Panel).add_theme_stylebox_override("panel", style)
	if is_instance_valid(_role_label):
		_role_label.text = str(_character_data.get("tag", ""))
