class_name ExperiencePickup
extends Area2D

@export var amount := 2
@export var pickup_radius := 26.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_palette_color()
	SettingsManager.palette_changed.connect(_update_palette_color)

func _update_palette_color() -> void:
	if has_node("Visual"):
		var visual := $Visual as CanvasItem
		if visual is Polygon2D:
			(visual as Polygon2D).color = SettingsManager.get_color("xp_pickup", Color(0.45, 0.95, 0.55, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect_experience(amount)
		queue_free()
