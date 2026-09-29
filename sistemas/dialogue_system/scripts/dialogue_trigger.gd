## dialogue_trigger.gd — Trigger reutilizable para NPCs y objetos interactivos
## Adjunta este script (o instancia dialogue_trigger.tscn) a cualquier Area2D del juego.
## No necesitas escribir código nuevo para darle diálogo a un NPC:
##   1. Arrastra dialogue_trigger.tscn como hijo del NPC
##   2. Configura dialogue_path en el Inspector
##   3. Añade al jugador al grupo "player" si aún no lo has hecho
extends Area2D

# ══════════════════════════════════════════════════════════════════
#  EXPORTACIONES (configurables en el Inspector de Godot)
# ══════════════════════════════════════════════════════════════════
@export_group("Diálogo")
## Ruta al archivo .json del diálogo que se lanzará al interactuar.
## Ejemplo: res://dialogue_system/dialogues/cap1/cap1_escena1.json
@export_file("*.json") var dialogue_path: String = ""

## Si es true, este trigger solo funciona una vez por sesión de juego.
@export var one_shot: bool = false

@export_group("Interacción")
## Acción de input que activa el diálogo cuando el jugador está en rango.
@export var interaction_key: String = "ui_accept"

## Grupo al que debe pertenecer el cuerpo para considerarse "el jugador".
## Asegúrate de añadir a Serafina/Ignia al grupo con este nombre.
@export var player_group: String = "player"

# ══════════════════════════════════════════════════════════════════
#  ESTADO INTERNO
# ══════════════════════════════════════════════════════════════════
var _player_in_range: bool = false
var _already_triggered: bool = false

# ══════════════════════════════════════════════════════════════════
#  SEÑALES
# ══════════════════════════════════════════════════════════════════
## Emitida justo antes de iniciar el diálogo, por si la escena necesita reaccionar.
signal about_to_trigger(trigger: Area2D)

# ══════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ══════════════════════════════════════════════════════════════════
#  INPUT
# ══════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed(interaction_key):
		trigger_dialogue()

# ══════════════════════════════════════════════════════════════════
#  API PÚBLICA
# ══════════════════════════════════════════════════════════════════

## Llama a esto para forzar el diálogo por código (sin que el jugador interactúe).
func trigger_dialogue() -> void:
	if dialogue_path.is_empty():
		printerr("DialogueTrigger ▸ 'dialogue_path' no configurado en nodo: ", name)
		return
	if one_shot and _already_triggered:
		return
	if DialogueManager.is_active:
		return
	_already_triggered = true
	about_to_trigger.emit(self)
	DialogueManager.start_dialogue(dialogue_path)

## Reinicia el trigger (útil si one_shot pero el juego necesita resetearlo).
func reset_trigger() -> void:
	_already_triggered = false

# ══════════════════════════════════════════════════════════════════
#  DETECCIÓN DE JUGADOR
# ══════════════════════════════════════════════════════════════════
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group):
		_player_in_range = false
