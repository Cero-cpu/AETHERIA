class_name MecanicaAtaque
extends MecanicaBase

@export_category("Configuración de Ataque")
@export var anim_name: String = "ataquebasico1"
@export var anim_combo: String = "ataquebasico2"
@export var bloquear_movimiento: bool = true
@export var tiempo_reset_combo: float = 1.0

var is_attacking: bool = false
var action_timer: float = 0.0
var paso_combo: int = 1
var timer_reset: float = 0.0
var combo_buffered: bool = false

func _ready() -> void:
	super._ready()
	if action_name.is_empty():
		action_name = "ataque_basico"

func puede_ejecutar() -> bool:
	if is_attacking:
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
		paso_combo = 2 if paso_combo == 1 else 1
		timer_reset = tiempo_reset_combo

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

	if combo_buffered:
		combo_buffered = false
		ejecutar_mecanica()
	else:
		timer_reset = tiempo_reset_combo

func esta_activa() -> bool:
	return is_attacking

func bloquea_movimiento() -> bool:
	return is_attacking and bloquear_movimiento
