extends Node3D


const REGISTRAR_CORRER = true

func _ready():
	_registrar("move_left", [KEY_A, KEY_LEFT])
	_registrar("move_right", [KEY_D, KEY_RIGHT])
	_registrar("move_up", [KEY_W, KEY_UP])
	_registrar("move_down", [KEY_S, KEY_DOWN])
	if REGISTRAR_CORRER:
		_registrar("correr", [KEY_SHIFT])

func _registrar(nombre, teclas):
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	for k in teclas:
		var e = InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(nombre, e)
