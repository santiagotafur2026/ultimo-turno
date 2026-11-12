extends Node3D

signal panel_apagado(panel: Node3D)
signal panel_reiniciado(panel: Node3D)
signal calor_cambiado(nuevo_calor: float)

@export var calor: float = 30.0
@export var tasa_generacion: float = 1.0
@export var icono: String = ""
@export var nombre_sistema: String = ""

var tasa_extra: float = 0.0
var apagado: bool = false
var sin_senal: bool = false

@onready var texto: Label3D = get_node_or_null("Consola/Label3D")
@onready var aguja: Node3D = get_node_or_null("Consola/Dial/AgujaPivot")
@onready var luz_led: OmniLight3D = get_node_or_null("Consola/LuzLED")

# Angulos limites para el recorrido de la aguja analogica (grados)
const ANGULO_MIN_AGUJA: float = 75.0   # 0 grados de calor (izquierda)
const ANGULO_MAX_AGUJA: float = -75.0  # 100 grados de calor (derecha)

func _ready() -> void:
	if nombre_sistema == "":
		nombre_sistema = name
	actualizar_interfaz_diegética()

func _physics_process(delta: float) -> void:
	if not apagado:
		# Generacion continua de calor combinando tasa base y sobretasa termica
		calor += (tasa_generacion + tasa_extra) * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			panel_apagado.emit(self)
		actualizar_interfaz_diegética()
		calor_cambiado.emit(calor)

func enfriar(delta: float) -> void:
	# Enfriamiento sostenido manual mientras el sistema continue encendido
	if apagado:
		return
	calor -= 5.0 * delta
	if calor < 0.0:
		calor = 0.0
	actualizar_interfaz_diegética()
	calor_cambiado.emit(calor)

func reiniciar() -> void:
	# Reactivacion manual del sistema encendiendose a temperatura de seguridad
	if not apagado:
		return
	apagado = false
	calor = 60.0
	actualizar_interfaz_diegética()
	panel_reiniciado.emit(self)
	print(">>> SISTEMA RESTAURADO: %s reiniciado a 60°C <<<" % nombre_sistema)

func actualizar_interfaz_diegética() -> void:
	# Movimiento de la aguja mecanica en el dial analogico
	if aguja != null and not sin_senal:
		var factor = clampf(calor / 100.0, 0.0, 1.0)
		var angulo_z = lerpf(ANGULO_MIN_AGUJA, ANGULO_MAX_AGUJA, factor)
		aguja.rotation_degrees.z = angulo_z
	
	# Color de la senal luminica e indicador de advertencia
	var color_estado: Color
	if apagado:
		color_estado = Color(0.85, 0.15, 0.15) # Rojo critico oscuro
	elif sin_senal:
		color_estado = Color(0.45, 0.45, 0.45) # Gris sin senal
	elif calor >= 90.0:
		color_estado = Color(0.84, 0.23, 0.23) # Rojo critico
	elif calor >= 50.0:
		color_estado = Color(0.9, 0.49, 0.13)  # Naranja advertencia
	else:
		color_estado = Color(0.18, 0.8, 0.44)  # Verde optimo
	
	if luz_led != null:
		luz_led.light_color = color_estado
		luz_led.light_energy = 0.15 if sin_senal else (0.8 if calor >= 90.0 else 0.45)
	
	# Pantalla de informacion diegetica del panel
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
