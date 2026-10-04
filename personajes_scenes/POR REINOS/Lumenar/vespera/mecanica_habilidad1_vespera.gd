class_name MecanicaHabilidad1Vespera
extends MecanicaHabilidad

# ==============================================================================
# MECÁNICA DE HABILIDAD 1 (CHASQUIDO TEMPORAL) - VESPERA
# Ejecuta la animación "habilidad1" (chasquido de dedos) y despliega una
# onda de distorsión y parálisis del tiempo con desaturación cromática y
# resplandor arcano. Paraliza (stun) a todos los enemigos dentro del rango.
# ==============================================================================

const ShaderParalisisScript = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/paralisis_tiempo_vespera.gdshader")

@export_category("Configuración Chasquido Temporal")
@export var delay_chasquido: float = 0.25 # Momento exacto del chasquido en la animación
@export var duracion_onda: float = 0.6 # Duración de la expansión de la onda temporal
@export var desaturacion_tiempo: float = 0.85

@export_category("Configuración Parálisis / Stun")
@export var radio_stun: float = 280.0 # Radio en píxeles del área de parálisis
@export var duracion_stun: float = 1.0 # Duración del stun en segundos

var overlay_canvas: CanvasLayer = null
var color_rect_efecto: ColorRect = null
var material_shader: ShaderMaterial = null
var tween_efecto: Tween = null

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
		
	is_using_skill = true
	if personaje:
		personaje.is_using_skill = true
		var anim = _determinar_animacion()
		action_timer = personaje.play_action_anim(anim)
		
		# Calcular la sincronización al final de la animación (13 FPS)
		var delay_efecto: float = action_timer
		if personaje.animated_sprite and personaje.animated_sprite.sprite_frames:
			if personaje.animated_sprite.sprite_frames.has_animation(anim):
				var count = personaje.animated_sprite.sprite_frames.get_frame_count(anim)
				var fps = personaje.animated_sprite.sprite_frames.get_animation_speed(anim)
				if fps > 0.0 and count > 0:
					# Disparar justo al alcanzar el cuadro final del chasquido (~frame 8 @ 13fps)
					delay_efecto = float(count - 1) / fps if count > 1 else float(count) / fps
		
		# Programar la activación del efecto visual del chasquido justo al final de la animación
		var tree = personaje.get_tree()
		if tree:
			tree.create_timer(delay_efecto).timeout.connect(_activar_chasquido_temporal)

func _activar_chasquido_temporal() -> void:
	if not is_instance_valid(personaje):
		return
		
	_crear_overlay_pantalla()
	_animar_efecto_temporal()
	_aplicar_stun_enemigos_en_rango()

func _aplicar_stun_enemigos_en_rango() -> void:
	if not is_instance_valid(personaje):
		return

	var tree = personaje.get_tree()
	if not tree:
		return

	var pos_centro = personaje.global_position
	var rango_sq = radio_stun * radio_stun

	var enemigos = tree.get_nodes_in_group("enemigos")
	for enemigo in enemigos:
		if not is_instance_valid(enemigo) or enemigo == personaje:
			continue

		var dist_sq = pos_centro.distance_squared_to(enemigo.global_position)
		if dist_sq <= rango_sq:
			if enemigo.has_method("aplicar_stun"):
				enemigo.aplicar_stun(duracion_stun)

func _crear_overlay_pantalla() -> void:
	# Limpiar overlay anterior si existiera
	_limpiar_overlay()
	
	overlay_canvas = CanvasLayer.new()
	overlay_canvas.layer = 10 # Capa por encima del juego pero bajo la UI principal
	
	var back_buffer = BackBufferCopy.new()
	back_buffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	back_buffer.rect = Rect2(0, 0, 1920, 1080)
	overlay_canvas.add_child(back_buffer)
	
	color_rect_efecto = ColorRect.new()
	color_rect_efecto.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect_efecto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	material_shader = ShaderMaterial.new()
	material_shader.shader = ShaderParalisisScript
	
	# Calcular la posición en pantalla (0.0 a 1.0) del personaje para centrar la onda
	var centro_uv = Vector2(0.5, 0.5)
	if personaje:
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

	material_shader.set_shader_parameter("centro_pantalla", centro_uv)
	material_shader.set_shader_parameter("progreso", 0.0)
	material_shader.set_shader_parameter("desaturacion", desaturacion_tiempo)
	material_shader.set_shader_parameter("brillo_relampago", 1.2)
	
	color_rect_efecto.material = material_shader
	overlay_canvas.add_child(color_rect_efecto)
	
	var tree = personaje.get_tree()
	if tree and tree.root:
		tree.root.add_child(overlay_canvas)

func _animar_efecto_temporal() -> void:
	if not material_shader:
		return
		
	if tween_efecto and tween_efecto.is_valid():
		tween_efecto.kill()
		
	tween_efecto = personaje.create_tween()
	
	# Destello inicial de chasquido
	tween_efecto.tween_property(material_shader, "shader_parameter/brillo_relampago", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Expansión de la onda de tiempo congelado
	var tween_onda = personaje.create_tween()
	tween_onda.tween_property(material_shader, "shader_parameter/progreso", 1.0, duracion_onda).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Desvanecimiento progresivo del efecto al finalizar la onda
	tween_onda.tween_property(material_shader, "shader_parameter/desaturacion", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween_onda.finished.connect(_limpiar_overlay)

func _limpiar_overlay() -> void:
	if is_instance_valid(overlay_canvas):
		overlay_canvas.queue_free()
		overlay_canvas = null
	color_rect_efecto = null
	material_shader = null

func finalizar_habilidad() -> void:
	super.finalizar_habilidad()

func _exit_tree() -> void:
	_limpiar_overlay()

