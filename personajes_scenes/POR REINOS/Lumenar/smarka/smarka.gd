extends CharacterBody2D

@export var velocidad: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Dirección de -1 a 1 en cada eje (flechas / WASD según tu Input Map)
	var direccion := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = direccion * velocidad
	move_and_slide()

	if direccion != Vector2.ZERO:
		sprite.play("walk")
		# Voltear el sprite según hacia dónde camina
		if direccion.x != 0:
			sprite.flip_h = direccion.x < 0
	else:
		sprite.play("idle")  # o sprite.stop() si no tienes animación idle
