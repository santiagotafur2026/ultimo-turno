extends Node3D

signal panel_apagado(panel: Node3D)
signal panel_reiniciado(panel: Node3D)
signal calor_cambiado(nuevo_calor: float)

@export var calor: float = 30.0
@export var tasa_generacion: float = 4.0
@export var icono: String = ""
@export var nombre_sistema: String = ""
@export var frecuencia_alarma: float = 440.0

var tasa_extra: float = 0.0
var apagado: bool = false
var sin_senal: bool = false

@onready var texto: Label3D = get_node_or_null("Consola/Label3D")
@onready var aguja: Node3D = get_node_or_null("Consola/Dial/AgujaPivot")
@onready var luz_led: OmniLight3D = get_node_or_null("Consola/LuzLED")
@onready var alarma: Node = get_node_or_null("Alarma")

const ANGULO_MIN_AGUJA: float = 75.0
const ANGULO_MAX_AGUJA: float = -75.0

var _era_apagado: bool = false

func _ready() -> void:
	if nombre_sistema == "":
		nombre_sistema = name
	if alarma != null and "frecuencia_base" in alarma:
		alarma.frecuencia_base = frecuencia_alarma
	actualizar_interfaz_diegética()

func _physics_process(delta: float) -> void:
	if not apagado:
		calor += (tasa_generacion + tasa_extra) * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			if alarma != null:
				alarma.desactivar()
			panel_apagado.emit(self)
		else:
			# Actualizar alarma segun temperatura actual
			if alarma != null:
				alarma.activar(calor)
		actualizar_interfaz_diegética()
		calor_cambiado.emit(calor)
	
	# Parpadeo del LED cuando esta en estado critico
	if apagado or calor >= 90.0:
		_parpadear_led(delta)

func enfriar(delta: float) -> void:
	if apagado:
		return
	calor -= 2.0 * delta
	if calor < 0.0:
		calor = 0.0
	actualizar_interfaz_diegética()
	calor_cambiado.emit(calor)

func reiniciar() -> void:
	if not apagado:
		return
	apagado = false
	calor = 60.0
	actualizar_interfaz_diegética()
	panel_reiniciado.emit(self)
	print(">>> SISTEMA RESTAURADO: %s reiniciado a 60°C <<<" % nombre_sistema)

func actualizar_interfaz_diegética() -> void:
	if aguja != null and not sin_senal:
		var factor = clampf(calor / 100.0, 0.0, 1.0)
		var angulo_z = lerpf(ANGULO_MIN_AGUJA, ANGULO_MAX_AGUJA, factor)
		aguja.rotation_degrees.z = angulo_z
	
	var color_estado: Color
	if apagado:
		color_estado = Color(0.85, 0.15, 0.15)
	elif sin_senal:
		color_estado = Color(0.45, 0.45, 0.45)
	elif calor >= 90.0:
		color_estado = Color(0.84, 0.23, 0.23)
	elif calor >= 50.0:
		color_estado = Color(0.9, 0.49, 0.13)
	else:
		color_estado = Color(0.18, 0.8, 0.44)
	
	if luz_led != null:
		luz_led.light_color = color_estado
		luz_led.light_energy = 0.15 if sin_senal else (0.8 if calor >= 90.0 else 0.45)
	
	if texto != null:
		var cabecera = "%s %s" % [icono, nombre_sistema]
		if apagado:
			texto.text = "%s\nAPAGADO (100°)\n[Mantén E para reiniciar]" % cabecera
			texto.modulate = Color(0.9, 0.2, 0.2)
		elif sin_senal:
			texto.text = "%s\n[SIN SEÑAL]" % cabecera
			texto.modulate = Color(0.55, 0.55, 0.55)
		else:
			texto.text = "%s\n%.1f°C" % [cabecera, calor]
			texto.modulate = color_estado

var _tiempo_parpadeo: float = 0.0

func _parpadear_led(delta: float) -> void:
	if luz_led == null:
		return
	# Frecuencia de parpadeo segun gravedad: critico mas rapido
	var hz = 6.0 if apagado else 2.5
	_tiempo_parpadeo += delta * hz
	var encendido = int(_tiempo_parpadeo) % 2 == 0
	var energia_base = 0.9 if apagado else 0.75
	luz_led.light_energy = energia_base if encendido else 0.05
