extends Node

signal panel_enfocado(panel: Node3D)
signal panel_desenfocado()
signal reinicio_iniciado(panel: Node3D)
signal reinicio_progreso(progreso_norm: float, segundos: float)
signal reinicio_cancelado()
signal reinicio_exitoso(panel: Node3D)
signal enfriando(panel: Node3D, delta: float)
signal enfriamiento_detenido()

@export var alcance: float = 1.5
@onready var pj: CharacterBody3D = get_parent()

var tiempo_reinicio: float = 0.0
const TIEMPO_REINICIO_TOTAL: float = 4.0 # Cuatro segundos continuos para reactivacion

var panel_actual: Node3D = null
var esta_reiniciando: bool = false
var esta_enfriando: bool = false

func _ready() -> void:
	add_to_group("interactuador")

func _physics_process(delta: float) -> void:
	# Solicitud de ayuda de emergencia por radio
	if Input.is_action_just_pressed("pedir_ayuda"):
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("solicitar_ayuda"):
			gm.solicitar_ayuda()
	
	var obj = mas_cercano()
	
	# Gestion de cambio de foco
	if obj != panel_actual:
		_cancelar_reinicio()
		_detener_enfriamiento()
		panel_actual = obj
		if panel_actual != null:
			panel_enfocado.emit(panel_actual)
		else:
			panel_desenfocado.emit()
	
	if obj == null:
		return
	
	# Reinicio manual de panel apagado sosteniendo la tecla
	if obj.get("apagado") == true:
		_detener_enfriamiento()
		if Input.is_action_pressed("reiniciar"):
			if not esta_reiniciando:
				esta_reiniciando = true
				reinicio_iniciado.emit(obj)
			
			tiempo_reinicio += delta
			var pct_norm = clampf(tiempo_reinicio / TIEMPO_REINICIO_TOTAL, 0.0, 1.0)
			reinicio_progreso.emit(pct_norm, tiempo_reinicio)
			
			if Engine.get_physics_frames() % 30 == 0:
				var pct = int(pct_norm * 100.0)
				print("[REINICIO] %s: %.1fs / 4.0s (%d%%)" % [obj.name, tiempo_reinicio, pct])
			
			if tiempo_reinicio >= TIEMPO_REINICIO_TOTAL:
				if obj.has_method("reiniciar"):
					obj.reiniciar()
				reinicio_exitoso.emit(obj)
				tiempo_reinicio = 0.0
				esta_reiniciando = false
		else:
			_cancelar_reinicio()
		return # Mientras el panel este apagado o en proceso de reinicio no se puede enfriar
	else:
		_cancelar_reinicio()
	
	# Enfriamiento manual sosteniendo el clic cerca de un panel encendido
	if Input.is_action_pressed("enfriar"):
		if obj.has_method("enfriar"):
			obj.enfriar(delta)
			if not esta_enfriando:
				esta_enfriando = true
			enfriando.emit(obj, delta)
			if Engine.get_physics_frames() % 60 == 0:
				print("[ENFRIANDO] %s · Calor actual: %.1f°C" % [obj.name, obj.calor])
	else:
		_detener_enfriamiento()

func _cancelar_reinicio() -> void:
	if esta_reiniciando or tiempo_reinicio > 0.0:
		print("[REINICIO] Proceso cancelado (tecla liberada o jugador fuera de alcance)")
		tiempo_reinicio = 0.0
		esta_reiniciando = false
		reinicio_cancelado.emit()

func _detener_enfriamiento() -> void:
	if esta_enfriando:
		esta_enfriando = false
		enfriamiento_detenido.emit()

func mas_cercano() -> Node3D:
	var mejor: Node3D = null
	var distancia_menor = alcance
	
	for obj in get_tree().get_nodes_in_group("interactivos"):
		var dx = pj.global_position.x - obj.global_position.x
		var dz = pj.global_position.z - obj.global_position.z
		var d = sqrt(dx * dx + dz * dz)
		
		if d <= distancia_menor:
			mejor = obj
			distancia_menor = d
			
	return mejor
