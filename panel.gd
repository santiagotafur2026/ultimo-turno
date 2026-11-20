extends Node3D

signal panel_apagado(panel: Node3D)
signal panel_reiniciado(panel: Node3D)
signal calor_cambiado(nuevo_calor: float)

@export var calor: float = 20.0
@export var tasa_generacion: float = 0.7
@export var icono: String = ""
@export var nombre_sistema: String = ""
@export var frecuencia_alarma: float = 440.0

var tasa_extra: float = 0.0
var apagado: bool = false
var sin_senal: bool = false
var tiene_sanguijuela: bool = false
var sanguijuela_instancia: SanguijuelaTermica = null
var _color_identidad: Color
var _material_acento: StandardMaterial3D
var _luz_acento: OmniLight3D
var _decoracion: Node3D
var _tiempo_visual: float = 0.0
var _tween_visual: Tween

@onready var texto: Label3D = get_node_or_null("Consola/Label3D")
@onready var aguja: Node3D = get_node_or_null("Consola/Dial/AgujaPivot")
@onready var luz_led: OmniLight3D = get_node_or_null("Consola/LuzLED")
@onready var alarma: Node = get_node_or_null("Alarma")

const ANGULO_MIN_AGUJA: float = 75.0
const ANGULO_MAX_AGUJA: float = -75.0

var _era_apagado: bool = false

func _ready() -> void:
	if nombre_sistema == "":
		nombre_sistema = name
	if alarma != null and "frecuencia_base" in alarma:
		alarma.frecuencia_base = frecuencia_alarma
	_configurar_identidad_visual()
	actualizar_interfaz_diegética()

func _physics_process(delta: float) -> void:
	_tiempo_visual += delta
	if not apagado:
		calor += (tasa_generacion + tasa_extra) * delta
		if calor >= 100.0:
			calor = 100.0
			apagado = true
			if alarma != null:
				alarma.desactivar()
			panel_apagado.emit(self)
		else:
			# Actualizar alarma segun temperatura actual
			if alarma != null:
				alarma.activar(calor)
		actualizar_interfaz_diegética()
		calor_cambiado.emit(calor)
	
	# Parpadeo del LED cuando esta en estado critico
	if apagado or calor >= 90.0:
		_parpadear_led(delta)
	_actualizar_efectos_visuales()

func _configurar_identidad_visual() -> void:
	match name:
		"Energia":
			_color_identidad = Color(1.0, 0.56, 0.12)
		"Refrigeracion":
			_color_identidad = Color(0.18, 0.82, 1.0)
		"Comunicaciones":
			_color_identidad = Color(0.62, 0.48, 1.0)
		"SoporteVital":
			_color_identidad = Color(0.24, 1.0, 0.62)
		_:
			_color_identidad = Color(0.3, 0.82, 1.0)

	var consola := get_node_or_null("Consola") as Node3D
	if consola == null:
		return

	var material_consola := StandardMaterial3D.new()
	material_consola.albedo_color = Color(0.09, 0.12, 0.15)
	material_consola.metallic = 0.58
	material_consola.roughness = 0.38
	var mesa := consola.get_node_or_null("Mesa") as MeshInstance3D
	var tablero := consola.get_node_or_null("Tablero") as MeshInstance3D
	if mesa != null:
		mesa.material_override = material_consola
	if tablero != null:
		tablero.material_override = material_consola

	_decoracion = Node3D.new()
	_decoracion.name = "DetallesIdentidad"
	consola.add_child(_decoracion)

	_material_acento = StandardMaterial3D.new()
	_material_acento.albedo_color = _color_identidad
	_material_acento.metallic = 0.38
	_material_acento.roughness = 0.3
	_material_acento.emission_enabled = true
	_material_acento.emission = _color_identidad
	_material_acento.emission_energy_multiplier = 0.7

	# Frisos laterales enmarcan el tablero sin tapar la aguja ni los controles.
	for lado in [-1, 1]:
		var friso := BoxMesh.new()
		friso.size = Vector3(0.035, 0.27, 0.035)
		_agregar_detalle(friso, _material_acento,
			Vector3(0.42 * lado, 0.97, 0.105), Vector3(-20.0, 0.0, 0.0))

	# Remaches e indicadores de estado secundarios.
	var material_remache := StandardMaterial3D.new()
	material_remache.albedo_color = Color(0.48, 0.55, 0.6)
	material_remache.metallic = 0.85
	material_remache.roughness = 0.22
	for x in [-0.39, 0.39]:
		for y in [0.86, 1.08]:
			var remache := SphereMesh.new()
			remache.radius = 0.018
			remache.height = 0.018
			_agregar_detalle(remache, material_remache, Vector3(x, y, 0.13))

	for indice in range(3):
		var indicador := SphereMesh.new()
		indicador.radius = 0.022
		indicador.height = 0.022
		_agregar_detalle(indicador, _material_acento,
			Vector3(0.29, 0.91 + indice * 0.075, 0.145))

	_crear_motivo_funcional()

	_luz_acento = OmniLight3D.new()
	_luz_acento.name = "LuzIdentidad"
	_luz_acento.position = Vector3(0.0, 1.03, 0.38)
	_luz_acento.light_color = _color_identidad
	_luz_acento.light_energy = 0.32
	_luz_acento.omni_range = 1.2
	_luz_acento.shadow_enabled = false
	consola.add_child(_luz_acento)

	if luz_led != null:
		luz_led.light_color = _color_identidad
		luz_led.light_energy = 0.55
		luz_led.omni_range = 1.5

func _agregar_detalle(mesh: Mesh, material: Material, posicion: Vector3,
		rotacion: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var detalle := MeshInstance3D.new()
	detalle.mesh = mesh
	detalle.material_override = material
	detalle.position = posicion
	detalle.rotation_degrees = rotacion
	_decoracion.add_child(detalle)
	return detalle

func _crear_motivo_funcional() -> void:
	var placa := BoxMesh.new()
	placa.size = Vector3(0.19, 0.035, 0.018)
	var material_oscuro := StandardMaterial3D.new()
	material_oscuro.albedo_color = Color(0.035, 0.05, 0.065)
	material_oscuro.metallic = 0.25
	material_oscuro.roughness = 0.48
	_agregar_detalle(placa, material_oscuro,
		Vector3(-0.25, 0.88, 0.15), Vector3(-20.0, 0.0, 0.0))

	var sello := Label3D.new()
	sello.name = "SelloFuncion"
	sello.position = Vector3(-0.25, 0.885, 0.163)
	sello.rotation_degrees.x = -20.0
	sello.font_size = 14
	sello.outline_size = 3
	sello.modulate = _color_identidad
	sello.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match name:
		"Energia":
			sello.text = "HV"
			_crear_motivo_energia()
		"Refrigeracion":
			sello.text = "COOL"
			_crear_motivo_refrigeracion()
		"Comunicaciones":
			sello.text = "RF"
			_crear_motivo_comunicaciones()
		"SoporteVital":
			sello.text = "O2"
			_crear_motivo_soporte()
		_:
			sello.text = "SYSTEM"
	_decoracion.add_child(sello)

func _crear_motivo_energia() -> void:
	for indice in range(3):
		var bobina := CylinderMesh.new()
		bobina.top_radius = 0.035
		bobina.bottom_radius = 0.035
		bobina.height = 0.13 + indice * 0.035
		_agregar_detalle(bobina, _material_acento,
			Vector3(-0.29 + indice * 0.08, 0.85, 0.18))

func _crear_motivo_refrigeracion() -> void:
	for indice in range(4):
		var rejilla := BoxMesh.new()
		rejilla.size = Vector3(0.035, 0.17, 0.025)
		_agregar_detalle(rejilla, _material_acento,
			Vector3(-0.29 + indice * 0.065, 0.98, 0.17),
			Vector3(-20.0, 0.0, -8.0))

func _crear_motivo_comunicaciones() -> void:
	for indice in range(3):
		var antena := CylinderMesh.new()
		antena.top_radius = 0.009
		antena.bottom_radius = 0.009
		antena.height = 0.13 + indice * 0.045
		_agregar_detalle(antena, _material_acento,
			Vector3(-0.3 + indice * 0.08, 1.0, 0.16))

func _crear_motivo_soporte() -> void:
	var tanque := CylinderMesh.new()
	tanque.top_radius = 0.035
	tanque.bottom_radius = 0.035
	tanque.height = 0.2
	_agregar_detalle(tanque, _material_acento,
		Vector3(-0.28, 0.98, 0.17))
	var marca := BoxMesh.new()
	marca.size = Vector3(0.12, 0.018, 0.02)
	_agregar_detalle(marca, _material_acento,
		Vector3(-0.28, 0.98, 0.205), Vector3(-20.0, 0.0, 0.0))

func _actualizar_efectos_visuales() -> void:
	if _material_acento == null:
		return
	var factor_alerta := clampf((calor - 70.0) / 30.0, 0.0, 1.0)
	var pulso := 0.5 + 0.5 * sin(_tiempo_visual * (2.0 + factor_alerta * 5.0))
	var color_estado := _color_identidad
	if apagado or tiene_sanguijuela:
		color_estado = Color(1.0, 0.12, 0.08)
	elif sin_senal:
		color_estado = Color(0.42, 0.48, 0.52)
	_material_acento.emission = color_estado
	_material_acento.emission_energy_multiplier = lerpf(0.45, 1.15, pulso * (0.25 + factor_alerta * 0.75))
	if _luz_acento != null:
		_luz_acento.light_color = color_estado
		_luz_acento.light_energy = 0.22 + pulso * (0.16 + factor_alerta * 0.28)

func enfriar(delta: float) -> void:
	if apagado or tiene_sanguijuela:
		return
	calor -= 8.0 * delta
	if calor < 0.0:
		calor = 0.0
	actualizar_interfaz_diegética()
	calor_cambiado.emit(calor)

func adherir_sanguijuela() -> void:
	if tiene_sanguijuela or apagado:
		return
	var sang := SanguijuelaTermica.new()
	var consola = get_node_or_null("Consola")
	if consola:
		consola.add_child(sang)
		sang.position = Vector3(0, 1.28, 0.34)
	else:
		add_child(sang)
		sang.position = Vector3(0, 1.28, 0.34)
	sanguijuela_instancia = sang
	sang.destruida.connect(_on_sanguijuela_destruida)
	sang.adherir_a_panel(self)
	actualizar_interfaz_diegética()

func _on_sanguijuela_destruida(_p: Node3D) -> void:
	tiene_sanguijuela = false
	sanguijuela_instancia = null
	actualizar_interfaz_diegética()

func reiniciar() -> void:
	if not apagado:
		return
	apagado = false
	calor = 35.0
	_animar_reinicio()
	actualizar_interfaz_diegética()
	panel_reiniciado.emit(self)
	print(">>> SISTEMA RESTAURADO: %s reiniciado a 35°C <<<" % nombre_sistema)

func _animar_reinicio() -> void:
	if _decoracion == null:
		return
	if _tween_visual != null and _tween_visual.is_running():
		_tween_visual.kill()
	_decoracion.scale = Vector3.ONE * 0.88
	if _material_acento != null:
		_material_acento.emission_energy_multiplier = 1.8
	_tween_visual = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween_visual.tween_property(_decoracion, "scale", Vector3.ONE, 0.32)
	if _material_acento != null:
		_tween_visual.parallel().tween_property(_material_acento, "emission_energy_multiplier", 0.65, 0.45)

func actualizar_interfaz_diegética() -> void:
	if aguja != null and not sin_senal:
		var factor = clampf(calor / 100.0, 0.0, 1.0)
		var angulo_z = lerpf(ANGULO_MIN_AGUJA, ANGULO_MAX_AGUJA, factor)
		aguja.rotation_degrees.z = angulo_z
	
	var color_estado: Color
	if apagado:
		color_estado = Color(0.85, 0.15, 0.15)
	elif sin_senal:
		color_estado = Color(0.45, 0.45, 0.45)
	elif calor >= 90.0:
		color_estado = Color(0.84, 0.23, 0.23)
	elif calor >= 50.0:
		color_estado = Color(0.9, 0.49, 0.13)
	else:
		color_estado = Color(0.18, 0.8, 0.44)
	
	if luz_led != null:
		luz_led.light_color = color_estado
		luz_led.light_energy = 0.15 if sin_senal else (0.8 if calor >= 90.0 else 0.45)
	
	if texto != null:
		texto.font_size = 26
		texto.outline_size = 5
		texto.outline_modulate = Color(0.015, 0.025, 0.035, 1.0)
		var cabecera = "%s %s" % [icono, nombre_sistema]
		if tiene_sanguijuela:
			texto.text = "%s\n¡PARÁSITO ADHERIDO!\n[Golpea con Llave Q]" % cabecera
			texto.modulate = Color(1.0, 0.2, 0.2)
		elif apagado:
			texto.text = "%s\nAPAGADO (100°)\n[Mantén E para reiniciar]" % cabecera
			texto.modulate = Color(0.9, 0.2, 0.2)
		elif sin_senal:
			texto.text = "%s\n[SIN SEÑAL]" % cabecera
			texto.modulate = Color(0.55, 0.55, 0.55)
		else:
			texto.text = "%s\n%.1f°C" % [cabecera, calor]
			texto.modulate = color_estado

var _tiempo_parpadeo: float = 0.0

func _parpadear_led(delta: float) -> void:
	if luz_led == null:
		return
	# Frecuencia de parpadeo segun gravedad: critico mas rapido
	var hz = 6.0 if apagado else 2.5
	_tiempo_parpadeo += delta * hz
	var encendido = int(_tiempo_parpadeo) % 2 == 0
	var energia_base = 0.9 if apagado else 0.75
	luz_led.light_energy = energia_base if encendido else 0.05
