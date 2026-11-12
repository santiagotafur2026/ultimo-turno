extends Node3D

const REGISTRAR_CORRER = true

func _ready():
	_registrar("move_left", [KEY_A, KEY_LEFT])
	_registrar("move_right", [KEY_D, KEY_RIGHT])
	_registrar("move_up", [KEY_W, KEY_UP])
	_registrar("move_down", [KEY_S, KEY_DOWN])
	if REGISTRAR_CORRER:
		_registrar("correr", [KEY_SHIFT])
	
	# Mapeos de acción para Último Turno
	_registrar("reiniciar", [KEY_E])
	_registrar("pedir_ayuda", [KEY_F])
	_registrar("pausa", [KEY_ESCAPE])
	_registrar("reintentar", [KEY_ENTER, KEY_KP_ENTER])

func _registrar(nombre: String, teclas: Array):
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	for k in teclas:
		var e = InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(nombre, e)
