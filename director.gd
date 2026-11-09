extends Node

enum Fase { CALMA, PRESION, CRISIS }
@export var golpe = 8.0
@export var limite_presion = 50.0
@export var limite_crisis = 70.0
@export var intervalos: Array[float] = [8.0, 5.0, 3.0]
@export var calor_maximo = 100.0

var estado = Fase.CALMA
var paneles = []
var indice = 0
var reloj = 0.0
var jugador = null

func _ready():
	
	jugador = get_tree().get_first_node_in_group("jugador")
	paneles = get_tree().get_nodes_in_group("paneles")
	reloj = intervalos[estado]

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
	var mejor = null
	var mejor_d = -1.0
	for p in paneles:
		if p.calor >= calor_maximo: 
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
	print("elige ", p.name)
	p.subir(golpe)
