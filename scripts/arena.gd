class_name Arena
extends Node2D

func apply_map(map_data: Dictionary) -> void:
	if map_data.is_empty():
		return
	if has_node("Floor"):
		($Floor as Polygon2D).color = map_data.get("turf_color", Color(0.06, 0.34, 0.16, 1.0))
	if has_node("LeftEndZone"):
		($LeftEndZone as Polygon2D).color = map_data.get("end_zone_color", Color(0.04, 0.25, 0.13, 1.0))
	if has_node("RightEndZone"):
		($RightEndZone as Polygon2D).color = map_data.get("end_zone_color", Color(0.04, 0.25, 0.13, 1.0))
	if has_node("HomeSideline"):
		($HomeSideline as Line2D).default_color = map_data.get("sideline_color", Color(1.0, 0.82, 0.3, 0.9))
	if has_node("AwaySideline"):
		($AwaySideline as Line2D).default_color = map_data.get("sideline_color", Color(1.0, 0.82, 0.3, 0.9))
	if has_node("HomeGoalpost"):
		($HomeGoalpost as Line2D).default_color = map_data.get("goalpost_color", Color(1.0, 0.86, 0.35, 1.0))
	if has_node("AwayGoalpost"):
		($AwayGoalpost as Line2D).default_color = map_data.get("goalpost_color", Color(1.0, 0.86, 0.35, 1.0))
	if has_node("HomeEndZoneLabel"):
		($HomeEndZoneLabel as Label).add_theme_color_override("font_color", map_data.get("end_zone_label_color", Color(1.0, 0.82, 0.35, 0.8)))
	if has_node("AwayEndZoneLabel"):
		($AwayEndZoneLabel as Label).add_theme_color_override("font_color", map_data.get("end_zone_label_color", Color(1.0, 0.82, 0.35, 0.8)))
	if has_node("CrowdTop"):
		($CrowdTop as Polygon2D).color = map_data.get("crowd_color", Color(0.15, 0.19, 0.27, 0.9))
	if has_node("CrowdBottom"):
		($CrowdBottom as Polygon2D).color = map_data.get("crowd_color", Color(0.15, 0.19, 0.27, 0.9))
	if has_node("Boundary"):
		($Boundary as Line2D).default_color = map_data.get("boundary_color", Color(0.92, 0.97, 0.86, 1.0))
	if has_node("MidfieldCircle"):
		($MidfieldCircle as Polygon2D).color = map_data.get("yard_line_color", Color(0.75, 0.95, 0.73, 0.72))
	if has_node("CenterMark"):
		($CenterMark as Polygon2D).color = map_data.get("center_mark_color", Color(0.9, 0.98, 0.84, 0.9))

	var yard_color: Color = map_data.get("yard_line_color", Color(0.75, 0.95, 0.73, 0.72))
	for child in get_children():
		if child is Line2D and child.name.begins_with("YardLine"):
			(child as Line2D).default_color = yard_color
