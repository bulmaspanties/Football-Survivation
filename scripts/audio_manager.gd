extends Node

# Centralized, built-in-only SFX playback. Cues are procedurally generated
# short tones/noise bursts cached as AudioStreamWAV and routed through the
# Master bus, so SettingsManager volume/mute apply automatically. The cue
# table is the single integration point: call sites only ever request a
# named cue, so real audio assets could later replace generated tones here
# without touching any call site.

const MIX_RATE := 22050
const POOL_SIZE := 12

# wave: "sine", "square", or "noise". sweep_to (optional) glides the pitch
# linearly from freq to that frequency across the cue's duration.
# respect_pause: true skips playback while the tree is paused (gameplay
# cues); false always plays (menu navigation/confirmation feedback).
const CUES := {
	"football_throw": {"freq": 640.0, "duration": 0.08, "wave": "square", "volume_db": -8.0, "respect_pause": true},
	"tackle_burst": {"freq": 140.0, "duration": 0.18, "wave": "noise", "volume_db": -5.0, "respect_pause": true},
	"hail_mary_throw": {"freq": 260.0, "sweep_to": 460.0, "duration": 0.38, "wave": "sine", "volume_db": -6.0, "respect_pause": true},
	"stiff_arm": {"freq": 320.0, "sweep_to": 180.0, "duration": 0.14, "wave": "square", "volume_db": -6.0, "respect_pause": true},
	"enemy_hit": {"freq": 900.0, "duration": 0.05, "wave": "square", "volume_db": -10.0, "respect_pause": true},
	"enemy_defeat": {"freq": 420.0, "sweep_to": 120.0, "duration": 0.22, "wave": "noise", "volume_db": -7.0, "respect_pause": true},
	"xp_pickup": {"freq": 780.0, "sweep_to": 1040.0, "duration": 0.12, "wave": "sine", "volume_db": -9.0, "respect_pause": true},
	"level_up": {"freq": 440.0, "sweep_to": 880.0, "duration": 0.45, "wave": "sine", "volume_db": -5.0, "respect_pause": false},
	"phase_change": {"freq": 500.0, "sweep_to": 640.0, "duration": 0.3, "wave": "sine", "volume_db": -7.0, "respect_pause": true},
	"boss_warning": {"freq": 200.0, "sweep_to": 140.0, "duration": 0.5, "wave": "square", "volume_db": -5.0, "respect_pause": true},
	"boss_defeat": {"freq": 300.0, "sweep_to": 80.0, "duration": 0.6, "wave": "noise", "volume_db": -4.0, "respect_pause": true},
	"player_damage": {"freq": 160.0, "duration": 0.12, "wave": "noise", "volume_db": -6.0, "respect_pause": true},
	"victory": {"freq": 520.0, "sweep_to": 1040.0, "duration": 0.6, "wave": "sine", "volume_db": -4.0, "respect_pause": false},
	"game_over": {"freq": 300.0, "sweep_to": 90.0, "duration": 0.55, "wave": "square", "volume_db": -5.0, "respect_pause": false},
	"menu_navigate": {"freq": 620.0, "duration": 0.045, "wave": "sine", "volume_db": -12.0, "respect_pause": false},
	"menu_confirm": {"freq": 720.0, "sweep_to": 900.0, "duration": 0.09, "wave": "sine", "volume_db": -9.0, "respect_pause": false},
}

var _stream_cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_players.append(player)

func play_cue(cue_id: String) -> void:
	if not CUES.has(cue_id):
		return
	var cue: Dictionary = CUES[cue_id]
	if bool(cue.get("respect_pause", true)) and get_tree().paused:
		return
	var player := _acquire_player()
	player.stream = _get_stream(cue_id, cue)
	player.volume_db = float(cue.get("volume_db", 0.0))
	player.play()

func _acquire_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return player

func _get_stream(cue_id: String, cue: Dictionary) -> AudioStreamWAV:
	if _stream_cache.has(cue_id):
		return _stream_cache[cue_id]
	var stream := _generate_tone(cue)
	_stream_cache[cue_id] = stream
	return stream

func _generate_tone(cue: Dictionary) -> AudioStreamWAV:
	var duration: float = maxf(float(cue.get("duration", 0.1)), 0.02)
	var freq: float = float(cue.get("freq", 440.0))
	var sweep_to: float = float(cue.get("sweep_to", freq))
	var wave: String = str(cue.get("wave", "sine"))
	var sample_count := maxi(int(MIX_RATE * duration), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hash(cue))
	var phase := 0.0
	var attack := minf(0.008, duration * 0.25)
	var release := minf(0.06, duration * 0.5)
	for i in sample_count:
		var t := float(i) / float(MIX_RATE)
		var progress := float(i) / float(maxi(sample_count - 1, 1))
		var current_freq := lerpf(freq, sweep_to, progress)
		phase += current_freq / float(MIX_RATE)
		var sample := 0.0
		match wave:
			"noise":
				sample = rng.randf_range(-1.0, 1.0)
			"square":
				sample = 1.0 if sin(phase * TAU) >= 0.0 else -1.0
			_:
				sample = sin(phase * TAU)
		var envelope := 1.0
		if t < attack:
			envelope = t / attack
		elif t > duration - release:
			envelope = maxf((duration - t) / release, 0.0)
		sample = clampf(sample * envelope, -1.0, 1.0)
		var value := int(sample * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
