class_name ImpMagico
extends CharacterBody2D

# ==============================================================================
# ENEMIGO IMP MÁGICO VOLADOR - REINO LUMENAR
# Enemigo aéreo con comportamiento de vuelo y flotación sinusoidal,
# persecución tridimensional 2D del jugador manteniendo distancia de combate,
# lanzamiento de proyectiles mágicos telegrafiados, sistema de vida,
# daño por contacto, retroceso aéreo y shader de impacto blanco (Hit Flash).
# ==============================================================================

const ProyectilEscena = preload("res://personajes_scenes/POR REINOS/Lumenar/Enemigos/imp_magicos/proyectil_imp.tscn")
const ShaderHitFlash = preload("res://personajes_scenes/POR REINOS/Lumenar/Enemigos/imp_magicos/hit_flash_imp.gdshader")

signal vida_cambiada(nueva_vida: float, vida_max: float)
signal enemigo_muerto

enum Estado { IDLE, PATRULLA, PERSECUCION, ATAQUE, HERIDO, MUERTO, STUNNED }

@export_category("Estadísticas de Imp Mágico")
@export var vida_maxima: float = 30.0
@export var velocidad_vuelo: float = 75.0
@export var velocidad_persecucion: float = 115.0
@export var aceleracion: float = 480.0
@export var friccion: float = 380.0
@export var dano_contacto: float = 8.0
@export var fuerza_retroceso: float = 220.0
@export var duracion_hitstun: float = 0.22

@export_category("Comportamiento Aéreo")
@export var amplitud_flotacion: float = 9.0
@export var frecuencia_flotacion: float = 3.2
@export var altura_preferida_jugador: float = -42.0 # Altura por encima del jugador al volar
@export var distancia_combate: float = 135.0 # Distancia horizontal preferida antes de disparar

@export_category("Ataque a Distancia")
@export var cooldown_ataque: float = 2.2
@export var tiempo_anticipacion: float = 0.32
@export var tiempo_recuperacion: float = 0.28

var estado_actual: Estado = Estado.IDLE
var vida_actual: float = 30.0
var direccion_mirada: float = 1.0 # 1.0 = Derecha, -1.0 = Izquierda
var objetivo_jugador: Node2D = null
var timer_cooldown: float = 0.0
var tiempo_flotacion: float = 0.0
var material_hit: ShaderMaterial
var tween_deformacion: Tween = null
var escala_inicial: Vector2 = Vector2.ONE
var estado_pre_stun: Estado = Estado.IDLE
var esta_atacando: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var area_rango_ataque: Area2D = $AreaRangoAtaque
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var punto_disparo: Marker2D = $PuntoDisparo

func _ready() -> void:
	add_to_group("enemigos")
	# Capa 4 (Enemigos), colisiona con Capa 1 (Mundo/Obstáculos)
	collision_layer = 4
	collision_mask = 1

	vida_actual = vida_maxima

	if animated_sprite:
		escala_inicial = animated_sprite.scale

	# Configurar Shader de Hit Flash
	material_hit = ShaderMaterial.new()
	material_hit.shader = ShaderHitFlash
	material_hit.set_shader_parameter("flash_fuerza", 0.0)
	material_hit.set_shader_parameter("color_flash", Color(1.0, 1.0, 1.0, 1.0))
	material_hit.set_shader_parameter("grosor_borde", 3.0)

	if animated_sprite:
		animated_sprite.material = material_hit

	# Conectar señales de detección y combate
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_area_deteccion_body_entered)
		area_deteccion.body_exited.connect(_on_area_deteccion_body_exited)

	if area_rango_ataque:
		area_rango_ataque.body_entered.connect(_on_area_rango_ataque_body_entered)

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	_reproducir_animacion("idle")

func _physics_process(delta: float) -> void:
	if estado_actual == Estado.MUERTO:
		return

	# Control de cooldown de disparo
	if timer_cooldown > 0.0:
		timer_cooldown -= delta

	# STUN: parálisis temporal completa
	if estado_actual == Estado.STUNNED:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * 3.0 * delta)
		move_and_slide()
		return

	tiempo_flotacion += delta
	var oscilacion_y = sin(tiempo_flotacion * frecuencia_flotacion) * amplitud_flotacion

	match estado_actual:
		Estado.IDLE:
			_procesar_idle(delta, oscilacion_y)
		Estado.PATRULLA:
			_procesar_patrulla(delta, oscilacion_y)
		Estado.PERSECUCION:
			_procesar_persecucion(delta, oscilacion_y)
		Estado.ATAQUE:
			_procesar_ataque(delta, oscilacion_y)
		Estado.HERIDO:
			_procesar_herido(delta)

	move_and_slide()
	_actualizar_orientacion_visual()

# --- MÉTODOS DE COMPORTAMIENTO / IA ---

func _procesar_idle(delta: float, oscilacion_y: float) -> void:
	var vel_objetivo = Vector2(0.0, oscilacion_y * 1.5)
	velocity = velocity.move_toward(vel_objetivo, friccion * delta)
	_reproducir_animacion("idle")

func _procesar_patrulla(delta: float, oscilacion_y: float) -> void:
	var vel_x = direccion_mirada * velocidad_vuelo
	var vel_objetivo = Vector2(vel_x, oscilacion_y * 1.8)
	velocity = velocity.move_toward(vel_objetivo, aceleracion * delta)

	# Si choca con una pared en el aire, da la vuelta
	if is_on_wall():
		direccion_mirada *= -1.0

	_reproducir_animacion("run")

func _procesar_persecucion(delta: float, oscilacion_y: float) -> void:
	if not is_instance_valid(objetivo_jugador):
		objetivo_jugador = null
		estado_actual = Estado.IDLE
		return

	# Mirar siempre hacia el jugador
	var diff = objetivo_jugador.global_position - global_position
	if abs(diff.x) > 6.0:
		direccion_mirada = sign(diff.x)

	# Posición táctica deseada: mantener distancia horizontal y estar por encima
	var pos_deseada = objetivo_jugador.global_position
	pos_deseada.y += altura_preferida_jugador
	pos_deseada.x -= direccion_mirada * distancia_combate

	var vector_a_pos = pos_deseada - global_position
	var dist = vector_a_pos.length()

	# Si está en rango óptimo de disparo y el cooldown terminó, iniciar ataque
	if dist < 160.0 and timer_cooldown <= 0.0 and not esta_atacando:
		_iniciar_ataque()
		return

	# Movimiento suave hacia la posición táctica
	var dir_normalizada = vector_a_pos.normalized() if dist > 10.0 else Vector2.ZERO
	var vel_deseada = dir_normalizada * velocidad_persecucion
	vel_deseada.y += oscilacion_y * 1.2
	velocity = velocity.move_toward(vel_deseada, aceleracion * delta)

	if velocity.length() > 20.0:
		_reproducir_animacion("run")
	else:
		_reproducir_animacion("idle")

func _procesar_ataque(delta: float, oscilacion_y: float) -> void:
	# Flotar suavemente mientras prepara o lanza el hechizo
	var vel_ataque = Vector2(0.0, oscilacion_y * 0.8)
	velocity = velocity.move_toward(vel_ataque, friccion * delta)

func _procesar_herido(delta: float) -> void:
	# Desaceleración suave del retroceso aéreo
	velocity = velocity.move_toward(Vector2.ZERO, friccion * 1.8 * delta)

func _iniciar_ataque() -> void:
	if esta_atacando or estado_actual == Estado.HERIDO or estado_actual == Estado.MUERTO:
		return

	esta_atacando = true
	estado_actual = Estado.ATAQUE
	timer_cooldown = cooldown_ataque

	if is_instance_valid(objetivo_jugador):
		direccion_mirada = sign(objetivo_jugador.global_position.x - global_position.x)
		if direccion_mirada == 0.0:
			direccion_mirada = 1.0

	_reproducir_animacion("attack")

	# Anticipación telegrafiada antes del disparo
	var tree = get_tree()
	if not tree:
		return

	tree.create_timer(tiempo_anticipacion).timeout.connect(func():
		if estado_actual == Estado.ATAQUE and not esta_stunned():
			_disparar_proyectil()

			# Tiempo de recuperación tras disparar
			var timer_recup = get_tree().create_timer(tiempo_recuperacion)
			timer_recup.timeout.connect(func():
				esta_atacando = false
				if estado_actual == Estado.ATAQUE:
					estado_actual = Estado.PERSECUCION if objetivo_jugador else Estado.IDLE
			)
	)

func _disparar_proyectil() -> void:
	if not ProyectilEscena:
		return

	var proyectil = ProyectilEscena.instantiate()
	var spawn_pos = punto_disparo.global_position if punto_disparo else global_position
	proyectil.global_position = spawn_pos

	# Calcular dirección hacia el jugador o hacia adelante si no hay objetivo
	var dir_disparo = Vector2(direccion_mirada, 0.0)
	if is_instance_valid(objetivo_jugador):
		# Apuntar al torso del jugador
		var pos_objetivo = objetivo_jugador.global_position + Vector2(0.0, -10.0)
		dir_disparo = (pos_objetivo - spawn_pos).normalized()

	proyectil.direccion = dir_disparo

	# Añadir al árbol de la escena principal (mundo)
	var contenedor = get_parent()
	if contenedor:
		contenedor.add_child(proyectil)
	else:
		get_tree().current_scene.add_child(proyectil)

# --- SISTEMA DE DAÑO Y HIT FLASH ---

func recibir_dano(cantidad: float, origen_impacto: Vector2 = Vector2.ZERO) -> void:
	if estado_actual == Estado.MUERTO:
		return

	vida_actual = max(vida_actual - cantidad, 0.0)
	vida_cambiada.emit(vida_actual, vida_maxima)

	# 1. Knockback aéreo en dirección opuesta al impacto
	if origen_impacto != Vector2.ZERO:
		var dir_impacto = (global_position - origen_impacto).normalized()
		# Asegurar un impulso ascendente agradable
		if dir_impacto.y > -0.2:
			dir_impacto.y = -0.35
		velocity = dir_impacto.normalized() * fuerza_retroceso
	else:
		velocity = Vector2(-direccion_mirada * 0.8, -0.6).normalized() * fuerza_retroceso

	# 2. Shader de Hit Flash (Blanqueado de impacto)
	_activar_efecto_blanqueado_hit()

	# 3. Squash & Stretch de impacto
	_animar_deformacion_golpe()

	if vida_actual <= 0.0:
		_morir()
	else:
		esta_atacando = false
		estado_actual = Estado.HERIDO
		_reproducir_animacion("hit")

		var tree = get_tree()
		if tree:
			tree.create_timer(duracion_hitstun).timeout.connect(func():
				if estado_actual == Estado.HERIDO:
					estado_actual = Estado.PERSECUCION if objetivo_jugador else Estado.IDLE
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

	if tween_deformacion and tween_deformacion.is_valid():
		tween_deformacion.kill()

	animated_sprite.scale = escala_inicial

	var escala_estirada = escala_inicial * Vector2(0.78, 1.28)
	var escala_aplastada = escala_inicial * Vector2(1.24, 0.80)

	tween_deformacion = create_tween()
	tween_deformacion.tween_property(animated_sprite, "scale", escala_estirada, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_deformacion.tween_property(animated_sprite, "scale", escala_aplastada, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_deformacion.tween_property(animated_sprite, "scale", escala_inicial, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func aplicar_stun(duracion: float) -> void:
	if estado_actual == Estado.MUERTO or estado_actual == Estado.STUNNED:
		return

	estado_pre_stun = estado_actual
	estado_actual = Estado.STUNNED
	velocity = Vector2.ZERO

	if animated_sprite:
		animated_sprite.pause()
		animated_sprite.modulate = Color(0.65, 0.55, 1.0, 1.0)

	var tree = get_tree()
	if tree:
		tree.create_timer(duracion).timeout.connect(_liberar_stun)

func _liberar_stun() -> void:
	if estado_actual != Estado.STUNNED:
		return

	if animated_sprite:
		animated_sprite.play()
		animated_sprite.modulate = Color.WHITE

	estado_actual = Estado.PERSECUCION if objetivo_jugador else Estado.IDLE

func esta_stunned() -> bool:
	return estado_actual == Estado.STUNNED

func _morir() -> void:
	estado_actual = Estado.MUERTO
	enemigo_muerto.emit()
	velocity = Vector2.ZERO

	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

	# Desactivar colisiones
	set_collision_layer_value(1, false)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)

	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("dead"):
		animated_sprite.play("dead")
		var duracion_muerte: float = 0.7
		var speed: float = animated_sprite.sprite_frames.get_animation_speed("dead")
		var frames_count: int = animated_sprite.sprite_frames.get_frame_count("dead")
		if speed > 0.0 and frames_count > 0:
			duracion_muerte = float(frames_count) / speed

		var tree = get_tree()
		if tree:
			tree.create_timer(duracion_muerte).timeout.connect(func():
				if is_instance_valid(animated_sprite):
					var tween = create_tween().set_parallel(true)
					tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.35)
					tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 0.75, 0.35)
					tween.chain().tween_callback(queue_free)
				else:
					queue_free()
			)
		else:
			queue_free()
	elif animated_sprite:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.4)
		tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 0.6, 0.4)
		tween.finished.connect(queue_free)
	else:
		queue_free()

# --- ACTUALIZACIÓN VISUAL Y ANIMACIONES ---

func _actualizar_orientacion_visual() -> void:
	if animated_sprite and direccion_mirada != 0.0:
		animated_sprite.flip_h = (direccion_mirada < 0.0)

	if punto_disparo:
		punto_disparo.position.x = abs(punto_disparo.position.x) * direccion_mirada

func _reproducir_animacion(nombre_anim: String) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return

	# Si la animación solicitada existe, reproducirla
	if animated_sprite.sprite_frames.has_animation(nombre_anim):
		if animated_sprite.animation != nombre_anim or not animated_sprite.is_playing():
			animated_sprite.play(nombre_anim)
	elif animated_sprite.sprite_frames.has_animation("idle"):
		# Fallback seguro a idle
		if animated_sprite.animation != "idle" or not animated_sprite.is_playing():
			animated_sprite.play("idle")

# --- CONEXIÓN DE DETECCIÓN Y COLISIONES ---

func _on_area_deteccion_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.is_in_group("jugador") or body.get("is_attacking") != null or "facing_direction" in body:
		objetivo_jugador = body
		if estado_actual == Estado.IDLE or estado_actual == Estado.PATRULLA:
			estado_actual = Estado.PERSECUCION

func _on_area_deteccion_body_exited(body: Node2D) -> void:
	if body == objetivo_jugador:
		objetivo_jugador = null
		if estado_actual == Estado.PERSECUCION:
			estado_actual = Estado.IDLE

func _on_area_rango_ataque_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador") or body == objetivo_jugador:
		if timer_cooldown <= 0.0 and estado_actual == Estado.PERSECUCION:
			_iniciar_ataque()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self or body.is_in_group("enemigos"):
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano_contacto, global_position)
	elif body.has_method("take_damage"):
		body.take_damage(dano_contacto)

func _on_hitbox_area_entered(area: Area2D) -> void:
	var dueno = area.owner if area.owner else area
	if dueno and dueno != self and not dueno.is_in_group("enemigos") and dueno.has_method("recibir_dano"):
		dueno.recibir_dano(dano_contacto, global_position)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	var proyectil = area as Area2D
	# Daño por proyectiles del jugador
	if proyectil and not (proyectil.owner is ImpMagico) and not proyectil.is_in_group("enemigos"):
		if "direccion" in proyectil or "dano" in proyectil:
			var dano = proyectil.get("dano") if "dano" in proyectil else 15.0
			recibir_dano(dano, proyectil.global_position)
