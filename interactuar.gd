extends Node

@onready var pj = get_parent() as CharacterBody3D

func _physics_process(delta):
	if Engine.get_physics_frames() % 30 == 0:
		var obj = mas_cercano()
		if obj == null:
			print("no hay nada en el grupo interactivos")
		else:
			var d = snappedf(distancia_a(obj), 0.01)
			print("más cercano: ", obj.name, " a ", d, " m")

func mas_cercano():
	var mejor = null
	for obj in get_tree().get_nodes_in_group("interactivos"):
		if mejor == null or distancia_a(obj) < distancia_a(mejor):
			mejor = obj
	return mejor

func distancia_a(obj):
	# Verificamos que ambos tengan posición global (que sean 3D)
	if not pj is Node3D or not obj is Node3D:
		return 9999.0 # Si no es 3D, lo mandamos lejos para que no lo elija
		
	var a = Vector2(pj.global_position.x, pj.global_position.z)
	var b = Vector2(obj.global_position.x, obj.global_position.z)
	return a.distance_to(b)
