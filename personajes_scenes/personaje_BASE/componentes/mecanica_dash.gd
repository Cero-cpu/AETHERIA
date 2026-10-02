class_name MecanicaDash
extends MecanicaBase

@export_category("Configuración de Dash")
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.18
@export var anim_name: String = "dash"

var is_dashing: bool = false
var dash_timer: float = 0.0

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
	dash_timer = dash_duration
	if personaje:
		personaje.is_dashing = true
		personaje.play_action_anim(anim_name)

func procesar_mecanica(delta: float) -> void:
	if not is_dashing or not personaje:
		return
		
	dash_timer -= delta
	personaje.velocity.x = personaje.facing_direction * dash_speed
	personaje.velocity.y = 0.0
	personaje.play_anim_if_exists(anim_name)
	
	if dash_timer <= 0.0:
		finalizar_dash()

func finalizar_dash() -> void:
	is_dashing = false
	if personaje:
		personaje.is_dashing = false

func esta_activa() -> bool:
	return is_dashing
