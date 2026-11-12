extends Node

@export var alcance: float = 1.5
@onready var pj: CharacterBody3D = get_parent()

var tiempo_reinicio: float = 0.0
const TIEMPO_REINICIO_TOTAL: float = 4.0 # Cuatro segundos continuos para reactivacion

func _physics_process(delta: float) -> void:
	# Solicitud de ayuda de emergencia por radio
	if Input.is_action_just_pressed("pedir_ayuda"):
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm and gm.has_method("solicitar_ayuda"):
			gm.solicitar_ayuda()
	
	var obj = mas_cercano()
	
	if obj == null:
		_cancelar_reinicio()
		return
	
	# Reinicio manual de panel apagado sosteniendo la tecla
	if obj.get("apagado") == true:
		if Input.is_action_pressed("reiniciar"):
			tiempo_reinicio += delta
			var pct = int((tiempo_reinicio / TIEMPO_REINICIO_TOTAL) * 100.0)
			if Engine.get_physics_frames() % 30 == 0:
				print("[REINICIO] %s: %.1fs / 4.0s (%d%%)" % [obj.name, tiempo_reinicio, pct])
			
			if tiempo_reinicio >= TIEMPO_REINICIO_TOTAL:
				if obj.has_method("reiniciar"):
					obj.reiniciar()
				tiempo_reinicio = 0.0
		else:
			_cancelar_reinicio()
		return # Mientras el panel este apagado o en proceso de reinicio no se puede enfriar
	else:
		_cancelar_reinicio()
	
	# Enfriamiento manual sosteniendo el clic cerca de un panel encendido
	if Input.is_action_pressed("enfriar"):
		if obj.has_method("enfriar"):
			obj.enfriar(delta)
			if Engine.get_physics_frames() % 60 == 0:
				print("[ENFRIANDO] %s · Calor actual: %.1f°C" % [obj.name, obj.calor])

func _cancelar_reinicio() -> void:
	if tiempo_reinicio > 0.0:
		print("[REINICIO] Proceso cancelado (tecla liberada o jugador fuera de alcance)")
		tiempo_reinicio = 0.0

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
