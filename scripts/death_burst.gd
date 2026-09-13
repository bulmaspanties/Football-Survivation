extends Node2D

var _age := 0.0
var _duration := 0.28
var _burst_color := Color(1.0, 0.42, 0.18, 1.0)

func setup(color: Color) -> void:
	_burst_color = color
	queue_redraw()

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= _duration:
		queue_free()

func _draw() -> void:
	var progress := _age / _duration
	var radius := lerpf(5.0, 30.0, progress)
	var alpha := 1.0 - progress
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var direction := Vector2.from_angle(angle)
		draw_line(direction * radius * 0.35, direction * radius, Color(_burst_color, alpha), 3.0)
	draw_circle(Vector2.ZERO, lerpf(5.0, 2.0, progress), Color(_burst_color, alpha))
