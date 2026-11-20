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
var visual_herramienta: Node3D
var _animacion_herramienta: Tween

# --- Mecánica: Golpe Crítico de Enfriamiento (Skill Check) ---
var cursor_critico: float = 0.0
var dir_cursor_critico: float = 1.0
const VEL_CURSOR_CRITICO: float = 2.4
var zona_critica_min: float = 0.72
var zona_critica_max: float = 0.84

func _ready() -> void:
	add_to_group("interactuador")
	_crear_visual_herramienta()

func _crear_visual_herramienta() -> void:
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return

	visual_herramienta = Node3D.new()
	visual_herramienta.name = "HerramientaPrimeraPersona"
	visual_herramienta.position = Vector3(0.34, -0.3, -0.62)
	visual_herramienta.rotation_degrees = Vector3(-8.0, -12.0, -8.0)
	camara.add_child(visual_herramienta)
	_actualizar_visual_herramienta()

func _actualizar_visual_herramienta() -> void:
	if visual_herramienta == null:
		_crear_visual_herramienta()
	if visual_herramienta == null:
		return
	if _animacion_herramienta != null and _animacion_herramienta.is_running():
		_animacion_herramienta.kill()
	for hijo in visual_herramienta.get_children():
		hijo.queue_free()

	visual_herramienta.visible = herramienta_equipada != Herramienta.NINGUNA
	if herramienta_equipada == Herramienta.LLAVE_INGLESA:
		_construir_llave_primera_persona()
	elif herramienta_equipada == Herramienta.EXTINTOR:
		_construir_extintor_primera_persona()

func _crear_malla(mesh: Mesh, color: Color, metallic: float = 0.0, roughness: float = 0.4) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	mesh.material = material
	var instancia := MeshInstance3D.new()
	instancia.mesh = mesh
	return instancia

func _construir_llave_primera_persona() -> void:
	var mango := BoxMesh.new()
	mango.size = Vector3(0.075, 0.42, 0.055)
	visual_herramienta.add_child(_crear_malla(mango, Color(0.72, 0.76, 0.8), 0.85, 0.22))

	var cabeza := BoxMesh.new()
	cabeza.size = Vector3(0.22, 0.085, 0.065)
	var pieza_cabeza := _crear_malla(cabeza, Color(0.78, 0.81, 0.84), 0.9, 0.2)
	pieza_cabeza.position.y = 0.22
	visual_herramienta.add_child(pieza_cabeza)

	var boca := BoxMesh.new()
	boca.size = Vector3(0.08, 0.055, 0.07)
	var hueco := _crear_malla(boca, Color(0.12, 0.14, 0.16), 0.55, 0.3)
	hueco.position = Vector3(0.045, 0.27, 0.002)
	visual_herramienta.add_child(hueco)

func _construir_extintor_primera_persona() -> void:
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.105
	cilindro.bottom_radius = 0.12
	cilindro.height = 0.38
	visual_herramienta.add_child(_crear_malla(cilindro, Color(0.86, 0.08, 0.055), 0.25, 0.3))

	var asa := BoxMesh.new()
	asa.size = Vector3(0.19, 0.035, 0.045)
	var pieza_asa := _crear_malla(asa, Color(0.15, 0.17, 0.19), 0.75, 0.25)
	pieza_asa.position = Vector3(0.0, 0.23, 0.0)
	visual_herramienta.add_child(pieza_asa)

	var boquilla := CylinderMesh.new()
	boquilla.top_radius = 0.025
	boquilla.bottom_radius = 0.035
	boquilla.height = 0.16
	var pieza_boquilla := _crear_malla(boquilla, Color(0.16, 0.19, 0.21), 0.8, 0.22)
	pieza_boquilla.position = Vector3(0.12, 0.2, -0.03)
	pieza_boquilla.rotation_degrees.z = -55.0
	visual_herramienta.add_child(pieza_boquilla)

func _physics_process(delta: float) -> void:
	if visual_herramienta == null:
		_crear_visual_herramienta()

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
				_actualizar_visual_herramienta()
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
	_animar_uso_herramienta(false)
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
	_animar_uso_herramienta(true)
	_emitir_rafaga_co2()
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("sacudir"):
		cam.sacudir(0.08, 0.35)
	
	# Enfriamiento masivo instantáneo (-35°C)
	if obj != null and obj.get("apagado") != true:
		if "calor" in obj:
			obj.calor = maxf(0.0, obj.calor - 35.0)
			if obj.has_method("actualizar_interfaz_diegética"):
				obj.actualizar_interfaz_diegética()
			_emitir_impacto_co2(obj)
		print(">>> [EXTINTOR] Ráfaga de CO₂ aplicada a %s (-35°C). Cargas restantes: %d <<<" % [obj.name, cargas_extintor])
	else:
		print(">>> [EXTINTOR] Ráfaga de CO₂ descargada al aire. Cargas restantes: %d <<<" % cargas_extintor)
	
	extintor_disparado.emit(cargas_extintor, obj)

func _animar_uso_herramienta(extintor: bool) -> void:
	if visual_herramienta == null or not visual_herramienta.visible:
		return
	if _animacion_herramienta != null and _animacion_herramienta.is_running():
		_animacion_herramienta.kill()

	var pose_inicial := Vector3(-8.0, -12.0, -8.0)
	visual_herramienta.rotation_degrees = pose_inicial
	if extintor:
		_animacion_herramienta = create_tween()
		_animacion_herramienta.tween_property(visual_herramienta, "position", Vector3(0.34, -0.25, -0.52), 0.08)
		_animacion_herramienta.tween_property(visual_herramienta, "position", Vector3(0.34, -0.3, -0.62), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_animacion_herramienta = create_tween()
		_animacion_herramienta.tween_property(visual_herramienta, "rotation_degrees", pose_inicial + Vector3(-28.0, 0.0, 72.0), 0.09).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_animacion_herramienta.tween_property(visual_herramienta, "rotation_degrees", pose_inicial + Vector3(12.0, 0.0, -18.0), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_animacion_herramienta.tween_property(visual_herramienta, "rotation_degrees", pose_inicial, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _emitir_rafaga_co2() -> void:
	var camara := get_viewport().get_camera_3d()
	if camara == null or visual_herramienta == null:
		return
	var particulas := _crear_particulas_co2()
	camara.add_child(particulas)
	particulas.position = visual_herramienta.position + Vector3(0.1, 0.2, -0.18)
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.2).timeout.connect(particulas.queue_free)

func _emitir_impacto_co2(obj: Node3D) -> void:
	var particulas := _crear_particulas_co2()
	get_tree().current_scene.add_child(particulas)
	particulas.global_position = obj.global_position + Vector3(0.0, 0.95, 0.15)
	particulas.direction = Vector3(0.0, 0.0, 1.0)
	particulas.spread = 85.0
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.2).timeout.connect(particulas.queue_free)

func _crear_particulas_co2() -> CPUParticles3D:
	var particulas := CPUParticles3D.new()
	particulas.one_shot = true
	particulas.amount = 42
	particulas.lifetime = 0.55
	particulas.explosiveness = 0.82
	particulas.randomness = 0.8
	particulas.direction = Vector3(0.0, 0.0, -1.0)
	particulas.spread = 18.0
	particulas.initial_velocity_min = 1.8
	particulas.initial_velocity_max = 3.2
	particulas.gravity = Vector3(0.0, 0.15, 0.0)
	particulas.scale_amount_min = 0.035
	particulas.scale_amount_max = 0.09
	particulas.color = Color(0.72, 0.9, 1.0, 0.72)
	var malla := SphereMesh.new()
	malla.radius = 0.5
	malla.height = 1.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = particulas.color
	material.emission_enabled = true
	material.emission = Color(0.35, 0.72, 1.0)
	material.emission_energy_multiplier = 0.55
	malla.material = material
	particulas.mesh = malla
	return particulas

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
