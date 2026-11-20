extends Node

enum Fase { CALMA, PRESION, CRISIS }
@export var golpe = 8.0
@export var limite_presion = 50.0
@export var limite_crisis = 70.0
@export var intervalos: Array[float] = [8.0, 5.0, 3.0]
@export var calor_maximo = 100.0


@export var semilla = 7
@export var variacion = 5.0
var rng = RandomNumberGenerator.new()
var ultimo = null


var estado = Fase.CALMA
var paneles = []
var indice = 0
var reloj = 0.0
var jugador = null

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		print("ERROR: El Personaje no está en el grupo 'jugador'")
		return
		
	paneles = get_tree().get_nodes_in_group("paneles")
	reloj = intervalos[estado]
	
	
	rng.seed = semilla
	for p in paneles:
		p.calor += rng.randf_range(-variacion, variacion)
		print(p.name, " empieza en ", snappedf(p.calor, 0.1))
	

func _physics_process(delta):
	reloj -= delta
	var nuevo = decidir()
	if nuevo != estado:
		estado = nuevo
		print("fase ", Fase.keys()[estado], " cuadro ", Engine.get_physics_frames())
		
	if reloj <= 0.001:
		reloj = intervalos[estado]
		fallar()

func decidir():
	var mayor = calor_mayor()
	if mayor >= limite_crisis:
		return Fase.CRISIS
	if mayor >= limite_presion:
		return Fase.PRESION
	return Fase.CALMA

func calor_mayor():
	var mayor = 0.0
	for p in paneles:
		mayor = maxf(mayor, p.calor)
	return mayor

func elegir_panel():
	if jugador == null:
		return null
		
	var mejor = null
	var mejor_d = -1.0
	for p in paneles:
		
		if p.calor >= calor_maximo or p == ultimo:
			continue
		
		var d = p.global_position.distance_to(jugador.global_position)
		if d > mejor_d:
			mejor = p
			mejor_d = d
	return mejor

func fallar():
	var p = elegir_panel()
	if p == null:
		print("no queda panel por fallar")
		return
		
	ultimo = p 
	print("elige ", p.name)
	p.subir(golpe)
