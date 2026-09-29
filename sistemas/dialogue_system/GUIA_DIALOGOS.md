# 💬 Guía del Sistema de Diálogos (Para cualquier Godotero)

El sistema de diálogos en este proyecto está diseñado para ser muy modular. Se basa principalmente en **archivos JSON** para guardar el texto y en un **Autoload (`DialogueManager`)** para mostrar la interfaz gráfica desde cualquier lugar.

Aquí tienes los 4 pasos para crear y usar un nuevo diálogo con diferentes personajes y expresiones.

## Paso 1: Registra a tus personajes (El archivo global)

Antes de que un personaje pueda hablar, el sistema necesita saber cómo se llama y de qué color será su nombre. Esto se define en un único archivo global:
📂 `res://dialogue_system/dialogues/characters.json`

Si abres este archivo, verás algo como esto. Para agregar un personaje nuevo, simplemente añade su "ID" a la lista:

```json
{
  "characters": {
	"serafina": {
	  "display_name": "Serafina",
	  "name_color": "#C8A0F0"
	},
	"nuevo_personaje": {
	  "display_name": "Señor Misterioso",
	  "name_color": "#FFD700"
	}
  }
}
```
* **ID (`nuevo_personaje`)**: Es el código interno que usarás en el sistema.
* **`display_name`**: El nombre que leerá el jugador en la pantalla.
* **`name_color`**: El color del nombre (en formato Hexadecimal).

## Paso 2: Crea el guion de tu escena (El archivo JSON del diálogo)

Cada conversación en tu juego tendrá su propio archivo `.json`. Crea uno nuevo (por ejemplo, `mi_escena.json`) en tu carpeta de diálogos. 

El archivo se divide en dos partes: **`scene_characters`** (quiénes están en la pantalla) y **`lines`** (qué dicen).

```json
{
  "scene_characters": [
	{ "id": "serafina", "slot": 2, "initial_expression": "idle" },
	{ "id": "nuevo_personaje", "slot": 3, "initial_expression": "smile" }
  ],
  "lines": [
	{
	  "speaker_id": "nuevo_personaje",
	  "expression": "smile",
	  "text": "¡Hola Serafina! Qué [b]bueno[/b] verte.",
	  "event": "",
	  "choices": []
	},
	{
	  "speaker_id": "serafina",
	  "expression": "surprised",
	  "text": "¿Quién eres tú y qué quieres?",
	  "event": "trigger_musica_combate",
	  "choices": []
	}
  ]
}
```
### ¿Qué significa cada cosa aquí?
* **`slot` (1 al 4)**: Es la posición en la pantalla donde aparecerá el personaje. El sistema soporta hasta 4 personajes en pantalla al mismo tiempo.
* **`expression`**: Define qué sprite o animación facial se mostrará en ese momento exacto. (Ver Paso 3).
* **`text`**: El diálogo. ¡Soporta BBCode nativo de Godot! (ej: `[b]negrita[/b]`, `[color=red]rojo[/color]`).
* **`event`**: (Opcional) Si escribes algo aquí (ej: `"trigger_musica_combate"`), el sistema emitirá una señal para que tu código de Godot haga algo en ese momento exacto del diálogo.

## Paso 3: ¿Cómo funcionan las Expresiones Faciales (Sprites)?

El sistema cambia las caras automáticamente leyendo el campo `"expression"` de tu JSON. Pero, ¿cómo sabe Godot qué imagen poner?

El sistema utiliza nodos **`AnimatedSprite2D`** (o `SpriteFrames`). 
Cuando en tu JSON pones `"expression": "surprised"`, el código de la caja de diálogo internamente hace esto:
```gdscript
sprite.play("surprised")
```
**Para agregar nuevas expresiones:**
1. Ve al `SpriteFrames` de tu personaje.
2. Crea una nueva animación y llámala exactamente igual que en tu JSON (ej: `idle`, `smile`, `surprised`, `angry`).
3. Pon el frame de la cara correspondiente en esa animación. ¡El sistema de diálogos se encargará de cambiar a esa animación cuando lea esa línea!

## Paso 4: Disparar el diálogo en CUALQUIER escena

Una vez que tienes tus personajes en `characters.json` y tu guion en `mi_escena.json`, llamarlo desde Godot es facilísimo.

No necesitas instanciar la caja de diálogo manualmente en cada escena. Como usa un gestor global (`DialogueManager`), solo necesitas escribir una línea de código en cualquier script:

```gdscript
extends Node2D

func _ready():
	# Puedes llamarlo al iniciar la escena...
	DialogueManager.start_dialogue("res://ruta/a/tu/archivo/mi_escena.json")

func al_interactuar_con_npc():
	# ...o cuando el jugador presiona un botón cerca de un NPC
	DialogueManager.start_dialogue("res://ruta/a/tu/archivo/charla_npc.json")
```

### (Opcional) Usar el Trigger prefabricado
Si prefieres no programar, puedes arrastrar la escena 📂 `dialogue_trigger.tscn` a tu nivel. Este nodo (usualmente un `Area2D`) probablemente ya tiene configurado un export para que le pongas la ruta del `.json` desde el Inspector de Godot, y él se encargará de llamar al `DialogueManager` cuando el jugador entre en el área.

---

### 💡 Resumen Rápido:
1. **Añade al personaje** en `characters.json`.
2. **Crea sus animaciones** en su `SpriteFrames` (`idle`, `sad`, `happy`).
3. **Escribe el guion** en un `.json` usando los IDs y los nombres de las animaciones.
4. **Llama a `DialogueManager.start_dialogue("ruta_al.json")`** desde cualquier script.
