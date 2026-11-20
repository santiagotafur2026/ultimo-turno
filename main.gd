extends Node3D

const REGISTRAR_CORRER = true

var particulas_polvo: CPUParticles3D
var luz_principal_node: OmniLight3D
var luz_emergencia_node: OmniLight3D
var tiempo_inmersivo: float = 0.0

func _ready():
	_registrar("move_left", [KEY_A, KEY_LEFT])
	_registrar("move_right", [KEY_D, KEY_RIGHT])
	_registrar("move_up", [KEY_W, KEY_UP])
	_registrar("move_down", [KEY_S, KEY_DOWN])
	if REGISTRAR_CORRER:
		_registrar("correr", [KEY_SHIFT])
	
	# Mapeos de acción para Último Turno
	_registrar("reiniciar", [KEY_E])
	_registrar("pedir_ayuda", [KEY_F])
	_registrar("pausa", [KEY_ESCAPE])
	_registrar("reintentar", [KEY_ENTER, KEY_KP_ENTER])
	_registrar("golpe_critico", [KEY_SPACE])
	_registrar("usar_herramienta", [KEY_Q])

	_configurar_ambiente()
	_crear_detalles_escenario()
	_crear_particulas_atmosfericas()
	luz_principal_node = get_node_or_null("LuzPrincipal")
	luz_emergencia_node = get_node_or_null("LuzEmergencia")

func _registrar(nombre: String, teclas: Array):
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	for k in teclas:
		var e = InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(nombre, e)

func _configurar_ambiente() -> void:
	var material_pared := StandardMaterial3D.new()
	material_pared.albedo_color = Color(0.105, 0.15, 0.19)
	material_pared.metallic = 0.16
	material_pared.roughness = 0.84
	_aplicar_material("SalaControl/ParedNorte", material_pared)
	_aplicar_material("SalaControl/ParedSur", material_pared)
	_aplicar_material("SalaControl/ParedEste", material_pared)
	_aplicar_material("SalaControl/ParedOeste", material_pared)

	var material_suelo := StandardMaterial3D.new()
	material_suelo.albedo_color = Color(0.075, 0.095, 0.12)
	material_suelo.metallic = 0.28
	material_suelo.roughness = 0.72
	_aplicar_material("SalaControl/Suelo", material_suelo)

	var material_techo := StandardMaterial3D.new()
	material_techo.albedo_color = Color(0.055, 0.075, 0.1)
	material_techo.metallic = 0.2
	material_techo.roughness = 0.82
	_aplicar_material("SalaControl/Techo", material_techo)

	_crear_luz_acento("LuzReboteCian", Vector3(-2.75, 2.55, 0.0),
		Color(0.28, 0.72, 0.85), 0.38, 4.2)
	_crear_luz_acento("LuzReboteAmbar", Vector3(2.75, 2.35, 0.0),
		Color(1.0, 0.58, 0.28), 0.24, 3.8)

func _aplicar_material(ruta: String, material: Material) -> void:
	var instancia := get_node_or_null(ruta) as MeshInstance3D
	if instancia != null:
		instancia.material_override = material

func _crear_luz_acento(nombre: String, posicion: Vector3, color: Color,
		energia: float, alcance: float) -> void:
	var luz := OmniLight3D.new()
	luz.name = nombre
	luz.position = posicion
	luz.light_color = color
	luz.light_energy = energia
	luz.omni_range = alcance
	luz.shadow_enabled = false
	add_child(luz)

func _crear_detalles_escenario() -> void:
	var decoracion := Node3D.new()
	decoracion.name = "DetallesArquitectonicos"
	add_child(decoracion)

	var material_panel := StandardMaterial3D.new()
	material_panel.albedo_color = Color(0.065, 0.105, 0.14)
	material_panel.metallic = 0.3
	material_panel.roughness = 0.68
	var material_borde := StandardMaterial3D.new()
	material_borde.albedo_color = Color(0.16, 0.25, 0.29)
	material_borde.metallic = 0.65
	material_borde.roughness = 0.35
	var material_cian := StandardMaterial3D.new()
	material_cian.albedo_color = Color(0.18, 0.72, 0.78)
	material_cian.emission_enabled = true
	material_cian.emission = Color(0.07, 0.42, 0.48)
	material_cian.emission_energy_multiplier = 0.55
	var material_ambar := StandardMaterial3D.new()
	material_ambar.albedo_color = Color(0.9, 0.46, 0.18)
	material_ambar.emission_enabled = true
	material_ambar.emission = Color(0.5, 0.16, 0.035)
	material_ambar.emission_energy_multiplier = 0.4

	# Paneles empotrados y remates finos rompen las superficies sin recargar la sala.
	for x in [-2.0, 2.0]:
		_crear_pieza_escenario(decoracion, "PanelNorte", Vector3(0.82, 2.05, 0.028),
			Vector3(x, 1.5, -2.962), material_panel)
		_crear_pieza_escenario(decoracion, "PanelSur", Vector3(0.82, 2.05, 0.028),
			Vector3(x, 1.5, 2.962), material_panel)
		_crear_pieza_escenario(decoracion, "LineaNorte", Vector3(0.018, 1.72, 0.012),
			Vector3(x - 0.35, 1.5, -2.942), material_cian)
		_crear_pieza_escenario(decoracion, "LineaSur", Vector3(0.018, 1.72, 0.012),
			Vector3(x + 0.35, 1.5, 2.942), material_ambar)

	for z in [-2.0, 2.0]:
		_crear_pieza_escenario(decoracion, "PanelOeste", Vector3(0.028, 2.05, 0.82),
			Vector3(-2.962, 1.5, z), material_panel)
		_crear_pieza_escenario(decoracion, "PanelEste", Vector3(0.028, 2.05, 0.82),
			Vector3(2.962, 1.5, z), material_panel)
		_crear_pieza_escenario(decoracion, "LineaOeste", Vector3(0.012, 1.72, 0.018),
			Vector3(-2.942, 1.5, z - 0.35), material_ambar)
		_crear_pieza_escenario(decoracion, "LineaEste", Vector3(0.012, 1.72, 0.018),
			Vector3(2.942, 1.5, z + 0.35), material_cian)

	# Zócalos y molduras superiores de metal satinado.
	for z in [-2.965, 2.965]:
		_crear_pieza_escenario(decoracion, "Zocalo", Vector3(5.85, 0.055, 0.045),
			Vector3(0.0, 0.16, z), material_borde)
		_crear_pieza_escenario(decoracion, "MolduraSuperior", Vector3(5.85, 0.045, 0.04),
			Vector3(0.0, 2.82, z), material_borde)
	for x in [-2.965, 2.965]:
		_crear_pieza_escenario(decoracion, "Zocalo", Vector3(0.045, 0.055, 5.85),
			Vector3(x, 0.16, 0.0), material_borde)
		_crear_pieza_escenario(decoracion, "MolduraSuperior", Vector3(0.04, 0.045, 5.85),
			Vector3(x, 2.82, 0.0), material_borde)

	# Pequeñas juntas de piso que ayudan a leer profundidad y escala.
	var material_junta := StandardMaterial3D.new()
	material_junta.albedo_color = Color(0.045, 0.065, 0.085)
	material_junta.roughness = 0.9
	for x in [-1.4, 0.0, 1.4]:
		_crear_pieza_escenario(decoracion, "JuntaSuelo", Vector3(0.012, 0.008, 5.4),
			Vector3(x, 0.008, 0.0), material_junta)
	for z in [-1.4, 1.4]:
		_crear_pieza_escenario(decoracion, "JuntaSuelo", Vector3(5.4, 0.008, 0.012),
			Vector3(0.0, 0.008, z), material_junta)

	# Luz lineal discreta integrada al techo.
	_crear_pieza_escenario(decoracion, "LuzTechoCian", Vector3(1.7, 0.018, 0.055),
		Vector3(-1.25, 2.975, 0.0), material_cian)
	_crear_pieza_escenario(decoracion, "LuzTechoAmbar", Vector3(1.7, 0.018, 0.055),
		Vector3(1.25, 2.975, 0.0), material_ambar)

func _crear_pieza_escenario(padre: Node3D, prefijo: String, tamano: Vector3,
		posicion: Vector3, material: Material) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tamano
	var pieza := MeshInstance3D.new()
	pieza.name = prefijo
	pieza.mesh = malla
	pieza.material_override = material
	pieza.position = posicion
	padre.add_child(pieza)
	return pieza

func _crear_particulas_atmosfericas() -> void:
	particulas_polvo = CPUParticles3D.new()
	particulas_polvo.name = "PolvoAtmosferico"
	particulas_polvo.amount = 45
	particulas_polvo.lifetime = 7.0
	particulas_polvo.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particulas_polvo.emission_box_extents = Vector3(2.8, 1.35, 2.8)
	particulas_polvo.direction = Vector3(0.08, 0.02, 0.0)
	particulas_polvo.gravity = Vector3(0.0, 0.01, 0.0)
	particulas_polvo.initial_velocity_min = 0.01
	particulas_polvo.initial_velocity_max = 0.035
	particulas_polvo.scale_amount_min = 0.004
	particulas_polvo.scale_amount_max = 0.012
	particulas_polvo.color = Color(0.75, 0.82, 0.88, 0.22)
	particulas_polvo.position = Vector3(0, 1.45, 0)
	var malla_polvo := SphereMesh.new()
	malla_polvo.radius = 0.5
	malla_polvo.height = 1.0
	var material_polvo := StandardMaterial3D.new()
	material_polvo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_polvo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_polvo.albedo_color = Color(0.48, 0.74, 0.82, 0.24)
	malla_polvo.material = material_polvo
	particulas_polvo.mesh = malla_polvo
	add_child(particulas_polvo)

func _process(delta: float) -> void:
	tiempo_inmersivo += delta
	if luz_principal_node != null:
		luz_principal_node.light_energy = 1.15 + sin(tiempo_inmersivo * 0.7) * 0.025
	if luz_emergencia_node != null and luz_emergencia_node.visible:
		luz_emergencia_node.light_energy = 0.35 + (sin(tiempo_inmersivo * 4.0) * 0.5 + 0.5) * 0.55
