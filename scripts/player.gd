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
signal audible_triggered(ability_name: String)

const AUDIBLE_COOLDOWN := 30.0

var health := max_health
var experience := 0
var level := 1
var experience_to_next_level := 5
var tackle_unlocked := false
var hail_mary_unlocked := false
var stiff_arm_unlocked := false
var xp_multiplier := 1.0
var turf_speed_modifier := 1.0
var audible_cooldown_remaining := 0.0

var _character_data: Dictionary = {}
var _knockback_velocity := Vector2.ZERO
var _damage_cooldown_remaining := 0.0
var _feedback_remaining := 0.0
var _flagged_remaining := 0.0
var _penalty_zone_count := 0
var _facing_direction := Vector2.RIGHT

var _audible_active_time := 0.0
var _audible_dash_velocity := Vector2.ZERO
var _audible_ability_type := ""
var _pocket_pulse_remaining := 0.0
var _audible_hit_enemies: Array[Enemy] = []

@onready var _visual: CanvasItem = $Visual
@onready var _jersey_stripe: CanvasItem = get_node_or_null("JerseyStripe")
@onready var _football_mark: CanvasItem = get_node_or_null("FootballMark")
@onready var _role_label: Label = $RoleLabel
@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func has_sprite_art() -> bool:
	if not is_instance_valid(_animated_sprite) or _animated_sprite.sprite_frames == null:
		return false
	var frames := _animated_sprite.sprite_frames
	for anim_name in ["idle", "run", "hit", "death"]:
		if frames.has_animation(anim_name) and frames.get_frame_count(anim_name) > 0:
			return true
	return false

func _sync_visual_mode() -> void:
	var use_sprite := has_sprite_art()
	if is_instance_valid(_animated_sprite):
		_animated_sprite.visible = use_sprite
	if is_instance_valid(_visual):
		_visual.visible = not use_sprite
	if is_instance_valid(_jersey_stripe):
		_jersey_stripe.visible = not use_sprite
	if is_instance_valid(_football_mark):
		_football_mark.visible = not use_sprite
	if is_instance_valid(_role_label):
		_role_label.visible = not use_sprite

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	experience_changed.emit(experience, experience_to_next_level, level)
	SettingsManager.palette_changed.connect(_update_character_visual)
	_sync_visual_mode()

func is_flagged() -> bool:
	return _flagged_remaining > 0.0

func apply_flagged(duration: float = 2.0) -> void:
	_flagged_remaining = maxf(_flagged_remaining, duration)
	AudioManager.play_cue("flagged")
	SettingsManager.rumble(0.4, 0.6, 0.2)

func enter_penalty_zone() -> void:
	_penalty_zone_count += 1

func exit_penalty_zone() -> void:
	_penalty_zone_count = maxi(_penalty_zone_count - 1, 0)

func is_in_penalty_zone() -> bool:
	return _penalty_zone_count > 0

func notify_attack_fired() -> void:
	if is_in_penalty_zone() and not is_flagged():
		apply_flagged(2.0)

func set_turf_speed_modifier(modifier: float) -> void:
	turf_speed_modifier = clampf(modifier, 0.1, 2.0)

func get_audible_name() -> String:
	var char_id: String = str(_character_data.get("id", "quarterback"))
	match char_id:
		"running_back":
			return "Juke Move"
		"linebacker":
			return "Bull Rush"
		_:
			return "Pocket Protection"

func get_audible_ready() -> bool:
	return audible_cooldown_remaining <= 0.0 and health > 0.0

func trigger_audible() -> bool:
	if not get_audible_ready():
		return false
	audible_cooldown_remaining = AUDIBLE_COOLDOWN
	notify_attack_fired()
	var char_id: String = str(_character_data.get("id", "quarterback"))
	_audible_ability_type = char_id
	_audible_hit_enemies.clear()

	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir.length_squared() > 0.01:
		_facing_direction = move_dir.normalized()

	match char_id:
		"running_back":
			_audible_active_time = 0.35
			_audible_dash_velocity = _facing_direction * (speed * 3.2)
			_damage_cooldown_remaining = 0.35
			AudioManager.play_cue("audible_rb")
			SettingsManager.rumble(0.4, 0.6, 0.2)
		"linebacker":
			_audible_active_time = 0.5
			_audible_dash_velocity = _facing_direction * (speed * 2.5)
			AudioManager.play_cue("audible_lb")
			SettingsManager.rumble(0.6, 0.85, 0.35)
		_:
			# Quarterback Pocket Protection
			_audible_active_time = 0.0
			_pocket_pulse_remaining = 0.4
			_damage_cooldown_remaining = 2.0
			_feedback_remaining = 0.5
			AudioManager.play_cue("audible_qb")
			SettingsManager.rumble(0.45, 0.7, 0.25)
			for node in get_tree().get_nodes_in_group("enemy"):
				var enemy: Enemy = node as Enemy
				if is_instance_valid(enemy):
					var diff := enemy.global_position - global_position
					if diff.length() <= 220.0 and diff.length() > 0.0:
						enemy.take_damage(20.0)
						enemy.apply_knockback(diff.normalized() * 650.0)
						var main := get_tree().current_scene
						if main != null and main.has_method("_on_weapon_hit"):
							main._on_weapon_hit("Pocket Protection")

	audible_triggered.emit(get_audible_name())
	queue_redraw()
	return true

func _physics_process(delta: float) -> void:
	_feedback_remaining = maxf(_feedback_remaining - delta, 0.0)
	_damage_cooldown_remaining = maxf(_damage_cooldown_remaining - delta, 0.0)
	_flagged_remaining = maxf(_flagged_remaining - delta, 0.0)
	audible_cooldown_remaining = maxf(audible_cooldown_remaining - delta, 0.0)
	_pocket_pulse_remaining = maxf(_pocket_pulse_remaining - delta, 0.0)

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.01:
		_facing_direction = input_vector.normalized()

	if Input.is_action_just_pressed("audible_ability"):
		trigger_audible()

	var effective_speed := speed * turf_speed_modifier
	if is_flagged():
		effective_speed *= 0.55

	if _audible_active_time > 0.0:
		_audible_active_time = maxf(_audible_active_time - delta, 0.0)
		velocity = _audible_dash_velocity
		_process_audible_collisions()
	else:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity = input_vector * effective_speed + _knockback_velocity

	move_and_slide()

	# Visual modulation
	var is_hit := _feedback_remaining > 0.0
	var mod_color := Color.WHITE
	if is_hit:
		mod_color = Color(1.0, 0.45, 0.45, 1.0)
	elif is_flagged():
		mod_color = Color(1.0, 0.9, 0.25, 1.0)
	elif _damage_cooldown_remaining > 0.0:
		mod_color = Color(1.0, 0.85, 0.4, 0.9)

	if has_sprite_art():
		_animated_sprite.modulate = mod_color
		if velocity.length_squared() > 10.0:
			if _animated_sprite.animation != "run":
				_animated_sprite.play("run")
			if velocity.x != 0.0:
				_animated_sprite.flip_h = velocity.x < 0.0
		else:
			if _animated_sprite.animation != "idle":
				_animated_sprite.play("idle")
	else:
		_visual.modulate = mod_color

	queue_redraw()

func _process_audible_collisions() -> void:
	var hit_radius := 44.0 if _audible_ability_type == "running_back" else 52.0
	var dmg := 35.0 if _audible_ability_type == "running_back" else 50.0
	var kb := 250.0 if _audible_ability_type == "running_back" else 550.0
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		if not is_instance_valid(enemy) or enemy in _audible_hit_enemies:
			continue
		if global_position.distance_to(enemy.global_position) <= hit_radius:
			_audible_hit_enemies.append(enemy)
			enemy.take_damage(dmg)
			var kb_dir := _facing_direction
			enemy.apply_knockback(kb_dir * kb)
			var main := get_tree().current_scene
			if main != null and main.has_method("_on_weapon_hit"):
				main._on_weapon_hit(get_audible_name())

func take_damage(amount: float) -> void:
	if amount <= 0.0 or _damage_cooldown_remaining > 0.0 or health <= 0.0:
		return
	var actual_amount := amount
	if _audible_active_time > 0.0 and _audible_ability_type == "linebacker":
		actual_amount *= 0.2
	_damage_cooldown_remaining = damage_cooldown
	health = maxf(health - actual_amount, 0.0)
	_feedback_remaining = 0.22
	if has_sprite_art() and _animated_sprite.sprite_frames.has_animation("hit") and _animated_sprite.sprite_frames.get_frame_count("hit") > 0:
		_animated_sprite.play("hit")
	SettingsManager.rumble(0.4, 0.7, 0.2)
	damage_taken.emit(actual_amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		velocity = Vector2.ZERO
		set_physics_process(false)
		if has_sprite_art() and _animated_sprite.sprite_frames.has_animation("death") and _animated_sprite.sprite_frames.get_frame_count("death") > 0:
			_animated_sprite.play("death")
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

func _draw() -> void:
	if _pocket_pulse_remaining > 0.0:
		var progress := 1.0 - (_pocket_pulse_remaining / 0.4)
		var r := lerpf(40.0, 220.0, progress)
		var col := Color(1.0, 0.85, 0.3, 1.0 - progress)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, col, 5.0)
	if _audible_active_time > 0.0:
		if _audible_ability_type == "running_back":
			draw_circle(Vector2.ZERO, 28.0, Color(0.2, 0.9, 0.5, 0.35))
		elif _audible_ability_type == "linebacker":
			draw_circle(Vector2.ZERO, 34.0, Color(0.95, 0.25, 0.25, 0.4))
	if is_flagged():
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.1, 0.8), 3.0)
