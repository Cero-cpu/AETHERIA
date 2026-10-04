class_name MecanicaDefinitivaVespera
extends MecanicaHabilidad

# ==============================================================================
# MECÁNICA ÉPICA DE DEFINITIVA PARA VESPERA
# - Elevación lenta y elevada en el aire a 8.0 FPS durante la animación.
# - Ataque dual procedural desde ambos brazos mediante GDShader (sin sprites extra).
# - Área de daño destructivo masivo para los enemigos en pantalla.
# - Oscurecimiento del entorno a Noche Crepuscular y aura mística de energía.
# ==============================================================================

const ShaderDefinitiva = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/aura_definitiva_vespera.gdshader")
const ShaderNoche = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/oscuridad_noche_vespera.gdshader")
const ShaderAtaqueDual = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/ataque_definitiva_vespera.gdshader")

@export_category("Configuración Aura Definitiva Vespera")
@export var intensidad_maxima: float = 3.2
@export var grosor_aura_maximo: float = 6.0
@export var destellos_maximos: float = 3.5
@export var intervalo_estela_fantasma: float = 0.06

@export_category("Configuración Levitación y Ascenso")
@export var elevar_personaje: bool = true
@export var altura_elevacion: float = 75.0 # Elevación alta y majestuosa en píxeles
@export var duracion_elevacion: float = 1.38 # Ascenso gradual y continuo a 8.0 fps (~frame 11)

@export_category("Configuración Dominio de la Noche")
@export var intensidad_oscuridad_noche: float = 0.88

@export_category("Configuración Daño e Impacto Dual")
@export var dano_definitiva: float = 60.0
@export var radio_impacto_ancho: float = 420.0
@export var radio_impacto_alto: float = 220.0

var material_definitiva: ShaderMaterial
var material_original: Material = null

# Overlay de Noche
var canvas_noche: CanvasLayer = null
var color_rect_noche: ColorRect = null
var material_noche: ShaderMaterial = null
var tween_noche: Tween = null

var tiempo_transcurrido: float = 0.0
var duracion_definitiva_total: float = 2.125
var timer_fantasma: float = 0.0
var ataque_ejecutado: bool = false

func _ready() -> void:
	super._ready()
	anim_name = "definitiva"
	anim_fallbacks = ["habilidad_definitiva", "ult", "habilidad2"]
	bloquear_movimiento = true

	# Inicializar ShaderMaterial del aura con parámetros por defecto
	material_definitiva = ShaderMaterial.new()
	material_definitiva.shader = ShaderDefinitiva
	material_definitiva.set_shader_parameter("activo", 0.0)
	material_definitiva.set_shader_parameter("intensidad", 1.5)
	material_definitiva.set_shader_parameter("velocidad", 3.8)
	material_definitiva.set_shader_parameter("grosor_aura", 3.0)
	material_definitiva.set_shader_parameter("color_nucleo", Color(0.98, 0.88, 1.0, 1.0))
	material_definitiva.set_shader_parameter("color_intenso", Color(0.78, 0.12, 1.0, 1.0))
	material_definitiva.set_shader_parameter("color_aura", Color(0.48, 0.02, 0.92, 1.0))
	material_definitiva.set_shader_parameter("color_borde", Color(0.18, 0.0, 0.48, 1.0))
	material_definitiva.set_shader_parameter("color_destello", Color(1.0, 0.45, 0.98, 1.0))

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return

	super.ejecutar_mecanica()

	if personaje and personaje.animated_sprite:
		material_original = personaje.animated_sprite.material
		personaje.animated_sprite.material = material_definitiva
		
		tiempo_transcurrido = 0.0
		timer_fantasma = 0.0
		ataque_ejecutado = false

		# Duración total de la animación a 8 FPS (17 frames @ 8fps = 2.125s)
		duracion_definitiva_total = max(action_timer, 2.125)

		# Encender aura shader
		material_definitiva.set_shader_parameter("activo", 1.0)
		material_definitiva.set_shader_parameter("progreso_ult", 0.0)

		# ---- 1. ACTIVAR DOMINIO DE LA NOCHE ----
		_activar_dominio_noche()
		
		# ---- 2. ASCENSO LENTO Y MAJESTUOSO HASTA EL IMPACTO DE BRAZOS ----
		if elevar_personaje:
			personaje.velocity = Vector2.ZERO
			var pos_objetivo_y = personaje.global_position.y - altura_elevacion
			var tree_elev = personaje.get_tree()
			if tree_elev:
				var tween_elev = personaje.create_tween()
				tween_elev.tween_property(personaje, "global_position:y", pos_objetivo_y, duracion_elevacion).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		# Animar parámetros iniciales de aura de carga
		var tree = personaje.get_tree()
		if tree:
			var tween = personaje.create_tween().set_parallel(true)
			tween.tween_method(func(val: float): material_definitiva.set_shader_parameter("intensidad", val), 1.5, intensidad_maxima, duracion_definitiva_total * 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_method(func(val: float): material_definitiva.set_shader_parameter("grosor_aura", val), 3.0, grosor_aura_maximo, duracion_definitiva_total * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_method(func(val: float): material_definitiva.set_shader_parameter("destellos_fuerza", val), 1.0, destellos_maximos, duracion_definitiva_total * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			# Programar la ráfaga de ataque dual por shader en ambos brazos (~frame 11 @ 8fps = 1.375s)
			tree.create_timer(duracion_elevacion).timeout.connect(_desplegar_ataque_dual_shader)

func procesar_mecanica(delta: float) -> void:
	if not is_using_skill or not personaje:
		return

	super.procesar_mecanica(delta)

	tiempo_transcurrido += delta
	var progreso: float = clamp(tiempo_transcurrido / max(duracion_definitiva_total, 0.01), 0.0, 1.0)

	# ---- MANTENER FLOTACIÓN MÍSTICA EN EL AIRE ----
	if elevar_personaje:
		personaje.velocity.y = sin(tiempo_transcurrido * 6.0) * 4.0

	if material_definitiva:
		material_definitiva.set_shader_parameter("progreso_ult", progreso)

	_actualizar_centro_foco_noche()

	# Estela de fantasmas arcanos ascendentes
	timer_fantasma -= delta
	if timer_fantasma <= 0.0:
		timer_fantasma = intervalo_estela_fantasma
		_generar_eco_arcano(progreso)

func _desplegar_ataque_dual_shader() -> void:
	if not is_instance_valid(personaje) or ataque_ejecutado:
		return
		
	ataque_ejecutado = true

	# Crear nodo de visualización del shader de ataque procedural
	var contenedor_ataque = Node2D.new()
	contenedor_ataque.global_position = personaje.global_position

	var rect_efecto = ColorRect.new()
	rect_efecto.size = Vector2(radio_impacto_ancho, radio_impacto_alto)
	rect_efecto.position = -rect_efecto.size * 0.5
	rect_efecto.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat_ataque = ShaderMaterial.new()
	mat_ataque.shader = ShaderAtaqueDual
	mat_ataque.set_shader_parameter("progreso", 0.0)
	rect_efecto.material = mat_ataque

	contenedor_ataque.add_child(rect_efecto)

	var parent = personaje.get_parent()
	if parent:
		parent.add_child(contenedor_ataque)
	else:
		personaje.add_child(contenedor_ataque)

	# Animar el progreso del shader expansivo de ambos brazos
	var tree = personaje.get_tree()
	if tree:
		var tween_shader = personaje.create_tween()
		tween_shader.tween_method(func(val: float):
			if is_instance_valid(mat_ataque):
				mat_ataque.set_shader_parameter("progreso", val)
		, 0.0, 1.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_shader.finished.connect(contenedor_ataque.queue_free)

	# ---- DAÑO ÉPICO Y REPULESO A TODOS LOS ENEMIGOS ----
	_aplicar_dano_area_definitiva()

func _aplicar_dano_area_definitiva() -> void:
	if not is_instance_valid(personaje):
		return

	var pos_centro = personaje.global_position
	var rango_cuadrado = (radio_impacto_ancho * 0.5) * (radio_impacto_ancho * 0.5)

	# Buscar a los enemigos en el grupo "enemigos" o en la escena
	var tree = personaje.get_tree()
	if not tree:
		return

	var enemigos = tree.get_nodes_in_group("enemigos")
	for enemigo in enemigos:
		if is_instance_valid(enemigo) and enemigo != personaje:
			var dist_sq = pos_centro.distance_squared_to(enemigo.global_position)
			if dist_sq <= rango_cuadrado:
				if enemigo.has_method("recibir_dano"):
					enemigo.recibir_dano(dano_definitiva, pos_centro)
				elif enemigo.has_method("take_damage"):
					enemigo.take_damage(dano_definitiva)

func _activar_dominio_noche() -> void:
	_limpiar_overlay_noche()

	canvas_noche = CanvasLayer.new()
	canvas_noche.layer = 9

	var back_buffer = BackBufferCopy.new()
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	back_buffer.rect = Rect2(0, 0, 1920, 1080)
	canvas_noche.add_child(back_buffer)

	color_rect_noche = ColorRect.new()
	color_rect_noche.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect_noche.mouse_filter = Control.MOUSE_FILTER_IGNORE

	material_noche = ShaderMaterial.new()
	material_noche.shader = ShaderNoche
	material_noche.set_shader_parameter("intensidad_noche", 0.0)
	material_noche.set_shader_parameter("radio_luz_vespera", 0.36)

	color_rect_noche.material = material_noche
	canvas_noche.add_child(color_rect_noche)

	_actualizar_centro_foco_noche()

	var tree = personaje.get_tree()
	if tree and tree.root:
		tree.root.add_child(canvas_noche)
		
		if tween_noche and tween_noche.is_valid():
			tween_noche.kill()
		tween_noche = personaje.create_tween()
		tween_noche.tween_method(func(val: float):
			if material_noche:
				material_noche.set_shader_parameter("intensidad_noche", val)
		, 0.0, intensidad_oscuridad_noche, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _actualizar_centro_foco_noche() -> void:
	if not material_noche or not is_instance_valid(personaje):
		return

	var centro_uv = Vector2(0.5, 0.5)
	var viewport = personaje.get_viewport()
	if viewport:
		var camara = viewport.get_camera_2d()
		if camara:
			var pos_pantalla = camara.get_screen_center_position()
			var offset_cam = personaje.global_position - pos_pantalla
			var size_pantalla = viewport.get_visible_rect().size
			if size_pantalla.x > 0 and size_pantalla.y > 0:
				centro_uv = (size_pantalla * 0.5 + offset_cam) / size_pantalla
				centro_uv.x = clampf(centro_uv.x, 0.0, 1.0)
				centro_uv.y = clampf(centro_uv.y, 0.0, 1.0)

	material_noche.set_shader_parameter("centro_pantalla", centro_uv)

func _limpiar_overlay_noche() -> void:
	if is_instance_valid(canvas_noche):
		canvas_noche.queue_free()
		canvas_noche = null
	color_rect_noche = null
	material_noche = null

func finalizar_habilidad() -> void:
	if material_noche and is_instance_valid(personaje):
		var tree = personaje.get_tree()
		if tree:
			var tween_salida = personaje.create_tween()
			tween_salida.tween_method(func(val: float):
				if material_noche:
					material_noche.set_shader_parameter("intensidad_noche", val)
			, intensidad_oscuridad_noche, 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween_salida.finished.connect(_limpiar_overlay_noche)
		else:
			_limpiar_overlay_noche()
	else:
		_limpiar_overlay_noche()

	if personaje and personaje.animated_sprite and personaje.animated_sprite.material == material_definitiva:
		var sprite = personaje.animated_sprite
		var tree = personaje.get_tree()
		if tree:
			var tween = personaje.create_tween()
			tween.tween_method(func(val: float): material_definitiva.set_shader_parameter("activo", val), 1.0, 0.0, 0.15)
			tween.finished.connect(func():
				if sprite and sprite.material == material_definitiva:
					sprite.material = material_original
			)
		else:
			sprite.material = material_original

	super.finalizar_habilidad()

func _exit_tree() -> void:
	_limpiar_overlay_noche()

func _generar_eco_arcano(progreso: float) -> void:
	if not personaje or not personaje.animated_sprite:
		return

	var sprite: AnimatedSprite2D = personaje.animated_sprite
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return

	var tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return

	var eco = Sprite2D.new()
	eco.texture = tex
	eco.global_position = sprite.global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-6.0, 2.0))
	eco.global_rotation = sprite.global_rotation
	eco.global_scale = sprite.global_scale * (1.0 + progreso * 0.15)
	eco.flip_h = sprite.flip_h
	eco.flip_v = sprite.flip_v
	eco.offset = sprite.offset
	eco.centered = sprite.centered
	eco.modulate = Color(0.85, 0.2, 1.0, 0.65)

	var parent = personaje.get_parent()
	if parent:
		parent.add_child(eco)
	else:
		personaje.add_child(eco)

	var tween = eco.create_tween().set_parallel(true)
	tween.tween_property(eco, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(eco, "position:y", eco.position.y - 12.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(eco, "scale", eco.scale * 1.12, 0.3)
	tween.finished.connect(eco.queue_free)
