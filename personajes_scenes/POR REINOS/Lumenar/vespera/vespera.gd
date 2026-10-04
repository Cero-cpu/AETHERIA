extends "res://personajes_scenes/personaje_BASE/personaje_base.gd"

# Vespera hereda las físicas de PersonajeBase y personaliza sus mecánicas únicas.

const MecanicaAtaqueVesperaScript = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/mecanica_ataque_vespera.gd")
const MecanicaDashVesperaScript = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/mecanica_dash_vespera.gd")
const MecanicaHabilidad1VesperaScript = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/mecanica_habilidad1_vespera.gd")
const MecanicaDefinitivaVesperaScript = preload("res://personajes_scenes/POR REINOS/Lumenar/vespera/mecanica_definitiva_vespera.gd")

func _ready() -> void:
	super._ready()
	_configurar_componentes_vespera()

func _configurar_componentes_vespera() -> void:
	var contenedor = get_node_or_null("Componentes")
	
	for i in range(componentes_mecanicas.size()):
		var comp = componentes_mecanicas[i]
		
		# Reemplazar Ataque Básico por MecanicaAtaqueVespera
		if comp is MecanicaAtaque and comp.get_script() != MecanicaAtaqueVesperaScript:
			var action_n = comp.action_name
			var anim_n = comp.anim_name
			var block_m = comp.bloquear_movimiento
			
			comp.queue_free()
			
			var comp_vespera = MecanicaAtaqueVesperaScript.new()
			comp_vespera.name = "MecanicaAtaqueVespera"
			comp_vespera.action_name = action_n
			comp_vespera.anim_name = anim_n
			comp_vespera.bloquear_movimiento = block_m
			
			if contenedor:
				contenedor.add_child(comp_vespera)
			else:
				add_child(comp_vespera)
				
			componentes_mecanicas[i] = comp_vespera
			
		# Reemplazar Dash por MecanicaDashVespera
		elif comp is MecanicaDash and comp.get_script() != MecanicaDashVesperaScript:
			var action_n = comp.action_name
			var speed_v = comp.dash_speed
			var dur_v = comp.dash_duration
			var anim_n = comp.anim_name
			
			comp.queue_free()
			
			var dash_vespera = MecanicaDashVesperaScript.new()
			dash_vespera.name = "MecanicaDashVespera"
			dash_vespera.action_name = action_n
			dash_vespera.dash_speed = speed_v
			dash_vespera.dash_duration = dur_v
			dash_vespera.anim_name = anim_n
			
			if contenedor:
				contenedor.add_child(dash_vespera)
			else:
				add_child(dash_vespera)
				
			componentes_mecanicas[i] = dash_vespera

		# Reemplazar Habilidad 1 por MecanicaHabilidad1Vespera (Chasquido Temporal)
		elif comp is MecanicaHabilidad and (comp.action_name == "habilidad_1" or comp.anim_name == "habilidad1" or comp.name == "MecanicaHabilidad1") and comp.get_script() != MecanicaHabilidad1VesperaScript:
			var action_n = comp.action_name
			var anim_n = comp.anim_name
			
			comp.queue_free()
			
			var hab1_vespera = MecanicaHabilidad1VesperaScript.new()
			hab1_vespera.name = "MecanicaHabilidad1Vespera"
			hab1_vespera.action_name = action_n
			hab1_vespera.anim_name = anim_n
			
			if contenedor:
				contenedor.add_child(hab1_vespera)
			else:
				add_child(hab1_vespera)
				
			componentes_mecanicas[i] = hab1_vespera

		# Reemplazar Definitiva por MecanicaDefinitivaVespera
		elif comp is MecanicaHabilidad and (comp.action_name == "habilidad_definitiva" or comp.name == "MecanicaDefinitiva") and comp.get_script() != MecanicaDefinitivaVesperaScript:
			var action_n = comp.action_name
			var anim_n = comp.anim_name
			
			comp.queue_free()
			
			var ult_vespera = MecanicaDefinitivaVesperaScript.new()
			ult_vespera.name = "MecanicaDefinitivaVespera"
			ult_vespera.action_name = action_n
			ult_vespera.anim_name = anim_n
			
			if contenedor:
				contenedor.add_child(ult_vespera)
			else:
				add_child(ult_vespera)
				
			componentes_mecanicas[i] = ult_vespera
