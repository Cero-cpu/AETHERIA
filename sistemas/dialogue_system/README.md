# 📖 Sistema de Diálogos — AETHERIA
**Estilo Undertale / SAO Lost Song · Godot 4.7.2**

---

## 📁 Estructura de la carpeta

```
dialogue_system/
├── scripts/
│   ├── dialogue_manager.gd     ← Autoload global (singleton)
│   ├── dialogue_box.gd         ← Controlador de la UI (adjunto a la escena)
│   └── dialogue_trigger.gd     ← Trigger reutilizable para NPCs
├── scenes/
│   ├── dialogue_scene.tscn     ← Escena completa: CanvasLayer + 4 slots + caja
│   └── dialogue_trigger.tscn   ← Escena trigger lista para arrastrar a NPCs
├── portraits/
│   ├── missing_expression.jpg  ← Fallback visual si falta un sprite
│   ├── serafina/
│   │   └── frames.tres         ← (Tú lo creas: SpriteFrames con animaciones)
│   ├── ignia/
│   │   └── frames.tres
│   └── personaje_expresion.png ← Alternativa: texturas sueltas por expresión
└── dialogues/
	├── characters.json          ← Registro central de personajes
	└── cap1/
		└── cap1_escena1.json   ← Ejemplo de diálogo
```

---

## 🔧 Paso 1 — Registrar el Autoload

> Esto es lo ÚNICO que conecta este sistema con el resto del proyecto.

1. Abre Godot → **Proyecto → Configuración del Proyecto → Autoload**
2. Haz clic en la carpeta y navega a:
   `res://dialogue_system/scripts/dialogue_manager.gd`
3. Pon como nombre: `DialogueManager`
4. Activa "Enable" y haz clic en **Añadir**

Desde ese momento cualquier escena puede llamar `DialogueManager.start_dialogue(...)`.

---

## 🎮 Paso 2 — Pausar al jugador durante el diálogo

Agrega este bloque al inicio de `_physics_process` en `serafina.gd` e `ignia.gd`:

```gdscript
func _physics_process(delta: float) -> void:
	# Bloquear movimiento mientras hay un diálogo activo
	if DialogueManager.is_active:
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return
	# ... resto del código de movimiento ...
```

Esto no pausa el árbol completo, así que las animaciones de fondo siguen corriendo.

---

## 🎭 Paso 3 — Abrir y ajustar la escena en el editor

1. Abre `res://dialogue_system/scenes/dialogue_scene.tscn` en Godot
2. En la vista **2D**, verás los 4 CharacterSlots como rectángulos y los 4 sprites
3. **Arrastra cada Sprite1/2/3/4** a la posición visual correcta dentro de su slot
   (por ejemplo, centrado en la parte inferior del slot, como si el personaje estuviera de pie)
4. Ajusta el DialogueBox (fondo lila oscuro) al tamaño que prefieras desde el editor
5. Verifica que el NameTag y el SkipButton queden visibles sobre el borde superior de la caja

> **Tip**: Los CharacterSlots están ocultos (`visible = false`) por defecto.
> Para verlos en el editor mientras ajustas, ponlos temporalmente en `visible = true`,
> y después devuélvelos a `false` antes de guardar.

---

## 🖼️ Paso 4 — Agregar sprites de personajes

### Opción A — SpriteFrames .tres (RECOMENDADA para equipos)

Crea un archivo `frames.tres` por personaje en su carpeta:

```
dialogue_system/portraits/serafina/frames.tres
dialogue_system/portraits/ignia/frames.tres
```

El `.tres` es un recurso `SpriteFrames` con **animaciones por expresión**:
- Animación `"idle"` → expresión neutral
- Animación `"smile"` → sonriendo
- Animación `"angry"` → enojada
- etc.

**¿Cómo crearlo?**
1. Selecciona cualquier `AnimatedSprite2D` en el editor
2. En la propiedad `SpriteFrames`, crea un nuevo recurso
3. Agrega todas las animaciones/expresiones del personaje
4. Guárdalo como `.tres` en la ruta correcta

**Ventaja para el diseñador**: cada personaje tiene su propio `.tres` con todas sus
expresiones en un solo lugar. Fácil de versionar en Git y de actualizar sin tocar código.

### Opción B — Texturas por expresión (fallback automático)

Si no existe `frames.tres`, el sistema busca automáticamente:
```
dialogue_system/portraits/{personaje_id}_{expresion}.png
```
Ejemplo: `dialogue_system/portraits/serafina_smile.png`

Útil durante producción temprana. El diseñador solo entrega PNGs individuales.

### Fallback final

Si no encuentra ningún sprite, muestra `missing_expression.jpg` (el ícono `?` violeta).
Esto ayuda a detectar visualmente qué sprites faltan durante desarrollo.

---

## 📝 Paso 5 — Registrar personajes

Edita `dialogues/characters.json` para agregar cada personaje del juego:

```json
{
  "characters": {
	"serafina": {
	  "display_name": "Serafina",
	  "name_color": "#C8A0F0"
	},
	"ignia": {
	  "display_name": "Ignia",
	  "name_color": "#FF8B35"
	},
	"nuevo_personaje": {
	  "display_name": "Nombre que ve el jugador",
	  "name_color": "#AAFFBB"
	}
  }
}
```

- `"display_name"`: lo que aparece en el tag de nombre en pantalla
- `"name_color"`: color del texto del nombre (hex)
- La clave del objeto (ej. `"serafina"`) es el **ID** que usarás en todos los JSONs de diálogo

---

## 💬 Paso 6 — Crear archivos de diálogo

Crea un `.json` por escena/conversación en `dialogues/cap1/` (o la subcarpeta del capítulo):

```json
{
  "scene_characters": [
	{ "id": "serafina", "slot": 2, "initial_expression": "idle" },
	{ "id": "ignia",    "slot": 3, "initial_expression": "idle" }
  ],
  "lines": [
	{
	  "speaker_id": "serafina",
	  "expression": "smile",
	  "text": "Hola, [b]Ignia[/b]. ¿Lista para la aventura?",
	  "event": "",
	  "choices": []
	},
	{
	  "speaker_id": "ignia",
	  "expression": "idle",
	  "text": "Siempre. [color=#FF6B6B]No hay tiempo que perder.[/color]",
	  "event": "abrir_puerta",
	  "choices": []
	}
  ]
}
```

### Campos de `scene_characters`:
| Campo | Descripción |
|---|---|
| `id` | ID del personaje (debe existir en characters.json) |
| `slot` | Posición en pantalla: 1 (izq), 2 (centro-izq), 3 (centro-der), 4 (der) |
| `initial_expression` | Animación inicial al aparecer |

### Campos de cada `line`:
| Campo | Descripción |
|---|---|
| `speaker_id` | Quién habla (determina quién se resalta) |
| `expression` | Animación/expresión para esa línea |
| `text` | Texto (soporta BBCode: `[b]`, `[color=...]`, `[i]`, etc.) |
| `event` | ID de evento a disparar (puede estar vacío `""`) |
| `choices` | Array vacío por ahora (estructura lista para ramificaciones futuras) |

---

## 🎯 Paso 7 — Iniciar un diálogo desde código

Desde cualquier escena del juego:

```gdscript
# Iniciar un diálogo
DialogueManager.start_dialogue("res://dialogue_system/dialogues/cap1/cap1_escena1.json")

# Escuchar cuando termina (para reactivar mecánicas, etc.)
DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
	# Reactivar al jugador, abrir una puerta, cambiar música, etc.
	pass

# Escuchar eventos disparados por líneas específicas
DialogueManager.event_triggered.connect(_on_dialogue_event)

func _on_dialogue_event(event_id: String) -> void:
	match event_id:
		"abrir_puerta":
			$Puerta.abrir()
		"dar_item":
			inventario.agregar("espada")
```

---

## 🧩 Paso 8 — Agregar diálogo a un NPC (sin código)

1. Instancia `dialogue_trigger.tscn` como hijo del nodo del NPC
2. En el Inspector, configura `dialogue_path`:
   `res://dialogue_system/dialogues/cap1/cap1_escena1.json`
3. Asegúrate de que Serafina/Ignia estén en el grupo `"player"`:
   - Selecciona el CharacterBody2D del jugador
   - Pestaña "Nodo" → "Grupos" → Agrega `"player"`
4. Ajusta el `CollisionShape2D` del trigger al tamaño del área de interacción

Eso es todo. Sin línea de código adicional.

---

## 🔔 Señales disponibles de DialogueManager

```gdscript
DialogueManager.dialogue_started(dialogue_path: String)
DialogueManager.dialogue_finished
DialogueManager.line_changed(line_index: int, total_lines: int)
DialogueManager.event_triggered(event_id: String)
```

---

## ❓ Preguntas frecuentes

**¿El diálogo reemplaza la escena de juego?**
No. Vive en un `CanvasLayer` con capa 10 sobre todo lo demás. El nivel sigue visible.

**¿Qué pasa si llamo `start_dialogue` mientras hay uno activo?**
Se ignora y se imprime un warning en consola. El diálogo activo continúa sin interrupciones.

**¿Cómo muevo el sistema a otro proyecto?**
Copia la carpeta `dialogue_system/` completa y registra el Autoload de nuevo. Nada más.

**¿Puedo tener más de 4 personajes en pantalla?**
El diseño soporta 4 slots. Para más, agrega `CharacterSlot5` / `Sprite5` a la escena
y aumenta `SLOT_COUNT = 5` en `dialogue_box.gd`.

**¿Cómo preparo el sistema para traducción?**
Cambia el campo `"text"` por una clave de traducción:
`"text": "TR:KEY_INTRO_SERAFINA_01"` y en el manager usa `tr(text)` antes de mostrarlo.
