class_name GameManager extends Node

enum EstadoPartida { JUGANDO, VICTORIA, DERROTA }

const DURACION_PARTIDA: float = 300.0 # 5 minutos (M14)
const INTEGRIDAD_INICIAL: float = 100.0 # M13
const VIDA_INICIAL: float = 100.0 # M12
const PENALIZACION_APAGADO: float = 20.0 # M5: 20% por apagado

signal segundo_actualizado(tiempo_restante: float)
signal minuto_cambiado(nuevo_minuto: int, nueva_tasa: float)
signal integridad_cambiada(nueva_integridad: float)
signal vida_cambiada(nueva_vida: float)
signal partida_terminada(victoria: bool, motivo: String, puntaje: int)

var estado_partida: EstadoPartida = EstadoPartida.JUGANDO
var tiempo_restante: float = DURACION_PARTIDA
var vida: float = VIDA_INICIAL
var integridad: float = INTEGRIDAD_INICIAL
var minuto_actual: int = 0
var tasa_base_calor: float = 1.0
var paneles: Array[Node] = []
var motivo_fin: String = ""
var puntaje_final: int = 0
var segundo_anterior: int = -1

func _ready() -> void:
	# Recopilar todos los paneles de la sala
	paneles = get_tree().get_nodes_in_group("paneles")
	for p in paneles:
		if p.has_signal("panel_apagado"):
			p.panel_apagado.connect(_on_panel_apagado)
		if "tasa_generacion" in p:
			p.tasa_generacion = 1.0
	
	print("========================================")
	print("  ÚLTIMO TURNO - INICIO DE PARTIDA (5:00)")
	print("  Paneles activos: ", paneles.size())
	print("  Integridad: 100% | Vida: 100")
	print("========================================")

func _physics_process(delta: float) -> void:
	if estado_partida != EstadoPartida.JUGANDO:
		if Input.is_action_just_pressed("reintentar"):
			print("Reiniciando turno...")
			get_tree().reload_current_scene()
		return
	
	tiempo_restante -= delta
	
	# Notificar y reportar cada segundo transcurrido
	var seg_entero = int(tiempo_restante)
	if seg_entero != segundo_anterior:
		segundo_anterior = seg_entero
		segundo_actualizado.emit(tiempo_restante)
		# Registro en consola cada 10 segundos
		if seg_entero % 10 == 0:
			var m = seg_entero / 60
			var s = seg_entero % 60
			print("[TURNO %02d:%02d] Tasa: %.1f°/s | Integridad: %.0f%% | Vida: %.0f" % [m, s, tasa_base_calor, integridad, vida])
	
	# M2: Escalada de calor por cada minuto completado (1.0 / 1.2 / 1.4 / 1.6 / 1.8)
	var tiempo_transcurrido = DURACION_PARTIDA - tiempo_restante
	var min_transcurrido = int(tiempo_transcurrido / 60.0)
	if min_transcurrido != minuto_actual and min_transcurrido < 5:
		minuto_actual = min_transcurrido
		tasa_base_calor = 1.0 + (minuto_actual * 0.2)
		for p in paneles:
			if "tasa_generacion" in p:
				p.tasa_generacion = tasa_base_calor
		minuto_cambiado.emit(minuto_actual, tasa_base_calor)
		print(">>> ALERTA DE CARGA: Minuto %d. La tasa de calor sube a %.1f°/s <<<" % [minuto_actual, tasa_base_calor])
	
	# M14: Victoria al sobrevivir 300 s con Vida > 0 e Integridad > 0
	if tiempo_restante <= 0.0:
		tiempo_restante = 0.0
		_finalizar_partida(true, "Reinicio completado")

func _on_panel_apagado(panel: Node) -> void:
	integridad -= PENALIZACION_APAGADO
	integridad = maxf(integridad, 0.0)
	integridad_cambiada.emit(integridad)
	print(">>> ¡FALLO DE SISTEMA! %s colapsó. Integridad restante: %.0f%% <<<" % [panel.name, integridad])
	
	# M13 y M15: Derrota por colapso estructural al 5to apagado (Integridad = 0%)
	if integridad <= 0.0:
		_finalizar_partida(false, "Sala colapsada")

func aplicar_danio_vida(cantidad: float) -> void:
	if estado_partida != EstadoPartida.JUGANDO:
		return
	vida -= cantidad
	vida = maxf(vida, 0.0)
	vida_cambiada.emit(vida)
	if vida <= 0.0:
		_finalizar_partida(false, "Aire agotado")

func _finalizar_partida(victoria: bool, motivo: String) -> void:
	estado_partida = EstadoPartida.VICTORIA if victoria else EstadoPartida.DERROTA
	motivo_fin = motivo
	
	var paneles_activos = 0
	for p in paneles:
		if "apagado" in p and not p.apagado:
			paneles_activos += 1
	
	# M16: Integridad × 10 + Vida × 5 + Paneles encendidos × 100 (máximo 1900)
	puntaje_final = int((integridad * 10.0) + (vida * 5.0) + (paneles_activos * 100.0))
	partida_terminada.emit(victoria, motivo, puntaje_final)
	
	print("\n========================================")
	if victoria:
		print("  ¡VICTORIA! - ", motivo)
	else:
		print("  DERROTA - ", motivo)
	print("  Puntaje final: ", puntaje_final, " / 1900")
	print("  (Integridad: %.0f%% x 10 = %.0f) + (Vida: %.0f x 5 = %.0f) + (Paneles: %d x 100 = %d)" % [
		integridad, integridad * 10, vida, vida * 5, paneles_activos, paneles_activos * 100
	])
	print("  Presiona ENTER para reintentar")
	print("========================================\n")
