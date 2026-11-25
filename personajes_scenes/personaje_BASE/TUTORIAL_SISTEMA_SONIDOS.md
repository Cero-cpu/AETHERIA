# 🎵 Tutorial del Sistema de Sonidos y Taunt para PersonajeBase

Este documento explica cómo utilizar, configurar y extender el **Sistema de Sonidos y Taunt** integrado en `PersonajeBase` para cualquier personaje heredado del juego (como Vespera, Smarka, Ignia, etc.).

---

## 📋 Índice
1. [Resumen del Sistema](#resumen-del-sistema)
2. [Configuración desde el Inspector de Godot](#configuración-desde-el-inspector-de-godot)
3. [Configuración por Código (GDScript)](#configuración-por-código-gdscript)
4. [Eventos y Sonidos Disponibles](#eventos-y-sonidos-disponibles)
5. [Sistema de Taunt (Idle Prolongado)](#sistema-de-taunt-idle-prolongado)
6. [Sistema de Vida, Daño y Muerte](#sistema-de-vida-daño-y-muerte)
7. [Cómo Llamar Sonidos desde Nuevas Mecánicas](#cómo-llamar-sonidos-desde-nuevas-mecánicas)

---

## 1. Resumen del Sistema

El sistema está diseñado de forma modular y desacoplada:
- **`PersonajeBase`**: Expone las propiedades de sonido en el Inspector, gestiona las condiciones de inactividad (taunt) y coordina cuándo se dispara cada sonido.
- **`SistemaSonidosPersonaje`**: Nodo componente interno que administra un **pool de reproductores `AudioStreamPlayer2D`**, permitiendo que varios sonidos ocurran al mismo tiempo sin cortarse entre sí, además de añadir variación sutil de tono (*pitch*) para evitar fatiga auditiva.

---

## 2. Configuración desde el Inspector de Godot

Al seleccionar cualquier personaje en el editor que herede de `PersonajeBase` (por ejemplo, `vespera.tscn`), en el panel lateral **Inspector** verás las siguientes secciones:

### 🔊 Categoría: Sistema de Sonidos
Arrastra tus archivos `.wav`, `.ogg` o `.mp3` desde el explorador de archivos de Godot a cada ranura:

| Propiedad | Tipo | Descripción |
| :--- | :--- | :--- |
| `sonido_salto` | `AudioStream` | Sonido reproducido al saltar o doble saltar. |
| `sonido_ataque` | `AudioStream` | Sonido al ejecutar un ataque básico o combo. |
| `sonido_habilidad` | `AudioStream` | Sonido de la habilidad primaria (Habilidad 1). |
| `sonido_definitiva` | `AudioStream` | Sonido al activar la habilidad Ultimate. |
| `sonido_recibir_dano` | `AudioStream` | Sonido o quejido al recibir un golpe. |
| `sonido_morir` | `AudioStream` | Sonido o efecto final al perder toda la vida. |
| `sonido_taunt` | `AudioStream` | Sonido o frase cuando el personaje pasa tiempo quieto. |

### 🎚️ Grupo: Configuración de Audio
- **`Audio Bus`**: Por defecto `"Master"`. Puedes cambiarlo a `"SFX"` o `"Voces"` si tienes buses creados en el mezclador de audio de Godot.
- **`Volumen Sonidos Db`**: Ajuste general de volumen en decibelios (por defecto `0.0`).
- **`Variar Pitch`**: `true` / `false`. Activa una ligera variación aleatoria para que cada golpe o salto suene único.
- **`Pitch Min` / `Pitch Max`**: Rango de variación (por defecto `0.95` a `1.05`).

### ⏳ Grupo: Comportamiento Taunt (Idle Prolongado)
- **`Tiempo Para Taunt`**: Tiempo en segundos que el personaje debe permanecer inmóvil en el suelo para iniciar la burla (por defecto `6.0` s).
- **`Anim Taunt`**: Nombre de la animación en `SpriteFrames` (por defecto `"taunt"`).
- **`Anim Taunt Fallbacks`**: Nombres alternativos buscados automáticamente si `"taunt"` no existe (`["idle_taunt", "burla"]`).

---

## 3. Configuración por Código (GDScript)

Si prefieres asignar o cambiar los sonidos dinámicamente mediante código en el script de un personaje hijo (por ejemplo `vespera.gd`):

```gdscript
extends "res://personajes_scenes/personaje_BASE/personaje_base.gd"

func _ready() -> void:
    super._ready()
    
    # Asignar sonidos precargados
    sonido_salto = preload("res://assets/audio/salto_vespera.wav")
    sonido_ataque = preload("res://assets/audio/ataque_vespera.wav")
    sonido_habilidad = preload("res://assets/audio/chasquido.wav")
    sonido_definitiva = preload("res://assets/audio/ultimate_vespera.wav")
    sonido_recibir_dano = preload("res://assets/audio/golpe_vespera.wav")
    sonido_morir = preload("res://assets/audio/muerte_vespera.wav")
    sonido_taunt = preload("res://assets/audio/taunt_vespera.wav")
    
    # Configurar tiempo de inactividad
    tiempo_para_taunt = 5.0
```

---

## 4. Eventos y Sonidos Disponibles

| Método en `PersonajeBase` | Acción |
| :--- | :--- |
| `reproducir_sonido_salto()` | Reproduce `sonido_salto` y emite señal `sonido_reproducido("salto", stream)`. |
| `reproducir_sonido_ataque()` | Reproduce `sonido_ataque` y emite señal `sonido_reproducido("ataque", stream)`. |
| `reproducir_sonido_habilidad()` | Reproduce `sonido_habilidad` y emite señal `sonido_reproducido("habilidad", stream)`. |
| `reproducir_sonido_definitiva()` | Reproduce `sonido_definitiva` con pitch estable para máxima contundencia. |
| `reproducir_sonido_recibir_dano()` | Reproduce `sonido_recibir_dano` y cancela cualquier taunt activo. |
| `reproducir_sonido_morir()` | Reproduce `sonido_morir`. |
| `reproducir_sonido_taunt()` | Reproduce `sonido_taunt` y emite señal `taunt_iniciado`. |
| `reproducir_sonido(stream, variar_pitch, offset_db)` | Reproduce cualquier `AudioStream` personalizado usando el pool. |

---

## 5. Sistema de Taunt (Idle Prolongado)

### ¿Cómo se activa?
1. El personaje está en el suelo (`is_on_floor()`).
2. No tiene velocidad horizontal (`velocity.x ≈ 0`) y no se presiona ninguna tecla de movimiento.
3. No está en medio de un ataque, dash, habilidad o recibiendo daño (`not is_action_busy()`).
4. Tras `tiempo_para_taunt` segundos continuos (por defecto 6s), se dispara `ejecutar_taunt()`.

### Animación y Sonido
- Reproduce el sonido asignado en `sonido_taunt`.
- Busca la animación `"taunt"` (o `"idle_taunt"` / `"burla"`) en el nodo `AnimatedSprite2D`. Si existe, la reproduce. Si no existe, reproduce el sonido igualmente sin alterar el sprite.

### Cancelación Instantánea (Responsive Control)
Si el jugador presiona cualquier tecla (moverse a los lados, saltar, atacar, usar dash o habilidad), **el taunt se cancela al instante** para que el control del personaje nunca se sienta pesado o trabado.

---

## 6. Sistema de Vida, Daño y Muerte

El personaje base cuenta con funciones directas listas para conectar con trampas, enemigos y proyectiles:

```gdscript
# Aplicar daño numérico al personaje (ej. llamado por un enemigo):
personaje.recibir_dano(25.0)

# Aplicar solo animación de golpe y sonido:
personaje.recibir_hit()

# Curar vida:
personaje.curar(15.0)

# Derrotar al personaje de inmediato:
personaje.morir()
```

### Comportamiento al morir:
1. Pone `is_dead = true` y cancela cualquier acción en curso.
2. Desactiva la lectura de controles del jugador.
3. Reproduce `sonido_morir`.
4. Emite la señal `personaje_murio`.
5. Reproduce la animación `"dead"` (o `"muerte"` / `"morir"`) si está disponible.

---

## 7. Cómo Llamar Sonidos desde Nuevas Mecánicas

Si creas un nuevo componente derivado de `MecanicaBase` (como un disparo, contraataque o gancho), puedes invocar los sonidos del personaje con total facilidad:

```gdscript
extends MecanicaBase

func ejecutar_mecanica() -> void:
    if not puede_ejecutar():
        return
        
    if personaje:
        # Usar los métodos estándar de PersonajeBase:
        personaje.reproducir_sonido_ataque()
        
        # O reproducir un sonido particular propio de este componente:
        if mi_sonido_especial:
            personaje.reproducir_sonido(mi_sonido_especial)
```
