class_name MecanicaBase
extends Node

# ==========================================================
# CLASE BASE PARA MECÁNICAS DE PERSONAJE
# Cada habilidad/mecánica (disparo, combo, dash, parry, etc.)
# hereda de esta clase y se coloca como nodo hijo del personaje.
# ==========================================================

@export var enabled: bool = true
@export var action_name: String = "" # Nombre de la acción en InputMap (ej. "dash", "ataque_basico")

var personaje: PersonajeBase

func _ready() -> void:
	personaje = _obtener_personaje_padre()

func _obtener_personaje_padre() -> PersonajeBase:
	var parent = get_parent()
	while parent != null:
		if parent is PersonajeBase:
			return parent
		parent = parent.get_parent()
	return null

## Comprueba si la mecánica puede ejecutarse actualmente
func puede_ejecutar() -> bool:
	if not enabled or not personaje:
		return false
	if personaje.is_action_busy():
		return false
	return true

## Método que se invoca cuando la mecánica se activa
func ejecutar_mecanica() -> void:
	pass

## Se llama en cada frame de física para mecánicas continuas (ej. Dash en progreso)
func procesar_mecanica(_delta: float) -> void:
	pass

## Retorna verdadero si la mecánica está ejecutándose en este instante
func esta_activa() -> bool:
	return false

## Retorna verdadero si esta mecánica debe bloquear el movimiento horizontal del personaje
func bloquea_movimiento() -> bool:
	return false
