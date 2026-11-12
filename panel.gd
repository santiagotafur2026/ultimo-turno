extends Node3D

signal panel_apagado(panel: Node3D)
signal calor_cambiado(nuevo_calor: float)

@export var calor: float = 30.0
@export var tasa_generacion: float = 1.0
var tasa_extra: float = 0.0
var apagado: bool = false

@onready var texto: Label3D = $Label3D

func _ready() -> void:
	actualizar_texto()

func _physics_process(delta: float) -> void:
	if not apagado:
		# M2: Generación continua de calor con escalada
		calor += (tasa_generacion + tasa_extra) * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			panel_apagado.emit(self)
		actualizar_texto()
		calor_cambiado.emit(calor)

func enfriar(delta: float) -> void:
	# M3: Enfriamiento de 5 por segundo mientras no esté apagado
	if apagado:
		return
	calor -= 5.0 * delta
	if calor < 0.0:
		calor = 0.0
	actualizar_texto()
	calor_cambiado.emit(calor)

func actualizar_texto() -> void:
	if texto != null:
		if apagado:
			texto.text = "%s\nAPAGADO (100°)" % name
			texto.modulate = Color(0.85, 0.15, 0.15)
		else:
			texto.text = "%s\n%.1f°C" % [name, calor]
			if calor >= 90.0:
				texto.modulate = Color.RED
			elif calor >= 50.0:
				texto.modulate = Color.ORANGE
			else:
				texto.modulate = Color.GREEN
