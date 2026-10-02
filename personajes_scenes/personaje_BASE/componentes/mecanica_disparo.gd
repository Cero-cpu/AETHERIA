class_name MecanicaDisparo
extends MecanicaBase

# ==========================================================
# EJEMPLO DE MECÁNICA DE DISPARO (Para personajes Pistoleros)
# ==========================================================

@export_category("Configuración de Disparo")
@export var cadencia_disparo: float = 0.25 # Tiempo entre disparos en segundos
@export var anim_disparo: String = "disparar"
@export var escena_proyectil: PackedScene

var cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	if action_name.is_empty():
		action_name = "ataque_basico"

func puede_ejecutar() -> bool:
	if cooldown_timer > 0.0:
		return false
	return super.puede_ejecutar()

func ejecutar_mecanica() -> void:
	if not puede_ejecutar():
		return
		
	cooldown_timer = cadencia_disparo
	if personaje:
		personaje.play_action_anim(anim_disparo)
		# Si hay una escena de proyectil configurada, se instancia
		if escena_proyectil:
			var bala = escena_proyectil.instantiate()
			var spawn_pos = personaje.global_position
			bala.global_position = spawn_pos
			personaje.get_parent().add_child(bala)

func procesar_mecanica(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
