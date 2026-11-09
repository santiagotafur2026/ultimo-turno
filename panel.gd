extends Node3D

@export var calor = 30.0
@export var genera = 1.0
@onready var texto = $Label3D

var apagado = false 

func _ready():
	actualizar_texto()

func _physics_process(delta):
	if not apagado:
		calor += genera * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			print("¡", name, " se ha apagado!")
		actualizar_texto()

func subir(cuanto):
	if apagado:
		return
	calor += cuanto
	if calor >= 100.0:
		calor = 100.0
		apagado = true
		print("¡", name, " se ha apagado!")
	actualizar_texto()
	print(name, " sube ", cuanto, ": calor ", snappedf(calor, 0.1))

func enfriar(delta):
	if apagado:
		return
	calor -= 5.0 * delta
	if calor < 0:
		calor = 0
	actualizar_texto()

func actualizar_texto():
	if texto != null:
		texto.text = str(snappedf(calor, 0.1))
		if calor >= 90:
			texto.modulate = Color.RED
		elif calor >= 50:
			texto.modulate = Color.ORANGE
		else:
			texto.modulate = Color.GREEN
