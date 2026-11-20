extends Camera3D

@export var objetivo: Node3D
@export var altura_ojos = 1.6
@export var sensibilidad = 0.003
@export var fov_normal = 75.0
@export var fov_apuntando = 50.0
@export var rapidez_zoom = 10.0

var shake_timer: float = 0.0
var shake_intensity: float = 0.05
var offset_shake: Vector3 = Vector3.ZERO

func sacudir(intensidad: float = 0.06, duracion: float = 0.35) -> void:
	shake_timer = duracion
	shake_intensity = intensidad

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
		var s = sensibilidad * fov / fov_normal # apuntando, más lento
		rotation.y -= evento.relative.x * s
		rotation.x -= evento.relative.y * s
		rotation.x = clampf(rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

		

func _physics_process(delta):
	if shake_timer > 0.0:
		shake_timer -= delta
		offset_shake = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
	else:
		offset_shake = Vector3.ZERO
	global_position = objetivo.global_position + Vector3(0, altura_ojos, 0) + offset_shake
	var apunta = Input.is_action_pressed("apuntar")
	var meta = fov_apuntando if apunta else fov_normal
	fov = lerp(fov, meta, rapidez_zoom * delta)
	if apunta and fov > 50.2:
		print("fov ", snappedf(fov, 0.01))
