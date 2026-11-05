extends Camera3D

@export var objetivo: Node3D
@export var altura_ojos = 1.6

func _ready():
	top_level = true
	rotation = Vector3.ZERO # empieza mirando al frente
	objetivo.get_node("Modelo").visible = false # adentro de la cabeza

func _physics_process(delta):
	global_position = objetivo.global_position + Vector3(0, altura_ojos, 0)
	# Medida (bórrenla al terminar):
	if Engine.get_physics_frames() % 30 == 0:
		print("cámara ", global_position.snappedf(0.01))
