extends Node

# Generador de alarma sintetica para cada panel usando AudioStreamGenerator.
# No requiere archivos de audio externos: sintetiza tonos en tiempo real.

@export var frecuencia_base: float = 440.0
@export var umbral_alarma: float = 70.0
@export var umbral_critico: float = 90.0

var _reproductor: AudioStreamPlayer3D
var _stream: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback

var _activa: bool = false
var _fase: float = 0.0
var _volumen_actual: float = 0.0
var _volumen_objetivo: float = 0.0

const TASA_MUESTREO: float = 22050.0
const FADE_VELOCIDAD: float = 2.5

func _ready() -> void:
	_stream = AudioStreamGenerator.new()
	_stream.mix_rate = TASA_MUESTREO
	_stream.buffer_length = 0.1
	
	_reproductor = AudioStreamPlayer3D.new()
	_reproductor.stream = _stream
	_reproductor.max_distance = 6.0
	_reproductor.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	_reproductor.unit_size = 1.5
	_reproductor.volume_db = -80.0
	add_child(_reproductor)
	_reproductor.play()
	_playback = _reproductor.get_stream_playback()

func _process(delta: float) -> void:
	# Interpolar suavemente hacia el volumen objetivo
	_volumen_actual = lerpf(_volumen_actual, _volumen_objetivo, FADE_VELOCIDAD * delta)
	
	if _volumen_actual < 0.001:
		return
	
	if _playback == null or not _reproductor.playing:
		return
	
	# Calcular cuantos frames se pueden rellenar
	var frames_disponibles = _playback.get_frames_available()
	if frames_disponibles <= 0:
		return
	
	var incremento = (TAU * frecuencia_base) / TASA_MUESTREO
	var frames_a_escribir = mini(frames_disponibles, 512)
	
	for _i in range(frames_a_escribir):
		var muestra = sin(_fase) * _volumen_actual
		_playback.push_frame(Vector2(muestra, muestra))
		_fase += incremento
		if _fase > TAU:
			_fase -= TAU

func activar(calor: float) -> void:
	if calor >= umbral_alarma:
		# Modulacion de volumen entre umbral y nivel critico
		var rango = umbral_critico - umbral_alarma
		var exceso = clampf(calor - umbral_alarma, 0.0, rango)
		var factor = exceso / rango if rango > 0.0 else 1.0
		_volumen_objetivo = lerpf(0.08, 0.6, factor)
		
		# Variacion de frecuencia: sube con el calor para aumentar urgencia
		frecuencia_base = lerpf(frecuencia_base, _frecuencia_critica(), 0.02)
		_activa = true
	else:
		desactivar()

func desactivar() -> void:
	_volumen_objetivo = 0.0
	_activa = false

func esta_activa() -> bool:
	return _activa

func _frecuencia_critica() -> float:
	return frecuencia_base * 2.0
