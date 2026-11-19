extends Node

signal panel_enfocado(panel: Node3D)
signal panel_desenfocado()
signal reinicio_iniciado(panel: Node3D)
signal reinicio_progreso(progreso_norm: float, segundos: float)
signal reinicio_cancelado()
signal reinicio_exitoso(panel: Node3D)
signal enfriando(panel: Node3D, delta: float)
signal enfriamiento_detenido()

# Nuevas señales para las 3 mecánicas
signal skill_check_actualizado(pos_cursor: float, min_zona: float, max_zona: float)
signal skill_check_resultado(exito: bool, panel: Node3D)
signal golpe_parasito_ejecutado(panel: Node3D, exito: bool)
signal extintor_disparado(cargas_restantes: int, panel: Node3D)
signal herramienta_cambiada(tipo_herramienta: int)

@export var alcance: float = 1.6
@onready var pj: CharacterBody3D = get_parent()

var tiempo_reinicio: float = 0.0
const TIEMPO_REINICIO_TOTAL: float = 2.0 # Dos segundos continuos para reactivacion

var panel_actual: Node3D = null
var esta_reiniciando: bool = false
var esta_enfriando: bool = false

# --- Mecánica: Herramientas (0: Ninguna, 1: Llave Inglesa, 2: Extintor) ---
enum Herramienta { NINGUNA, LLAVE_INGLESA, EXTINTOR }
var herramienta_equipada: int = Herramienta.NINGUNA
var cargas_extintor: int = 3
const CARGAS_MAX_EXTINTOR: int = 3

# --- Mecánica: Golpe Crítico de Enfriamiento (Skill Check) ---
var cursor_critico: float = 0.0
var dir_cursor_critico: float = 1.0
const VEL_CURSOR_CRITICO: float = 2.4
var zona_critica_min: float = 0.72
var zona_critica_max: float = 0.84

func _ready() -> void:
	add_to_group("interactuador")

func _physics_process(delta: float) -> void:
	# Si el jugador está aturdido, cancelar acciones activas
	if pj != null and "tiempo_aturdido" in pj and pj.tiempo_aturdido > 0.0:
		_cancelar_reinicio()
		_detener_enfriamiento()
		return
	
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
	
	# --- Interacción con estaciones de herramienta en la pared ---
	if obj != null and obj.is_in_group("estaciones_herramienta"):
		if Input.is_action_just_pressed("reiniciar"):
			if obj.has_method("interactuar_con_jugador"):
				obj.interactuar_con_jugador(self)
				herramienta_cambiada.emit(herramienta_equipada)
		return
	
	# --- Uso activo de herramientas (Llave / Extintor) con Q o Espacio ---
	if Input.is_action_just_pressed("usar_herramienta"):
		if herramienta_equipada == Herramienta.LLAVE_INGLESA:
			_ejecutar_golpe_llave(obj)
			return
		elif herramienta_equipada == Herramienta.EXTINTOR:
			_disparar_extintor(obj)
			return
	
	if obj == null:
		return
	
	# --- Reinicio manual de panel apagado sosteniendo la tecla E ---
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
				print("[REINICIO] %s: %.1fs / 2.0s (%d%%)" % [obj.name, tiempo_reinicio, pct])
			
			if tiempo_reinicio >= TIEMPO_REINICIO_TOTAL:
				if obj.has_method("reiniciar"):
					obj.reiniciar()
				reinicio_exitoso.emit(obj)
				tiempo_reinicio = 0.0
				esta_reiniciando = false
		else:
			_cancelar_reinicio()
		return
	else:
		_cancelar_reinicio()
	
	# --- Si el panel tiene un parásito adherido, bloquea el enfriamiento normal ---
	if obj.get("tiene_sanguijuela") == true:
		_detener_enfriamiento()
		return
	
	# --- Enfriamiento manual sosteniendo el clic cerca de un panel encendido ---
	if Input.is_action_pressed("enfriar"):
		if obj.has_method("enfriar"):
			obj.enfriar(delta)
			if not esta_enfriando:
				esta_enfriando = true
			enfriando.emit(obj, delta)
			
			# Avanzar cursor mientras se mantiene clic
			_procesar_skill_check(delta)
	elif Input.is_action_just_released("enfriar"):
		# Al soltar el clic, evaluar si el cursor está en la zona verde
		_evaluar_purga_al_soltar(obj)
		_detener_enfriamiento()
	else:
		_detener_enfriamiento()

# ---------------------------------------------------- Golpe de Llave Inglesa
func _ejecutar_golpe_llave(obj: Node3D) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("sacudir"):
		cam.sacudir(0.04, 0.2)
	
	if obj != null and obj.get("tiene_sanguijuela") == true:
		var sang = obj.get("sanguijuela_instancia")
		if sang != null and sang.has_method("recibir_golpe"):
			sang.recibir_golpe()
			golpe_parasito_ejecutado.emit(obj, true)
			return
	golpe_parasito_ejecutado.emit(obj, false)

# -------------------------------------------------------- Disparo de Extintor
func _disparar_extintor(obj: Node3D) -> void:
	if cargas_extintor <= 0:
		print(">>> [EXTINTOR] ¡Descargado! No quedan cargas de CO₂ <<<")
		return
	
	cargas_extintor -= 1
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("sacudir"):
		cam.sacudir(0.08, 0.35)
	
	# Enfriamiento masivo instantáneo (-35°C)
	if obj != null and obj.get("apagado") != true:
		if "calor" in obj:
			obj.calor = maxf(0.0, obj.calor - 35.0)
			if obj.has_method("actualizar_interfaz_diegética"):
				obj.actualizar_interfaz_diegética()
		print(">>> [EXTINTOR] Ráfaga de CO₂ aplicada a %s (-35°C). Cargas restantes: %d <<<" % [obj.name, cargas_extintor])
	else:
		print(">>> [EXTINTOR] Ráfaga de CO₂ descargada al aire. Cargas restantes: %d <<<" % cargas_extintor)
	
	extintor_disparado.emit(cargas_extintor, obj)

# ------------------------------------ Golpe Crítico de Enfriamiento (Skill Check)
func _procesar_skill_check(delta: float) -> void:
	cursor_critico += dir_cursor_critico * VEL_CURSOR_CRITICO * delta
	if cursor_critico >= 1.0:
		cursor_critico = 1.0
		dir_cursor_critico = -1.0
	elif cursor_critico <= 0.0:
		cursor_critico = 0.0
		dir_cursor_critico = 1.0
	
	skill_check_actualizado.emit(cursor_critico, zona_critica_min, zona_critica_max)

func _evaluar_purga_al_soltar(obj: Node3D) -> void:
	if obj == null or obj.get("apagado") == true:
		return
	
	var en_zona: bool = cursor_critico >= zona_critica_min and cursor_critico <= zona_critica_max
	if en_zona:
		# ¡PURGA EXITOSA! (-30°C de golpe)
		if "calor" in obj:
			obj.calor = maxf(0.0, obj.calor - 30.0)
			if obj.has_method("actualizar_interfaz_diegética"):
				obj.actualizar_interfaz_diegética()
		
		var cam = get_viewport().get_camera_3d()
		if cam and cam.has_method("sacudir"):
			cam.sacudir(0.04, 0.25)
		
		# Reubicar zona crítica para el próximo intento
		zona_critica_min = randf_range(0.55, 0.76)
		zona_critica_max = zona_critica_min + 0.11
		skill_check_resultado.emit(true, obj)
		print(">>> ¡PURGA CRÍTICA EXITOSA en %s! -30°C de calor <<<" % obj.name)
	else:
		# ¡FALLO! Chispazo y aturdimiento
		if pj != null and pj.has_method("aturdir"):
			pj.aturdir(1.2)
		
		var cam = get_viewport().get_camera_3d()
		if cam and cam.has_method("sacudir"):
			cam.sacudir(0.09, 0.45)
		
		skill_check_resultado.emit(false, obj)
		print(">>> ¡CHISPAZO POR FALLO DE TIMING! Jugador aturdido 1.2s <<<")

func _cancelar_reinicio() -> void:
	if esta_reiniciando or tiempo_reinicio > 0.0:
		tiempo_reinicio = 0.0
		esta_reiniciando = false
		reinicio_cancelado.emit()

func _detener_enfriamiento() -> void:
	if esta_enfriando:
		esta_enfriando = false
		cursor_critico = 0.0
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
