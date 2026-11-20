extends Node

@export var sistema: SistemaSol
@export var camara: Camera3D
@export var superficie: MeshInstance3D 
@export var punto := Vector3(0, 0, 0) # Centro del piso
@export var horas: Array[float] = [8.0, 9.0, 10.0]

var i := 0
var espera := 0

func _ready() -> void:
	var env := sistema.entorno.environment
	# Modo laboratorio: apagamos ambiente, reflejos y tonemap
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	
	# Hacemos el piso blanco mate para medir bien
	var mate := StandardMaterial3D.new()
	mate.roughness = 1.0
	mate.metallic_specular = 0.0
	superficie.material_override = mate
	
	sistema.ciclo.pausado = true
	sistema.ciclo.hora = horas[0]

func _process(_delta: float) -> void:
	espera += 1
	if espera < 10: # Esperar a que la cámara renderice
		return
	espera = 0
	
	# Proyectar el punto 3D a la pantalla y leer el píxel
	var px := camara.unproject_position(punto)
	var imagen := get_viewport().get_texture().get_image()
	var color := imagen.get_pixel(int(px.x), int(px.y))
	
	# Imprimir en consola el medido vs el predicho
	print("hora %.1f  medido %.3f  predicho %.3f" % [sistema.ciclo.hora, color.srgb_to_linear().r, sistema.prediccion_piso()])
	
	i += 1
	if i < horas.size():
		sistema.ciclo.hora = horas[i] # Avanzar a la siguiente hora
	else:
		sistema.ciclo.pausado = false # Reanuda el ciclo una vez finalizadas las medidas
		set_process(false) # Terminar
