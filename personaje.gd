extends CharacterBody3D

@export var camara: Camera3D
@export var speed_caminar = 2.5
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25
@onready var anim = $Modelo/AnimationPlayer

# --- Enchufes ---
@export var multiplicador = 1.0
@export var empuje = Vector3.ZERO
@export var accion = ""
var avance = Vector3.ZERO

func _physics_process(delta):
	velocity += get_gravity() * delta
	var input_dir = Input.get_vector("move_left", "move_right",
		"move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	var giro_cam = camara.global_rotation.y
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()
	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar

	var objetivo = direction * speed * multiplicador
	var paso = speed / tiempo_arranque * delta
	avance = avance.move_toward(objetivo, paso)
	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z

	if direction.length() > 0:
		basis = Basis.looking_at(direction)
	if accion != "":
		anim.play(accion)
	elif avance.length() > speed_caminar + 0.1:
		anim.play("sprint")
	elif avance.length() > 0.1:
		anim.play("walk")
	else:
		anim.play("idle")
	move_and_slide()
