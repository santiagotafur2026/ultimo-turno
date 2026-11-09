class_name SistemaSol extends Node

# 1. La señal del Nivel 2
signal cambio_noche(es_noche: bool)

@export var sol: DirectionalLight3D
@export var entorno: WorldEnvironment
@export var energia_sol := 1.0
@export var azimut := -30.0
@export var ambiente_dia := 1.0
@export var ambiente_noche := 0.15 
@onready var ciclo = $CicloDia

var era_noche := false # 2. Para recordar el frame anterior

func _ready() -> void:
	aplicar_hora()
	# 3. Inicializar el estado
	era_noche = ciclo.factor_sol(ciclo.hora) <= 0.0

func _process(delta: float) -> void:
	ciclo.avanzar(delta)
	aplicar_hora()
	
	# 4. Comprobar si cambió y emitir la señal
	var es_noche = ciclo.factor_sol(ciclo.hora) <= 0.0
	if es_noche != era_noche:
		era_noche = es_noche
		cambio_noche.emit(es_noche)

func aplicar_hora() -> void:
	var h = ciclo.hora
	var f = ciclo.factor_sol(h)
	
	if sol != null:
		sol.rotation_degrees = Vector3(-ciclo.elevacion(h), azimut, 0.0)
		sol.light_energy = energia_sol * f
		sol.light_color = ciclo.color_sol(h)
		
	if entorno != null and entorno.environment != null:
		entorno.environment.ambient_light_energy = lerpf(ambiente_noche, ambiente_dia, f)
static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	
	var n = normal.normalized()
	var l = hacia_luz.normalized()
	
	var punto = n.dot(l)
	
	return maxf(0.0, punto)

func prediccion_piso() -> float:
	
	var hacia_luz = -sol.global_transform.basis.z
	var l = lambert(Vector3.UP, hacia_luz)
	
	return sol.light_energy * sol.light_color.r * l
