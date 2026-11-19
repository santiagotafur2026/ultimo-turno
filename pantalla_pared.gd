class_name PantallaPared extends Node3D

@onready var lbl_titulo: Label3D = get_node_or_null("LabelTitulo")
@onready var lbl_estado: Label3D = get_node_or_null("LabelEstado")
@onready var lbl_telemetria: Label3D = get_node_or_null("LabelTelemetria")
@onready var lbl_alerta: Label3D = get_node_or_null("LabelAlerta")
@onready var luz_pantalla: OmniLight3D = get_node_or_null("LuzPantalla")

var game_manager: GameManager = null
var paneles: Array[Node] = []
var _parpadeo_timer: float = 0.0

const COL_VERDE := Color(0.2, 0.85, 0.45)
const COL_NARANJA := Color(0.95, 0.55, 0.15)
const COL_ROJO := Color(0.9, 0.2, 0.2)
const COL_CIAN := Color(0.3, 0.85, 1.0)
const COL_GRIS := Color(0.5, 0.5, 0.5)

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager
	paneles = get_tree().get_nodes_in_group("paneles")

func _physics_process(delta: float) -> void:
	_parpadeo_timer += delta * 4.0
	_actualizar_pantalla()

func _actualizar_pantalla() -> void:
	if game_manager == null:
		game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager
	if paneles.is_empty():
		paneles = get_tree().get_nodes_in_group("paneles")
	
	var hay_apagado := false
	var peor_calor := 0.0
	var panel_peor: Node = null
	
	var info_p := {}
	for p in paneles:
		var n = p.name
		var c = p.get("calor") if "calor" in p else 0.0
		var a = p.get("apagado") if "apagado" in p else false
		var s = p.get("sin_senal") if "sin_senal" in p else false
		info_p[n] = {"calor": c, "apagado": a, "sin_senal": s}
		
		if a:
			hay_apagado = true
		if c > peor_calor:
			peor_calor = c
			panel_peor = p
	
	# 1. Telemetría formateada
	if lbl_telemetria != null:
		var t_energia = _formato_panel(info_p.get("Energia", {}), "⚡ ENERGÍA")
		var t_refrig = _formato_panel(info_p.get("Refrigeracion", {}), "❄ REFRIG")
		var t_comms = _formato_panel(info_p.get("Comunicaciones", {}), "📡 COMMS")
		var t_soporte = _formato_panel(info_p.get("SoporteVital", {}), "🫁 SOPORTE")
		
		lbl_telemetria.text = "%s    |    %s\n%s    |    %s" % [t_energia, t_refrig, t_comms, t_soporte]
	
	# 2. Estado central y luz ambiental de la pantalla
	var col_estado := COL_VERDE
	var texto_estado := "ESTADO: SALA OPERATIVA Y ESTABLE"
	
	if game_manager != null and game_manager._panel_esta_apagado("SoporteVital"):
		col_estado = COL_ROJO
		texto_estado = "¡ALERTA ROJA! SOPORTE VITAL CAÍDO — ASFIXIA"
	elif hay_apagado:
		col_estado = COL_ROJO
		texto_estado = "¡FALLO DE SISTEMA! PANEL DESCONECTADO"
	elif peor_calor >= 90.0:
		col_estado = COL_ROJO
		var nom = panel_peor.get("nombre_sistema") if panel_peor and "nombre_sistema" in panel_peor else "SISTEMA"
		texto_estado = "¡PELIGRO CRÍTICO! %s AL BORDE DEL COLAPSO" % nom
	elif peor_calor >= 70.0:
		col_estado = COL_NARANJA
		var nom = panel_peor.get("nombre_sistema") if panel_peor and "nombre_sistema" in panel_peor else "SISTEMA"
		texto_estado = "PRECAUCIÓN: %s CON TEMPERATURA ELEVADA" % nom
	
	if lbl_estado != null:
		lbl_estado.text = texto_estado
		lbl_estado.modulate = col_estado
		if col_estado == COL_ROJO:
			var parpadeo = int(_parpadeo_timer) % 2 == 0
			lbl_estado.modulate.a = 1.0 if parpadeo else 0.25
		else:
			lbl_estado.modulate.a = 1.0
	
	if luz_pantalla != null:
		luz_pantalla.light_color = col_estado
		luz_pantalla.light_energy = 0.4 if col_estado == COL_VERDE else 0.7
	
	# 3. Alerta / resumen inferior (Integridad y Vida)
	if lbl_alerta != null and game_manager != null:
		lbl_alerta.text = "INTEGRIDAD DE SALA: %.0f%%   |   NIVEL DE OXÍGENO: %.0f%%" % [game_manager.integridad, game_manager.vida]
		if game_manager.integridad <= 40.0 or game_manager.vida <= 40.0:
			lbl_alerta.modulate = COL_ROJO
		else:
			lbl_alerta.modulate = COL_CIAN

func _formato_panel(datos: Dictionary, nombre_corto: String) -> String:
	if datos.is_empty():
		return "%s: --" % nombre_corto
	if datos.get("apagado", false):
		return "%s: [APAGADO]" % nombre_corto
	if datos.get("sin_senal", false):
		return "%s: [S/SEÑAL]" % nombre_corto
	var c = datos.get("calor", 0.0)
	var marca = " ⚠" if c >= 90.0 else ""
	return "%s: %.1f°C%s" % [nombre_corto, c, marca]
