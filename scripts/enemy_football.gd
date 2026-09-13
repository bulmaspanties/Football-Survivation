class_name EnemyFootball
extends Area2D

@export var speed := 220.0
@export var damage := 12.0
@export var lifetime := 3.5

var direction := Vector2.RIGHT
var _remaining_lifetime := 0.0

func _ready() -> void:
	_remaining_lifetime = lifetime
	body_entered.connect(_on_body_entered)

func launch(aim_direction: Vector2) -> void:
	if aim_direction.length_squared() > 0.0:
		direction = aim_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()
		return
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()
