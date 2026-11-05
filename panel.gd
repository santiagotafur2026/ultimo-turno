extends Node3D
var calor = 100.0

func enfriar(delta):
	calor -= 5.0 * delta
	if calor < 0:
		calor = 0
