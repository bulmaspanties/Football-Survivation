class_name Arena
extends Node2D

var _current_map_data: Dictionary = {}
var _current_hazard := ""

@onready var _left_boundary: StaticBody2D = get_node_or_null("LeftBoundary")
@onready var _right_boundary: StaticBody2D = get_node_or_null("RightBoundary")

func apply_map(map_data: Dictionary) -> void:
	if map_data.is_empty():
		return
	_current_map_data = map_data
	_update_visuals()

func _update_visuals() -> void:
	if _current_map_data.is_empty():
		return
	var turf_col: Color = _current_map_data.get("turf_color", Color(0.06, 0.34, 0.16, 1.0))
	if _current_hazard == "muddy_turf":
		turf_col = turf_col.lerp(Color(0.24, 0.18, 0.10, 1.0), 0.65)

	if has_node("Floor"):
		($Floor as Polygon2D).color = turf_col
	if has_node("LeftEndZone"):
		($LeftEndZone as Polygon2D).color = _current_map_data.get("end_zone_color", Color(0.04, 0.25, 0.13, 1.0))
	if has_node("RightEndZone"):
		($RightEndZone as Polygon2D).color = _current_map_data.get("end_zone_color", Color(0.04, 0.25, 0.13, 1.0))
	if has_node("HomeSideline"):
		($HomeSideline as Line2D).default_color = _current_map_data.get("sideline_color", Color(1.0, 0.82, 0.3, 0.9))
	if has_node("AwaySideline"):
		($AwaySideline as Line2D).default_color = _current_map_data.get("sideline_color", Color(1.0, 0.82, 0.3, 0.9))
	if has_node("HomeGoalpost"):
		($HomeGoalpost as Line2D).default_color = _current_map_data.get("goalpost_color", Color(1.0, 0.86, 0.35, 1.0))
	if has_node("AwayGoalpost"):
		($AwayGoalpost as Line2D).default_color = _current_map_data.get("goalpost_color", Color(1.0, 0.86, 0.35, 1.0))
	if has_node("HomeEndZoneLabel"):
		($HomeEndZoneLabel as Label).add_theme_color_override("font_color", _current_map_data.get("end_zone_label_color", Color(1.0, 0.82, 0.35, 0.8)))
	if has_node("AwayEndZoneLabel"):
		($AwayEndZoneLabel as Label).add_theme_color_override("font_color", _current_map_data.get("end_zone_label_color", Color(1.0, 0.82, 0.35, 0.8)))
	if has_node("CrowdTop"):
		($CrowdTop as Polygon2D).color = _current_map_data.get("crowd_color", Color(0.15, 0.19, 0.27, 0.9))
	if has_node("CrowdBottom"):
		($CrowdBottom as Polygon2D).color = _current_map_data.get("crowd_color", Color(0.15, 0.19, 0.27, 0.9))
	if has_node("Boundary"):
		($Boundary as Line2D).default_color = _current_map_data.get("boundary_color", Color(0.92, 0.97, 0.86, 1.0))
	if has_node("MidfieldCircle"):
		($MidfieldCircle as Polygon2D).color = _current_map_data.get("yard_line_color", Color(0.75, 0.95, 0.73, 0.72))
	if has_node("CenterMark"):
		($CenterMark as Polygon2D).color = _current_map_data.get("center_mark_color", Color(0.9, 0.98, 0.84, 0.9))

	var yard_color: Color = _current_map_data.get("yard_line_color", Color(0.75, 0.95, 0.73, 0.72))
	for child in get_children():
		if child is Line2D and child.name.begins_with("YardLine"):
			(child as Line2D).default_color = yard_color

func set_hazard(hazard: String) -> void:
	_current_hazard = hazard
	_update_visuals()
	if is_instance_valid(_left_boundary) and is_instance_valid(_right_boundary):
		if _current_hazard == "sideline_chains":
			_left_boundary.position.x = -395.0
			_right_boundary.position.x = 395.0
		else:
			_left_boundary.position.x = -572.0
			_right_boundary.position.x = 572.0
	queue_redraw()

func _draw() -> void:
	if _current_hazard == "sideline_chains":
		# Draw prominent warning chain barriers at +/- 385px
		var chain_col := Color(1.0, 0.85, 0.25, 0.85)
		draw_line(Vector2(-385.0, -300.0), Vector2(-385.0, 300.0), chain_col, 4.0)
		draw_line(Vector2(385.0, -300.0), Vector2(385.0, 300.0), chain_col, 4.0)
		for y in range(-280, 300, 40):
			draw_circle(Vector2(-385.0, float(y)), 6.0, Color(1.0, 0.3, 0.2, 0.9))
			draw_circle(Vector2(385.0, float(y)), 6.0, Color(1.0, 0.3, 0.2, 0.9))
	elif _current_hazard == "muddy_turf":
		# Draw subtle mud patch textures across field
		var mud_col := Color(0.2, 0.14, 0.08, 0.35)
		for pos in [Vector2(-200, -80), Vector2(-120, 100), Vector2(40, -120), Vector2(160, 60), Vector2(280, -40), Vector2(-20, 40)]:
			draw_circle(pos, 55.0, mud_col)
