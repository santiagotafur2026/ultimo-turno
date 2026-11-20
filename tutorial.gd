class_name Tutorial extends Control
# Tutorial explicativo de ULTIMO TURNO.
# Todo el contenido esta basado en el codigo real del proyecto:
#   game_manager.gd, PANEL.gd, interactuar.gd, personaje.gd,
#   camara_primera.gd, main.gd, project.godot y main.tscn.
#
# Se usa desde menu.gd:
#   - Modo.INICIO_PARTIDA: aparece tras "Nueva partida". Al terminar (o al
#     omitir) se pide iniciar la partida.
#   - Modo.CONSULTA: aparece desde "Como jugar". Al terminar se vuelve al menu.

signal tutorial_terminado(comenzar_partida: bool)

enum Modo { INICIO_PARTIDA, CONSULTA }

# --- Paleta del juego (sacada de PANEL.gd y main.tscn) ---
const COL_FONDO := Color(0.018, 0.035, 0.052)
const COL_MARCO := Color(0.055, 0.095, 0.125)
const COL_DIAL := Color(0.075, 0.12, 0.15)
const COL_CONSOLA := Color(0.09, 0.145, 0.18)
const COL_ESTRUCTURA := Color(0.16, 0.25, 0.29)
const COL_TEXTO := Color(0.89, 0.95, 0.98)
const COL_VERDE := Color(0.2, 0.78, 0.72)
const COL_NARANJA := Color(0.96, 0.57, 0.22)
const COL_ROJO := Color(0.9, 0.24, 0.2)

# Mismos colores en formato BBCode para el RichTextLabel
const V := "[color=#35cfc0]"
const N := "[color=#f59b45]"
const R := "[color=#e65350]"
const FIN := "[/color]"

# Se debe asignar ANTES de añadir el nodo al arbol (add_child).
var modo: Modo = Modo.INICIO_PARTIDA
var paso: int = 0
var _pasos: Array[Dictionary] = []
var _puntos: Array[ColorRect] = []

@onready var etiqueta_paso: Label = %EtiquetaPaso
@onready var titulo: Label = %Titulo
@onready var ilustracion: Control = %Ilustracion
@onready var texto: RichTextLabel = %Texto
@onready var contenedor_puntos: HBoxContainer = %Puntos
@onready var tarjeta: PanelContainer = %Tarjeta
@onready var boton_omitir: Button = %BotonOmitir
@onready var boton_anterior: Button = %BotonAnterior
@onready var boton_siguiente: Button = %BotonSiguiente
@onready var boton_comenzar: Button = %BotonComenzar

func _ready() -> void:
	_construir_pasos()
	_aplicar_estilo()
	_crear_puntos()

	# Conexion de señales de los botones
	boton_omitir.pressed.connect(_on_omitir_pressed)
	boton_anterior.pressed.connect(_on_anterior_pressed)
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	boton_comenzar.pressed.connect(_on_comenzar_pressed)

	# Textos de botones segun el modo
	if modo == Modo.INICIO_PARTIDA:
		boton_omitir.text = "Omitir tutorial"
		boton_comenzar.text = "Comenzar partida"
	else:
		boton_omitir.text = "Cerrar"
		boton_comenzar.text = "Volver al menú"

	_mostrar_paso()

# ------------------------------------------------------------ navegacion

func _mostrar_paso() -> void:
	var datos: Dictionary = _pasos[paso]
	etiqueta_paso.text = "PASO %d / %d" % [paso + 1, _pasos.size()]
	titulo.text = datos["titulo"]
	ilustracion.set("modo", datos["ilustracion"])
	texto.text = datos["texto"]

	var es_ultimo := paso == _pasos.size() - 1
	boton_anterior.disabled = paso == 0
	boton_siguiente.visible = not es_ultimo
	boton_comenzar.visible = es_ultimo

	for i in range(_puntos.size()):
		_puntos[i].color = COL_VERDE if i == paso else COL_ESTRUCTURA

	# Dejar el foco en el boton principal para poder usar Enter / Espacio
	if es_ultimo:
		boton_comenzar.grab_focus()
	else:
		boton_siguiente.grab_focus()

func _on_siguiente_pressed() -> void:
	if paso < _pasos.size() - 1:
		paso += 1
		_mostrar_paso()

func _on_anterior_pressed() -> void:
	if paso > 0:
		paso -= 1
		_mostrar_paso()

func _on_omitir_pressed() -> void:
	_terminar()

func _on_comenzar_pressed() -> void:
	_terminar()

func _terminar() -> void:
	# En INICIO_PARTIDA (omitir o comenzar) se inicia la partida.
	# En CONSULTA solo se vuelve al menu.
	tutorial_terminado.emit(modo == Modo.INICIO_PARTIDA)

# ------------------------------------------------------------ contenido

func _construir_pasos() -> void:
	_pasos = [
		{
			"titulo": "Bienvenida",
			"ilustracion": "bienvenida",
			"texto": "[b]ÚLTIMO TURNO[/b]\n\n"
				+ "Bienvenido a la sala de control.\n\n"
				+ "Esta guía rápida te explica de qué trata el juego, cómo se maneja y cómo conseguir la victoria.\n\n"
				+ "Puedes avanzar con [b]Siguiente[/b], volver con [b]Anterior[/b] o saltarla cuando quieras.",
		},
		{
			"titulo": "¿De qué trata?",
			"ilustracion": "sala",
			"texto": "Estás dentro de una [b]sala de control[/b], en primera persona.\n\n"
				+ "En las cuatro esquinas hay un panel con su propio dial y su temperatura:\n"
				+ "• [b]⚡ Energía[/b]\n• [b]❄ Refrigeración[/b]\n• [b]📡 Comunicaciones[/b]\n• [b]🫁 Soporte Vital[/b]\n\n"
				+ "Los cuatro se [b]calientan solos[/b] sin parar. Tu trabajo es mantenerlos en marcha.",
		},
		{
			"titulo": "Objetivo principal",
			"ilustracion": "objetivo",
			"texto": "[b]Sobrevive hasta que el reloj llegue a 00:00.[/b]\n\n"
				+ "El turno dura [b]5 minutos[/b]. El reloj de la pared cuenta hacia atrás y parpadea en rojo en los últimos 30 segundos.\n\n"
				+ "Si llega a cero con la sala en pie, el reinicio se completa y " + V + "ganas" + FIN + ".",
		},
		{
			"titulo": "¿Cómo se juega?",
			"ilustracion": "partida",
			"texto": "1. Cada panel muestra su temperatura en un texto y en su dial.\n\n"
				+ "2. [b]Todos suben solos[/b], y cada minuto que pasa suben más rápido.\n\n"
				+ "3. Acércate a un panel y [b]mantén el clic izquierdo[/b] para enfriarlo.\n\n"
				+ "4. Si un panel llega a [b]100°[/b], se apaga: tendrás que reiniciarlo.",
		},
		{
			"titulo": "Controles",
			"ilustracion": "controles",
			"texto": "[b]W A S D[/b] o [b]flechas[/b]: moverte\n"
				+ "[b]Ratón[/b]: mirar a tu alrededor\n"
				+ "[b]Shift[/b]: correr\n"
				+ "[b]Clic izquierdo[/b] (mantener): enfriar el panel cercano\n"
				+ "[b]Clic derecho[/b] (mantener): apuntar / acercar la vista\n"
				+ "[b]E[/b] (mantener): reiniciar un panel apagado / recoger herramienta\n"
				+ "[b]Q[/b]: usar herramienta equipada (llave inglesa o extintor)\n"
				+ "[b]F[/b]: pedir ayuda por radio\n"
				+ "[b]Enter[/b]: reintentar cuando termina la partida\n"
				+ "[b]Esc[/b]: liberar el cursor del ratón",
		},
		{
			"titulo": "Mecánicas básicas",
			"ilustracion": "mecanicas",
			"texto": "[b]Colores del panel:[/b]\n"
				+ V + "verde" + FIN + " menos de 50° · " + N + "naranja" + FIN + " desde 50° · " + R + "rojo" + FIN + " desde 90° (el LED parpadea).\n\n"
				+ "[b]Enfriar:[/b] debes estar [b]muy cerca[/b] de un panel encendido. Solo afecta al panel más cercano.\n\n"
				+ "[b]Reiniciar:[/b] cerca de un panel apagado, mantén [b]E[/b] durante 2 segundos. Vuelve a funcionar a 35°.\n\n"
				+ "[b]Alarmas:[/b] cada panel emite un sonido desde los 70°, más fuerte cuanto más se calienta.",
		},
		{
			"titulo": "Purga crítica de enfriamiento",
			"ilustracion": "mecanicas",
			"texto": "Mientras mantienes el [b]clic izquierdo[/b] sobre un panel, aparece una " + V + "barra con un indicador en movimiento" + FIN + ".\n\n"
				+ "• El indicador oscila de un lado a otro sobre la barra.\n"
				+ "• Hay una " + V + "zona verde" + FIN + " marcada en la barra.\n\n"
				+ "[b]¿Cómo funciona?[/b]\n"
				+ "Suelta el clic en el momento exacto en que el indicador esté dentro de la " + V + "zona verde" + FIN + ".\n\n"
				+ V + "✔ Acierto:" + FIN + " purga instantánea de [b]−30°C[/b] en ese panel.\n"
				+ R + "✘ Fallo:" + FIN + " chispazo eléctrico — quedas [b]aturdido 1,2 segundos[/b] sin poder actuar.\n\n"
				+ "La zona verde cambia de posición después de cada intento.",
		},
		{
			"titulo": "Sanguijuelas térmicas",
			"ilustracion": "mecanicas",
			"texto": "Con el tiempo aparecen [b]sanguijuelas térmicas[/b]: pequeños parásitos que se adhieren al panel más caliente.\n\n"
				+ "• Mientras están adheridas, " + R + "bloquean el enfriamiento normal" + FIN + " de ese panel y elevan su temperatura rápidamente.\n\n"
				+ "[b]¿Cómo eliminarlas?[/b]\n"
				+ "1. Recoge la [b]llave inglesa[/b] de la pared (pulsa [b]E[/b] cerca de su estación).\n"
				+ "2. Acércate al panel afectado.\n"
				+ "3. Pulsa [b]Q[/b] para golpear y destruir la sanguijuela.\n\n"
				+ N + "⚠ Actúa rápido:" + FIN + " cuanto más tiempo permanezcan, más temperatura acumulan.",
		},
		{
			"titulo": "Extintor de CO₂",
			"ilustracion": "mecanicas",
			"texto": "En la pared hay un [b]extintor de CO₂[/b] como recurso de emergencia.\n\n"
				+ "• Recógelo pulsando [b]E[/b] cerca de su estación.\n"
				+ "• Acércate a un panel en situación crítica y pulsa [b]Q[/b] para disparar una ráfaga.\n"
				+ "• La ráfaga reduce [b]−35°C[/b] al instante en ese panel.\n\n"
				+ N + "⚠ Solo tiene 3 cargas." + FIN + " Una vez agotado no se recarga durante la partida.\n\n"
				+ "[b]Consejo:[/b] guárdalo para emergencias reales, cuando un panel está al límite y no tienes tiempo de enfriarlo a mano.",
		},
		{
			"titulo": "Cómo ganar",
			"ilustracion": "ganar",
			"texto": "• [b]Vigila los diales[/b] y atiende primero el panel más caliente.\n\n"
				+ "• [b]No esperes al 100°[/b]: enfría antes de que llegue al rojo.\n\n"
				+ "• Usa la [b]purga crítica[/b] para bajar temperatura rápido cuando el panel está en zona peligrosa.\n\n"
				+ "• [b]Elimina las sanguijuelas[/b] antes de que bloqueen el panel demasiado tiempo.\n\n"
				+ "• Reserva el [b]extintor[/b] para situaciones críticas; úsalo con cabeza.\n\n"
				+ "• [b]F[/b] pide un soplado de emergencia (−20° a todos) — solo se puede usar [b]una vez[/b].",
		},
		{
			"titulo": "Qué debes evitar",
			"ilustracion": "evitar",
			"texto": R + "Perderás" + FIN + " si ocurre alguna de estas cosas:\n\n"
				+ "• [b]Sala colapsada:[/b] cada panel que se apaga resta integridad. Al llegar a 0, se acaba.\n\n"
				+ "• [b]Aire agotado:[/b] con Soporte Vital apagado tu vida baja sin parar.\n\n"
				+ "• [b]Fallo de purga crítica[/b] en mal momento: el aturdimiento puede costarte un panel.\n\n"
				+ "• Dejar que se calienten todos a la vez: solo puedes enfriar el panel más cercano.",
		},
		{
			"titulo": "¡A comenzar!",
			"ilustracion": "comenzar",
			"texto": "Ya sabes lo esencial:\n\n"
				+ "• Aguanta [b]5 minutos[/b].\n"
				+ "• [b]Enfría[/b] los paneles y usa la [b]purga crítica[/b] para bajar temperatura rápido.\n"
				+ "• [b]Elimina sanguijuelas[/b] con la llave inglesa antes de que bloqueen el panel.\n"
				+ "• Usa el [b]extintor[/b] solo en emergencias reales.\n"
				+ "• [b]Reinicia[/b] los paneles apagados cuanto antes.\n\n"
				+ V + "Pulsa el botón cuando estés listo." + FIN,
		},
	]

# ------------------------------------------------------------ estilo

func _aplicar_estilo() -> void:
	# Tarjeta: colores de las consolas / estructura de la sala
	var estilo_tarjeta := StyleBoxFlat.new()
	estilo_tarjeta.bg_color = COL_MARCO
	estilo_tarjeta.border_color = COL_ESTRUCTURA
	estilo_tarjeta.set_border_width_all(2)
	estilo_tarjeta.set_corner_radius_all(6)
	tarjeta.add_theme_stylebox_override("panel", estilo_tarjeta)

	# Textos
	etiqueta_paso.add_theme_color_override("font_color", COL_VERDE)
	etiqueta_paso.add_theme_font_size_override("font_size", 16)
	titulo.add_theme_color_override("font_color", COL_TEXTO)
	titulo.add_theme_font_size_override("font_size", 34)
	texto.add_theme_color_override("default_color", COL_TEXTO)
	texto.add_theme_font_size_override("normal_font_size", 18)
	texto.add_theme_font_size_override("bold_font_size", 18)

	# Botones
	_estilizar_boton(boton_omitir, COL_DIAL, COL_ESTRUCTURA, COL_TEXTO)
	_estilizar_boton(boton_anterior, COL_CONSOLA, COL_ESTRUCTURA, COL_TEXTO)
	_estilizar_boton(boton_siguiente, COL_CONSOLA, COL_VERDE, COL_TEXTO)
	_estilizar_boton(boton_comenzar, Color(0.1, 0.4, 0.22), COL_VERDE, COL_TEXTO)

func _estilizar_boton(boton: Button, fondo: Color, borde: Color, color_texto: Color) -> void:
	boton.add_theme_stylebox_override("normal", _caja_boton(fondo, borde))
	boton.add_theme_stylebox_override("hover", _caja_boton(fondo.lightened(0.15), borde))
	boton.add_theme_stylebox_override("pressed", _caja_boton(fondo.darkened(0.25), borde))
	boton.add_theme_stylebox_override("focus", _caja_boton(fondo.lightened(0.1), COL_TEXTO))
	boton.add_theme_stylebox_override("disabled", _caja_boton(COL_FONDO, COL_CONSOLA))
	boton.add_theme_color_override("font_color", color_texto)
	boton.add_theme_color_override("font_hover_color", Color.WHITE)
	boton.add_theme_color_override("font_focus_color", Color.WHITE)
	boton.add_theme_color_override("font_pressed_color", color_texto)
	boton.add_theme_color_override("font_disabled_color", COL_ESTRUCTURA)
	boton.add_theme_font_size_override("font_size", 18)
	boton.custom_minimum_size = Vector2(160, 44)

func _caja_boton(fondo: Color, borde: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(2)
	caja.set_corner_radius_all(4)
	caja.content_margin_left = 18
	caja.content_margin_right = 18
	caja.content_margin_top = 8
	caja.content_margin_bottom = 8
	return caja

func _crear_puntos() -> void:
	# Indicador de progreso: un cuadrado por paso (verde = paso actual)
	for i in range(_pasos.size()):
		var punto := ColorRect.new()
		punto.custom_minimum_size = Vector2(12, 12)
		punto.color = COL_ESTRUCTURA
		contenedor_puntos.add_child(punto)
		_puntos.append(punto)
