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
	# Cuerpo segmentado del parasito
	cuerpo_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.07
	cap.height = 0.28
	
	var mat_cuerpo := StandardMaterial3D.new()
	mat_cuerpo.albedo_color = Color(0.08, 0.09, 0.1)
	mat_cuerpo.roughness = 0.3
	mat_cuerpo.metallic = 0.6
	cap.material = mat_cuerpo
	cuerpo_mesh.mesh = cap
	cuerpo_mesh.rotation_degrees.x = 75.0
	add_child(cuerpo_mesh)
	
	# Ojos incandescentes
	ojos_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.03, 0.04)
	
	var mat_ojos := StandardMaterial3D.new()
	mat_ojos.albedo_color = Color(1.0, 0.1, 0.1)
	mat_ojos.emission_enabled = true
	mat_ojos.emission = Color(1.0, 0.1, 0.1)
	mat_ojos.emission_energy_multiplier = 2.0
	box.material = mat_ojos
	ojos_mesh.mesh = box
	ojos_mesh.position = Vector3(0, 0.05, 0.12)
	add_child(ojos_mesh)
	
	# Luz roja pulsante
	luz_ojos = OmniLight3D.new()
	luz_ojos.light_color = Color(1.0, 0.15, 0.15)
	luz_ojos.light_energy = 0.8
	luz_ojos.omni_range = 1.2
	luz_ojos.position = Vector3(0, 0.08, 0.15)
	add_child(luz_ojos)

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
	# Respiracion / vibracion organica del parasito
	var escala_v = 1.0 + sin(_tiempo) * 0.08
	scale = Vector3(escala_v, escala_v, 1.0)
	if luz_ojos != null:
		luz_ojos.light_energy = 0.6 + sin(_tiempo * 1.5) * 0.4
