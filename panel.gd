extends Node3D

var calor = 100.0
@onready var texto = $Label3D

func _ready():
	actualizar_texto()

func enfriar(delta):
	calor -= 5.0 * delta
	if calor < 0:
		calor = 0
	actualizar_texto()

func actualizar_texto():
	texto.text = str(snappedf(calor, 0.1))
	
	if calor > 70:
		texto.modulate = Color.RED
	elif calor > 50:
		texto.modulate = Color.ORANGE
	else:
		texto.modulate = Color.GREEN
