class_name ExperiencePickup
extends Area2D

@export var amount := 2
@export var pickup_radius := 26.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect_experience(amount)
		queue_free()
