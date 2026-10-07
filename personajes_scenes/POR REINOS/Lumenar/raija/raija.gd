extends "res://personajes_scenes/personaje_BASE/personaje_base.gd"

# Script para el personaje Raija.
# Hereda el sistema de físicas, movimiento, salto y doble salto de PersonajeBase.

const MecanicaAtaqueRaijaScript = preload("res://personajes_scenes/POR REINOS/Lumenar/raija/mecanica_ataque_raija.gd")

func _ready() -> void:
	super._ready()
	_configurar_componentes_raija()

func _configurar_componentes_raija() -> void:
	var contenedor = get_node_or_null("Componentes")
	
	for i in range(componentes_mecanicas.size()):
		var comp = componentes_mecanicas[i]
		if comp is MecanicaAtaque and comp.get_script() != MecanicaAtaqueRaijaScript:
			var action_n = comp.action_name
			var anim_n = comp.anim_name
			var anim_c = comp.anim_combo
			var block_m = comp.bloquear_movimiento
			
			comp.queue_free()
			
			var comp_raija = MecanicaAtaqueRaijaScript.new()
			comp_raija.name = "MecanicaAtaqueRaija"
			comp_raija.action_name = action_n
			comp_raija.anim_name = anim_n
			comp_raija.anim_combo = anim_c
			comp_raija.bloquear_movimiento = block_m
			
			if contenedor:
				contenedor.add_child(comp_raija)
			else:
				add_child(comp_raija)
				
			componentes_mecanicas[i] = comp_raija

