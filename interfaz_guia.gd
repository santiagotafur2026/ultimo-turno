class_name InterfazGuia extends CanvasLayer

# --- Paleta de colores oficial del juego ---
const COL_FONDO := Color(0.04, 0.06, 0.08, 0.88)
const COL_BORDE := Color(0.2, 0.25, 0.3, 0.8)
const COL_VERDE := Color(0.18, 0.8, 0.44)
const COL_NARANJA := Color(0.9, 0.49, 0.13)
const COL_ROJO := Color(0.85, 0.2, 0.2)
const COL_CIAN := Color(0.25, 0.78, 0.95)
const COL_TEXTO := Color(0.92, 0.96, 1.0)
const COL_TEXTO_MUTED := Color(0.6, 0.65, 0.7)
const COL_TECLA_FONDO := Color(0.12, 0.15, 0.18)
const COL_APAGADO := Color(0.5, 0.5, 0.5)

# Referencias
var interactuador: Node = null
var game_manager: GameManager = null
var camara: Camera3D = null

# Nodos de la UI
var raiz: Control
var reticula_draw: Control
var caja_accion: PanelContainer
var lbl_panel_titulo: Label
var lbl_tecla: Label
var lbl_accion: Label
var contenedor_progreso: VBoxContainer
var barra_progreso: ProgressBar
var lbl_progreso: Label
var lbl_feedback: Label

# Cabecera de objetivo
var cabecera_panel: PanelContainer
var lbl_objetivo_titulo: Label
var lbl_objetivo_desc: Label
var lbl_integridad: Label
var lbl_vida: Label

# Telemetria inferior
var contenedor_telemetria: HBoxContainer
var tarjetas_paneles: Dictionary = {}
var lbl_radio_estado: Label

# Flechas perimetrales
var contenedor_flechas: Control

# Estado interno
var panel_enfocado: Node3D = null
var expansion_reticula: float = 0.0
var color_reticula_actual: Color = Color(1, 1, 1, 0.4)
var tiempo_feedback: float = 0.0
var mensaje_objetivo_prioritario: String = ""

func _ready() -> void:
	layer = 10 # Se dibuja encima de la escena 3D
	_construir_interfaz()
	_conectar_sistemas()

func _construir_interfaz() -> void:
	raiz = Control.new()
	raiz.name = "Raiz"
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	
	_crear_cabecera_objetivo()
	_crear_reticula_y_accion()
	_crear_telemetria_inferior()
	_crear_capa_flechas()

func _crear_cabecera_objetivo() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margen.offset_left = 20
	margen.offset_right = -20
	margen.offset_top = 16
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(margen)
	
	cabecera_panel = PanelContainer.new()
	cabecera_panel.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_FONDO, COL_BORDE, 6, 2))
	cabecera_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(cabecera_panel)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cabecera_panel.add_child(hbox)
	
	# Indicador de estado de mision
	var caja_izq := VBoxContainer.new()
	caja_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja_izq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(caja_izq)
	
	lbl_objetivo_titulo = Label.new()
	lbl_objetivo_titulo.text = "SUPERVISIÓN DEL TURNO — SALA DE CONTROL"
	lbl_objetivo_titulo.add_theme_color_override("font_color", COL_CIAN)
	lbl_objetivo_titulo.add_theme_font_size_override("font_size", 12)
	caja_izq.add_child(lbl_objetivo_titulo)
	
	lbl_objetivo_desc = Label.new()
	lbl_objetivo_desc.text = "Iniciando turno: mantén las cuatro consolas térmicamente estables."
	lbl_objetivo_desc.add_theme_color_override("font_color", COL_TEXTO)
	lbl_objetivo_desc.add_theme_font_size_override("font_size", 16)
	caja_izq.add_child(lbl_objetivo_desc)
	
	# Estado vital e integridad
	var caja_der := HBoxContainer.new()
	caja_der.add_theme_constant_override("separation", 18)
	caja_der.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(caja_der)
	
	lbl_integridad = Label.new()
	lbl_integridad.text = "INTEGRIDAD: 100%"
	lbl_integridad.add_theme_color_override("font_color", COL_VERDE)
	lbl_integridad.add_theme_font_size_override("font_size", 14)
	caja_der.add_child(lbl_integridad)
	
	lbl_vida = Label.new()
	lbl_vida.text = "OXÍGENO: 100%"
	lbl_vida.add_theme_color_override("font_color", COL_CIAN)
	lbl_vida.add_theme_font_size_override("font_size", 14)
	caja_der.add_child(lbl_vida)

func _crear_reticula_y_accion() -> void:
	# Nodo de dibujo personalizado para la reticula
	reticula_draw = Control.new()
	reticula_draw.name = "Reticula"
	reticula_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	reticula_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticula_draw.draw.connect(_on_reticula_draw)
	raiz.add_child(reticula_draw)
	
	# Contenedor central de accion
	caja_accion = PanelContainer.new()
	caja_accion.name = "CajaAccion"
	caja_accion.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_FONDO, COL_BORDE, 6, 2))
	caja_accion.custom_minimum_size = Vector2(280, 0)
	caja_accion.visible = false
	caja_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(caja_accion)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_accion.add_child(vbox)
	
	# Titulo del panel enfocado
	lbl_panel_titulo = Label.new()
	lbl_panel_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_panel_titulo.add_theme_color_override("font_color", COL_CIAN)
	lbl_panel_titulo.add_theme_font_size_override("font_size", 14)
	lbl_panel_titulo.text = "⚡ PANEL ENERGÍA"
	vbox.add_child(lbl_panel_titulo)
	
	# Fila de tecla e instruccion
	var fila_accion := HBoxContainer.new()
	fila_accion.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_accion.add_theme_constant_override("separation", 10)
	fila_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(fila_accion)
	
	var marco_tecla := PanelContainer.new()
	marco_tecla.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_TECLA_FONDO, COL_CIAN, 4, 1))
	marco_tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_accion.add_child(marco_tecla)
	
	lbl_tecla = Label.new()
	lbl_tecla.text = " [ E ] "
	lbl_tecla.add_theme_color_override("font_color", Color.WHITE)
	lbl_tecla.add_theme_font_size_override("font_size", 13)
	marco_tecla.add_child(lbl_tecla)
	
	lbl_accion = Label.new()
	lbl_accion.text = "Mantén presionado para reiniciar"
	lbl_accion.add_theme_color_override("font_color", COL_TEXTO)
	lbl_accion.add_theme_font_size_override("font_size", 13)
	fila_accion.add_child(lbl_accion)
	
	# Barra de progreso para reinicio
	contenedor_progreso = VBoxContainer.new()
	contenedor_progreso.visible = false
	contenedor_progreso.add_theme_constant_override("separation", 4)
	contenedor_progreso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(contenedor_progreso)
	
	barra_progreso = ProgressBar.new()
	barra_progreso.min_value = 0.0
	barra_progreso.max_value = 1.0
	barra_progreso.value = 0.0
	barra_progreso.show_percentage = false
	barra_progreso.custom_minimum_size = Vector2(0, 10)
	
	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = Color(0.1, 0.12, 0.15)
	estilo_fondo.set_corner_radius_all(3)
	barra_progreso.add_theme_stylebox_override("background", estilo_fondo)
	
	var estilo_lleno := StyleBoxFlat.new()
	estilo_lleno.bg_color = COL_VERDE
	estilo_lleno.set_corner_radius_all(3)
	barra_progreso.add_theme_stylebox_override("fill", estilo_lleno)
	contenedor_progreso.add_child(barra_progreso)
	
	lbl_progreso = Label.new()
	lbl_progreso.text = "REINICIANDO... 0%"
	lbl_progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_progreso.add_theme_color_override("font_color", COL_VERDE)
	lbl_progreso.add_theme_font_size_override("font_size", 11)
	contenedor_progreso.add_child(lbl_progreso)
	
	# Mensajes de retroalimentacion (exito / cancelado)
	lbl_feedback = Label.new()
	lbl_feedback.text = ""
	lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_feedback.add_theme_font_size_override("font_size", 12)
	lbl_feedback.visible = false
	vbox.add_child(lbl_feedback)

func _crear_telemetria_inferior() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margen.offset_left = 20
	margen.offset_right = -20
	margen.offset_bottom = -14
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(margen)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(vbox)
	
	# Fila de tarjetas de paneles
	contenedor_telemetria = HBoxContainer.new()
	contenedor_telemetria.add_theme_constant_override("separation", 10)
	contenedor_telemetria.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(contenedor_telemetria)
	
	var nombres = ["Energia", "Refrigeracion", "Comunicaciones", "SoporteVital"]
	var iconos = {"Energia": "⚡", "Refrigeracion": "❄", "Comunicaciones": "📡", "SoporteVital": "🫁"}
	var etiquetas = {"Energia": "ENERGÍA", "Refrigeracion": "REFRIG.", "Comunicaciones": "COMMS", "SoporteVital": "SOPORTE"}
	
	for n in nombres:
		var panel_card := PanelContainer.new()
		panel_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_card.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_FONDO, COL_BORDE, 4, 1))
		panel_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contenedor_telemetria.add_child(panel_card)
		
		var h := HBoxContainer.new()
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		h.add_theme_constant_override("separation", 8)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_card.add_child(h)
		
		var ico := Label.new()
		ico.text = iconos[n]
		ico.add_theme_font_size_override("font_size", 14)
		h.add_child(ico)
		
		var lbl := Label.new()
		lbl.text = "%s: 30°C" % etiquetas[n]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", COL_VERDE)
		h.add_child(lbl)
		
		tarjetas_paneles[n] = {
			"panel": panel_card,
			"icono": ico,
			"label": lbl,
			"nombre_corto": etiquetas[n]
		}
	
	# Indicador de estado de la radio de emergencia
	var panel_radio := PanelContainer.new()
	panel_radio.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_FONDO, Color(0.2, 0.4, 0.5, 0.6), 4, 1))
	panel_radio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(panel_radio)
	
	lbl_radio_estado = Label.new()
	lbl_radio_estado.text = "📻 [F] AUXILIO POR RADIO: DISPONIBLE (Soplado térmico general de -20°C)"
	lbl_radio_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_radio_estado.add_theme_color_override("font_color", COL_CIAN)
	lbl_radio_estado.add_theme_font_size_override("font_size", 12)
	panel_radio.add_child(lbl_radio_estado)

func _crear_capa_flechas() -> void:
	contenedor_flechas = Control.new()
	contenedor_flechas.name = "FlechasPerimetrales"
	contenedor_flechas.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_flechas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(contenedor_flechas)

func _crear_estilo_panel(fondo: Color, borde: Color, radio: int, ancho_borde: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = borde
	sb.set_border_width_all(ancho_borde)
	sb.set_corner_radius_all(radio)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

# ---------------------------------------------------------------- Conexiones
func _conectar_sistemas() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager
	if game_manager != null:
		game_manager.integridad_cambiada.connect(_on_integridad_cambiada)
		game_manager.vida_cambiada.connect(_on_vida_cambiada)
		game_manager.segundo_actualizado.connect(_on_segundo_actualizado)
		game_manager.partida_terminada.connect(_on_partida_terminada)
	
	camara = get_viewport().get_camera_3d()
	
	# Conectar con el interactuador
	interactuador = get_tree().get_first_node_in_group("interactuador")
	if interactuador != null:
		interactuador.panel_enfocado.connect(_on_panel_enfocado)
		interactuador.panel_desenfocado.connect(_on_panel_desenfocado)
		interactuador.reinicio_iniciado.connect(_on_reinicio_iniciado)
		interactuador.reinicio_progreso.connect(_on_reinicio_progreso)
		interactuador.reinicio_cancelado.connect(_on_reinicio_cancelado)
		interactuador.reinicio_exitoso.connect(_on_reinicio_exitoso)
		interactuador.enfriando.connect(_on_enfriando)
		interactuador.enfriamiento_detenido.connect(_on_enfriamiento_detenido)

func _process(delta: float) -> void:
	if camara == null:
		camara = get_viewport().get_camera_3d()
	
	_actualizar_posicion_caja_accion(delta)
	_actualizar_telemetria_y_alertas()
	_actualizar_flechas_perimetrales()
	reticula_draw.queue_redraw()

# ------------------------------------------------------------- Dibujo Retícula
func _on_reticula_draw() -> void:
	var centro := reticula_draw.size * 0.5
	var color := color_reticula_actual
	
	# Punto central
	reticula_draw.draw_circle(centro, 2.5, color)
	
	# Brackets esquineros que se abren suavemente
	var gap := 8.0 + expansion_reticula * 12.0
	var largo := 6.0
	var grosor := 1.5
	
	# Arriba
	reticula_draw.draw_line(centro + Vector2(-largo, -gap), centro + Vector2(largo, -gap), color, grosor)
	# Abajo
	reticula_draw.draw_line(centro + Vector2(-largo, gap), centro + Vector2(largo, gap), color, grosor)
	# Izquierda
	reticula_draw.draw_line(centro + Vector2(-gap, -largo), centro + Vector2(-gap, largo), color, grosor)
	# Derecha
	reticula_draw.draw_line(centro + Vector2(gap, -largo), centro + Vector2(gap, largo), color, grosor)

func _actualizar_posicion_caja_accion(delta: float) -> void:
	var centro := raiz.size * 0.5
	# Posicionar la caja de accion centrada horizontalmente, 40px debajo del centro
	var meta_pos := Vector2(centro.x - (caja_accion.size.x * 0.5), centro.y + 36)
	caja_accion.position = caja_accion.position.lerp(meta_pos, delta * 15.0)
	
	# Suavizado de la expansion de la reticula
	var meta_exp := 1.0 if panel_enfocado != null else 0.0
	expansion_reticula = lerpf(expansion_reticula, meta_exp, delta * 12.0)

# -------------------------------------------------------------- Señales de foco
func _on_panel_enfocado(panel: Node3D) -> void:
	panel_enfocado = panel
	caja_accion.visible = true
	contenedor_progreso.visible = false
	lbl_feedback.visible = false
	
	var es_apagado = panel.get("apagado") == true
	var calor = panel.get("calor") if "calor" in panel else 0.0
	var nombre_sistema = panel.get("nombre_sistema") if "nombre_sistema" in panel else panel.name
	var icono = panel.get("icono") if "icono" in panel else "⚙"
	
	if es_apagado:
		lbl_panel_titulo.text = "%s %s — [COLAPSADO]" % [icono, nombre_sistema]
		lbl_panel_titulo.add_theme_color_override("font_color", COL_ROJO)
		lbl_tecla.text = " [ E ] "
		lbl_accion.text = "Mantén presionado para reiniciar"
		color_reticula_actual = COL_ROJO
	else:
		lbl_panel_titulo.text = "%s %s — %.1f°C" % [icono, nombre_sistema, calor]
		lbl_panel_titulo.add_theme_color_override("font_color", COL_CIAN)
		lbl_tecla.text = " [ 🖱 CLIC IZQ ] "
		lbl_accion.text = "Mantén presionado para enfriar"
		color_reticula_actual = COL_VERDE if calor < 50.0 else (COL_NARANJA if calor < 90.0 else COL_ROJO)

func _on_panel_desenfocado() -> void:
	panel_enfocado = null
	caja_accion.visible = false
	color_reticula_actual = Color(1, 1, 1, 0.4)

func _on_reinicio_iniciado(_panel: Node3D) -> void:
	contenedor_progreso.visible = true
	barra_progreso.value = 0.0
	lbl_progreso.text = "REINICIANDO... 0%"
	lbl_progreso.add_theme_color_override("font_color", COL_VERDE)
	lbl_feedback.visible = false

func _on_reinicio_progreso(progreso_norm: float, _segundos: float) -> void:
	contenedor_progreso.visible = true
	barra_progreso.value = progreso_norm
	var pct = int(progreso_norm * 100.0)
	lbl_progreso.text = "REINICIANDO... %d%%" % pct

func _on_reinicio_cancelado() -> void:
	contenedor_progreso.visible = false
	_mostrar_feedback("❌ REINICIO INTERRUMPIDO (Mantén presionada la tecla E)", COL_ROJO)

func _on_reinicio_exitoso(panel: Node3D) -> void:
	contenedor_progreso.visible = false
	_mostrar_feedback("✔ ¡SISTEMA RESTAURADO A 60°C!", COL_VERDE)
	if panel != null:
		_on_panel_enfocado(panel)

func _on_enfriando(panel: Node3D, _delta: float) -> void:
	if panel == null:
		return
	var calor = panel.get("calor") if "calor" in panel else 0.0
	var nombre_sistema = panel.get("nombre_sistema") if "nombre_sistema" in panel else panel.name
	var icono = panel.get("icono") if "icono" in panel else "⚙"
	lbl_panel_titulo.text = "%s %s — %.1f°C" % [icono, nombre_sistema, calor]
	lbl_accion.text = "❄ ENFRIANDO (-2.0°C/s)"
	lbl_accion.add_theme_color_override("font_color", COL_CIAN)

func _on_enfriamiento_detenido() -> void:
	if panel_enfocado != null and not panel_enfocado.get("apagado"):
		lbl_accion.text = "Mantén presionado para enfriar"
		lbl_accion.add_theme_color_override("font_color", COL_TEXTO)

func _mostrar_feedback(mensaje: String, color: Color) -> void:
	lbl_feedback.text = mensaje
	lbl_feedback.add_theme_color_override("font_color", color)
	lbl_feedback.visible = true
	lbl_feedback.modulate.a = 1.0
	
	var tween := create_tween()
	tween.tween_interval(1.8)
	tween.tween_property(lbl_feedback, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): lbl_feedback.visible = false)

# --------------------------------------------------- Telemetría y Guía Superior
func _actualizar_telemetria_y_alertas() -> void:
	if game_manager == null:
		return
	
	var peor_calor := -1.0
	var panel_critico: Node = null
	var hay_apagado := false
	var panel_apagado: Node = null
	
	for p in game_manager.paneles:
		var n = p.name
		if not tarjetas_paneles.has(n):
			continue
		
		var card = tarjetas_paneles[n]
		var calor: float = p.get("calor") if "calor" in p else 0.0
		var apagado: bool = p.get("apagado") if "apagado" in p else false
		var sin_senal: bool = p.get("sin_senal") if "sin_senal" in p else false
		
		var col: Color
		var txt: String
		if apagado:
			col = COL_ROJO
			txt = "%s: APAGADO" % card["nombre_corto"]
			hay_apagado = true
			panel_apagado = p
		elif sin_senal:
			col = COL_APAGADO
			txt = "%s: [SIN SEÑAL]" % card["nombre_corto"]
		elif calor >= 90.0:
			col = COL_ROJO
			txt = "%s: %.0f°C ⚠" % [card["nombre_corto"], calor]
			if calor > peor_calor:
				peor_calor = calor
				panel_critico = p
		elif calor >= 50.0:
			col = COL_NARANJA
			txt = "%s: %.0f°C" % [card["nombre_corto"], calor]
			if peor_calor < 90.0 and calor > peor_calor:
				peor_calor = calor
				panel_critico = p
		else:
			col = COL_VERDE
			txt = "%s: %.0f°C" % [card["nombre_corto"], calor]
		
		card["label"].text = txt
		card["label"].add_theme_color_override("font_color", col)
		
		# Borde parpadeante si esta critico o apagado
		if apagado or calor >= 90.0:
			var parpadeo = int(Time.get_ticks_msec() / 250) % 2 == 0
			var sb: StyleBoxFlat = card["panel"].get_theme_stylebox("panel")
			if sb != null:
				sb.border_color = COL_ROJO if parpadeo else COL_BORDE
		else:
			var sb: StyleBoxFlat = card["panel"].get_theme_stylebox("panel")
			if sb != null:
				sb.border_color = COL_BORDE
	
	# Actualizar estado de la radio de emergencia
	if game_manager.ayuda_usada:
		lbl_radio_estado.text = "📻 [F] AUXILIO POR RADIO: AGOTADO EN ESTE TURNO"
		lbl_radio_estado.add_theme_color_override("font_color", COL_TEXTO_MUTED)
	elif game_manager.tiempo_espera_ayuda > 0.0:
		lbl_radio_estado.text = "📻 [F] AUXILIO: ¡SOPLADO DE EMERGENCIA EN %.1f SEGUNDOS!" % game_manager.tiempo_espera_ayuda
		lbl_radio_estado.add_theme_color_override("font_color", COL_VERDE)
	elif game_manager._panel_esta_apagado("Comunicaciones"):
		lbl_radio_estado.text = "📻 [F] AUXILIO POR RADIO: SIN SEÑAL (Comunicaciones colapsadas)"
		lbl_radio_estado.add_theme_color_override("font_color", COL_ROJO)
	else:
		lbl_radio_estado.text = "📻 [F] AUXILIO POR RADIO: DISPONIBLE (Soplado general de -20°C a toda la sala)"
		lbl_radio_estado.add_theme_color_override("font_color", COL_CIAN)
	
	# Actualizar el Banner de Objetivo Dinamico segun situacion
	_actualizar_mensaje_objetivo(hay_apagado, panel_apagado, peor_calor, panel_critico)

func _actualizar_mensaje_objetivo(hay_apagado: bool, p_apagado: Node, peor_calor: float, p_critico: Node) -> void:
	if game_manager == null:
		return
	
	if game_manager.tiempo_restante <= 30.0:
		lbl_objetivo_titulo.text = "FASE FINAL — REINICIO DEL SISTEMA INMINENTE"
		lbl_objetivo_titulo.add_theme_color_override("font_color", COL_VERDE)
		lbl_objetivo_desc.text = "¡Resiste! El reloj está por llegar a 00:00. Mantén la sala con vida."
		return
	
	if game_manager._panel_esta_apagado("SoporteVital"):
		lbl_objetivo_titulo.text = "🚨 ALERTA CRÍTICA — PÉRDIDA DE PRESIÓN Y OXÍGENO"
		lbl_objetivo_titulo.add_theme_color_override("font_color", COL_ROJO)
		lbl_objetivo_desc.text = "¡Soporte Vital colapsado! Te estás asfixiando: ve de inmediato y mantén [E] 4 segundos."
		return
		
	if hay_apagado and p_apagado != null:
		var nombre = p_apagado.get("nombre_sistema") if "nombre_sistema" in p_apagado else p_apagado.name
		lbl_objetivo_titulo.text = "⚠ EMERGENCIA — SISTEMA EN COLAPSO"
		lbl_objetivo_titulo.add_theme_color_override("font_color", COL_ROJO)
		lbl_objetivo_desc.text = "%s está apagado y daña la sala. Acércate y mantén [E] para reiniciarlo." % nombre
		return
		
	if peor_calor >= 90.0 and p_critico != null:
		var nombre = p_critico.get("nombre_sistema") if "nombre_sistema" in p_critico else p_critico.name
		lbl_objetivo_titulo.text = "🚨 SOBRECALENTAMIENTO CRÍTICO (≥90°C)"
		lbl_objetivo_titulo.add_theme_color_override("font_color", COL_ROJO)
		lbl_objetivo_desc.text = "¡%s a punto de colapsar! Acércate y mantén Clic Izquierdo para enfriarlo." % nombre
		return
		
	if peor_calor >= 70.0 and p_critico != null:
		var nombre = p_critico.get("nombre_sistema") if "nombre_sistema" in p_critico else p_critico.name
		lbl_objetivo_titulo.text = "PRECAUCIÓN TÉRMICA — CARGA ELEVADA"
		lbl_objetivo_titulo.add_theme_color_override("font_color", COL_NARANJA)
		lbl_objetivo_desc.text = "%s supera los 70°C. Comienza a enfriarlo antes de que suene la alarma." % nombre
		return
	
	# Estado normal
	lbl_objetivo_titulo.text = "SUPERVISIÓN DEL TURNO — SALA ESTABLE"
	lbl_objetivo_titulo.add_theme_color_override("font_color", COL_CIAN)
	lbl_objetivo_desc.text = "Inspecciona los 4 paneles. Enfría las consolas que suban de temperatura."

# ------------------------------------------------ Flechas Perimetrales de Guía
func _actualizar_flechas_perimetrales() -> void:
	# Limpiar flechas anteriores
	for hijo in contenedor_flechas.get_children():
		hijo.queue_free()
	
	if camara == null or game_manager == null:
		return
	
	var rect_pantalla := raiz.get_viewport_rect()
	var centro_pantalla := rect_pantalla.size * 0.5
	var margen_borde := 40.0
	
	for p in game_manager.paneles:
		var calor: float = p.get("calor") if "calor" in p else 0.0
		var apagado: bool = p.get("apagado") if "apagado" in p else false
		
		# Solo mostramos flechas de amenaza para paneles que esten criticos o apagados
		if not apagado and calor < 90.0:
			continue
		
		var pos_panel: Vector3 = p.global_position + Vector3(0, 1.2, 0)
		var detras := camara.is_position_behind(pos_panel)
		var pos_2d := camara.unproject_position(pos_panel)
		
		var fuera_pantalla := detras or pos_2d.x < 60 or pos_2d.x > rect_pantalla.size.x - 60 or pos_2d.y < 60 or pos_2d.y > rect_pantalla.size.y - 60
		
		if fuera_pantalla:
			# Calcular direccion desde el centro hacia el objeto
			var dir: Vector2
			if detras:
				# Si esta atras, invertir para que la flecha apunte correctamente hacia atras/lados
				var local := camara.to_local(pos_panel)
				dir = Vector2(local.x, -local.y).normalized()
			else:
				dir = (pos_2d - centro_pantalla).normalized()
			
			if dir.length_squared() < 0.001:
				dir = Vector2.DOWN
			
			# Proyectar direccion al perimetro de la pantalla
			var distancia_x = (rect_pantalla.size.x * 0.5) - margen_borde
			var distancia_y = (rect_pantalla.size.y * 0.5) - margen_borde
			var factor = minf(distancia_x / absf(dir.x) if absf(dir.x) > 0.001 else 9999.0, distancia_y / absf(dir.y) if absf(dir.y) > 0.001 else 9999.0)
			var pos_flecha = centro_pantalla + (dir * factor)
			
			var etiqueta_flecha := Label.new()
			var icono = p.get("icono") if "icono" in p else "⚠"
			var estado_txt = "APAGADO" if apagado else "%.0f°C" % calor
			etiqueta_flecha.text = "▲\n%s %s" % [icono, estado_txt]
			etiqueta_flecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			etiqueta_flecha.add_theme_color_override("font_color", COL_ROJO)
			etiqueta_flecha.add_theme_font_size_override("font_size", 12)
			etiqueta_flecha.position = pos_flecha - Vector2(40, 20)
			
			# Rotar el icono de flecha apuntando hacia el borde
			var parpadeo = int(Time.get_ticks_msec() / 200) % 2 == 0
			etiqueta_flecha.modulate.a = 1.0 if parpadeo else 0.4
			contenedor_flechas.add_child(etiqueta_flecha)

# ---------------------------------------------------- Respuestas de GameManager
func _on_integridad_cambiada(nueva_integridad: float) -> void:
	lbl_integridad.text = "INTEGRIDAD: %.0f%%" % nueva_integridad
	if nueva_integridad <= 40.0:
		lbl_integridad.add_theme_color_override("font_color", COL_ROJO)
	elif nueva_integridad <= 70.0:
		lbl_integridad.add_theme_color_override("font_color", COL_NARANJA)
	else:
		lbl_integridad.add_theme_color_override("font_color", COL_VERDE)

func _on_vida_cambiada(nueva_vida: float) -> void:
	lbl_vida.text = "OXÍGENO: %.0f%%" % nueva_vida
	if nueva_vida <= 40.0:
		lbl_vida.add_theme_color_override("font_color", COL_ROJO)
	elif nueva_vida <= 70.0:
		lbl_vida.add_theme_color_override("font_color", COL_NARANJA)
	else:
		lbl_vida.add_theme_color_override("font_color", COL_CIAN)

func _on_segundo_actualizado(tiempo: float) -> void:
	var m = int(tiempo) / 60
	var s = int(tiempo) % 60
	var formato_tiempo = "%02d:%02d" % [m, s]
	lbl_objetivo_titulo.text = "TURNO EN CURSO — TIEMPO RESTANTE: %s" % formato_tiempo

func _on_partida_terminada(victoria: bool, motivo: String, puntaje: int) -> void:
	cabecera_panel.visible = false
	caja_accion.visible = false
	contenedor_telemetria.get_parent().visible = false
	contenedor_flechas.visible = false
	reticula_draw.visible = false
	
	# Pantalla de resultados integrada
	var panel_fin := PanelContainer.new()
	panel_fin.set_anchors_preset(Control.PRESET_CENTER)
	panel_fin.custom_minimum_size = Vector2(460, 260)
	panel_fin.add_theme_stylebox_override("panel", _crear_estilo_panel(COL_FONDO, COL_VERDE if victoria else COL_ROJO, 8, 3))
	panel_fin.position = (raiz.size * 0.5) - Vector2(230, 130)
	raiz.add_child(panel_fin)
	
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	panel_fin.add_child(v)
	
	var tit := Label.new()
	tit.text = "¡TURNO COMPLETADO CON ÉXITO!" if victoria else "TURNO FALLIDO — " + motivo.to_upper()
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_color_override("font_color", COL_VERDE if victoria else COL_ROJO)
	tit.add_theme_font_size_override("font_size", 20)
	v.add_child(tit)
	
	var sub := Label.new()
	sub.text = "Puntuación final: %d / 1900 pts" % puntaje
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", COL_CIAN)
	sub.add_theme_font_size_override("font_size", 16)
	v.add_child(sub)
	
	var desc := Label.new()
	desc.text = "Presiona [ENTER] para reiniciar el turno o [ESC] para salir"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", COL_TEXTO_MUTED)
	desc.add_theme_font_size_override("font_size", 13)
	v.add_child(desc)
