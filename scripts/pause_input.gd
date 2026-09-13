extends Node

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") and not event.is_echo():
		var main := get_parent()
		if main.has_method("_on_pause_requested"):
			main._on_pause_requested()
