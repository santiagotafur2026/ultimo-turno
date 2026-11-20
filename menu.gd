extends Control
# Menu principal de ULTIMO TURNO.
# Es la nueva escena de arranque (run/main_scene en project.godot).
# La partida en si sigue siendo res://main.tscn, sin modificaciones.

const ESCENA_JUEGO := "res://main.tscn"
const ESCENA_TUTORIAL: PackedScene = preload("res://tutorial.tscn")

# Paleta del juego
const COL_FONDO := Color(0.018, 0.035, 0.052)
const COL_MARCO := Color(0.055, 0.095, 0.125)
const COL_CONSOLA := Color(0.09, 0.145, 0.18)
const COL_ESTRUCTURA := Color(0.16, 0.25, 0.29)
const COL_TEXTO := Color(0.89, 0.95, 0.98)
const COL_VERDE := Color(0.2, 0.78, 0.72)

@onready var contenido: Control = %Contenido
@onready var titulo: Label = %Titulo
@onready var subtitulo: Label = %Subtitulo
@onready var boton_nueva: Button = %BotonNuevaPartida
@onready var boton_como_jugar: Button = %BotonComoJugar
@onready var boton_salir: Button = %BotonSalir

var _tutorial: Tutorial = null

func _ready() -> void:
	# El cursor debe verse en el menu (la camara de la partida lo captura al iniciar)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	titulo.add_theme_color_override("font_color", COL_TEXTO)
	titulo.add_theme_font_size_override("font_size", 64)
	subtitulo.add_theme_color_override("font_color", COL_VERDE)
	subtitulo.add_theme_font_size_override("font_size", 18)
	for b in [boton_nueva, boton_como_jugar, boton_salir]:
		_estilizar_boton(b)

	boton_nueva.pressed.connect(_on_nueva_partida_pressed)
	boton_como_jugar.pressed.connect(_on_como_jugar_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)

	boton_nueva.grab_focus()

func _on_nueva_partida_pressed() -> void:
	_abrir_tutorial(Tutorial.Modo.INICIO_PARTIDA)

func _on_como_jugar_pressed() -> void:
	_abrir_tutorial(Tutorial.Modo.CONSULTA)

func _on_salir_pressed() -> void:
	get_tree().quit()

func _abrir_tutorial(modo_tutorial: Tutorial.Modo) -> void:
	if _tutorial != null:
		return
	_tutorial = ESCENA_TUTORIAL.instantiate() as Tutorial
	_tutorial.modo = modo_tutorial # debe asignarse antes de add_child
	_tutorial.tutorial_terminado.connect(_on_tutorial_terminado)
	contenido.hide()
	add_child(_tutorial)

func _on_tutorial_terminado(comenzar_partida: bool) -> void:
	if comenzar_partida:
		var error := get_tree().change_scene_to_file(ESCENA_JUEGO)
		if error != OK:
			push_error("No se pudo cargar la partida: " + ESCENA_JUEGO)
		return
	# Modo consulta: volver al menu
	_tutorial.queue_free()
	_tutorial = null
	contenido.show()
	boton_como_jugar.grab_focus()

func _estilizar_boton(boton: Button) -> void:
	boton.add_theme_stylebox_override("normal", _caja(COL_CONSOLA, COL_ESTRUCTURA))
	boton.add_theme_stylebox_override("hover", _caja(COL_ESTRUCTURA, COL_VERDE))
	boton.add_theme_stylebox_override("pressed", _caja(COL_MARCO, COL_VERDE))
	boton.add_theme_stylebox_override("focus", _caja(COL_CONSOLA, COL_VERDE))
	boton.add_theme_color_override("font_color", COL_TEXTO)
	boton.add_theme_color_override("font_hover_color", Color.WHITE)
	boton.add_theme_color_override("font_focus_color", Color.WHITE)
	boton.add_theme_font_size_override("font_size", 22)
	boton.custom_minimum_size = Vector2(320, 56)

func _caja(fondo: Color, borde: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = fondo
	caja.border_color = borde
	caja.set_border_width_all(2)
	caja.set_corner_radius_all(4)
	return caja
