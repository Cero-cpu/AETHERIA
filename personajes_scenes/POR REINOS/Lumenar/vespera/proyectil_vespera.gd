class_name ProyectilVespera
extends Area2D

# ==========================================================
# PROYECTIL DE BOLA DE ENERGÍA DE VESPERA
# Avanza en línea recta hasta impactar una colisión o agotar su tiempo de vida
# ==========================================================

@export var velocidad: float = 500.0
@export var tiempo_vida_maximo: float = 4.0
@export var dano: float = 20.0  # Leído por el Hurtbox del enemigo

var direccion: Vector2 = Vector2.RIGHT
var _ya_impacto: bool = false  # Evita doble daño

func _ready() -> void:
	area_entered.connect(_on_area_entered)

	# Temporizador de seguridad para destruir de la memoria RAM
	var timer = get_tree().create_timer(tiempo_vida_maximo)
	timer.timeout.connect(_destruir)

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

func _on_area_entered(area: Area2D) -> void:
	if _ya_impacto:
		return
	# Ignorar si el área pertenece al personaje jugador
	if area.owner is PersonajeBase:
		return
	# Verificar si es el Hitbox/Hurtbox de un enemigo
	var objetivo = area.owner if area.owner else area
	if objetivo and objetivo != self and objetivo.has_method("recibir_dano"):
		_ya_impacto = true
		objetivo.recibir_dano(dano, global_position)
		_destruir()

func _destruir() -> void:
	queue_free()
