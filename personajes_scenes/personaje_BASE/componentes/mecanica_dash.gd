class_name MecanicaDash
extends MecanicaBase

@export_category("Configuración de Dash")
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.25
@export var anim_name: String = "dash"
@export var sincronizar_con_duracion_anim: bool = true
@export var ajustar_velocidad_animacion: bool = true

var is_dashing: bool = false
var dash_timer: float = 0.0
var speed_scale_original: float = 1.0

func _ready() -> void:
	super._ready()
	if action_name.is_empty():
		action_name = "dash"

func puede_ejecutar() -> bool:
	if is_dashing:
		return false
	return super.puede_ejecutar()

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
	is_dashing = true
	if personaje:
		personaje.is_dashing = true
		var anim_dur = personaje.play_action_anim(anim_name)
		if sincronizar_con_duracion_anim and anim_dur > 0.0:
			dash_timer = anim_dur
		else:
			dash_timer = dash_duration
			if ajustar_velocidad_animacion and anim_dur > 0.0 and personaje.animated_sprite:
				speed_scale_original = personaje.animated_sprite.speed_scale
				personaje.animated_sprite.speed_scale = anim_dur / dash_duration
	else:
		dash_timer = dash_duration

func procesar_mecanica(delta: float) -> void:
	if not is_dashing or not personaje:
		return
		
	dash_timer -= delta
	personaje.velocity.x = personaje.facing_direction * dash_speed
	personaje.velocity.y = 0.0
	
	if dash_timer <= 0.0:
		finalizar_dash()

func finalizar_dash() -> void:
	is_dashing = false
	if personaje:
		personaje.is_dashing = false
		if personaje.animated_sprite and speed_scale_original > 0.0:
			personaje.animated_sprite.speed_scale = speed_scale_original

func esta_activa() -> bool:
	return is_dashing
