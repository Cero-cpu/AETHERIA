## dialogue_box.gd — Controlador de la UI del diálogo
## Adjunto al nodo raíz (DialogueLayer / CanvasLayer) de dialogue_scene.tscn
## REGLA: Este script NUNCA crea nodos. Solo referencia los ya existentes en la escena.
extends CanvasLayer

# ══════════════════════════════════════════════════════════════════
#  SEÑALES (escuchadas por DialogueManager)
# ══════════════════════════════════════════════════════════════════
## Avanzar una línea (también se emite con ui_accept)
signal continue_pressed
## Saltar todo el diálogo restante
signal skip_pressed

# ══════════════════════════════════════════════════════════════════
#  REFERENCIAS A NODOS PRE-EXISTENTES EN LA ESCENA
#  Todos estos nodos deben estar armados en dialogue_scene.tscn.
#  Si renombras un nodo en el editor, actualiza la ruta aquí.
# ══════════════════════════════════════════════════════════════════

# — Raíz de la escena (Control full-rect)
@onready var _scene: Control = $DialogueScene

# — Cuadro de retrato (izquierda)
@onready var _portrait_box:    Panel            = $DialogueScene/DialogueBox/PortraitBox
@onready var _portrait_sprite: AnimatedSprite2D = $DialogueScene/DialogueBox/PortraitBox/PortraitSprite

# — Cuadrito del nombre (arriba a la derecha del retrato)
@onready var _name_box:   Panel = $DialogueScene/DialogueBox/TextArea/NameBox
@onready var _name_label: Label = $DialogueScene/DialogueBox/TextArea/NameBox/NameLabel

# — Cuadro del texto (debajo del nombre)
@onready var _text_box:      Panel         = $DialogueScene/DialogueBox/TextArea/TextBox
@onready var _dlg_text:      RichTextLabel = $DialogueScene/DialogueBox/TextArea/TextBox/DialogueText
@onready var _continue_ind:  Label         = $DialogueScene/DialogueBox/TextArea/TextBox/ContinueIndicator

# — Botón saltar (esquina sup-der)
@onready var _skip_btn: Button = $DialogueScene/DialogueBox/SkipButton

# Slots de personaje de fondo — se llenan en _ready() según SLOT_COUNT
var _slot_nodes:   Array[Control]          = []
var _sprite_nodes: Array[AnimatedSprite2D] = []

# ══════════════════════════════════════════════════════════════════
#  CONSTANTES
# ══════════════════════════════════════════════════════════════════
const SLOT_COUNT    := 4
const TYPING_SPEED  := 0.035   # segundos por carácter
const DIM_COLOR     := Color(0.45, 0.45, 0.55, 1.0)
const BRIGHT_COLOR  := Color(1.0,  1.0,  1.0,  1.0)
const SCALE_SPEAKER := Vector2(1.06, 1.06)
const SCALE_SILENT  := Vector2(0.94, 0.94)
const BLINK_SPEED   := 0.004   # velocidad parpadeo ▼

# ══════════════════════════════════════════════════════════════════
#  ESTADO DEL TYPEWRITER
# ══════════════════════════════════════════════════════════════════
## True mientras el texto se está escribiendo carácter a carácter.
var is_typing: bool = false
var _typing_timer: float = 0.0

# ══════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	_collect_slot_refs()
	_skip_btn.pressed.connect(_on_skip_btn_pressed)
	# Ocultar slots y el indicador al inicio
	for slot in _slot_nodes:
		slot.visible = false
	_continue_ind.visible = false

func _collect_slot_refs() -> void:
	## Recoge los 4 slots de fondo y sus sprites del árbol de escena.
	## Formato esperado: CharacterSlot1…4 → Sprite1…4
	_slot_nodes.clear()
	_sprite_nodes.clear()
	for i in range(1, SLOT_COUNT + 1):
		var slot   := _scene.get_node("CharacterSlot%d" % i) as Control
		var sprite := slot.get_node("Sprite%d" % i) as AnimatedSprite2D
		_slot_nodes.append(slot)
		_sprite_nodes.append(sprite)

# ══════════════════════════════════════════════════════════════════
#  API LLAMADA POR DialogueManager
# ══════════════════════════════════════════════════════════════════

## Muestra la barra de diálogo y configura los slots de fondo.
## scene_chars: Array de { "id": "serafina", "slot": 2, "initial_expression": "idle" }
## chars_data:  Dictionary del characters.json
func setup_characters(scene_chars: Array, chars_data: Dictionary) -> void:
	_scene.visible = true

	# Apagar todos los slots de fondo primero
	for i in range(SLOT_COUNT):
		_slot_nodes[i].visible = false
		_sprite_nodes[i].modulate = BRIGHT_COLOR
		_sprite_nodes[i].scale    = Vector2.ONE

	# Encender los usados
	for sc in scene_chars:
		var idx: int = sc.get("slot", 1) - 1   # slot 1-4 → índice 0-3
		if idx < 0 or idx >= SLOT_COUNT:
			continue
		_slot_nodes[idx].visible = true
		_sprite_nodes[idx].modulate = DIM_COLOR

## Actualiza el sprite de un slot DE FONDO con SpriteFrames y expresión.
func update_character_sprite(slot: int, frames: SpriteFrames, expression: String) -> void:
	var idx := slot - 1
	if idx < 0 or idx >= SLOT_COUNT or not _slot_nodes[idx].visible:
		return
	var sp := _sprite_nodes[idx]
	if frames:
		sp.sprite_frames = frames
		if frames.has_animation(expression):
			sp.play(expression)
		elif frames.has_animation("idle"):
			sp.play("idle")
		elif frames.get_animation_names().size() > 0:
			sp.play(frames.get_animation_names()[0])

## Actualiza el retrato en el cuadro izquierdo de la barra inferior.
## Llamar después de update_character_sprite() para reflejar al hablante actual.
func update_portrait(frames: SpriteFrames, expression: String) -> void:
	if frames == null:
		_portrait_sprite.visible = false
		return
	_portrait_sprite.visible = true
	_portrait_sprite.sprite_frames = frames
	if frames.has_animation(expression):
		_portrait_sprite.play(expression)
	elif frames.has_animation("idle"):
		_portrait_sprite.play("idle")
	elif frames.get_animation_names().size() > 0:
		_portrait_sprite.play(frames.get_animation_names()[0])

## Muestra los datos de una línea: nombre, color, retrato, texto y resaltado.
func show_line(line_data: Dictionary) -> void:
	var speaker_slot:  int    = line_data.get("speaker_slot", -1)
	var display_name:  String = line_data.get("display_name", "")
	var name_color:    Color  = line_data.get("name_color", Color.WHITE)
	var text:          String = line_data.get("text", "")
	var portrait:      SpriteFrames = line_data.get("portrait_frames", null)
	var expression:    String = line_data.get("expression", "idle")

	# — Nombre
	_name_label.text = display_name
	_name_label.add_theme_color_override("font_color", name_color)
	# Ocultar NameBox si es narrador (sin nombre)
	_name_box.visible = not display_name.is_empty()

	# — Retrato en el cuadrito izquierdo
	update_portrait(portrait, expression)

	# — Resaltar personaje activo en los slots de fondo
	_update_speaker_highlight(speaker_slot)

	# — Iniciar efecto de escritura
	_start_typewriter(text)

## Salta el typewriter: muestra todo el texto inmediatamente.
func skip_typewriter() -> void:
	if not is_typing:
		return
	is_typing = false
	_dlg_text.visible_characters = -1
	_continue_ind.visible = true

## Oculta todo y limpia el estado.
func hide_dialogue() -> void:
	is_typing = false
	_continue_ind.visible = false
	_dlg_text.text = ""
	_name_label.text = ""
	_portrait_sprite.visible = false
	for i in range(SLOT_COUNT):
		_slot_nodes[i].visible = false

# ══════════════════════════════════════════════════════════════════
#  TYPEWRITER (usa visible_characters para respetar BBCode)
# ══════════════════════════════════════════════════════════════════
func _start_typewriter(text: String) -> void:
	_dlg_text.text = text
	_dlg_text.visible_characters = 0
	_continue_ind.visible = false
	is_typing = true
	_typing_timer = 0.0

func _process(delta: float) -> void:
	if is_typing:
		_typing_timer += delta
		var total := _dlg_text.get_total_character_count()
		var show_count := int(_typing_timer / TYPING_SPEED)
		_dlg_text.visible_characters = min(show_count, total)

		if _dlg_text.visible_characters >= total:
			is_typing = false
			_dlg_text.visible_characters = -1
			_continue_ind.visible = true

	# Parpadeo sinusoidal del indicador ▼
	if _continue_ind.visible:
		_continue_ind.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() * BLINK_SPEED)

# ══════════════════════════════════════════════════════════════════
#  RESALTADO DE PERSONAJE ACTIVO (slots de fondo)
# ══════════════════════════════════════════════════════════════════
func _update_speaker_highlight(speaker_slot: int) -> void:
	for i in range(SLOT_COUNT):
		if not _slot_nodes[i].visible:
			continue
		var sp := _sprite_nodes[i]
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		if i == speaker_slot - 1:
			tween.tween_property(sp, "modulate", BRIGHT_COLOR, 0.18)
			tween.parallel().tween_property(sp, "scale", SCALE_SPEAKER, 0.18)
		else:
			tween.tween_property(sp, "modulate", DIM_COLOR, 0.18)
			tween.parallel().tween_property(sp, "scale", SCALE_SILENT, 0.18)

# ══════════════════════════════════════════════════════════════════
#  INPUT — avanzar con ui_accept, bloquea propagación al juego
# ══════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		continue_pressed.emit()
		get_viewport().set_input_as_handled()

func _on_skip_btn_pressed() -> void:
	skip_pressed.emit()
