class_name StiffArm
extends Node2D

@export var cooldown := 2.0
@export var radius := 82.0
@export var damage := 26.0

var unlocked := false
var _cooldown_remaining := 0.0
var _feedback_remaining := 0.0
var _player: Player

func _ready() -> void:
	_player = get_parent() as Player
	set_process(false)

func _process(delta: float) -> void:
	if not unlocked or not is_instance_valid(_player) or _player.health <= 0.0:
		return
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	_feedback_remaining = maxf(_feedback_remaining - delta, 0.0)
	queue_redraw()
	if _cooldown_remaining > 0.0:
		return
	var hit_count := 0
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy: Enemy = node as Enemy
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(damage)
			hit_count += 1
			var main := get_tree().current_scene
			if main != null and main.has_method("_on_weapon_hit"):
				main._on_weapon_hit("Stiff Arm")
	if hit_count > 0:
		_cooldown_remaining = cooldown
		_feedback_remaining = 0.2
		SettingsManager.rumble(0.3, 0.45, 0.14)
		AudioManager.play_cue("stiff_arm")

func unlock() -> void:
	unlocked = true
	set_process(true)

func activate() -> void:
	unlocked = true
	set_process(true)

func upgrade_damage(amount: float) -> void:
	damage += amount

func upgrade_cooldown(reduction: float) -> void:
	cooldown = maxf(cooldown - reduction, 0.7)

func _draw() -> void:
	if _feedback_remaining <= 0.0:
		return
	var progress := 1.0 - (_feedback_remaining / 0.2)
	draw_arc(Vector2.ZERO, lerpf(radius * 0.3, radius, progress), -1.1, 1.1, 24, Color(0.25, 0.9, 1.0, 1.0 - progress), 6.0)
