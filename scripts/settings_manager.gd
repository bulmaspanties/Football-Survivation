extends Node

signal settings_changed

const DEFAULT_VOLUME := 1.0

var master_volume := DEFAULT_VOLUME
var muted := false
var fullscreen := false

func _ready() -> void:
	_apply_audio()
	_apply_display()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	settings_changed.emit()

func set_muted(value: bool) -> void:
	muted = value
	_apply_audio()
	settings_changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	settings_changed.emit()

func reset_defaults() -> void:
	master_volume = DEFAULT_VOLUME
	muted = false
	fullscreen = false
	_apply_audio()
	_apply_display()
	settings_changed.emit()

func _apply_audio() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.0001)))
		AudioServer.set_bus_mute(master_bus, muted)

func _apply_display() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
