class_name EstacionHerramienta extends StaticBody3D

enum TipoHerramienta { LLAVE_INGLESA, EXTINTOR }

@export var tipo: TipoHerramienta = TipoHerramienta.LLAVE_INGLESA
@export var nombre_item: String = "Llave Inglesa"
@export var icono: String = "🔧"

var cargada: bool = true
var cuerpo_mesh: MeshInstance3D
var etiqueta: Label3D

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
	
	if tipo == TipoHerramienta.LLAVE_INGLESA:
		if item_actual == 1: # Ya tiene la llave
			interactuador.set("herramienta_equipada", 0) # Desequipar
			cuerpo_mesh.visible = true
			print(">>> [HERRAMIENTAS] Llave Inglesa guardada en el soporte. <<<")
		else:
			interactuador.set("herramienta_equipada", 1) # Equipar Llave
			cuerpo_mesh.visible = false
			print(">>> [HERRAMIENTAS] Llave Inglesa equipada. Presiona [Q / Clic] para golpear. <<<")
	elif tipo == TipoHerramienta.EXTINTOR:
		if item_actual == 2: # Ya tiene el extintor
			interactuador.set("herramienta_equipada", 0) # Desequipar
			cuerpo_mesh.visible = true
			print(">>> [HERRAMIENTAS] Extintor colocado en su soporte. <<<")
		else:
			interactuador.set("herramienta_equipada", 2) # Equipar Extintor
			cuerpo_mesh.visible = false
			print(">>> [HERRAMIENTAS] Extintor de CO₂ equipado. Presiona [ESPACIO / Q] para ráfaga criogénica. <<<")
