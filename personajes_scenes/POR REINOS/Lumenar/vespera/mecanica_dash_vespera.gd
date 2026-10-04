extends MecanicaDash

# Mini-mecánica de Dash única de Vespera con shader de velocidad/distorsión y estela de fantasmas arcanos

const ShaderDash = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/dash_vespera.gdshader")
const ShaderFantasma = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/dash_fantasma_vespera.gdshader")

var material_dash: ShaderMaterial
var material_original: Material = null

var timer_fantasma: float = 0.0
@export var intervalo_fantasma: float = 0.045

func _ready() -> void:
	super._ready()
	material_dash = ShaderMaterial.new()
	material_dash.shader = ShaderDash
	material_dash.set_shader_parameter("intensidad_glow", 1.8)
	material_dash.set_shader_parameter("aberracion_fuerza", 0.02)
	material_dash.set_shader_parameter("color_energia", Color(0.65, 0.1, 1.0, 1.0))
	material_dash.set_shader_parameter("color_borde", Color(0.3, 0.0, 0.8, 1.0))

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
	
	super.ejecutar_mecanica()
	
	if personaje and personaje.animated_sprite:
		material_original = personaje.animated_sprite.material
		personaje.animated_sprite.material = material_dash
		
		# Determinar dirección para la aberración del shader
		var dir_x = float(personaje.facing_direction)
		material_dash.set_shader_parameter("direccion_dash", Vector2(dir_x, 0.0))
		
		timer_fantasma = 0.0
		_crear_fantasma()

func procesar_mecanica(delta: float) -> void:
	if not is_dashing or not personaje:
		return
		
	super.procesar_mecanica(delta)
	
	# Spawn periódico de fantasmas/afterimages durante el dash
	timer_fantasma -= delta
	if timer_fantasma <= 0.0:
		timer_fantasma = intervalo_fantasma
		_crear_fantasma()

func finalizar_dash() -> void:
	if personaje and personaje.animated_sprite:
		personaje.animated_sprite.material = material_original
	super.finalizar_dash()

func _crear_fantasma() -> void:
	if not personaje or not personaje.animated_sprite:
		return
		
	var sprite: AnimatedSprite2D = personaje.animated_sprite
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return
		
	var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return
		
	# Crear sprite fantasma en el mundo
	var fantasma = Sprite2D.new()
	fantasma.texture = tex
	fantasma.global_position = sprite.global_position
	fantasma.global_rotation = sprite.global_rotation
	fantasma.global_scale = sprite.global_scale
	fantasma.flip_h = sprite.flip_h
	fantasma.flip_v = sprite.flip_v
	fantasma.offset = sprite.offset
	fantasma.centered = sprite.centered
	
	# Aplicar shader de fantasma arcano morado
	var mat_fantasma = ShaderMaterial.new()
	mat_fantasma.shader = ShaderFantasma
	mat_fantasma.set_shader_parameter("color_fantasma", Color(0.7, 0.15, 1.0, 0.8))
	mat_fantasma.set_shader_parameter("alpha_base", 0.6)
	fantasma.material = mat_fantasma
	
	# Añadir al padre del personaje (escena actual) para que quede estático mientras Vespera avanza
	var parent = personaje.get_parent()
	if parent:
		parent.add_child(fantasma)
	else:
		personaje.add_child(fantasma)
		
	# Tween para desvanecer y destruir el fantasma
	var tween = fantasma.create_tween().set_parallel(true)
	tween.tween_property(fantasma, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fantasma, "scale", fantasma.scale * 1.1, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(fantasma.queue_free)
