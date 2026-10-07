# Tutorial: Sistema de Transición de Escenas (Estilo Metroidvania)

Este sistema está diseñado para manejar mapas gigantescos divididos en múltiples escenas más pequeñas (habitaciones, zonas). Funciona haciendo un "Fade a negro" suave, cargando la nueva zona, y colocando al jugador exactamente en la puerta correspondiente.

## Arquitectura del Sistema
El sistema consta de 3 scripts principales ubicados en `sistemas/scene_transition/`:
1. `scene_manager.gd` -> El Cerebro global (Autoload).
2. `door.gd` -> El gatillo que pisas para cambiar de escena.
3. `spawn_point.gd` -> El marcador que dice dónde apareces.

---

## PASO 1: Configurar el Global (Autoload)
Este paso es **obligatorio** y solo se hace una vez por proyecto.

1. En Godot, ve arriba a **Proyecto** -> **Configuración del Proyecto**.
2. Ve a la pestaña **Autoload** (Autocarga).
3. En la ruta (Path), busca el archivo: `res://sistemas/scene_transition/scene_manager.gd`.
4. En el campo **Node Name** (Nombre del Nodo), asegúrate de que diga exactamente **`SceneManager`**.
5. Haz clic en el botón **Añadir**. (Asegúrate de que la casilla "Enable" esté marcada).

---

## PASO 2: Configurar tu Jugador
Para que el sistema sepa qué nodo es el que debe transportar, debes poner a tu personaje en el grupo correcto.

1. Abre la escena principal de tu personaje (ej. `personajeBase.tscn`).
2. Selecciona el nodo Raíz (CharacterBody2D).
3. A la derecha en el Inspector, ve a la pestaña **Nodo** -> **Grupos**.
4. Escribe **`player`** y pulsa "Añadir".

---

## PASO 3: Cómo conectar dos habitaciones

Imagina que queremos conectar la **Sala** con la **Cocina**.

### A. Creando la puerta de Salida (en la Sala)
1. Abre tu escena de la **Sala** (`sala.tscn`).
2. Crea un nodo **Area2D** y llámalo algo como `Puerta_Hacia_Cocina`.
3. Añádele un **CollisionShape2D** y dibuja el cuadro donde el jugador debe tocar para salir.
4. Arrastra el script `door.gd` al Area2D.
5. En el Inspector de este Area2D verás dos opciones nuevas:
   * **Next Scene Path:** Selecciona aquí la escena de destino (`res://.../cocina.tscn`).
   * **Destination Door Id:** Escribe un código único (todo en minúsculas y sin espacios), por ejemplo: `entrada_desde_sala`.

### B. Creando el punto de Llegada (en la Cocina)
1. Ahora abre tu escena de la **Cocina** (`cocina.tscn`).
2. Crea un nodo **Marker2D** (o Node2D) y llámalo `Spawn_Desde_Sala`.
3. Colócalo visualmente en el suelo, exactamente donde quieres que el jugador aparezca al entrar.
4. Arrastra el script `spawn_point.gd` a este Marker2D.
5. En el Inspector de este Marker2D verás la opción:
   * **Door Id:** Escribe EXACTAMENTE el mismo código que pusimos arriba: `entrada_desde_sala`.

### ¡Y listo! 
Al jugar, cuando el personaje toque la `Puerta_Hacia_Cocina` en la Sala, la pantalla se fundirá a negro, Godot cargará la Cocina, el `SceneManager` buscará el Spawn Point llamado `entrada_desde_sala`, teletransportará al jugador ahí y la pantalla se aclarará.

---

## Reglas de Oro para evitar Errores
- **No repitas IDs en una misma escena:** No puedes tener dos `spawn_point.gd` con el mismo ID en el mismo cuarto.
- **Si hay errores "fantasma":** Si modificas los scripts globales y Godot se queja de que "SceneManager" no existe, limpia la pestaña de Errores abajo y dale al botón de "Play" para que Godot refresque su caché.
- **Transiciones limpias:** Como el fundido se crea por código puro en el `scene_manager.gd`, no necesitas preocuparte por añadir CanvasLayers ni ColorRects manualmente en cada escena. 
