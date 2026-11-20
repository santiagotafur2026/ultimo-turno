class_name SanguijuelaTermica extends Node3D

signal destruida(panel: Node3D)

var panel_padre: Node3D = null
var activa: bool = false
var vida: int = 1
var _tiempo: float = 0.0

var cuerpo_mesh: MeshInstance3D
var ojos_mesh: MeshInstance3D
var luz_ojos: OmniLight3D

const CALOR_EXTRA_PARASITO: float = 1.8

func _ready() -> void:
	_construir_visuales()
	visible = false

func _construir_visuales() -> void:
	# Materiales emisivos mantienen el contraste incluso con la sala a oscuras.
	var mat_cuerpo := StandardMaterial3D.new()
	mat_cuerpo.albedo_color = Color(1.0, 0.19, 0.035, 1)
	mat_cuerpo.roughness = 0.32
	mat_cuerpo.metallic = 0.0
	mat_cuerpo.emission_enabled = true
	mat_cuerpo.emission = Color(1.0, 0.12, 0.015)
	mat_cuerpo.emission_energy_multiplier = 0.85

	cuerpo_mesh = MeshInstance3D.new()
	for i in range(7):
		var segmento := SphereMesh.new()
		segmento.radius = 0.12 if i in [2, 3, 4] else 0.105
		segmento.height = 0.24 if i in [2, 3, 4] else 0.21
		segmento.material = mat_cuerpo
		var nodo := MeshInstance3D.new()
		nodo.mesh = segmento
		nodo.position = Vector3((i - 3) * 0.13, 0.0, sin(i * 1.7) * 0.025)
		nodo.rotation_degrees.z = (i - 3) * 4.0
		cuerpo_mesh.add_child(nodo)
	cuerpo_mesh.rotation_degrees.x = 75.0
	add_child(cuerpo_mesh)

	# Placas dorsales cian que definen la silueta y el patrón segmentado.
	var mat_placas := StandardMaterial3D.new()
	mat_placas.albedo_color = Color(0.1, 1.0, 0.86)
	mat_placas.roughness = 0.24
	mat_placas.emission_enabled = true
	mat_placas.emission = Color(0.04, 1.0, 0.72)
	mat_placas.emission_energy_multiplier = 1.5
	for i in range(5):
		var placa_geo := SphereMesh.new()
		placa_geo.radius = 0.047
		placa_geo.height = 0.09
		placa_geo.material = mat_placas
		var placa := MeshInstance3D.new()
		placa.mesh = placa_geo
		placa.position = Vector3((i - 2) * 0.13, 0.095, 0.035)
		cuerpo_mesh.add_child(placa)

	# Ventosas laterales y boca sugadora.
	var mat_sucker := StandardMaterial3D.new()
	mat_sucker.albedo_color = Color(0.14, 0.015, 0.025)
	mat_sucker.roughness = 0.38
	for i in range(5):
		for lado in [-1, 1]:
			var ventosa_mesh := SphereMesh.new()
			ventosa_mesh.radius = 0.026
			ventosa_mesh.height = 0.036
			ventosa_mesh.material = mat_sucker
			var ventosa := MeshInstance3D.new()
			ventosa.mesh = ventosa_mesh
			ventosa.position = Vector3((i - 2) * 0.105, 0.065 * lado, 0.145)
			ventosa.scale = Vector3(1.0, 0.45, 1.0)
			add_child(ventosa)

	var boca_mesh := SphereMesh.new()
	boca_mesh.radius = 0.07
	boca_mesh.height = 0.035
	var mat_boca := StandardMaterial3D.new()
	mat_boca.albedo_color = Color(0.04, 0.008, 0.006)
	mat_boca.roughness = 0.5
	boca_mesh.material = mat_boca
	var boca := MeshInstance3D.new()
	boca.mesh = boca_mesh
	boca.position = Vector3(0.0, -0.01, 0.145)
	boca.scale = Vector3(1.0, 0.5, 1.0)
	add_child(boca)

	# Ojos pares con iris incandescentes.
	ojos_mesh = MeshInstance3D.new()
	var ojo_mat := StandardMaterial3D.new()
	ojo_mat.albedo_color = Color(1.0, 0.95, 0.22)
	ojo_mat.emission_enabled = true
	ojo_mat.emission = Color(1.0, 0.68, 0.08)
	ojo_mat.emission_energy_multiplier = 2.5
	for lado in [-1, 1]:
		var ojo_geo := SphereMesh.new()
		ojo_geo.radius = 0.03
		ojo_geo.height = 0.03
		ojo_geo.material = ojo_mat
		var ojo := MeshInstance3D.new()
		ojo.mesh = ojo_geo
		ojo.position = Vector3(0.045 * lado, 0.095, 0.22)
		ojos_mesh.add_child(ojo)
	add_child(ojos_mesh)

	luz_ojos = OmniLight3D.new()
	luz_ojos.light_color = Color(0.12, 1.0, 0.74)
	luz_ojos.light_energy = 1.6
	luz_ojos.omni_range = 2.2
	luz_ojos.shadow_enabled = false
	luz_ojos.position = Vector3(0, 0.12, 0.22)
	add_child(luz_ojos)

	# Las partículas necesitan una malla explícita para aparecer en 3D.
	var particulas := CPUParticles3D.new()
	particulas.amount = 24
	particulas.lifetime = 1.4
	particulas.explosiveness = 0.1
	particulas.randomness = 0.65
	particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = 0.24
	particulas.direction = Vector3(0, 1, 0)
	particulas.gravity = Vector3(0, 0.03, 0)
	particulas.initial_velocity_min = 0.04
	particulas.initial_velocity_max = 0.12
	particulas.scale_amount_min = 0.018
	particulas.scale_amount_max = 0.035
	particulas.color = Color(0.08, 1.0, 0.75, 0.9)
	var malla_particula := SphereMesh.new()
	malla_particula.radius = 0.5
	malla_particula.height = 1.0
	var mat_particula := StandardMaterial3D.new()
	mat_particula.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_particula.albedo_color = Color(0.08, 1.0, 0.75, 0.9)
	mat_particula.emission_enabled = true
	mat_particula.emission = Color(0.04, 1.0, 0.62)
	mat_particula.emission_energy_multiplier = 1.4
	malla_particula.material = mat_particula
	particulas.mesh = malla_particula
	particulas.position = Vector3(0, 0.03, 0.18)
	add_child(particulas)

func adherir_a_panel(panel: Node3D) -> void:
	panel_padre = panel
	activa = true
	vida = 1
	visible = true
	
	if panel_padre != null:
		panel_padre.set("tiene_sanguijuela", true)
		if "tasa_extra" in panel_padre:
			panel_padre.tasa_extra += CALOR_EXTRA_PARASITO
	
	print(">>> [AMENAZA] ¡Sanguijuela térmica adherida a %s! Calor extra: +%.1f°C/s <<<" % [
		panel_padre.name if panel_padre else "panel", CALOR_EXTRA_PARASITO
	])

func recibir_golpe() -> bool:
	if not activa:
		return false
	vida -= 1
	if vida <= 0:
		morir()
		return true
	return false

func morir() -> void:
	activa = false
	visible = false
	
	if panel_padre != null:
		panel_padre.set("tiene_sanguijuela", false)
		if "tasa_extra" in panel_padre:
			panel_padre.tasa_extra = maxf(0.0, panel_padre.tasa_extra - CALOR_EXTRA_PARASITO)
		destruida.emit(panel_padre)
		print(">>> [COMBATE] ¡Sanguijuela eliminada en %s! <<<" % panel_padre.name)

func _process(delta: float) -> void:
	if not activa:
		return
	_tiempo += delta * 6.0
	# Pulso orgánico limitado al cuerpo para no desalinear ojos ni partículas.
	var escala_v = 1.0 + sin(_tiempo) * 0.045
	cuerpo_mesh.scale = Vector3(escala_v, 1.0 / escala_v, 1.0)
	if luz_ojos != null:
		luz_ojos.light_energy = 1.35 + sin(_tiempo * 1.5) * 0.25
