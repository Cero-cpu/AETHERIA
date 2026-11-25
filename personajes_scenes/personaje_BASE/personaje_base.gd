class_name PersonajeBase
extends CharacterBody2D

# ==========================================================
# PARÁMETROS CONFIGURABLES DE FÍSICA Y MOVIMIENTO
# ==========================================================
@export_category("Movimiento Horizontal")
@export var max_speed: float = 240.0
@export var time_to_max_speed: float = 0.06
@export var time_to_stop: float = 0.04
@export var air_control_multiplier: float = 0.9

@export_category("Salto y Caída")
@export var jump_height: float = 110.0
@export var jump_time_to_peak: float = 0.30
@export var jump_time_to_descent: float = 0.24
@export var max_fall_speed: float = 900.0

@export_category("Mecánicas Avanzadas (Game Feel)")
@export var max_jumps: int = 2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var variable_jump_multiplier: float = 0.5

@export_category("Habilidades y Dash Base")
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.18

# ==========================================================
# SISTEMA DE SONIDOS Y AUDIO DEL PERSONAJE
# ==========================================================
@export_category("Sistema de Sonidos")
@export var sonido_salto: AudioStream
@export var sonido_ataque: AudioStream
@export var sonido_habilidad: AudioStream
@export var sonido_definitiva: AudioStream
@export var sonido_recibir_dano: AudioStream
@export var sonido_morir: AudioStream
@export var sonido_taunt: AudioStream

@export_group("Configuración de Audio")
@export var audio_bus: String = "Master"
@export var volumen_sonidos_db: float = 0.0
@export var variar_pitch: bool = true
@export var pitch_min: float = 0.95
@export var pitch_max: float = 1.05

@export_group("Comportamiento Taunt (Idle Prolongado)")
@export var tiempo_para_taunt: float = 6.0
@export var anim_taunt: String = "taunt"
@export var anim_taunt_fallbacks: Array[String] = ["idle_taunt", "burla"]

@export_category("Estadísticas de Vida y Combate")
@export var vida_maxima: float = 100.0

# ==========================================================
# VARIABLES INTERNAS DE FÍSICA Y ESTADO
# ==========================================================
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var jumps_left: int = 0
var facing_direction: float = 1.0

# Banderas de estado (compatibilidad y consulta externa)
var is_attacking: bool = false
var is_dashing: bool = false
var is_using_skill: bool = false
var is_hit: bool = false
var is_dead: bool = false
var is_taunting: bool = false
var tiempo_inactividad: float = 0.0
var taunt_ejecutado: bool = false
var action_timer: float = 0.0
var vida_actual: float = 100.0

# Registro modular de componentes y sistema de sonidos
var componentes_mecanicas: Array[MecanicaBase] = []
var sistema_sonidos: Node2D = null

# Señales de eventos del personaje
signal sonido_reproducido(tipo: String, stream: AudioStream)
signal taunt_iniciado()
signal taunt_finalizado()
signal vida_cambiada(nueva_vida: float, vida_max: float)
signal dano_recibido(cantidad: float, vida_restante: float)
signal personaje_murio()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("jugador")
	# El jugador existe en Capa 2 y solo choca físicamente con Capa 1 (Mundo/Escenario)
	# Esto permite atravesar enemigos suavemente sin empujarlos
	collision_layer = 2
	collision_mask = 1

	vida_actual = vida_maxima
	calculate_physics_parameters()
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_action_anim_completed)
		animated_sprite.animation_looped.connect(_on_action_anim_completed)
	
	_inicializar_sistema_sonidos()
	_inicializar_componentes_mecanicas()

## Registra nodos componentes existentes o crea los componentes base por defecto si no hay ninguno
func _inicializar_componentes_mecanicas() -> void:
	componentes_mecanicas.clear()
	
	# 1. Buscar nodo contenedor "Componentes" o nodos MecanicaBase hijos
	var contenedor_comp = get_node_or_null("Componentes")
	var nodos_a_revisar = contenedor_comp.get_children() if contenedor_comp else get_children()
	
	for child in nodos_a_revisar:
		if child is MecanicaBase:
			componentes_mecanicas.append(child)
	
	# 2. Si no se especificaron componentes en la escena, registrar mecánicas base automáticas
	if componentes_mecanicas.is_empty():
		_crear_componentes_por_defecto()

# Precarga de clases de componentes para evitar errores de asignación dinámica
const SistemaSonidosScript = preload("res://personajes_scenes/personaje_BASE/componentes/sistema_sonidos_personaje.gd")
const MecanicaDashScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_dash.gd")
const MecanicaAtaqueScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_ataque.gd")
const MecanicaHabilidadScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_habilidad.gd")

func _inicializar_sistema_sonidos() -> void:
	sistema_sonidos = get_node_or_null("SistemaSonidos")
	if not sistema_sonidos:
		sistema_sonidos = SistemaSonidosScript.new()
		sistema_sonidos.name = "SistemaSonidos"
		add_child(sistema_sonidos)
	sistema_sonidos.configurar(audio_bus, volumen_sonidos_db, variar_pitch, pitch_min, pitch_max)

func _crear_componentes_por_defecto() -> void:
	# Contenedor para mantener limpia la jerarquía de la escena
	var contenedor = Node.new()
	contenedor.name = "Componentes"
	add_child(contenedor)
	
	# Dash
	var comp_dash = MecanicaDashScript.new()
	comp_dash.name = "MecanicaDash"
	comp_dash.action_name = "dash"
	comp_dash.dash_speed = dash_speed
	comp_dash.dash_duration = dash_duration
	contenedor.add_child(comp_dash)
	componentes_mecanicas.append(comp_dash)
	
	# Ataque Básico
	var comp_ataque = MecanicaAtaqueScript.new()
	comp_ataque.name = "MecanicaAtaque"
	comp_ataque.action_name = "ataque_basico"
	comp_ataque.anim_name = "ataquebasico1"
	contenedor.add_child(comp_ataque)
	componentes_mecanicas.append(comp_ataque)
	
	# Habilidad 1
	var comp_habilidad_1 = MecanicaHabilidadScript.new()
	comp_habilidad_1.name = "MecanicaHabilidad1"
	comp_habilidad_1.action_name = "habilidad_1"
	comp_habilidad_1.anim_name = "habilidad1"
	contenedor.add_child(comp_habilidad_1)
	componentes_mecanicas.append(comp_habilidad_1)
	
	# Definitiva / Habilidad 2
	var comp_ult = MecanicaHabilidadScript.new()
	comp_ult.name = "MecanicaDefinitiva"
	comp_ult.action_name = "habilidad_definitiva"
	comp_ult.anim_name = "definitiva"
	comp_ult.anim_fallbacks = ["habilidad_definitiva", "ult", "habilidad2"]
	contenedor.add_child(comp_ult)
	componentes_mecanicas.append(comp_ult)

func calculate_physics_parameters() -> void:
	jump_velocity = -((2.0 * jump_height) / jump_time_to_peak)
	jump_gravity = (2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)
	fall_gravity = (2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)

func is_action_just_pressed_safe(action: String) -> bool:
	if action.is_empty() or not InputMap.has_action(action):
		return false
	return Input.is_action_just_pressed(action)

func is_action_just_released_safe(action: String) -> bool:
	if action.is_empty() or not InputMap.has_action(action):
		return false
	return Input.is_action_just_released(action)

## Consulta si el personaje está ocupado ejecutando alguna acción o recibiendo un golpe
func is_action_busy() -> bool:
	if is_dead or is_attacking or is_dashing or is_using_skill or is_hit:
		return true
	for comp in componentes_mecanicas:
		if comp.esta_activa():
			return true
	return false

func _physics_process(delta: float) -> void:
	# Si el personaje ha muerto, solo aplica gravedad y fricción residual
	if is_dead:
		if not is_on_floor():
			velocity.y += fall_gravity * delta
			velocity.y = minf(velocity.y, max_fall_speed)
		velocity.x = move_toward(velocity.x, 0.0, get_deceleration() * delta)
		move_and_slide()
		return

	var dialogue_mgr = get_node_or_null("/root/DialogueManager")
	if dialogue_mgr and dialogue_mgr.get("is_active") == true:
		if is_taunting:
			cancelar_taunt()
		velocity.x = move_toward(velocity.x, 0.0, get_deceleration() * delta)
		play_anim_if_exists("idle")
		move_and_slide()
		return

	# --- 0. RESPUESTA Y CANCELACIÓN ÁGIL DEL TAUNT ANTE CUALQUIER ACCIÓN ---
	var direction := Input.get_axis("ui_left", "ui_right")
	if is_taunting:
		var input_salto = is_action_just_pressed_safe("salto") or is_action_just_pressed_safe("ui_accept")
		var input_ataque = is_action_just_pressed_safe("ataque_basico")
		var input_dash = is_action_just_pressed_safe("dash")
		var input_skill = is_action_just_pressed_safe("habilidad_1") or is_action_just_pressed_safe("definitiva") or is_action_just_pressed_safe("habilidad_2")
		if not is_zero_approx(direction) or input_salto or input_ataque or input_dash or input_skill:
			cancelar_taunt()

	# --- 1. PROCESAR COMPONENTES DE MECÁNICAS ACTIVAS ---
	for comp in componentes_mecanicas:
		comp.procesar_mecanica(delta)

	# --- 2. MANEJO DE MOVIMIENTO EXCLUSIVO DE DASH EN CURSO ---
	if is_dashing:
		move_and_slide()
		return

	# --- 3. DETECCIÓN DE ENTRADA Y ACTIVACIÓN DE MECÁNICAS ---
	for comp in componentes_mecanicas:
		if not comp.action_name.is_empty() and is_action_just_pressed_safe(comp.action_name):
			if is_taunting:
				cancelar_taunt()
			comp.ejecutar_mecanica()
	
	# Verificación de fallback para acción alternativa de definitiva ("definitiva" / "habilidad_2")
	if not is_action_busy():
		if is_action_just_pressed_safe("definitiva") or is_action_just_pressed_safe("habilidad_2"):
			if is_taunting:
				cancelar_taunt()
			start_ultimate()

	# --- 4. ESTADO EN EL SUELO Y COYOTE TIME ---
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer -= delta
		if coyote_timer <= 0.0 and jumps_left == max_jumps:
			jumps_left = max_jumps - 1

	# --- 5. JUMP BUFFER ---
	if is_action_just_pressed_safe("salto") or is_action_just_pressed_safe("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	# --- 6. GRAVEDAD ---
	if not is_on_floor():
		var current_gravity = jump_gravity if velocity.y < 0.0 else fall_gravity
		velocity.y += current_gravity * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	# --- 7. SALTO ---
	if jump_buffer_timer > 0.0:
		if coyote_timer > 0.0:
			perform_jump()
			coyote_timer = 0.0
		elif jumps_left > 0:
			perform_jump()

	# --- 8. SALTO VARIABLE ---
	if (is_action_just_released_safe("salto") or is_action_just_released_safe("ui_accept")) and velocity.y < 0.0:
		velocity.y *= variable_jump_multiplier

	# --- 9. MOVIMIENTO HORIZONTAL ---
	var accel = get_acceleration()
	var decel = get_deceleration()

	var movement_blocked := false
	for comp in componentes_mecanicas:
		if comp.esta_activa() and comp.bloquea_movimiento():
			movement_blocked = true
			break

	# Permitir orientar la mirada / sprite aunque el movimiento de posición esté bloqueado
	if direction != 0.0:
		facing_direction = sign(direction)
		if animated_sprite:
			animated_sprite.flip_h = (direction < 0.0)

	if movement_blocked:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	elif direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# --- 10. DETECCIÓN Y PROCESAMIENTO DE INACTIVIDAD / TAUNT ---
	_procesar_inactividad_taunt(delta, direction)

	# --- 11. ACTUALIZACIÓN DE ANIMACIONES Y MOVIMIENTO ---
	update_animations(direction)
	move_and_slide()

# --- MÉTODOS FAÇADE / COMPATIBILIDAD DIRECCIÓN DE HABILIDADES ---

func start_dash() -> void:
	if is_taunting:
		cancelar_taunt()
	var comp = _buscar_componente_por_tipo(MecanicaDash)
	if comp:
		comp.ejecutar_mecanica()

func start_attack() -> void:
	if is_taunting:
		cancelar_taunt()
	var comp = _buscar_componente_por_tipo(MecanicaAtaque)
	if comp:
		comp.ejecutar_mecanica()

func start_skill_1() -> void:
	if is_taunting:
		cancelar_taunt()
	for comp in componentes_mecanicas:
		if comp is MecanicaHabilidad and comp.action_name == "habilidad_1":
			comp.ejecutar_mecanica()
			return

func start_ultimate() -> void:
	if is_taunting:
		cancelar_taunt()
	for comp in componentes_mecanicas:
		if comp is MecanicaHabilidad and (comp.action_name == "habilidad_definitiva" or comp.name == "MecanicaDefinitiva"):
			comp.ejecutar_mecanica()
			return

# ==========================================================
# MÉTODOS DEL SISTEMA DE SONIDOS
# ==========================================================

func reproducir_sonido(stream: AudioStream, con_pitch_random: bool = true, offset_db: float = 0.0) -> AudioStreamPlayer2D:
	if not is_instance_valid(sistema_sonidos):
		_inicializar_sistema_sonidos()
	if not sistema_sonidos or not stream:
		return null
	return sistema_sonidos.reproducir(stream, con_pitch_random, offset_db)

func reproducir_sonido_salto() -> void:
	if sonido_salto:
		reproducir_sonido(sonido_salto, true)
		sonido_reproducido.emit("salto", sonido_salto)

func reproducir_sonido_ataque() -> void:
	if sonido_ataque:
		reproducir_sonido(sonido_ataque, true)
		sonido_reproducido.emit("ataque", sonido_ataque)

func reproducir_sonido_habilidad() -> void:
	if sonido_habilidad:
		reproducir_sonido(sonido_habilidad, false)
		sonido_reproducido.emit("habilidad", sonido_habilidad)

func reproducir_sonido_definitiva() -> void:
	if sonido_definitiva:
		reproducir_sonido(sonido_definitiva, false)
		sonido_reproducido.emit("definitiva", sonido_definitiva)

func reproducir_sonido_recibir_dano() -> void:
	if sonido_recibir_dano:
		reproducir_sonido(sonido_recibir_dano, true)
		sonido_reproducido.emit("recibir_dano", sonido_recibir_dano)

func reproducir_sonido_morir() -> void:
	if sonido_morir:
		reproducir_sonido(sonido_morir, false)
		sonido_reproducido.emit("morir", sonido_morir)

func reproducir_sonido_taunt() -> void:
	if sonido_taunt:
		reproducir_sonido(sonido_taunt, false)
		sonido_reproducido.emit("taunt", sonido_taunt)

# ==========================================================
# LÓGICA DE TAUNT (IDLE PROLONGADO)
# ==========================================================

func _procesar_inactividad_taunt(delta: float, input_direccion: float) -> void:
	if is_dead or is_action_busy():
		tiempo_inactividad = 0.0
		return
		
	var esta_en_idle = is_on_floor() and is_zero_approx(input_direccion) and abs(velocity.x) < 5.0
	
	if esta_en_idle:
		tiempo_inactividad += delta
		if tiempo_inactividad >= tiempo_para_taunt and not taunt_ejecutado and not is_taunting:
			ejecutar_taunt()
	else:
		tiempo_inactividad = 0.0
		taunt_ejecutado = false
		if is_taunting:
			cancelar_taunt()

func ejecutar_taunt() -> void:
	if is_action_busy() or is_dead or not is_on_floor():
		return
		
	is_taunting = true
	taunt_ejecutado = true
	reproducir_sonido_taunt()
	taunt_iniciado.emit()
	
	var anim_reproducida = false
	if animated_sprite and animated_sprite.sprite_frames:
		var frames = animated_sprite.sprite_frames
		if frames.has_animation(anim_taunt):
			play_action_anim(anim_taunt)
			anim_reproducida = true
		else:
			for fallback in anim_taunt_fallbacks:
				if frames.has_animation(fallback):
					play_action_anim(fallback)
					anim_reproducida = true
					break
	
	# Si no existe animación visual de taunt, mantener el estado durante 1.5s
	if not anim_reproducida:
		var tree = get_tree()
		if tree:
			tree.create_timer(1.5).timeout.connect(func():
				if is_taunting:
					_finalizar_taunt()
			)

func cancelar_taunt() -> void:
	if not is_taunting:
		return
	is_taunting = false
	tiempo_inactividad = 0.0
	taunt_finalizado.emit()
	if is_on_floor() and not is_action_busy() and not is_dead:
		play_anim_if_exists("idle")

func _finalizar_taunt() -> void:
	if not is_taunting:
		return
	is_taunting = false
	taunt_finalizado.emit()
	if is_on_floor() and not is_action_busy() and not is_dead:
		play_anim_if_exists("idle")

# ==========================================================
# SISTEMA DE VIDA, DAÑO Y MUERTE
# ==========================================================

## Aplica daño numérico, reproduce sonido de golpe o muerte según la vida restante
func recibir_dano(cantidad: float) -> void:
	if is_dead:
		return
	vida_actual = maxf(0.0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)
	dano_recibido.emit(cantidad, vida_actual)
	if vida_actual <= 0.0:
		morir()
	else:
		recibir_hit(cantidad)

## Restaura vida respetando la vida máxima
func curar(cantidad: float) -> void:
	if is_dead:
		return
	vida_actual = minf(vida_maxima, vida_actual + cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)

## Método para activar la animación 'hit' cuando el personaje sea golpeado
func recibir_hit(_danio: float = 0.0) -> void:
	if is_dead:
		return
	if is_taunting:
		cancelar_taunt()
	tiempo_inactividad = 0.0
	taunt_ejecutado = false

	is_hit = true
	is_attacking = false
	is_dashing = false
	is_using_skill = false
	reproducir_sonido_recibir_dano()
	play_action_anim("hit")

## Provoca la muerte del personaje, reproduciendo su sonido y bloqueando inputs
func morir() -> void:
	if is_dead:
		return
	is_dead = true
	is_attacking = false
	is_dashing = false
	is_using_skill = false
	is_hit = false
	is_taunting = false
	velocity.x = 0.0
	
	reproducir_sonido_morir()
	personaje_murio.emit()
	
	if not play_anim_if_exists("dead"):
		if not play_anim_if_exists("muerte"):
			if not play_anim_if_exists("morir"):
				play_anim_if_exists("hit")

func _buscar_componente_por_tipo(tipo: Variant) -> MecanicaBase:
	for comp in componentes_mecanicas:
		if is_instance_of(comp, tipo):
			return comp
	return null

func perform_jump() -> void:
	if is_taunting:
		cancelar_taunt()
	tiempo_inactividad = 0.0
	taunt_ejecutado = false

	velocity.y = jump_velocity
	var is_double_jump := (jumps_left < max_jumps - 1)
	jumps_left -= 1
	jump_buffer_timer = 0.0
	
	reproducir_sonido_salto()
	
	if is_double_jump:
		if not play_anim_if_exists("dublejump"):
			if not play_anim_if_exists("doublejump"):
				play_anim_if_exists("jump")
	else:
		play_anim_if_exists("jump")
		
	if animated_sprite and animated_sprite.animation in ["jump", "dublejump", "doublejump"]:
		animated_sprite.set_frame_and_progress(0, 0.0)

func _on_action_anim_completed() -> void:
	if not animated_sprite:
		return
	var current_anim = animated_sprite.animation
	
	if current_anim == anim_taunt or current_anim in anim_taunt_fallbacks:
		_finalizar_taunt()
		return
		
	if current_anim in ["ataquebasico", "ataquebasico1", "ataquebasico2", "habilidad1", "habilidad2", "definitiva", "ult", "habilidad_definitiva", "dash", "hit"] or current_anim.begins_with("ataquebasico"):
		is_attacking = false
		is_using_skill = false
		is_dashing = false
		is_hit = false
		for comp in componentes_mecanicas:
			if comp.has_method("finalizar_dash") and comp.esta_activa():
				comp.call("finalizar_dash")
			elif comp.has_method("finalizar_ataque") and comp.esta_activa():
				comp.call("finalizar_ataque")
			elif comp.has_method("finalizar_habilidad") and comp.esta_activa():
				comp.call("finalizar_habilidad")

# --- FUNCIONES AUXILIARES DE ANIMACIÓN Y FÍSICA ---

func play_action_anim(anim_name: String) -> float:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0.3
		
	var target_anim = anim_name
	if not animated_sprite.sprite_frames.has_animation(target_anim):
		match target_anim:
			"ataquebasico1", "ataquebasico2":
				if animated_sprite.sprite_frames.has_animation("ataquebasico"):
					target_anim = "ataquebasico"
			"fall":
				if animated_sprite.sprite_frames.has_animation("jump"):
					target_anim = "jump"
			"walk":
				if animated_sprite.sprite_frames.has_animation("run"):
					target_anim = "run"
			"habilidad1":
				if animated_sprite.sprite_frames.has_animation("definitiva"):
					target_anim = "definitiva"
			"hit":
				if animated_sprite.sprite_frames.has_animation("idle"):
					target_anim = "idle"
					
		if not animated_sprite.sprite_frames.has_animation(target_anim):
			return 0.3
	
	var frame_count := animated_sprite.sprite_frames.get_frame_count(target_anim)
	if frame_count <= 0:
		return 0.3
		
	var speed := animated_sprite.sprite_frames.get_animation_speed(target_anim)
	if speed <= 0.0:
		speed = 10.0
		
	animated_sprite.play(target_anim)
	animated_sprite.set_frame_and_progress(0, 0.0)
	return float(frame_count) / speed

func get_acceleration() -> float:
	var accel = max_speed / maxf(time_to_max_speed, 0.001)
	return accel if is_on_floor() else accel * air_control_multiplier

func get_deceleration() -> float:
	var decel = max_speed / maxf(time_to_stop, 0.001)
	return decel if is_on_floor() else decel * air_control_multiplier

func update_animations(direction: float) -> void:
	if is_action_busy() or is_taunting or is_dead:
		return
		
	if not is_on_floor():
		if velocity.y < 0.0:
			if animated_sprite and not (animated_sprite.animation in ["jump", "dublejump", "doublejump"]):
				if not play_anim_if_exists("jump"):
					play_anim_if_exists("dublejump")
		else:
			if not play_anim_if_exists("fall"):
				if not play_anim_if_exists("jump"):
					play_anim_if_exists("dublejump")
	else:
		if direction != 0.0:
			if not play_anim_if_exists("walk"):
				play_anim_if_exists("run")
		else:
			play_anim_if_exists("idle")

func play_anim_if_exists(anim_name: String) -> bool:
	if not animated_sprite:
		return false
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
		return true
	return false
