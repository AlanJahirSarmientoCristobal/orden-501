extends Node

const MAX_CANALES := 10
const FRECUENCIA := 22050

var _canales: Array[AudioStreamPlayer] = []
var _musica: AudioStreamPlayer
var _murmullo: AudioStreamPlayer
var _cache := {}
var _pista_actual := ""
var _silencio := false
var _mutex := Mutex.new()
var _tarea := -1
var _pregenerado := false
var _pendiente := ""

const EFECTOS := {
	"click": [700.0, 0.05, "click", -6.0, ""],
	"pedido_listo": [1200.0, 0.45, "campana", 0.0, "pedido_listo"],
	"caja": [987.77, 0.35, "caja", -1.0, "caja"],
	"servir": [520.0, 0.15, "tintineo", -2.0, ""],
	"limpiar": [350.0, 0.25, "ruido", -5.0, ""],
	"cliente_perdido": [150.0, 0.4, "zumbido", 0.0, ""],
	"silbato": [1800.0, 0.55, "silbato", 0.0, "silbato"],
	"gol": [440.0, 1.4, "afición", 2.0, "gol"],
	"telefono": [880.0, 0.9, "telefono", -1.0, "telefono"],
	"stock_bajo": [660.0, 0.35, "alerta", -2.0, "stock_bajo"],
	"mejora": [523.25, 0.6, "arpegio", 0.0, ""],
	"error": [220.0, 0.2, "zumbido", -4.0, ""],
	"pedido": [900.0, 0.2, "campana", -4.0, ""],
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silencio = DisplayServer.get_name() == "headless"
	get_tree().node_added.connect(_al_agregar_nodo)
	for i in range(MAX_CANALES):
		var canal := AudioStreamPlayer.new()
		add_child(canal)
		_canales.append(canal)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -14.0
	add_child(_musica)
	_murmullo = AudioStreamPlayer.new()
	_murmullo.volume_db = -60.0
	add_child(_murmullo)
	if not _silencio:
		_tarea = WorkerThreadPool.add_task(_pregenerar, false, "Audio ORDEN 501")

func _pregenerar() -> void:
	for nombre in EFECTOS:
		var datos: Array = EFECTOS[nombre]
		_tono(nombre, datos[0], datos[1], datos[2])
	_generar_musica("manana")
	_generar_musica("jornada")
	_generar_murmullo()
	call_deferred("_pregeneracion_lista")

func _pregeneracion_lista() -> void:
	_pregenerado = true
	if _pendiente != "":
		var pista := _pendiente
		_pendiente = ""
		_pista_actual = ""
		musica(pista)

func _exit_tree() -> void:
	_exit_tree_audio()

func _exit_tree_audio() -> void:
	if _tarea != -1:
		WorkerThreadPool.wait_for_task_completion(_tarea)
		_tarea = -1

func _leer(clave: String) -> AudioStreamWAV:
	_mutex.lock()
	var valor: AudioStreamWAV = _cache.get(clave)
	_mutex.unlock()
	return valor

func _guardar(clave: String, valor: AudioStreamWAV) -> void:
	_mutex.lock()
	_cache[clave] = valor
	_mutex.unlock()

func sfx(nombre: String) -> void:
	if _silencio or not EFECTOS.has(nombre):
		return
	var datos: Array = EFECTOS[nombre]
	var stream: AudioStream = AssetPaths.audio(datos[4]) if datos[4] != "" else null
	if stream == null:
		stream = _tono(nombre, datos[0], datos[1], datos[2])
	var canal := _canal_libre()
	canal.stream = stream
	canal.volume_db = datos[3]
	canal.play()

func musica(pista: String) -> void:
	if _silencio or pista == _pista_actual:
		return
	_pista_actual = pista
	_musica.stop()
	_murmullo.stop()
	if pista == "":
		return
	var stream: AudioStream = AssetPaths.audio("musica_" + pista)
	if stream == null:
		if not _pregenerado and _leer("musica_" + pista) == null:
			_pendiente = pista
			return
		stream = _generar_musica(pista)
	_musica.stream = stream
	_musica.pitch_scale = 1.0
	_musica.play()
	if pista == "jornada":
		_murmullo.stream = _generar_murmullo()
		_murmullo.play()

func intensidad(factor: float) -> void:
	if _musica:
		_musica.pitch_scale = clampf(factor, 0.5, 2.0)

func murmullo(nivel: float) -> void:
	if _murmullo:
		_murmullo.volume_db = lerpf(-40.0, -16.0, clampf(nivel, 0.0, 1.0)) if nivel > 0.01 else -60.0

func _canal_libre() -> AudioStreamPlayer:
	for canal in _canales:
		if not canal.playing:
			return canal
	return _canales[0]

func _tono(nombre: String, frecuencia: float, duracion: float, tipo: String) -> AudioStreamWAV:
	var en_cache := _leer(nombre)
	if en_cache:
		return en_cache
	var muestras := int(FRECUENCIA * duracion)
	var datos := PackedFloat32Array()
	datos.resize(muestras)
	for i in range(muestras):
		var t := float(i) / FRECUENCIA
		var p := t / duracion
		var s := 0.0
		match tipo:
			"caja":
				var f := frecuencia if t < 0.12 else frecuencia * 1.5
				s = (sin(TAU * f * t) + 0.4 * sin(TAU * f * 2.0 * t)) * exp(-fmod(t, 0.12) * 16.0)
			"campana":
				s = (sin(TAU * frecuencia * t) + 0.5 * sin(TAU * frecuencia * 2.76 * t)) * exp(-t * 7.0) * 0.7
			"tintineo":
				s = (sin(TAU * frecuencia * t) + (randf() * 2.0 - 1.0) * 0.3) * exp(-t * 28.0)
			"ruido":
				s = (randf() * 2.0 - 1.0) * sin(PI * p) * 0.5
			"zumbido":
				s = (sin(TAU * frecuencia * t) + sin(TAU * frecuencia * 1.414 * t)) * (1.0 - p) * 0.6
			"silbato":
				s = sin(TAU * (frecuencia + sin(TAU * 25.0 * t) * 150.0) * t) * sin(PI * p) * 0.8
			"afición":
				var ruido := (randf() * 2.0 - 1.0) * 0.6
				var grito := sin(TAU * (frecuencia + p * 220.0) * t) * 0.25
				s = (ruido + grito) * sin(PI * p)
			"telefono":
				var activo := 1.0 if fmod(t, 0.3) < 0.2 else 0.0
				s = (sin(TAU * frecuencia * t) * 0.5 + sin(TAU * frecuencia * 1.25 * t) * 0.5) * activo * 0.6
			"alerta":
				var f2 := frecuencia if fmod(t, 0.16) < 0.08 else frecuencia * 0.75
				s = sin(TAU * f2 * t) * 0.6 * (1.0 - p * 0.5)
			"arpegio":
				var paso := clampi(int(t * 6.0), 0, 3)
				var notas := [1.0, 1.25, 1.5, 2.0]
				s = sin(TAU * frecuencia * notas[paso] * t) * (1.0 - p * 0.5) * 0.6
			_:
				s = sin(TAU * frecuencia * t) * exp(-t * 5.0)
		datos[i] = s
	var wav := _a_wav(datos, false)
	_guardar(nombre, wav)
	return wav

func _generar_musica(pista: String) -> AudioStreamWAV:
	var clave := "musica_" + pista
	var en_cache := _leer(clave)
	if en_cache:
		return en_cache
	var tranquila := pista == "manana"
	var bpm := 84.0 if tranquila else 132.0
	var pulso := 60.0 / bpm
	var compases := 8
	var duracion := pulso * 4.0 * compases
	var acordes := [[261.63, 329.63, 392.0], [220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [196.0, 246.94, 293.66]]
	var muestras := int(FRECUENCIA * duracion)
	var datos := PackedFloat32Array()
	datos.resize(muestras)
	var paso_arpegio := pulso / (2.0 if tranquila else 4.0)
	for i in range(muestras):
		var t := float(i) / FRECUENCIA
		var compas := int(t / (pulso * 4.0)) % compases
		var acorde: Array = acordes[int(compas / 2) % 4]
		var indice_nota := int(t / paso_arpegio) % 3
		var t_nota := fmod(t, paso_arpegio)
		var nota: float = acorde[indice_nota] * (2.0 if not tranquila else 1.0)
		var melodia := sin(TAU * nota * t) * exp(-t_nota * (3.0 if tranquila else 7.0)) * 0.35
		var t_pulso := fmod(t, pulso)
		var bajo := sin(TAU * acorde[0] * 0.5 * t) * exp(-t_pulso * 2.5) * 0.35
		var bateria := 0.0
		if not tranquila:
			bateria += sin(TAU * 60.0 * t_pulso) * exp(-t_pulso * 18.0) * 0.5
			var t_medio := fmod(t + pulso * 0.5, pulso)
			bateria += (randf() * 2.0 - 1.0) * exp(-t_medio * 40.0) * 0.15
		datos[i] = (melodia + bajo + bateria) * 0.8
	var wav := _a_wav(datos, true)
	_guardar(clave, wav)
	return wav

func _generar_murmullo() -> AudioStreamWAV:
	var en_cache := _leer("murmullo")
	if en_cache:
		return en_cache
	var muestras := FRECUENCIA * 2
	var datos := PackedFloat32Array()
	datos.resize(muestras)
	var previo := 0.0
	for i in range(muestras):
		var t := float(i) / FRECUENCIA
		previo = lerpf(previo, randf() * 2.0 - 1.0, 0.08)
		datos[i] = previo * (0.6 + 0.4 * sin(TAU * 1.3 * t)) * 1.5
	var wav := _a_wav(datos, true)
	_guardar("murmullo", wav)
	return wav

func _a_wav(datos: PackedFloat32Array, bucle: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(datos.size() * 2)
	for i in range(datos.size()):
		bytes.encode_s16(i * 2, int(clampf(datos[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = FRECUENCIA
	wav.stereo = false
	wav.data = bytes
	if bucle:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = datos.size()
	return wav

func _al_agregar_nodo(nodo: Node) -> void:
	if nodo is BaseButton and not nodo.pressed.is_connected(_clic):
		nodo.pressed.connect(_clic)

func _clic() -> void:
	sfx("click")
