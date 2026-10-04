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
var action_timer: float = 0.0

# Registro modular de componentes de mecánicas
var componentes_mecanicas: Array[MecanicaBase] = []

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("jugador")
	# El jugador existe en Capa 2 y solo choca físicamente con Capa 1 (Mundo/Escenario)
	# Esto permite atravesar enemigos suavemente sin empujarlos
	collision_layer = 2
	collision_mask = 1

	calculate_physics_parameters()
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_action_anim_completed)
		animated_sprite.animation_looped.connect(_on_action_anim_completed)
	
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
const MecanicaDashScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_dash.gd")
const MecanicaAtaqueScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_ataque.gd")
const MecanicaHabilidadScript = preload("res://personajes_scenes/personaje_BASE/componentes/mecanica_habilidad.gd")

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
	comp_ataque.anim_name = "ataquebasico"
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

## Consulta si el personaje está ocupado ejecutando alguna acción
func is_action_busy() -> bool:
	if is_attacking or is_dashing or is_using_skill:
		return true
	for comp in componentes_mecanicas:
		if comp.esta_activa():
			return true
	return false

func _physics_process(delta: float) -> void:
	var dialogue_mgr = get_node_or_null("/root/DialogueManager")
	if dialogue_mgr and dialogue_mgr.get("is_active") == true:
		velocity.x = move_toward(velocity.x, 0.0, get_deceleration() * delta)
		play_anim_if_exists("idle")
		move_and_slide()
		return

	# --- 1. PROCESAR COMPONENTES DE MECÁNICAS ACTIVAS ---
	for comp in componentes_mecanicas:
		comp.procesar_mecanica(delta)

	# --- 2. MANEJO DE MOVIMIENTO EXCLUSIVO DE DASH EN CURSO ---
	if is_dashing:
		move_and_slide()
		return

	# --- 3. DETECCIÓN DE ENTRADA Y ACTIVACIÓN DE MECÁNICAS ---
	if not is_action_busy():
		for comp in componentes_mecanicas:
			if not comp.action_name.is_empty() and is_action_just_pressed_safe(comp.action_name):
				comp.ejecutar_mecanica()
				if is_action_busy():
					break
		
		# Verificación de fallback para acción alternativa de definitiva ("definitiva" / "habilidad_2")
		if not is_action_busy():
			if is_action_just_pressed_safe("definitiva") or is_action_just_pressed_safe("habilidad_2"):
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
	var direction := Input.get_axis("ui_left", "ui_right")
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

	# --- 10. ACTUALIZACIÓN DE ANIMACIONES Y MOVIMIENTO ---
	update_animations(direction)
	move_and_slide()

# --- MÉTODOS FAÇADE / COMPATIBILIDAD DIRECCIÓN DE HABILIDADES ---

func start_dash() -> void:
	var comp = _buscar_componente_por_tipo(MecanicaDash)
	if comp:
		comp.ejecutar_mecanica()

func start_attack() -> void:
	var comp = _buscar_componente_por_tipo(MecanicaAtaque)
	if comp:
		comp.ejecutar_mecanica()

func start_skill_1() -> void:
	for comp in componentes_mecanicas:
		if comp is MecanicaHabilidad and comp.action_name == "habilidad_1":
			comp.ejecutar_mecanica()
			return

func start_ultimate() -> void:
	for comp in componentes_mecanicas:
		if comp is MecanicaHabilidad and (comp.action_name == "habilidad_definitiva" or comp.name == "MecanicaDefinitiva"):
			comp.ejecutar_mecanica()
			return

func _buscar_componente_por_tipo(tipo: Variant) -> MecanicaBase:
	for comp in componentes_mecanicas:
		if is_instance_of(comp, tipo):
			return comp
	return null

func perform_jump() -> void:
	velocity.y = jump_velocity
	var is_double_jump := (jumps_left < max_jumps - 1)
	jumps_left -= 1
	jump_buffer_timer = 0.0
	
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
	if current_anim in ["ataquebasico", "ataquebasico1", "ataquebasico2", "habilidad1", "habilidad2", "definitiva", "ult", "habilidad_definitiva", "dash"] or current_anim.begins_with("ataquebasico"):
		is_attacking = false
		is_using_skill = false
		is_dashing = false
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
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return 0.3
	
	var frame_count := animated_sprite.sprite_frames.get_frame_count(anim_name)
	if frame_count <= 0:
		return 0.3
		
	var speed := animated_sprite.sprite_frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		speed = 10.0
		
	animated_sprite.play(anim_name)
	return float(frame_count) / speed

func get_acceleration() -> float:
	var accel = max_speed / maxf(time_to_max_speed, 0.001)
	return accel if is_on_floor() else accel * air_control_multiplier

func get_deceleration() -> float:
	var decel = max_speed / maxf(time_to_stop, 0.001)
	return decel if is_on_floor() else decel * air_control_multiplier

func update_animations(direction: float) -> void:
	if is_action_busy():
		return
		
	if not is_on_floor():
		if velocity.y < 0.0:
			if animated_sprite and not (animated_sprite.animation in ["jump", "dublejump", "doublejump"]):
				if not play_anim_if_exists("jump"):
					play_anim_if_exists("dublejump")
		else:
			if not play_anim_if_exists("fall"):
				pass
	else:
		if direction != 0.0:
			if not play_anim_if_exists("run"):
				play_anim_if_exists("walk")
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
