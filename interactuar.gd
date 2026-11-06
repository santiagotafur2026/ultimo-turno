extends Node

@export var tecla = "enfriar"
@export var alcance = 1.5
@onready var pj = get_parent()
var actual = null

func _physics_process(delta):
	var obj = mas_cercano()
	
	# Si no presiona la tecla o no hay objeto, se detiene
	if not Input.is_action_pressed(tecla) or obj == null:
		actual = null
		return
		
	if obj != actual:
		actual = obj
		
	if obj.has_method("enfriar"):
		obj.enfriar(delta)
		# Esto imprimirá cada 1 segundo, sin llenar la pantalla
		if Engine.get_physics_frames() % 60 == 0:
			print("Enfriando ", obj.name, " · Calor: ", snappedf(obj.calor, 0.1))

func mas_cercano():
	var mejor = null
	var distancia_menor = alcance # Empezamos con el alcance máximo permitido
	
	for obj in get_tree().get_nodes_in_group("interactivos"):
		# Calculamos la distancia directamente aquí para evitar fallos
		var dx = pj.global_position.x - obj.global_position.x
		var dz = pj.global_position.z - obj.global_position.z
		var d = sqrt(dx * dx + dz * dz)
		
		# Si está dentro del alcance y es más cerca que el anterior
		if d <= distancia_menor:
			mejor = obj
			distancia_menor = d # Actualizamos la distancia menor
			
	return mejor
