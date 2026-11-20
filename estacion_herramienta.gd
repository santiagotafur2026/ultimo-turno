class_name EstacionHerramienta extends StaticBody3D

enum TipoHerramienta { LLAVE_INGLESA, EXTINTOR }

@export var tipo: TipoHerramienta = TipoHerramienta.LLAVE_INGLESA
@export var nombre_item: String = "Llave Inglesa"
@export var icono: String = "🔧"

var cargada: bool = true
var cuerpo_mesh: MeshInstance3D
var etiqueta: Label3D
var _tween_interaccion: Tween

func _ready() -> void:
	add_to_group("interactivos")
	add_to_group("estaciones_herramienta")
	_construir_visual()

func _construir_visual() -> void:
	# Soporte de pared metálico
	var soporte := MeshInstance3D.new()
	var box_soporte := BoxMesh.new()
	box_soporte.size = Vector3(0.35, 0.5, 0.08)
	var mat_soporte := StandardMaterial3D.new()
	mat_soporte.albedo_color = Color(0.12, 0.14, 0.16)
	mat_soporte.metallic = 0.5
	mat_soporte.roughness = 0.6
	box_soporte.material = mat_soporte
	soporte.mesh = box_soporte
	add_child(soporte)
	
	# Malla del objeto (Llave o Extintor)
	cuerpo_mesh = MeshInstance3D.new()
	cuerpo_mesh.position = Vector3(0, 0, 0.08)
	
	if tipo == TipoHerramienta.LLAVE_INGLESA:
		nombre_item = "Llave Inglesa"
		icono = "🔧"
		var mesh_llave := BoxMesh.new()
		mesh_llave.size = Vector3(0.08, 0.38, 0.04)
		var mat_llave := StandardMaterial3D.new()
		mat_llave.albedo_color = Color(0.8, 0.5, 0.15) # Amarillo industrial
		mat_llave.metallic = 0.8
		mat_llave.roughness = 0.3
		mesh_llave.material = mat_llave
		cuerpo_mesh.mesh = mesh_llave
	else:
		nombre_item = "Extintor de CO₂"
		icono = "🧯"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.09
		cyl.bottom_radius = 0.09
		cyl.height = 0.38
		var mat_ext := StandardMaterial3D.new()
		mat_ext.albedo_color = Color(0.85, 0.15, 0.15) # Rojo extintor
		mat_ext.roughness = 0.4
		cyl.material = mat_ext
		cuerpo_mesh.mesh = cyl
	
	add_child(cuerpo_mesh)
	
	# Etiqueta de texto diegética
	etiqueta = Label3D.new()
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	etiqueta.position = Vector3(0, 0.35, 0.05)
	etiqueta.font_size = 20
	etiqueta.outline_size = 4
	etiqueta.modulate = Color(0.9, 0.95, 1.0)
	etiqueta.text = "%s %s" % [icono, nombre_item.to_upper()]
	add_child(etiqueta)

func interactuar_con_jugador(interactuador: Node) -> void:
	if interactuador == null:
		return
	var item_actual = interactuador.get("herramienta_equipada")
	var herramienta_seleccionada: int = tipo + 1
	var equipando: bool = item_actual != herramienta_seleccionada

	if equipando:
		for estacion in get_tree().get_nodes_in_group("estaciones_herramienta"):
			if estacion is EstacionHerramienta:
				estacion.cuerpo_mesh.visible = estacion.tipo + 1 != herramienta_seleccionada
				estacion._animar_interaccion(estacion == self)
		interactuador.set("herramienta_equipada", herramienta_seleccionada)
	else:
		cuerpo_mesh.visible = true
		interactuador.set("herramienta_equipada", 0)
		_animar_interaccion(false)
	
	if tipo == TipoHerramienta.LLAVE_INGLESA:
		if not equipando:
			print(">>> [HERRAMIENTAS] Llave Inglesa guardada en el soporte. <<<")
		else:
			print(">>> [HERRAMIENTAS] Llave Inglesa equipada. Presiona [Q / Clic] para golpear. <<<")
	elif tipo == TipoHerramienta.EXTINTOR:
		if not equipando:
			print(">>> [HERRAMIENTAS] Extintor colocado en su soporte. <<<")
		else:
			print(">>> [HERRAMIENTAS] Extintor de CO₂ equipado. Presiona [ESPACIO / Q] para ráfaga criogénica. <<<")

func _animar_interaccion(equipando: bool) -> void:
	if _tween_interaccion != null and _tween_interaccion.is_running():
		_tween_interaccion.kill()

	var escala_objetivo := Vector3.ONE if cuerpo_mesh.visible else Vector3.ZERO
	if cuerpo_mesh.visible and equipando:
		cuerpo_mesh.scale = Vector3.ONE * 0.72
		_tween_interaccion = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween_interaccion.tween_property(cuerpo_mesh, "scale", Vector3.ONE, 0.28)
		_emitir_chispa_interaccion()
	else:
		_tween_interaccion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_tween_interaccion.tween_property(cuerpo_mesh, "rotation:z", cuerpo_mesh.rotation.z + deg_to_rad(20.0), 0.12)
		_tween_interaccion.parallel().tween_property(cuerpo_mesh, "scale", escala_objetivo, 0.16)
		_tween_interaccion.tween_callback(func() -> void:
			cuerpo_mesh.rotation.z = 0.0
		)

func _emitir_chispa_interaccion() -> void:
	var particulas := CPUParticles3D.new()
	particulas.one_shot = true
	particulas.amount = 10
	particulas.lifetime = 0.35
	particulas.explosiveness = 1.0
	particulas.direction = Vector3(0.0, 0.2, 1.0)
	particulas.spread = 65.0
	particulas.initial_velocity_min = 0.35
	particulas.initial_velocity_max = 0.8
	particulas.gravity = Vector3(0.0, -0.5, 0.0)
	particulas.scale_amount_min = 0.025
	particulas.scale_amount_max = 0.05
	particulas.color = Color(0.35, 0.9, 1.0, 0.9) if tipo == TipoHerramienta.EXTINTOR else Color(1.0, 0.7, 0.22, 0.9)
	var malla := SphereMesh.new()
	malla.radius = 0.5
	malla.height = 1.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = particulas.color
	material.emission_enabled = true
	material.emission = particulas.color
	material.emission_energy_multiplier = 1.4
	malla.material = material
	particulas.mesh = malla
	particulas.position = cuerpo_mesh.position + Vector3(0.0, 0.0, 0.12)
	add_child(particulas)
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.1).timeout.connect(particulas.queue_free)
