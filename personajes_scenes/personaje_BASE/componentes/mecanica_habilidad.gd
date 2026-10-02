class_name MecanicaHabilidad
extends MecanicaBase

@export_category("Configuración de Habilidad")
@export var anim_name: String = "habilidad1"
@export var anim_fallbacks: Array = []
@export var bloquear_movimiento: bool = true

var is_using_skill: bool = false
var action_timer: float = 0.0

func _ready() -> void:
	super._ready()
	if action_name.is_empty():
		action_name = "habilidad_1"

func puede_ejecutar() -> bool:
	if is_using_skill:
		return false
	return super.puede_ejecutar()

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
		
	is_using_skill = true
	if personaje:
		personaje.is_using_skill = true
		var anim_to_play = _determinar_animacion()
		action_timer = personaje.play_action_anim(anim_to_play)

func _determinar_animacion() -> String:
	if not personaje or not personaje.animated_sprite or not personaje.animated_sprite.sprite_frames:
		return anim_name
		
	var frames = personaje.animated_sprite.sprite_frames
	if frames.has_animation(anim_name):
		return anim_name
		
	for fallback in anim_fallbacks:
		if frames.has_animation(fallback):
			return fallback
			
	return anim_name

func procesar_mecanica(delta: float) -> void:
	if not is_using_skill or not personaje:
		return
		
	action_timer -= delta
	if action_timer <= 0.0:
		finalizar_habilidad()

func finalizar_habilidad() -> void:
	is_using_skill = false
	if personaje:
		personaje.is_using_skill = false

func esta_activa() -> bool:
	return is_using_skill

func bloquea_movimiento() -> bool:
	return is_using_skill and bloquear_movimiento
