class_name GameManager extends Node

enum EstadoPartida { JUGANDO, VICTORIA, DERROTA }

const DURACION_PARTIDA: float = 300.0 # Duracion del turno en segundos (5 minutos)
const INTEGRIDAD_INICIAL: float = 100.0
const VIDA_INICIAL: float = 100.0
const PENALIZACION_APAGADO: float = 15.0 # Reduccion de integridad por cada colapso (15% balanceado)

signal segundo_actualizado(tiempo_restante: float)
signal minuto_cambiado(nuevo_minuto: int, nueva_tasa: float)
signal integridad_cambiada(nueva_integridad: float)
signal vida_cambiada(nueva_vida: float)
signal partida_terminada(victoria: bool, motivo: String, puntaje: int)
signal amenaza_inminente(segundos: float)
signal sanguijuela_aparecida(nombre_panel: String)

@export var luz_principal: Light3D
@export var luz_emergencia: Light3D
@export var etiqueta_reloj: Label3D

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
var _aviso_parasito_emitido: bool = false

# Variables para la solicitud de auxilio por radio
var ayuda_usada: bool = false
var tiempo_espera_ayuda: float = -1.0
var tiempo_siguiente_parasito: float = 45.0 # Primera aparicion al segundo 45

func _ready() -> void:
	add_to_group("game_manager")
	
	# Recopilar todos los paneles de la sala
	paneles = get_tree().get_nodes_in_group("paneles")
	for p in paneles:
		if p.has_signal("panel_apagado"):
			p.panel_apagado.connect(_on_panel_apagado)
		if p.has_signal("panel_reiniciado"):
			p.panel_reiniciado.connect(_on_panel_reiniciado)
		if "tasa_generacion" in p:
			p.tasa_generacion = 0.7
	
	# Inicializar iluminacion
	if luz_principal:
		luz_principal.visible = true
	if luz_emergencia:
		luz_emergencia.visible = false
	
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
		
		# Registro periodico en consola
		if seg_entero % 10 == 0:
			var m = seg_entero / 60
			var s = seg_entero % 60
			print("[TURNO %02d:%02d] Tasa: %.1f°/s | Integridad: %.0f%% | Vida: %.0f" % [m, s, tasa_base_calor, integridad, vida])
	
	# Actualizar el reloj diegetico de pared
	if etiqueta_reloj != null:
		var min_reloj = int(tiempo_restante) / 60
		var seg_reloj = int(tiempo_restante) % 60
		etiqueta_reloj.text = "%02d:%02d" % [min_reloj, seg_reloj]
		
		# Parpadeo en color rojo en los ultimos 30 segundos
		if tiempo_restante <= 30.0 and tiempo_restante > 0.0:
			var parpadeo = int(tiempo_restante * 4.0) % 2 == 0
			etiqueta_reloj.modulate = Color(0.95, 0.2, 0.2) if parpadeo else Color(0.2, 0.05, 0.05)
		else:
			etiqueta_reloj.modulate = Color(0.9, 0.95, 1.0)
	
	# Escalada progresiva de calor por cada minuto completado
	var tiempo_transcurrido = DURACION_PARTIDA - tiempo_restante
	var min_transcurrido = int(tiempo_transcurrido / 60.0)
	if min_transcurrido != minuto_actual and min_transcurrido < 5:
		minuto_actual = min_transcurrido
		# Progresión balanceada: Min 0: 0.30, Min 1: 0.45, Min 2: 0.65, Min 3: 0.90, Min 4: 1.20
		var tasas_minuto = [0.30, 0.45, 0.65, 0.90, 1.20]
		tasa_base_calor = tasas_minuto[clampi(minuto_actual, 0, 4)]
		for p in paneles:
			if "tasa_generacion" in p:
				p.tasa_generacion = tasa_base_calor
		minuto_cambiado.emit(minuto_actual, tasa_base_calor)
		print(">>> ALERTA DE CARGA: Minuto %d. La tasa de calor sube a %.2f°/s <<<" % [minuto_actual, tasa_base_calor])
	
	# Efecto de Soporte Vital: asfixia si cae, o recuperación paulatina si está sano
	if _panel_esta_apagado("SoporteVital"):
		aplicar_danio_vida(1.0 * delta)
		if Engine.get_physics_frames() % 120 == 0:
			print("[PELIGRO] Soporte Vital caido. Asfixia: Vida restante: %.0f" % vida)
	else:
		if vida < VIDA_INICIAL:
			vida = minf(VIDA_INICIAL, vida + 0.6 * delta)
			vida_cambiada.emit(vida)
	
	# Conteo regresivo para el soplado de auxilio
	if tiempo_espera_ayuda > 0.0:
		tiempo_espera_ayuda -= delta
		if tiempo_espera_ayuda <= 0.0:
			tiempo_espera_ayuda = -1.0
			_ejecutar_soplado_ayuda()
	
	# Generacion dinamica de parasitos termicos
	tiempo_siguiente_parasito -= delta
	if tiempo_siguiente_parasito <= 10.0:
		if not _aviso_parasito_emitido:
			_aviso_parasito_emitido = true
		amenaza_inminente.emit(maxf(tiempo_siguiente_parasito, 0.0))
	if tiempo_siguiente_parasito <= 0.0:
		tiempo_siguiente_parasito = randf_range(45.0, 60.0)
		_aviso_parasito_emitido = false
		_aparecer_parasito()
	
	# Condicion de victoria al sobrevivir el tiempo completo
	if tiempo_restante <= 0.0:
		tiempo_restante = 0.0
		_finalizar_partida(true, "Reinicio completado")

func _on_panel_apagado(panel: Node) -> void:
	integridad -= PENALIZACION_APAGADO
	integridad = maxf(integridad, 0.0)
	integridad_cambiada.emit(integridad)
	print(">>> ¡FALLO DE SISTEMA! %s colapso. Integridad restante: %.0f%% <<<" % [panel.name, integridad])
	
	# Efecto de perdida de energia en la sala
	if panel.name == "Energia":
		if luz_principal:
			luz_principal.visible = false
		if luz_emergencia:
			luz_emergencia.visible = true
		print(">>> [ALERTA] ENERGÍA CAÍDA: Se apaga el alumbrado de la sala. Luz roja de emergencia activada. <<<")
	
	# Efecto de fallo en refrigeracion: aceleracion termica general
	elif panel.name == "Refrigeracion":
		for p in paneles:
			if "tasa_extra" in p:
				p.tasa_extra = 0.35
		print(">>> [ALERTA] REFRIGERACIÓN CAÍDA: Sobretasa térmica de +0.35°C/s <<<")
	
	# Efecto de fallo en comunicaciones: perdida de telemetria
	elif panel.name == "Comunicaciones":
		for p in paneles:
			if p != panel and "sin_senal" in p:
				p.sin_senal = true
				p.actualizar_interfaz_diegética()
		print(">>> [ALERTA] COMUNICACIONES CAÍDAS: Diales sin señal y solicitud de ayuda bloqueada. <<<")
	
	# Derrota por colapso estructural
	if integridad <= 0.0:
		_finalizar_partida(false, "Sala colapsada")

func _on_panel_reiniciado(panel: Node) -> void:
	print(">>> [SISTEMA] %s ha sido reactivado <<<" % panel.name)
	
	# Restauracion de iluminacion principal
	if panel.name == "Energia":
		if luz_principal:
			luz_principal.visible = true
		if luz_emergencia:
			luz_emergencia.visible = false
		print(">>> [SISTEMA] ENERGÍA RESTAURADA: Alumbrado principal encendido. <<<")
	
	# Restauracion de refrigeracion
	elif panel.name == "Refrigeracion":
		for p in paneles:
			if "tasa_extra" in p:
				p.tasa_extra = 0.0
		print(">>> [SISTEMA] REFRIGERACIÓN RESTAURADA: Se elimina la sobretasa de calor extra. <<<")
	
	# Restauracion de comunicaciones y telemetria
	elif panel.name == "Comunicaciones":
		for p in paneles:
			if "sin_senal" in p:
				p.sin_senal = false
				p.actualizar_interfaz_diegética()
		print(">>> [SISTEMA] COMUNICACIONES RESTAURADAS: Señal en diales recuperada. <<<")

func solicitar_ayuda() -> bool:
	if estado_partida != EstadoPartida.JUGANDO:
		return false
	
	if ayuda_usada:
		print("[RADIO] Solicitud rechazada: La ayuda de emergencia ya fue utilizada en este turno.")
		return false
	
	if _panel_esta_apagado("Comunicaciones"):
		print("[RADIO] Solicitud fallida: Comunicaciones fuera de línea. No hay señal para pedir auxilio.")
		return false
	
	ayuda_usada = true
	tiempo_espera_ayuda = 5.0
	print(">>> [RADIO] ¡Auxilio solicitado! Soplado de emergencia programado en 5 segundos... <<<")
	return true

func _ejecutar_soplado_ayuda() -> void:
	# Enfriamiento simultaneo de todos los paneles activos
	for p in paneles:
		if "apagado" in p and not p.apagado:
			p.calor = maxf(0.0, p.calor - 25.0)
			p.actualizar_interfaz_diegética()
	print(">>> [RADIO] ¡SOPLADO DE EMERGENCIA RECIBIDO! Todos los paneles encendidos bajan 25°C de calor. <<<")

func aplicar_danio_vida(cantidad: float) -> void:
	if estado_partida != EstadoPartida.JUGANDO:
		return
	vida -= cantidad
	vida = maxf(vida, 0.0)
	vida_cambiada.emit(vida)
	if vida <= 0.0:
		_finalizar_partida(false, "Aire agotado")

func _panel_esta_apagado(nombre_panel: String) -> bool:
	for p in paneles:
		if p.name == nombre_panel:
			return p.get("apagado") == true
	return false

func _aparecer_parasito() -> void:
	var mejor_panel: Node = null
	var mayor_calor: float = -1.0
	for p in paneles:
		if p.get("apagado") == true or p.get("tiene_sanguijuela") == true:
			continue
		var c = p.get("calor") if "calor" in p else 0.0
		if c > mayor_calor:
			mayor_calor = c
			mejor_panel = p
	if mejor_panel != null and mejor_panel.has_method("adherir_sanguijuela"):
		mejor_panel.adherir_sanguijuela()
		var nombre_panel = mejor_panel.get("nombre_sistema") if "nombre_sistema" in mejor_panel else mejor_panel.name
		sanguijuela_aparecida.emit(str(nombre_panel))

func _finalizar_partida(victoria: bool, motivo: String) -> void:
	estado_partida = EstadoPartida.VICTORIA if victoria else EstadoPartida.DERROTA
	motivo_fin = motivo
	
	var paneles_activos = 0
	for p in paneles:
		if "apagado" in p and not p.apagado:
			paneles_activos += 1
	
	# Calculo del puntaje final ponderado
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
