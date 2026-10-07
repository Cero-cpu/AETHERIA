class_name MecanicaAtaqueVespera
extends MecanicaAtaque

# ==========================================================
# MECÁNICA DE ATAQUE BÁSICO PROPIA DE VESPERA
# Alterna entre Ataque Básico 1 y Ataque Básico 2 en cada clic:
# - Clic 1: Ejecuta "ataquebasico1" y lanza la 1ª bola de energía en su timing oportuno.
# - Clic 2: Ejecuta "ataquebasico2" y lanza la 2ª bola de energía en su timing oportuno.
# Incluye búfer de entrada (combo) y reinicio automático si pasa el tiempo sin atacar.
# ==========================================================

const ProyectilVesperaScene = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/proyectil_vespera.tscn")

@export_category("Configuración Ataque Vespera")
@export var escena_proyectil: PackedScene = ProyectilVesperaScene
@export var offset_disparo: Vector2 = Vector2(25.0, -10.0)

# Tiempos sincronizados para cada ataque individual
@export var delay_disparo_1: float = 0.10 # Delay para la bola de basico 1
@export var delay_disparo_2: float = 0.10 # Delay para la bola de basico 2

func puede_ejecutar() -> bool:
	if is_attacking:
		# Si ya está atacando y vuelve a hacer clic, guardamos la entrada en el búfer
		combo_buffered = true
		return false
	return super.puede_ejecutar()

func ejecutar_mecanica() -> void:
	if is_attacking:
		combo_buffered = true
		return

	if not puede_ejecutar():
		return

	is_attacking = true
	combo_buffered = false

	# Seleccionar animación y delay según el paso de combo actual
	var anim_actual := "ataquebasico1" if paso_combo == 1 else "ataquebasico2"
	var delay_actual := delay_disparo_1 if paso_combo == 1 else delay_disparo_2

	# Fallback: si la animación específica no existe en SpriteFrames, usar "ataquebasico"
	if personaje and personaje.animated_sprite and personaje.animated_sprite.sprite_frames:
		if not personaje.animated_sprite.sprite_frames.has_animation(anim_actual):
			anim_actual = "ataquebasico"

	if personaje:
		personaje.is_attacking = true
		action_timer = personaje.play_action_anim(anim_actual)

		# Avanzar el paso de combo para el próximo clic
		paso_combo = 2 if paso_combo == 1 else 1
		timer_reset = tiempo_reset_combo

		var tree = personaje.get_tree()
		if tree:
			tree.create_timer(delay_actual).timeout.connect(
				func(): _instanciar_proyectil()
			)

func procesar_mecanica(delta: float) -> void:
	if is_attacking:
		action_timer -= delta
		if action_timer <= 0.0:
			finalizar_ataque()
	else:
		if timer_reset > 0.0:
			timer_reset -= delta
			if timer_reset <= 0.0:
				paso_combo = 1

func finalizar_ataque() -> void:
	is_attacking = false
	if personaje:
		personaje.is_attacking = false

	# Si se hizo clic durante el ataque, ejecutar inmediatamente el siguiente paso de combo
	if combo_buffered:
		combo_buffered = false
		ejecutar_mecanica()
	else:
		timer_reset = tiempo_reset_combo

func _instanciar_proyectil() -> void:
	if not personaje or not escena_proyectil:
		return

	var proyectil = escena_proyectil.instantiate() as Area2D
	if not proyectil:
		return

	var dir_x = personaje.facing_direction
	if "direccion" in proyectil:
		proyectil.set("direccion", Vector2(dir_x, 0.0))

	# Posición de spawn considerando la dirección
	var spawn_pos = personaje.global_position + Vector2(offset_disparo.x * dir_x, offset_disparo.y)
	proyectil.global_position = spawn_pos

	# Voltear sprite del proyectil si mira a la izquierda
	var sprite = proyectil.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = (dir_x < 0.0)

	var parent_node = personaje.get_parent()
	if parent_node:
		parent_node.add_child(proyectil)
