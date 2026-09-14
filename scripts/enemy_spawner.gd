class_name EnemySpawner
extends Node2D

signal phase_changed(title: String, details: String)
signal hazard_changed(hazard_type: String, hazard_title: String, hazard_desc: String)

const WAVE_PHASES := [
	{"start": 0.0, "end": 45.0, "title": "KICKOFF", "details": "Defenders establish the line.", "interval": 2.5, "cap": 12, "runner": 0.05, "thrower": 0.0, "blocker": 0.0, "coach": 0.0, "referee": 0.0, "hazard": ""},
	{"start": 45.0, "end": 105.0, "title": "FIRST QUARTER", "details": "Runners and Referees join the field.", "interval": 2.1, "cap": 15, "runner": 0.15, "thrower": 0.04, "blocker": 0.02, "coach": 0.0, "referee": 0.04, "hazard": ""},
	{"start": 105.0, "end": 150.0, "title": "SECOND QUARTER", "details": "Throwers test the pocket through Muddy Turf.", "interval": 1.8, "cap": 18, "runner": 0.22, "thrower": 0.1, "blocker": 0.06, "coach": 0.02, "referee": 0.06, "hazard": "muddy_turf"},
	{"start": 150.0, "end": 210.0, "title": "HALFTIME DRIVE", "details": "The Elite takes the field; hold the line.", "interval": 1.7, "cap": 20, "runner": 0.26, "thrower": 0.12, "blocker": 0.08, "coach": 0.04, "referee": 0.06, "hazard": ""},
	{"start": 210.0, "end": 270.0, "title": "FINAL DRIVE", "details": "Sideline Chains restrict the field under heavy pressure.", "interval": 1.5, "cap": 22, "runner": 0.28, "thrower": 0.14, "blocker": 0.10, "coach": 0.06, "referee": 0.07, "hazard": "sideline_chains"},
	{"start": 270.0, "end": 300.0, "title": "RED ZONE", "details": "Survive the last stand across the gridiron.", "interval": 1.35, "cap": 24, "runner": 0.28, "thrower": 0.16, "blocker": 0.12, "coach": 0.08, "referee": 0.08, "hazard": ""},
]

@export var enemy_scene: PackedScene
@export var runner_scene: PackedScene
@export var thrower_scene: PackedScene
@export var blocker_scene: PackedScene
@export var coach_scene: PackedScene
@export var referee_scene: PackedScene
@export var boss_scene: PackedScene
@export var spawn_interval := 2.5
@export var max_enemies := 12
@export var spawn_x := 520.0
@export var spawn_y := 270.0
@export var runner_chance_start := 0.0
@export var runner_chance_max := 0.3
@export var thrower_chance_max := 0.16
@export var blocker_chance_max := 0.12
@export var coach_chance_max := 0.08
@export var referee_chance_max := 0.08

const PRO_DIFFICULTY_PRESSURE_MULTIPLIER := 1.2

var _spawn_timer := 0.0
var pressure := 1.0
var pro_difficulty := false
var _phase_index := -1
var _phase_interval := 2.5
var _phase_cap := 12
var _phase_chances := {"runner": 0.0, "thrower": 0.0, "blocker": 0.0, "coach": 0.0, "referee": 0.0}
var _current_hazard := ""

func _ready() -> void:
	reset_run()

func reset_run() -> void:
	pressure = 1.0
	spawn_interval = 2.5
	max_enemies = 12
	_spawn_timer = spawn_interval
	_phase_index = -1
	_current_hazard = ""
	update_director(0.0, 1.0)

func _process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = spawn_interval
	if get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return
	_spawn_enemy()

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var scene_to_spawn := enemy_scene
	var runner_chance: float = _phase_chances["runner"]
	var thrower_chance: float = _phase_chances["thrower"]
	var blocker_chance: float = _phase_chances["blocker"]
	var coach_chance: float = _phase_chances["coach"]
	var referee_chance: float = _phase_chances["referee"]

	var roll := randf()
	if referee_scene != null and roll < referee_chance:
		scene_to_spawn = referee_scene
	elif runner_scene != null and roll < (referee_chance + runner_chance):
		scene_to_spawn = runner_scene
	elif thrower_scene != null and roll < (referee_chance + runner_chance + thrower_chance):
		scene_to_spawn = thrower_scene
	elif blocker_scene != null and roll < (referee_chance + runner_chance + thrower_chance + blocker_chance):
		scene_to_spawn = blocker_scene
	elif coach_scene != null and roll < (referee_chance + runner_chance + thrower_chance + blocker_chance + coach_chance):
		scene_to_spawn = coach_scene

	if scene_to_spawn == null:
		return
	var enemy: Enemy = scene_to_spawn.instantiate() as Enemy
	if enemy == null:
		return
	enemy.position = _perimeter_position()
	enemy.apply_pressure(pressure)
	enemy.add_to_group("enemy")
	get_parent().add_child(enemy)

func set_pressure(value: float) -> void:
	var effective_value := value * PRO_DIFFICULTY_PRESSURE_MULTIPLIER if pro_difficulty else value
	pressure = maxf(effective_value, 1.0)
	spawn_interval = maxf(_phase_interval / pressure, 0.65)
	max_enemies = _phase_cap + int((pressure - 1.0) * 6.0)

func update_director(elapsed: float, current_pressure: float) -> void:
	var next_index := WAVE_PHASES.size() - 1
	for index in WAVE_PHASES.size():
		var phase: Dictionary = WAVE_PHASES[index]
		if elapsed >= phase["start"] and elapsed < phase["end"]:
			next_index = index
			break
	if next_index != _phase_index:
		_phase_index = next_index
		var selected: Dictionary = WAVE_PHASES[_phase_index]
		_phase_interval = selected["interval"]
		_phase_cap = selected["cap"]
		_phase_chances = {
			"runner": selected["runner"],
			"thrower": selected["thrower"],
			"blocker": selected["blocker"],
			"coach": selected["coach"],
			"referee": selected.get("referee", 0.0),
		}
		phase_changed.emit(selected["title"], selected["details"])

		var new_hazard: String = selected.get("hazard", "")
		if new_hazard != _current_hazard:
			_current_hazard = new_hazard
			var h_title := ""
			var h_desc := ""
			match _current_hazard:
				"muddy_turf":
					h_title = "TURF HAZARD: MUDDY TURF"
					h_desc = "Soggy field reduces movement speed!"
				"sideline_chains":
					h_title = "TURF HAZARD: SIDELINE CHAINS"
					h_desc = "Sideline chains restrict the playable field width!"
				_:
					h_title = "TURF CLEAR"
					h_desc = "Standard field conditions restored."
			hazard_changed.emit(_current_hazard, h_title, h_desc)

	set_pressure(current_pressure)
	max_enemies = _phase_cap + int((pressure - 1.0) * 6.0)

func update_director(elapsed: float, current_pressure: float) -> void:
	var next_index := WAVE_PHASES.size() - 1
	for index in WAVE_PHASES.size():
		var phase: Dictionary = WAVE_PHASES[index]
		if elapsed >= phase["start"] and elapsed < phase["end"]:
			next_index = index
			break
	if next_index != _phase_index:
		_phase_index = next_index
		var selected: Dictionary = WAVE_PHASES[_phase_index]
		_phase_interval = selected["interval"]
		_phase_cap = selected["cap"]
		_phase_chances = {
			"runner": selected["runner"],
			"thrower": selected["thrower"],
			"blocker": selected["blocker"],
			"coach": selected["coach"],
		}
		phase_changed.emit(selected["title"], selected["details"])
	set_pressure(current_pressure)

func spawn_boss() -> Enemy:
	if boss_scene == null:
		return null
	var boss: Enemy = boss_scene.instantiate() as Enemy
	if boss == null:
		return null
	boss.position = _perimeter_position()
	boss.add_to_group("enemy")
	get_parent().add_child(boss)
	return boss

func _perimeter_position() -> Vector2:
	var edge := randi() % 4
	match edge:
		0:
			return Vector2(randf_range(-spawn_x, spawn_x), -spawn_y)
		1:
			return Vector2(randf_range(-spawn_x, spawn_x), spawn_y)
		2:
			return Vector2(-spawn_x, randf_range(-spawn_y, spawn_y))
		_:
			return Vector2(spawn_x, randf_range(-spawn_y, spawn_y))
