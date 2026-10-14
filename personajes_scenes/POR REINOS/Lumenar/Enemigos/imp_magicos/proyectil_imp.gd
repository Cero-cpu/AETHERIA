class_name ProyectilImp
extends Area2D

# ==========================================================
# PROYECTIL MÁGICO DEL IMP (REINO LUMENAR)
# Disparado por el Imp Mágico volador hacia la posición del jugador.
# Se desplaza en línea recta, rota según su dirección e inflige
# daño al impactar con el jugador o se disuelve al chocar con terreno.
# ==========================================================

@export var velocidad: float = 240.0
@export var dano: float = 10.0
@export var tiempo_vida_maximo: float = 4.0

var direccion: Vector2 = Vector2.RIGHT
var _ya_impacto: bool = false

@onready var sprite_orbe: CanvasItem = $SpriteOrbe
@onready var particulas: CPUParticles2D = get_node_or_null("Particulas")

func _ready() -> void:
	# Capa 8 (Hitbox enemiga/proyectil) detecta Capa 1 (Mundo) y Capa 2 (Jugador)
	collision_layer = 8
	collision_mask = 1 | 2

	add_to_group("proyectiles_enemigos")

	rotation = direccion.angle()

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Temporizador de autodestrucción por tiempo de vida
	var timer = get_tree().create_timer(tiempo_vida_maximo)
	timer.timeout.connect(func():
		if not _ya_impacto:
			_destruir()
	)

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	if _ya_impacto:
		return

	# Ignorar al propio imp y otros enemigos
	if body.is_in_group("enemigos") or body is ImpMagico:
		return

	# Dañar al jugador si colisiona con él
	if body.is_in_group("jugador") or body.has_method("recibir_dano") or body.has_method("take_damage"):
		_aplicar_dano_y_destruir(body)
		return

	# Si choca con el escenario/paredes (Capa 1)
	_destruir()

func _on_area_entered(area: Area2D) -> void:
	if _ya_impacto:
		return

	# Ignorar áreas de otros enemigos
	var dueno = area.owner if area.owner else area
	if dueno.is_in_group("enemigos") or dueno is ImpMagico:
		return

	# Detectar Hurtbox del jugador
	if dueno.is_in_group("jugador") or dueno.has_method("recibir_dano") or dueno.has_method("take_damage"):
		_aplicar_dano_y_destruir(dueno)

func _aplicar_dano_y_destruir(objetivo: Node) -> void:
	_ya_impacto = true
	if objetivo.has_method("recibir_dano"):
		objetivo.recibir_dano(dano, global_position)
	elif objetivo.has_method("take_damage"):
		objetivo.take_damage(dano)
	_destruir()

func _destruir() -> void:
	_ya_impacto = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)

	# Micro animación de disolución/impacto
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.5, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
