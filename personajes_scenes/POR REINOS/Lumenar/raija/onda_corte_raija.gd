class_name OndaCorteRaija
extends Area2D

# ==========================================================
# ONDA DE CORTE DE ENERGÍA (ESPADAZO) DE RAIJA
# Proyectil de onda corta que sale impulsado hacia el frente
# al realizar ataques básicos con Raija.
# ==========================================================

@export var velocidad: float = 650.0
@export var tiempo_vida_maximo: float = 0.35
@export var dano: float = 18.0

var direccion: Vector2 = Vector2.RIGHT
var _tiempo_transcurrido: float = 0.0
var _ya_impacto: bool = false

@onready var sprite_node: Node = get_node_or_null("SpriteOnda")

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta
	_tiempo_transcurrido += delta

	# Actualizar desvanecimiento del shader
	if sprite_node and sprite_node.material:
		var prog = clampf(_tiempo_transcurrido / tiempo_vida_maximo, 0.0, 1.0)
		sprite_node.material.set_shader_parameter("desvanecimiento", prog)

	if _tiempo_transcurrido >= tiempo_vida_maximo:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _ya_impacto:
		return
	if area.owner is PersonajeBase:
		return
	var objetivo = area.owner if area.owner else area
	if objetivo and objetivo != self and objetivo.has_method("recibir_dano"):
		_ya_impacto = true
		objetivo.recibir_dano(dano, global_position)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _ya_impacto or body is PersonajeBase:
		return
	if body.has_method("recibir_dano"):
		_ya_impacto = true
		body.recibir_dano(dano, global_position)
		queue_free()
