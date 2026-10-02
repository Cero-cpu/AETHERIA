class_name MecanicaAtaque
extends MecanicaBase

@export_category("Configuración de Ataque")
@export var anim_name: String = "ataquebasico"
@export var bloquear_movimiento: bool = true

var is_attacking: bool = false
var action_timer: float = 0.0

func _ready() -> void:
	super._ready()
	if action_name.is_empty():
		action_name = "ataque_basico"

func puede_ejecutar() -> bool:
	if is_attacking:
		return false
	return super.puede_ejecutar()

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
	is_attacking = true
	if personaje:
		personaje.is_attacking = true
		action_timer = personaje.play_action_anim(anim_name)

func procesar_mecanica(delta: float) -> void:
	if not is_attacking or not personaje:
		return
		
	action_timer -= delta
	if action_timer <= 0.0:
		finalizar_ataque()

func finalizar_ataque() -> void:
	is_attacking = false
	if personaje:
		personaje.is_attacking = false

func esta_activa() -> bool:
	return is_attacking

func bloquea_movimiento() -> bool:
	return is_attacking and bloquear_movimiento
