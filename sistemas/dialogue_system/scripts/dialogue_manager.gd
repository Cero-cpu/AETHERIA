## dialogue_manager.gd — Autoload Singleton
extends Node

# ══════════════════════════════════════════════════════════════════
#  SEÑALES PÚBLICAS
# ══════════════════════════════════════════════════════════════════
## Emitida al iniciar cualquier diálogo
signal dialogue_started(dialogue_path: String)
## Emitida al terminar o saltar un diálogo — escúchala para reactivar al jugador
signal dialogue_finished
## Emitida cada vez que se avanza a una nueva línea
signal line_changed(line_index: int, total_lines: int)
## Emitida cuando una línea tiene un "event" no vacío
## Conecta esta señal en tu escena de juego para reaccionar (dar ítems, abrir puertas, etc.)
signal event_triggered(event_id: String)

# ══════════════════════════════════════════════════════════════════
#  ESTADO PÚBLICO
# ══════════════════════════════════════════════════════════════════
## Mientras sea true el jugador debe ignorar su propio input.
## Compruébalo en serafina.gd / ignia.gd con:
##   if DialogueManager.is_active: return
var is_active: bool = false

# ══════════════════════════════════════════════════════════════════
#  RUTAS INTERNAS  (todo contenido dentro de dialogue_system/)
# ══════════════════════════════════════════════════════════════════
const _SCENE_PATH     := "res://sistemas/dialogue_system/scenes/dialogue_scene.tscn"
const _CHARS_PATH     := "res://sistemas/dialogue_system/dialogues/characters.json"
const _PORTRAITS_DIR  := "res://sistemas/dialogue_system/portraits/"
const _MISSING_PATH   := "res://sistemas/dialogue_system/portraits/missing_expression.jpg"

# ══════════════════════════════════════════════════════════════════
#  VARIABLES INTERNAS
# ══════════════════════════════════════════════════════════════════
var _ui: CanvasLayer            = null   # instancia de dialogue_scene.tscn
var _characters_data: Dictionary = {}   # contenido de characters.json
var _scene_chars: Array          = []   # personajes activos en este diálogo
var _lines: Array                = []   # todas las líneas del diálogo actual
var _index: int                  = 0    # línea actual
var _cache: Dictionary           = {}   # path → Resource  (evita recargas)

# ══════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════
func _ready() -> void:
	_load_characters_json()
	_setup_ui()

func _load_characters_json() -> void:
	var f := FileAccess.open(_CHARS_PATH, FileAccess.READ)
	if not f:
		printerr("DialogueManager ▸ characters.json no encontrado en: ", _CHARS_PATH)
		return
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		printerr("DialogueManager ▸ Error al parsear characters.json: ", json.get_error_message())
		f.close()
		return
	f.close()
	_characters_data = json.data.get("characters", {})

func _setup_ui() -> void:
	var packed: PackedScene = _get_cached(_SCENE_PATH)
	if not packed:
		printerr("DialogueManager ▸ dialogue_scene.tscn no encontrado en: ", _SCENE_PATH)
		return
	_ui = packed.instantiate()
	_ui.name = "DialogueLayer"
	# Conectar señales de la UI hacia el manager
	_ui.continue_pressed.connect(_on_continue_pressed)
	_ui.skip_pressed.connect(skip_dialogue)
	# Añadir al propio Autoload en diferido para evitar errores de parent busy
	call_deferred("add_child", _ui)
	_ui.visible = false

# ══════════════════════════════════════════════════════════════════
#  API PÚBLICA
# ══════════════════════════════════════════════════════════════════

## Inicia un diálogo. Ejemplo:
##   DialogueManager.start_dialogue("res://dialogue_system/dialogues/cap1/cap1_escena1.json")
func start_dialogue(path: String) -> void:
	if is_active:
		printerr("DialogueManager ▸ Ya hay un diálogo activo, ignorando: ", path)
		return
	if not _ui:
		printerr("DialogueManager ▸ La UI no está inicializada.")
		return

	var data := _load_dialogue_file(path)
	if data.is_empty():
		return

	_scene_chars = data.get("scene_characters", [])
	_lines       = data.get("lines", [])
	_index       = 0

	if _lines.is_empty():
		printerr("DialogueManager ▸ El archivo de diálogo no tiene líneas: ", path)
		return

	is_active = true
	_ui.visible = true
	_ui.setup_characters(_scene_chars, _characters_data)
	dialogue_started.emit(path)
	_show_current_line()

## Avanza a la siguiente línea o salta el typewriter si está escribiendo.
func next_line() -> void:
	if not is_active:
		return
	if _ui.is_typing:
		_ui.skip_typewriter()
		return
	_index += 1
	if _index >= _lines.size():
		_finish_dialogue()
	else:
		_show_current_line()

## Salta todo el diálogo restante de una vez. Misma señal que fin normal.
func skip_dialogue() -> void:
	if not is_active:
		return
	_finish_dialogue()

# ══════════════════════════════════════════════════════════════════
#  LÓGICA INTERNA
# ══════════════════════════════════════════════════════════════════

func _show_current_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker_id:  String = line.get("speaker_id", "")
	var expression:  String = line.get("expression", "idle")
	var text:        String = line.get("text", "")
	var event_id:    String = line.get("event", "")

	# Buscar slot del speaker en los personajes de la escena
	var speaker_slot := -1
	for sc in _scene_chars:
		if sc.get("id", "") == speaker_id:
			speaker_slot = sc.get("slot", -1)
			break

	# Cargar sprite del personaje que habla
	var frames: SpriteFrames = null
	if speaker_slot >= 1:
		frames = _load_sprite_frames(speaker_id, expression)
		_ui.update_character_sprite(speaker_slot, frames, expression)

	# Datos de nombre y color desde characters.json
	var char_data: Dictionary = _characters_data.get(speaker_id, {})
	var display_name: String  = char_data.get("display_name", speaker_id)
	var name_color_hex: String = char_data.get("name_color", "#FFFFFF")
	var name_color: Color = Color(name_color_hex)

	# Enviar datos a la UI (incluye portrait_frames para el cuadro izquierdo)
	_ui.show_line({
		"speaker_slot":    speaker_slot,
		"display_name":    display_name,
		"name_color":      name_color,
		"text":            text,
		"portrait_frames": frames,
		"expression":      expression,
	})

	line_changed.emit(_index, _lines.size())

	# Disparar evento (conecta la señal en tu escena de juego)
	if not event_id.is_empty():
		event_triggered.emit(event_id)

func _finish_dialogue() -> void:
	is_active = false
	_ui.hide_dialogue()
	_ui.visible = false
	_lines       = []
	_scene_chars = []
	_index       = 0
	dialogue_finished.emit()

func _on_continue_pressed() -> void:
	next_line()

# ══════════════════════════════════════════════════════════════════
#  CARGA DE RECURSOS CON CACHÉ
# ══════════════════════════════════════════════════════════════════

func _load_dialogue_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		printerr("DialogueManager ▸ Archivo de diálogo no encontrado: ", path)
		return {}
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		printerr("DialogueManager ▸ Error de JSON en: ", path, " — ", json.get_error_message())
		f.close()
		return {}
	f.close()
	return json.data

## Estrategia de carga de sprites (en orden de prioridad):
##
## OPCIÓN A — SpriteFrames .tres (RECOMENDADA para equipos con diseñador):
##   Ruta: res://dialogue_system/portraits/{character_id}/frames.tres
##   El diseñador exporta un único archivo .tres por personaje que contiene
##   TODAS las expresiones como animaciones ("idle", "smile", "angry"…).
##   Ventaja: el arte se versiona por personaje en una sola carpeta, fácil de
##   actualizar sin tocar código ni JSONs. Las expresiones son animation names.
##
## OPCIÓN B — Texturas estáticas por expresión (fallback automático):
##   Ruta: res://dialogue_system/portraits/{character_id}_{expression}.jpg/.png
##   Si no existe frames.tres, el sistema intenta cargar la textura directamente
##   y crea un SpriteFrames de un solo frame en memoria (solo para ese momento).
##   Útil durante producción temprana cuando aún no hay .tres listo.
##
## FALLBACK FINAL: muestra missing_expression.jpg para que el equipo detecte
##   visualmente qué sprite falta durante desarrollo.
func _load_sprite_frames(character_id: String, expression: String) -> SpriteFrames:
	# — OPCIÓN A: SpriteFrames .tres por personaje —
	var tres_path := _PORTRAITS_DIR + character_id + "/frames.tres"
	var cache_key := character_id + "::frames"
	if _cache.has(cache_key):
		return _cache[cache_key]
	if ResourceLoader.exists(tres_path):
		var frames: SpriteFrames = _get_cached(tres_path)
		_cache[cache_key] = frames
		return frames

	# — OPCIÓN B: textura estática por expresión —
	for ext in [".png", ".jpg", ".jpeg", ".webp"]:
		var tex_path: String = _PORTRAITS_DIR + character_id + "/" + expression + String(ext)
		if ResourceLoader.exists(tex_path):
			var tex_key: String = tex_path + "::frames"
			if _cache.has(tex_key):
				return _cache[tex_key]
			var tex: Texture2D = _get_cached(tex_path)
			if tex:
				var frames := SpriteFrames.new()
				if not frames.has_animation("idle"):
					frames.add_animation("idle")
				frames.add_frame("idle", tex)
				_cache[tex_key] = frames
				return frames

	# — FALLBACK: missing_expression —
	printerr("DialogueManager ▸ Sin sprite para '", character_id, "' (expresión: '", expression, "'). Usando fallback.")
	const mk := "__missing__"
	if _cache.has(mk):
		return _cache[mk]
	var missing := SpriteFrames.new()
	if ResourceLoader.exists(_MISSING_PATH):
		var mtex: Texture2D = _get_cached(_MISSING_PATH)
		if mtex:
			if not missing.has_animation("idle"):
				missing.add_animation("idle")
			missing.add_frame("idle", mtex)
	_cache[mk] = missing
	return missing

func _get_cached(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var res := load(path)
	_cache[path] = res
	return res
