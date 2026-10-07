class_name MecanicaAtaqueRaija
extends MecanicaAtaque

# ==========================================================
# MECÁNICA DE ATAQUE BÁSICO MELEE DE RAIJA CON SHADER ELEMENTAL
# Ataques rápidos cuerpo a cuerpo con búfer de entrada (combo_buffered),
# ventana de cancelación para encadenamiento fluido, micro-impulso hacia adelante
# y ShaderMaterial procedural de luz radiante/rayos en los sprites de ataque.
# ==========================================================

const ShaderAtaqueRaija = preload("res://personajes_scenes/POR REINOS/Lumenar/raija/ataque_raija.gdshader")
const OndaCorteRaijaScene = preload("res://personajes_scenes/POR REINOS/Lumenar/raija/onda_corte_raija.tscn")

@export_category("Configuración Melee Raija")
@export var impulso_ataque: float = 80.0
@export var cancel_window_time: float = 0.25

var material_shader: ShaderMaterial
var duracion_anim_total: float = 0.5

func _ready() -> void:
	super._ready()
	bloquear_movimiento = false # Raija ataca sin congelarse en el sitio
	material_shader = ShaderMaterial.new()
	material_shader.shader = ShaderAtaqueRaija

func _asegurar_material() -> void:
	if personaje and personaje.animated_sprite:
		if personaje.animated_sprite.material != material_shader:
			personaje.animated_sprite.material = material_shader

func puede_ejecutar() -> bool:
	if is_attacking:
		combo_buffered = true
		return false
	if not enabled or not personaje:
		return false
	if personaje.is_dashing or personaje.is_using_skill or personaje.is_hit:
		return false
	return true

func ejecutar_mecanica() -> void:
	if is_attacking:
		combo_buffered = true
		return

	if not puede_ejecutar():
		return

	is_attacking = true
	combo_buffered = false

	if personaje:
		personaje.is_attacking = true
		var anim_a_reproducir = anim_name if paso_combo == 1 else anim_combo
		if personaje.animated_sprite and personaje.animated_sprite.sprite_frames:
			if not personaje.animated_sprite.sprite_frames.has_animation(anim_a_reproducir):
				if personaje.animated_sprite.sprite_frames.has_animation(anim_name):
					anim_a_reproducir = anim_name
				elif personaje.animated_sprite.sprite_frames.has_animation("ataquebasico"):
					anim_a_reproducir = "ataquebasico"
		action_timer = personaje.play_action_anim(anim_a_reproducir)
		duracion_anim_total = maxf(action_timer, 0.01)

		# Lanzar la onda de corte de energía espadazo hacia el frente
		_lanzar_onda_corte()

		paso_combo = 2 if paso_combo == 1 else 1
		timer_reset = tiempo_reset_combo

		# Configurar e iniciar los parámetros del shader de ataque radiante
		_asegurar_material()
		if material_shader:
			material_shader.set_shader_parameter("activo", 1.0)
			material_shader.set_shader_parameter("progreso", 0.0)
			material_shader.set_shader_parameter("direccion", personaje.facing_direction)
			material_shader.set_shader_parameter("flash_hit", 1.0) # Flash radiante al 100% en cada golpe

		# Micro-impulso frontal para dar sensación de golpe melee impactante
		var dir = personaje.facing_direction
		personaje.velocity.x += dir * impulso_ataque

func _lanzar_onda_corte() -> void:
	if not personaje or not OndaCorteRaijaScene:
		return
		
	var onda = OndaCorteRaijaScene.instantiate() as Area2D
	if not onda:
		return
		
	var dir_x = personaje.facing_direction
	if dir_x == 0.0:
		dir_x = 1.0
		
	if "direccion" in onda:
		onda.set("direccion", Vector2(dir_x, 0.0))
		
	# Offset frontal del espadazo hacia adelante
	var spawn_offset = Vector2(dir_x * 35.0, -10.0)
	if paso_combo == 2:
		spawn_offset.y = -18.0
		
	onda.global_position = personaje.global_position + spawn_offset
	
	# Invertir solo si mira hacia la izquierda (<<<<); por defecto apunta hacia la derecha (>>>>)
	if dir_x < 0.0:
		onda.scale.x = -1.0
	else:
		onda.scale.x = 1.0
		
	var parent_node = personaje.get_parent()
	if parent_node:
		parent_node.add_child(onda)

func _get_float_param(param_name: String) -> float:
	if not material_shader:
		return 0.0
	var val = material_shader.get_shader_parameter(param_name)
	if val == null:
		return 0.0
	return float(val)

func procesar_mecanica(delta: float) -> void:
	if not is_attacking:
		if material_shader:
			var act = _get_float_param("activo")
			if act > 0.0:
				material_shader.set_shader_parameter("activo", move_toward(act, 0.0, delta * 6.0))
			var fl = _get_float_param("flash_hit")
			if fl > 0.0:
				material_shader.set_shader_parameter("flash_hit", move_toward(fl, 0.0, delta * 10.0))

		if timer_reset > 0.0:
			timer_reset -= delta
			if timer_reset <= 0.0:
				paso_combo = 1
		return

	action_timer -= delta

	# Actualizar avance del shader
	if material_shader:
		var prog = 1.0 - clampf(action_timer / duracion_anim_total, 0.0, 1.0)
		material_shader.set_shader_parameter("progreso", prog)
		var fl = _get_float_param("flash_hit")
		if fl > 0.0:
			material_shader.set_shader_parameter("flash_hit", move_toward(fl, 0.0, delta * 10.0))

	# Encadenar de inmediato si hay ataque en búfer y se alcanza la ventana de cancelación
	if combo_buffered and action_timer <= cancel_window_time:
		finalizar_ataque()
	elif action_timer <= 0.0:
		finalizar_ataque()

func finalizar_ataque() -> void:
	super.finalizar_ataque()
	if not combo_buffered and material_shader:
		material_shader.set_shader_parameter("activo", 0.0)
		material_shader.set_shader_parameter("flash_hit", 0.0)
