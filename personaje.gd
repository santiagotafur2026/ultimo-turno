extends CharacterBody3D
enum Estado { QUIETO, CAMINAR, ENFRIANDO }
const RAPIDEZ_MAX = [0.0, 2.0, 0.0]
@export var camara: Camera3D
@export var speed_caminar = 2.0
@export var speed_correr = 6.0
@export var tiempo_arranque = 0.25
@onready var anim = $Modelo/AnimationPlayer

# --- Enchufes ---
@export var multiplicador = 1.0
@export var empuje = Vector3.ZERO
@export var accion = ""

var avance = Vector3.ZERO
var estado = Estado.QUIETO
var rapidez_max = 0.0

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
	
	move_and_slide()
	var antes = estado
	estado = elegir_estado()
	rapidez_max = RAPIDEZ_MAX[estado]
	if estado != antes:
		print("Estado ", Estado.keys()[estado], " .Rapidez max", rapidez_max ," m/s")
		animar()
		#_prueba()
func elegir_estado():
	if Input.is_action_pressed("enfriar"):
		return Estado.ENFRIANDO
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CAMINAR
	return Estado.CAMINAR

func animar():
	if accion != "":
		anim.play(accion)
		return
	match estado:
		Estado.QUIETO:
			anim.play("idle")
		Estado.CAMINAR:
			anim.play("walk")
		Estado.ENFRIANDO:
			if anim.has_animation("crouch"):
				anim.play("crouch")
