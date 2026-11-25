extends Node2D

const DIALOGUE_PATH := "res://sistemas/dialogue_system/dialogues/test_reunion_general.json"

@onready var restart_hint: Label = $UI/Panel/VBox/RestartHint

func _ready() -> void:
	# Conectar señales del DialogueManager para actualizar UI de prueba
	if DialogueManager.has_signal("dialogue_finished"):
		DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	
	# Iniciar el diálogo tras un breve instante para inicialización de escena
	await get_tree().create_timer(0.4).timeout
	_start_test()

func _start_test() -> void:
	if restart_hint:
		restart_hint.visible = false
	DialogueManager.start_dialogue(DIALOGUE_PATH)

func _unhandled_input(event: InputEvent) -> void:
	# Permitir reiniciar con la tecla R
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			if not DialogueManager.is_active:
				_start_test()
		elif event.keycode == KEY_ESCAPE:
			# Si el diálogo está activo, saltarlo con escape
			if DialogueManager.is_active:
				DialogueManager.skip_dialogue()

func _on_dialogue_finished() -> void:
	if restart_hint:
		restart_hint.visible = true
