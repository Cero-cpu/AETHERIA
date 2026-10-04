class_name Goblin
extends CharacterBody2D

# ==============================================================================
# ENEMIGO ENTE GOBLIN - REINO SYLVANETH
# Enemigo terrestre básico con IA de patrulla inteligente, detección de abismos,
# persecución del jugador, sistema de vida, daño por contacto, salto de impacto
# al ser golpeado y shader de parpadeo/blanqueado de bordes.
# ==============================================================================

const ShaderHitFlash = preload("res://personajes_scenes/POR REINOS/Sylvaneth/enemigos/goblin/hit_flash_goblin.gdshader")

signal vida_cambiada(nueva_vida: float, vida_max: float)
signal enemigo_muerto

enum Estado { PATRULLA, PERSECUCION, HERIDO, MUERTO, STUNNED }

@export_category("Estadísticas de Goblin")
@export var vida_maxima: float = 40.0
@export var velocidad_patrulla: float = 65.0
@export var velocidad_persecucion: float = 120.0
@export var aceleracion: float = 850.0
@export var friccion: float = 1100.0
@export var dano_contacto: float = 12.0
@export var fuerza_retroceso: float = 240.0
@export var fuerza_salto_impacto: float = -190.0 # Impulso hacia arriba al recibir un golpe
@export var gravedad: float = 1150.0
@export var duracion_hitstun: float = 0.2

@export_category("Configuración IA")
@export var tiempo_espera_giro: float = 0.45

var estado_actual: Estado = Estado.PATRULLA
var vida_actual: float = 40.0
var direccion_movimiento: float = 1.0 # 1.0 = Derecha, -1.0 = Izquierda
var objetivo_jugador: Node2D = null
var timer_espera: float = 0.0
var esta_parado: bool = false
var material_hit: ShaderMaterial
var tween_deformacion: Tween = null
var esta_stunned: bool = false
var estado_pre_stun: Estado = Estado.PATRULLA

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector_suelo: RayCast2D = $DetectorSuelo
@onready var detector_pared: RayCast2D = $DetectorPared
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox

var escala_inicial: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("enemigos")
	# El enemigo existe en Capa 4 (Capa 3 de la UI) y solo choca físicamente con Capa 1 (Mundo/Escenario)
	# Esto evita empujar al jugador físicamente pero permite que sus Hitboxes y Hurtboxes se detecten
	collision_layer = 4
	collision_mask = 1

	vida_actual = vida_maxima

	if animated_sprite:
		escala_inicial = animated_sprite.scale

	# Configurar Shader de Hit Flash con bordes blancos
	material_hit = ShaderMaterial.new()
	material_hit.shader = ShaderHitFlash
	material_hit.set_shader_parameter("flash_fuerza", 0.0)
	material_hit.set_shader_parameter("color_flash", Color(1.0, 1.0, 1.0, 1.0))
	material_hit.set_shader_parameter("grosor_borde", 3.5)

	if animated_sprite:
		animated_sprite.material = material_hit

	# Conectar señales de detección
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_area_deteccion_body_entered)
		area_deteccion.body_exited.connect(_on_area_deteccion_body_exited)

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
	if estado_actual == Estado.MUERTO:
		return

	# ---- STUN / PARÁLISIS TEMPORAL: congelar toda acción ----
	if estado_actual == Estado.STUNNED:
		velocity.x = move_toward(velocity.x, 0.0, friccion * 3.0 * delta)
		if not is_on_floor():
			velocity.y += gravedad * delta
		move_and_slide()
		return

	# Aplicar Gravedad (más pesada al caer para dar sensación de peso Hollow Knight)
	if not is_on_floor():
		var mult_gravedad = 1.25 if velocity.y > 0.0 else 1.0
		velocity.y += gravedad * mult_gravedad * delta

	# Procesar según estado
	match estado_actual:
		Estado.PATRULLA:
			_procesar_patrulla(delta)
		Estado.PERSECUCION:
			_procesar_persecucion(delta)
		Estado.HERIDO:
			_procesar_herido(delta)

	move_and_slide()
	_actualizar_orientacion_y_animacion()

func _procesar_patrulla(delta: float) -> void:
	if esta_parado:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)
		timer_espera -= delta
		if timer_espera <= 0.0:
			esta_parado = false
			direccion_movimiento *= -1.0
			_actualizar_raycasts()
		return

	# Detección de bordes (abismos) o paredes para cambiar de dirección
	var hay_suelo = detector_suelo.is_colliding() if detector_suelo else true
	var hay_pared = detector_pared.is_colliding() if detector_pared else false

	if not hay_suelo or hay_pared:
		esta_parado = true
		timer_espera = tiempo_espera_giro
		return

	var vel_objetivo = direccion_movimiento * velocidad_patrulla
	velocity.x = move_toward(velocity.x, vel_objetivo, aceleracion * delta)

func _procesar_persecucion(delta: float) -> void:
	if not is_instance_valid(objetivo_jugador):
		estado_actual = Estado.PATRULLA
		return

	var diff_x = objetivo_jugador.global_position.x - global_position.x
	if abs(diff_x) > 12.0:
		direccion_movimiento = sign(diff_x)
		_actualizar_raycasts()

	# Evitar caer de plataformas durante persecución si no hay suelo adelante
	var hay_suelo = detector_suelo.is_colliding() if detector_suelo else true
	var vel_objetivo = (direccion_movimiento * velocidad_persecucion) if hay_suelo else 0.0
	velocity.x = move_toward(velocity.x, vel_objetivo, aceleracion * delta)

func _procesar_herido(delta: float) -> void:
	# Fricción de aire/suelo tras recibir golpe
	var friccion_knockback = friccion * 0.75 if not is_on_floor() else friccion * 1.5
	velocity.x = move_toward(velocity.x, 0.0, friccion_knockback * delta)

func _actualizar_orientacion_y_animacion() -> void:
	if direccion_movimiento != 0.0 and animated_sprite:
		animated_sprite.flip_h = (direccion_movimiento < 0.0)

	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")

func _actualizar_raycasts() -> void:
	if detector_suelo:
		detector_suelo.position.x = abs(detector_suelo.position.x) * direccion_movimiento
	if detector_pared:
		detector_pared.target_position.x = abs(detector_pared.target_position.x) * direccion_movimiento

func recibir_dano(cantidad: float, origen_impacto: Vector2 = Vector2.ZERO) -> void:
	if estado_actual == Estado.MUERTO:
		return

	vida_actual = max(vida_actual - cantidad, 0.0)
	vida_cambiada.emit(vida_actual, vida_maxima)

	# ---- 1. SALTO DE IMPACTO Y RETROCESO (REBOUND + KNOCKBACK) ----
	velocity.y = fuerza_salto_impacto # Salto hacia arriba al ser golpeado

	if origen_impacto != Vector2.ZERO:
		var dir_x = sign(global_position.x - origen_impacto.x)
		if dir_x == 0.0:
			dir_x = -direccion_movimiento
		velocity.x = dir_x * fuerza_retroceso
	else:
		velocity.x = -direccion_movimiento * fuerza_retroceso

	# ---- 2. EFECTO SHADER: BLANQUEADO DE BORDES Y CUERPO ----
	_activar_efecto_blanqueado_hit()

	# ---- 3. DEFORMACIÓN DE IMPACTO (SQUASH & STRETCH) ----
	_animar_deformacion_golpe()

	if vida_actual <= 0.0:
		_morir()
	else:
		estado_actual = Estado.HERIDO
		var tree = get_tree()
		if tree:
			tree.create_timer(duracion_hitstun).timeout.connect(func():
				if estado_actual == Estado.HERIDO:
					estado_actual = Estado.PERSECUCION if objetivo_jugador else Estado.PATRULLA
			)

func _activar_efecto_blanqueado_hit() -> void:
	if not material_hit:
		return

	material_hit.set_shader_parameter("flash_fuerza", 1.0)
	var tree = get_tree()
	if tree:
		var tween = create_tween()
		tween.tween_method(func(val: float):
			if material_hit:
				material_hit.set_shader_parameter("flash_fuerza", val)
		, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animar_deformacion_golpe() -> void:
	if not animated_sprite:
		return

	# Asegurar que la escala no se descorrompa ni se acumulen tweens
	if tween_deformacion and tween_deformacion.is_valid():
		tween_deformacion.kill()
	
	animated_sprite.scale = escala_inicial

	# Squash & Stretch exagerado proporcional a la escala inicial intacta
	var escala_estirada = escala_inicial * Vector2(0.76, 1.32) # Estiramiento vertical de impacto
	var escala_aplastada = escala_inicial * Vector2(1.22, 0.78) # Aplastamiento horizontal al rebotar

	tween_deformacion = create_tween()
	tween_deformacion.tween_property(animated_sprite, "scale", escala_estirada, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_deformacion.tween_property(animated_sprite, "scale", escala_aplastada, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_deformacion.tween_property(animated_sprite, "scale", escala_inicial, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func aplicar_stun(duracion: float) -> void:
	if estado_actual == Estado.MUERTO or estado_actual == Estado.STUNNED:
		return

	estado_pre_stun = estado_actual
	estado_actual = Estado.STUNNED
	esta_stunned = true
	velocity = Vector2.ZERO

	# Congelar la animación y aplicar un tinte violeta-azulado de parálisis
	if animated_sprite:
		animated_sprite.pause()
		animated_sprite.modulate = Color(0.65, 0.55, 1.0, 1.0)

	# Programar la liberación del stun
	var tree = get_tree()
	if tree:
		tree.create_timer(duracion).timeout.connect(_liberar_stun)

func _liberar_stun() -> void:
	if estado_actual != Estado.STUNNED:
		return

	esta_stunned = false

	# Restaurar visual normal
	if animated_sprite:
		animated_sprite.play()
		animated_sprite.modulate = Color.WHITE

	# Volver al estado que tenía antes del stun
	if estado_pre_stun == Estado.HERIDO:
		estado_actual = Estado.PERSECUCION if objetivo_jugador else Estado.PATRULLA
	else:
		estado_actual = estado_pre_stun

func _morir() -> void:
	estado_actual = Estado.MUERTO
	enemigo_muerto.emit()
	velocity = Vector2.ZERO

	# Restaurar modulate si estaba stunned
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

	# Desactivar colisiones
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Animación de desvanecimiento y destrucción
	if animated_sprite:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
		tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 0.7, 0.4)
		tween.finished.connect(queue_free)
	else:
		queue_free()

func _on_area_deteccion_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador") or body.get("is_attacking") != null or "facing_direction" in body:
		objetivo_jugador = body
		if estado_actual == Estado.PATRULLA:
			estado_actual = Estado.PERSECUCION

func _on_area_deteccion_body_exited(body: Node2D) -> void:
	if body == objetivo_jugador:
		objetivo_jugador = null
		if estado_actual == Estado.PERSECUCION:
			estado_actual = Estado.PATRULLA

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano_contacto, global_position)
	elif body.has_method("take_damage"):
		body.take_damage(dano_contacto)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var dueño = area.owner
	if dueño and dueño != self and dueño.has_method("recibir_dano"):
		dueño.recibir_dano(dano_contacto, global_position)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var proyectil = area as Area2D
	if proyectil and "direccion" in proyectil and not (proyectil.owner is Goblin):
		var dano = proyectil.get("dano") if "dano" in proyectil else 15.0
		recibir_dano(dano, proyectil.global_position)
