extends Control
# Dibuja las ilustraciones del tutorial usando la paleta real del juego
# (colores tomados de PANEL.gd, main.tscn y game_manager.gd).
# No usa imagenes externas: todo se dibuja con _draw().

# --- Paleta del juego ---
const COL_FONDO := Color(0.04, 0.05, 0.06)       # Material_RelojFondo
const COL_MARCO := Color(0.1, 0.12, 0.14)        # Material_RelojMarco
const COL_DIAL := Color(0.12, 0.14, 0.16)        # Material_DialFondo
const COL_CONSOLA := Color(0.18, 0.2, 0.22)      # Material_Consola
const COL_ESTRUCTURA := Color(0.24, 0.26, 0.28)  # Material_Estructura
const COL_TEXTO := Color(0.9, 0.95, 1.0)         # color del reloj de pared
const COL_VERDE := Color(0.18, 0.8, 0.44)        # calor < 50
const COL_NARANJA := Color(0.9, 0.49, 0.13)      # calor >= 50
const COL_ROJO := Color(0.84, 0.23, 0.23)        # calor >= 90
const COL_APAGADO := Color(0.85, 0.15, 0.15)     # panel apagado
const COL_AGUJA := Color(0.95, 0.2, 0.2)         # aguja del dial

var modo: String = "":
	set(valor):
		modo = valor
		queue_redraw()

var _fuente: Font

func _ready() -> void:
	_fuente = get_theme_default_font()
	resized.connect(queue_redraw)

func _draw() -> void:
	if _fuente == null:
		_fuente = get_theme_default_font()
	# Marco de la ilustracion
	draw_rect(Rect2(Vector2.ZERO, size), COL_FONDO, true)
	draw_rect(Rect2(Vector2.ZERO, size), COL_ESTRUCTURA, false, 2.0)
	match modo:
		"bienvenida": _dibujar_bienvenida()
		"sala": _dibujar_sala()
		"objetivo": _dibujar_objetivo()
		"partida": _dibujar_partida()
		"controles": _dibujar_controles()
		"mecanicas": _dibujar_mecanicas()
		"ganar": _dibujar_ganar()
		"evitar": _dibujar_evitar()
		"comenzar": _dibujar_comenzar()

# ---------------------------------------------------------------- utilidades

func _texto(pos: Vector2, cadena: String, tam: int, color: Color, ancho: float = -1.0, alineacion: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(_fuente, pos, cadena, alineacion, ancho, tam, color)

func _texto_centrado(centro: Vector2, cadena: String, tam: int, color: Color) -> void:
	var ancho := _fuente.get_string_size(cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string(_fuente, Vector2(centro.x - ancho * 0.5, centro.y + tam * 0.35), cadena, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)

func _color_calor(calor: float) -> Color:
	if calor >= 90.0:
		return COL_ROJO
	if calor >= 50.0:
		return COL_NARANJA
	return COL_VERDE

func _reloj(centro: Vector2, ancho: float, cadena: String, color: Color) -> void:
	var alto := ancho * 0.37
	draw_rect(Rect2(centro - Vector2(ancho, alto) * 0.5, Vector2(ancho, alto)), COL_MARCO, true)
	var interior := Vector2(ancho * 0.93, alto * 0.82)
	draw_rect(Rect2(centro - interior * 0.5, interior), COL_FONDO, true)
	_texto_centrado(centro, cadena, int(alto * 0.62), color)

func _dial(centro: Vector2, radio: float, calor: float) -> void:
	# Mismo recorrido de aguja que PANEL.gd: de +75 grados (0 C) a -75 grados (100 C)
	draw_circle(centro, radio, COL_DIAL)
	draw_arc(centro, radio, 0.0, TAU, 48, COL_CONSOLA, 3.0)
	# Arco de colores (verde / naranja / rojo) alrededor de la esfera
	var a_min := deg_to_rad(-90.0 - 75.0)
	var a_max := deg_to_rad(-90.0 + 75.0)
	var a50 := lerpf(a_min, a_max, 0.5)
	var a90 := lerpf(a_min, a_max, 0.9)
	draw_arc(centro, radio * 0.82, a_min, a50, 16, COL_VERDE, 5.0)
	draw_arc(centro, radio * 0.82, a50, a90, 16, COL_NARANJA, 5.0)
	draw_arc(centro, radio * 0.82, a90, a_max, 8, COL_ROJO, 5.0)
	var factor := clampf(calor / 100.0, 0.0, 1.0)
	var ang := lerpf(a_min, a_max, factor)
	var punta := centro + Vector2(cos(ang), sin(ang)) * radio * 0.7
	draw_line(centro, punta, COL_AGUJA, 3.0)
	draw_circle(centro, 4.0, COL_AGUJA)

func _tecla(rect: Rect2, cadena: String, tam: int = 16) -> void:
	draw_rect(rect, COL_CONSOLA, true)
	draw_rect(rect, COL_TEXTO, false, 2.0)
	_texto_centrado(rect.get_center(), cadena, tam, COL_TEXTO)

func _barra(rect: Rect2, valor: float, color: Color) -> void:
	draw_rect(rect, COL_DIAL, true)
	var relleno := Rect2(rect.position, Vector2(rect.size.x * clampf(valor, 0.0, 1.0), rect.size.y))
	draw_rect(relleno, color, true)
	draw_rect(rect, COL_CONSOLA, false, 1.5)

func _panel_mini(rect: Rect2, calor: float, etiqueta: String) -> void:
	draw_rect(rect, COL_CONSOLA, true)
	draw_rect(rect, _color_calor(calor), false, 2.0)
	_texto_centrado(Vector2(rect.get_center().x, rect.position.y + 14), etiqueta, 12, COL_TEXTO)
	_texto_centrado(Vector2(rect.get_center().x, rect.position.y + rect.size.y - 14), "%d°C" % int(calor), 14, _color_calor(calor))

# ------------------------------------------------------------- ilustraciones

func _dibujar_bienvenida() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.3)
	_reloj(c, size.x * 0.7, "05:00", COL_TEXTO)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.52), "ÚLTIMO TURNO", 26, COL_TEXTO)
	# Los cuatro sistemas como LEDs
	var nombres := ["ENERGÍA", "REFRIG.", "COMUNIC.", "S. VITAL"]
	var colores := [COL_VERDE, COL_NARANJA, COL_VERDE, COL_VERDE]
	var ancho_celda := size.x / 4.0
	for i in range(4):
		var cx := ancho_celda * (i + 0.5)
		var cy := size.y * 0.74
		draw_circle(Vector2(cx, cy), 9.0, colores[i])
		_texto_centrado(Vector2(cx, cy + 26.0), nombres[i], 12, COL_TEXTO)

func _dibujar_sala() -> void:
	# Vista desde arriba de la sala de control (cuadrada, 4 paneles en las esquinas)
	var lado := minf(size.x, size.y) * 0.8
	var origen := (size - Vector2(lado, lado)) * 0.5
	draw_rect(Rect2(origen, Vector2(lado, lado)), COL_ESTRUCTURA, false, 6.0)
	draw_rect(Rect2(origen + Vector2(3, 3), Vector2(lado - 6, lado - 6)), COL_DIAL, true)
	var ps := Vector2(lado * 0.3, lado * 0.17)
	var m := lado * 0.07
	# Mismas posiciones que main.tscn: Energia (NO), Refrigeracion (NE), Comunicaciones (SE), Soporte Vital (SO)
	_panel_mini(Rect2(origen + Vector2(m, m), ps), 30.0, "ENERGÍA")
	_panel_mini(Rect2(origen + Vector2(lado - m - ps.x, m), ps), 50.0, "REFRIG.")
	_panel_mini(Rect2(origen + Vector2(lado - m - ps.x, lado - m - ps.y), ps), 35.0, "COMUNIC.")
	_panel_mini(Rect2(origen + Vector2(m, lado - m - ps.y), ps), 40.0, "S. VITAL")
	# Reloj en la pared norte y jugador al centro
	_reloj(origen + Vector2(lado * 0.5, 14.0), lado * 0.28, "05:00", COL_TEXTO)
	var centro := origen + Vector2(lado, lado) * 0.5
	draw_circle(centro, 11.0, COL_TEXTO)
	draw_circle(centro, 11.0, COL_MARCO, false, 2.0)
	_texto_centrado(centro + Vector2(0, 26), "TÚ", 12, COL_TEXTO)

func _dibujar_objetivo() -> void:
	_reloj(Vector2(size.x * 0.5, size.y * 0.28), size.x * 0.7, "00:00", COL_VERDE)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.5), "REINICIO COMPLETADO", 20, COL_VERDE)
	# Cuatro paneles encendidos
	var ancho_celda := size.x / 4.0
	for i in range(4):
		var cx := ancho_celda * (i + 0.5)
		draw_circle(Vector2(cx, size.y * 0.72), 10.0, COL_VERDE)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.87), "Sobrevive con la sala en pie", 14, COL_TEXTO)

func _dibujar_partida() -> void:
	# Linea de tiempo de 5 minutos con el calor subiendo cada minuto
	var margen := 28.0
	var base_y := size.y * 0.78
	var ancho := size.x - margen * 2.0
	draw_line(Vector2(margen, base_y), Vector2(margen + ancho, base_y), COL_TEXTO, 2.0)
	for i in range(6):
		var x := margen + ancho * (i / 5.0)
		draw_line(Vector2(x, base_y - 6), Vector2(x, base_y + 6), COL_TEXTO, 2.0)
		_texto_centrado(Vector2(x, base_y + 22), "%d:00" % i if i < 5 else "5:00", 12, COL_TEXTO)
	# Escalones de calor (uno por minuto)
	for i in range(5):
		var x0 := margen + ancho * (i / 5.0) + 4.0
		var alto := size.y * (0.12 + 0.1 * i)
		var col := _color_calor(30.0 + 14.0 * i)
		draw_rect(Rect2(Vector2(x0, base_y - 10.0 - alto), Vector2(ancho / 5.0 - 8.0, alto)), col, true)
	_texto_centrado(Vector2(size.x * 0.5, 22), "El calor sube cada minuto", 16, COL_TEXTO)

func _dibujar_controles() -> void:
	var y := 22.0
	# WASD
	_tecla(Rect2(60, y, 34, 30), "W")
	_tecla(Rect2(20, y + 34, 34, 30), "A")
	_tecla(Rect2(60, y + 34, 34, 30), "S")
	_tecla(Rect2(100, y + 34, 34, 30), "D")
	_texto(Vector2(154, y + 26), "Moverte", 16, COL_TEXTO)
	_texto(Vector2(154, y + 46), "(o flechas)", 12, COL_TEXTO)
	# Resto de acciones: tecla a la izquierda, descripcion a la derecha
	y += 82.0
	var filas := [
		["SHIFT", 80.0, "Correr"],
		["CLIC IZQ.", 80.0, "Enfriar (mantener)"],
		["CLIC DER.", 80.0, "Apuntar (zoom)"],
		["E", 34.0, "Reiniciar (mantener)"],
		["F", 34.0, "Pedir ayuda por radio"],
	]
	for f in filas:
		var ancho_tecla: float = f[1]
		_tecla(Rect2(20, y, ancho_tecla, 30), f[0], 12 if ancho_tecla > 40.0 else 16)
		_texto(Vector2(20.0 + ancho_tecla + 14.0, y + 21), f[2], 16, COL_TEXTO)
		y += 38.0

func _dibujar_mecanicas() -> void:
	_dial(Vector2(size.x * 0.5, size.y * 0.36), minf(size.x, size.y) * 0.26, 62.0)
	# Escala de colores
	var margen := 24.0
	var ancho := size.x - margen * 2.0
	var y := size.y * 0.74
	draw_rect(Rect2(margen, y, ancho * 0.5, 14), COL_VERDE, true)
	draw_rect(Rect2(margen + ancho * 0.5, y, ancho * 0.4, 14), COL_NARANJA, true)
	draw_rect(Rect2(margen + ancho * 0.9, y, ancho * 0.1, 14), COL_ROJO, true)
	_texto_centrado(Vector2(margen + ancho * 0.25, y + 30), "0-49°", 13, COL_VERDE)
	_texto_centrado(Vector2(margen + ancho * 0.7, y + 30), "50-89°", 13, COL_NARANJA)
	_texto_centrado(Vector2(margen + ancho * 0.95, y + 30), "90+", 13, COL_ROJO)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.94), "Con 100° el panel se apaga", 13, COL_TEXTO)

func _dibujar_ganar() -> void:
	# Cuatro barras de calor: el jugador debe mantenerlas bajas
	var nombres := ["ENERGÍA", "REFRIGERACIÓN", "COMUNICACIONES", "SOPORTE VITAL"]
	var valores := [0.82, 0.35, 0.55, 0.28]
	var margen := 22.0
	var y := 36.0
	_texto(Vector2(margen, 22), "Atiende primero el más caliente", 14, COL_TEXTO)
	for i in range(4):
		var v: float = valores[i]
		_texto(Vector2(margen, y + 28), nombres[i], 12, COL_TEXTO)
		_barra(Rect2(margen, y + 34, size.x - margen * 2.0, 18), v, _color_calor(v * 100.0))
		y += 62.0
	# Marca del 90%
	var x90 := margen + (size.x - margen * 2.0) * 0.9
	draw_line(Vector2(x90, 54), Vector2(x90, size.y - 10), COL_ROJO, 1.5)

func _dibujar_evitar() -> void:
	# Integridad: 5 segmentos de 20 puntos; cada colapso quita uno
	_texto(Vector2(22, 30), "INTEGRIDAD DE LA SALA", 14, COL_TEXTO)
	var margen := 22.0
	var gap := 6.0
	var ancho := (size.x - margen * 2.0 - gap * 4.0) / 5.0
	for i in range(5):
		var col := COL_VERDE if i < 2 else COL_APAGADO
		var r := Rect2(Vector2(margen + i * (ancho + gap), 42), Vector2(ancho, 24))
		if i < 2:
			draw_rect(r, col, true)
		else:
			draw_rect(r, COL_DIAL, true)
			draw_rect(r, col, false, 2.0)
	_texto(Vector2(22, 92), "Cada panel apagado resta 20", 13, COL_TEXTO)
	# Consecuencias de apagarse
	var y := 124.0
	var filas := [
		["ENERGÍA", "Se apagan las luces"],
		["REFRIGERACIÓN", "Todo se calienta más"],
		["COMUNICACIONES", "Sin señal ni radio"],
		["SOPORTE VITAL", "El aire se agota"],
	]
	for f in filas:
		draw_circle(Vector2(30, y - 4), 6.0, COL_APAGADO)
		_texto(Vector2(46, y), f[0], 13, COL_TEXTO)
		_texto(Vector2(46, y + 16), f[1], 12, COL_NARANJA)
		y += 42.0

func _dibujar_comenzar() -> void:
	_dial(Vector2(size.x * 0.5, size.y * 0.42), minf(size.x, size.y) * 0.3, 25.0)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.8), "ÚLTIMO TURNO", 24, COL_TEXTO)
	_texto_centrado(Vector2(size.x * 0.5, size.y * 0.9), "05:00", 18, COL_VERDE)
