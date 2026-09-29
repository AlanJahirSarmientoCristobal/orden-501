extends Node

# Gestor de audio para 501: Rush de Campeonato
var players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS = 10

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(MAX_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		players.append(p)

func _get_available_player() -> AudioStreamPlayer:
	for p in players:
		if not p.playing:
			return p
	return players[0]

func _exit_tree() -> void:
	for player in players:
		player.stop()
		player.stream = null
	players.clear()

func play_sfx_register() -> void:
	# Caja registradora / kaching al cobrar mesa
	var stream = _generate_tone(987.77, 0.35, "register")
	_play_stream(stream, 0.0)

func play_sfx_bell() -> void:
	# Campanilla de orden lista en cocina
	var stream = _generate_tone(1200.0, 0.4, "bell")
	_play_stream(stream, 1.0)

func play_sfx_datapad() -> void:
	# Escaneo digital futurista de demanda
	var stream = _generate_tone(600.0, 0.45, "datapad")
	_play_stream(stream, 2.0)

func play_sfx_clink() -> void:
	# Entrega de plato a la mesa
	var stream = _generate_tone(500.0, 0.15, "clink")
	_play_stream(stream, 0.0)

func play_sfx_clean() -> void:
	# Limpieza de mesa
	var stream = _generate_tone(350.0, 0.2, "clean")
	_play_stream(stream, -3.0)

func play_sfx_lost_customer() -> void:
	# Cliente molesto que se va
	var stream = _generate_tone(150.0, 0.4, "buzzer")
	_play_stream(stream, 2.0)

func play_sfx_whistle() -> void:
	# Silbatazo de inicio de partido / medio tiempo
	var stream = _generate_tone(1800.0, 0.5, "whistle")
	_play_stream(stream, 2.0)

func play_sfx_click() -> void:
	var stream = _generate_tone(700.0, 0.05, "click")
	_play_stream(stream, -4.0)

func play_sfx_upgrade() -> void:
	var stream = _generate_tone(523.25, 0.6, "upgrade")
	_play_stream(stream, 1.0)

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	# Las pruebas headless no tienen salida de audio y no necesitan crear playbacks.
	if DisplayServer.get_name() == "headless":
		return
	var player = _get_available_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func _generate_tone(base_freq: float, duration: float, sound_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var sample: float = 0.0
		
		match sound_type:
			"register":
				# Dos notas brillantes consecutivas
				var f = base_freq if t < 0.12 else base_freq * 1.5
				var env = exp(-fmod(t, 0.12) * 16.0)
				sample = (sin(2.0 * PI * f * t) + 0.4 * sin(2.0 * PI * f * 2.0 * t)) * env
			"bell":
				var env = exp(-t * 7.0)
				sample = (sin(2.0 * PI * base_freq * t) + 0.5 * sin(2.0 * PI * base_freq * 2.76 * t)) * env * 0.7
			"datapad":
				# Sonido estilo radar sci-fi ascendente
				var f = base_freq + (t / duration) * 800.0 + sin(t * 80.0) * 100.0
				var env = sin(PI * (t / duration))
				sample = (sin(2.0 * PI * f * t) + 0.3 * (randf() * 2.0 - 1.0)) * env * 0.6
			"clink":
				var env = exp(-t * 28.0)
				sample = (sin(2.0 * PI * base_freq * t) + (randf() * 2.0 - 1.0) * 0.3) * env
			"clean":
				var env = sin(PI * (t / duration))
				sample = (randf() * 2.0 - 1.0) * env * 0.5
			"buzzer":
				# Tono grave discordante
				var env = 1.0 - (t / duration)
				sample = (sin(2.0 * PI * base_freq * t) + sin(2.0 * PI * (base_freq * 1.414) * t)) * env * 0.7
			"whistle":
				var mod = sin(2.0 * PI * 25.0 * t) * 150.0
				var env = sin(PI * (t / duration))
				sample = sin(2.0 * PI * (base_freq + mod) * t) * env * 0.8
			"upgrade":
				var step = int(t * 6.0)
				var freqs = [base_freq, base_freq * 1.25, base_freq * 1.5, base_freq * 2.0]
				var f = freqs[clamp(step, 0, 3)]
				sample = sin(2.0 * PI * f * t) * (1.0 - (t / duration) * 0.5) * 0.6
			_:
				sample = sin(2.0 * PI * base_freq * t) * exp(-t * 5.0)
		
		sample = clamp(sample, -1.0, 1.0)
		var int_val = int(sample * 32767.0)
		if int_val < 0:
			int_val += 65536
		bytes[i * 2] = int_val & 0xFF
		bytes[i * 2 + 1] = (int_val >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav
