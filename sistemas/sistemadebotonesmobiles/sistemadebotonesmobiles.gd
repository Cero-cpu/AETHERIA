extends CanvasLayer

signal ataque_basico_pressed
signal dash_pressed
signal habilidad_1_pressed
signal habilidad_2_pressed
signal habilidad_definitiva_pressed
signal salto_pressed

@onready var joystick = $Control/LeftContainer/VirtualJoystick
@onready var boton_ataque = $Control/RightContainer/BotonAtaqueBasico
@onready var boton_dash = $Control/RightContainer/BotonDash
@onready var boton_habilidad_1 = $Control/RightContainer/BotonHabilidad1
@onready var boton_habilidad_definitiva = $Control/RightContainer/BotonHabilidadDefinitiva
@onready var boton_saltar = $Control/RightContainer/BotonSaltar

func _ready() -> void:
	# Mantener la UI de controles táctiles por encima del gameplay
	layer = 10
	
	if boton_ataque:
		boton_ataque.button_down.connect(_on_ataque_pressed)
	if boton_dash:
		boton_dash.button_down.connect(_on_dash_pressed)
	if boton_habilidad_1:
		boton_habilidad_1.button_down.connect(_on_habilidad_1_pressed)
	if boton_habilidad_definitiva:
		boton_habilidad_definitiva.button_down.connect(_on_habilidad_definitiva_pressed)
	if boton_saltar:
		boton_saltar.button_down.connect(_on_salto_pressed)

func _on_ataque_pressed() -> void:
	ataque_basico_pressed.emit()

func _on_dash_pressed() -> void:
	dash_pressed.emit()

func _on_habilidad_1_pressed() -> void:
	habilidad_1_pressed.emit()

func _on_habilidad_definitiva_pressed() -> void:
	habilidad_definitiva_pressed.emit()
	habilidad_2_pressed.emit()

func _on_salto_pressed() -> void:
	salto_pressed.emit()
