extends Camera3D

@export var objetivo: Node3D
@export var altura_ojos = 1.6
@export var sensibilidad = 0.003

func _ready():
	top_level = true
	rotation = Vector3.ZERO # empieza mirando al frente
	objetivo.get_node("Modelo").visible = false # adentro de la cabeza
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(evento):
	if evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var capturado = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if evento is InputEventMouseMotion and capturado:
		rotation.y -= evento.relative.x * sensibilidad
		rotation.x -= evento.relative.y * sensibilidad
		rotation.x = clamp(rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	global_position = objetivo.global_position + Vector3(0, altura_ojos, 0)
