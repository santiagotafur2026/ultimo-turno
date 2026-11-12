extends Node3D

signal panel_apagado(panel: Node3D)
signal panel_reiniciado(panel: Node3D)
signal calor_cambiado(nuevo_calor: float)

@export var calor: float = 30.0
@export var tasa_generacion: float = 1.0

var tasa_extra: float = 0.0 # M7: +1.0 cuando Refrigeración está apagada
var apagado: bool = false
var sin_senal: bool = false #  Diales congelados cuando Comunicaciones está apagada

@onready var texto: Label3D = $Label3D

func _ready() -> void:
	actualizar_texto()

func _physics_process(delta: float) -> void:
	if not apagado:
		#  Generación de calor base + sobretasa de refrigeración
		calor += (tasa_generacion + tasa_extra) * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			panel_apagado.emit(self)
		actualizar_texto()
		calor_cambiado.emit(calor)

func enfriar(delta: float) -> void:
	# Enfriamiento de 5 por segundo mientras esté encendido
	if apagado:
		return
	calor -= 5.0 * delta
	if calor < 0.0:
		calor = 0.0
	actualizar_texto()
	calor_cambiado.emit(calor)

func reiniciar() -> void:
	#  Reinicio de panel a 60° tras mantener E durante 4 segundos
	if not apagado:
		return
	apagado = false
	calor = 60.0
	actualizar_texto()
	panel_reiniciado.emit(self)
	print(">>> ¡SISTEMA RESTAURADO! %s ha sido reiniciado a 60°C <<<" % name)

func actualizar_texto() -> void:
	if texto == null:
		return
	
	if apagado:
		texto.text = "%s\nAPAGADO (100°)\n[Mantén E para reiniciar]" % name
		texto.modulate = Color(0.85, 0.15, 0.15)
	elif sin_senal:
		# Pérdida de señal cuando Comunicaciones cae
		texto.text = "%s\n[SIN SEÑAL]" % name
		texto.modulate = Color(0.5, 0.5, 0.5)
	else:
		texto.text = "%s\n%.1f°C" % [name, calor]
		if calor >= 90.0:
			texto.modulate = Color.RED
		elif calor >= 50.0:
			texto.modulate = Color.ORANGE
		else:
			texto.modulate = Color.GREEN
