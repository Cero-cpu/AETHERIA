class_name IntroCinematica
extends Control

## Señal que avisa al resto del juego (ej. gestor de audio) que la intro terminó
signal secuencia_terminada

@export_category("Configuración de Transición")
## Escena a la que transicionará al terminar (ej. la primera capa del mundo).
@export_file("*.tscn") var ruta_siguiente_escena: String = "res://niveles/capa_1.tscn"

@export_category("Tiempos de Animación")
@export var tiempo_aparicion: float = 2.0
@export var tiempo_brillo: float = 0.3
@export var tiempo_espera: float = 1.5
@export var tiempo_desaparicion: float = 1.5

@export_category("Efectos Visuales")
@export var escala_inicial: Vector2 = Vector2(0.9, 0.9)
@export var escala_maxima: Vector2 = Vector2(1.05, 1.05)
@export var intensidad_brillo: float = 1.5

@onready var logo: TextureRect = $TextureRect

func _ready() -> void:
	_validar_nodos()
	_preparar_estado_inicial()
	iniciar_secuencia()

func _validar_nodos() -> void:
	# Previene crasheos silenciosos si el nodo fue renombrado o borrado por error
	assert(logo != null, "Error crítico: Nodo TextureRect no encontrado en la escena.")

func _preparar_estado_inicial() -> void:
	logo.modulate = Color.TRANSPARENT
	logo.scale = escala_inicial
	# Se centra el pivote dinámicamente asegurando precisión sin importar el tamaño de la imagen
	logo.pivot_offset = logo.size / 2.0

func iniciar_secuencia() -> void:
	var tween: Tween = create_tween()
	
	# 1. Fade In y Acercamiento
	tween.tween_property(logo, "modulate", Color.WHITE, tiempo_aparicion).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(logo, "scale", escala_maxima, tiempo_aparicion).set_trans(Tween.TRANS_SINE)
	
	# 2. Efecto de Resplandor (Glow)
	var color_brillante := Color(intensidad_brillo, intensidad_brillo, intensidad_brillo, 1.0)
	tween.tween_property(logo, "modulate", color_brillante, tiempo_brillo)
	
	# 3. Estabilización
	tween.tween_property(logo, "modulate", Color.WHITE, 0.5)
	tween.tween_property(logo, "scale", Vector2.ONE, 1.0)
	
	# 4. Pausa dramática
	tween.tween_interval(tiempo_espera)
	
	# 5. Fade Out al negro
	tween.tween_property(logo, "modulate", Color.TRANSPARENT, tiempo_desaparicion)
	
	# 6. Finalización
	tween.tween_callback(_al_terminar_secuencia)

func _al_terminar_secuencia() -> void:
	# Emitimos la señal por si otro nodo necesita reaccionar al fin de la intro
	secuencia_terminada.emit()
	_cargar_siguiente_escena()

func _cargar_siguiente_escena() -> void:
	if ruta_siguiente_escena.is_empty():
		printerr("IntroCinematica: Falta configurar la ruta de la siguiente escena para Runna Terra.")
		return
		
	var error: int = get_tree().change_scene_to_file(ruta_siguiente_escena)
	
	if error != OK:
		printerr("IntroCinematica: Fallo crítico al cargar el nivel. Código de error: ", error)
