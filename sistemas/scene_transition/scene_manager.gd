extends CanvasLayer

var current_spawn_door_id: String = ""

# FadeRect es un nodo hijo definido en scene_manager.tscn — sin código generador
@onready var fade_rect: ColorRect = $FadeRect

func change_scene(scene_path: String, destination_door_id: String) -> void:
	current_spawn_door_id = destination_door_id
	
	# 1. Fade Out (La pantalla se funde a negro)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	
	# 2. Cambiar de escena
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("Error al cambiar a la escena: ", scene_path)
		return 
	
	# Esperar a que la escena se cargue por completo (2 frames por seguridad)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 3. Buscar al jugador y colocarlo en el Spawn Point correcto
	#    (await necesario porque internamente espera un frame para snapear la cámara)
	await _position_player_at_spawn()
	
	# 4. Fade In (La pantalla vuelve a la normalidad)
	var tween_in = create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, 0.5)

func _position_player_at_spawn() -> void: # implicitly async due to awaits inside
	if current_spawn_door_id == "":
		return
		
	# Buscamos todos los nodos en el grupo "spawn_points"
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	var target_spawn: Node2D = null
	
	for spawn in spawn_points:
		if spawn.has_method("get_door_id") and spawn.get_door_id() == current_spawn_door_id:
			target_spawn = spawn
			break
			
	if target_spawn != null:
		var players = get_tree().get_nodes_in_group("player") 
		if players.size() > 0:
			var player = players[0]
			# 1. Mover el jugador al spawn
			player.global_position = target_spawn.global_position
			
			# 2. Snap de cámara: la forzamos a la nueva posición sin lerping
			#    para evitar el "acercón brusco" al regresar a una escena anterior.
			var camera = player.get_node_or_null("Camera2D")
			if camera is Camera2D:
				camera.position_smoothing_enabled = false
				camera.reset_smoothing()
				# Esperar un frame para que Godot procese la posición antes de reactivar el suavizado
				await get_tree().process_frame
				camera.position_smoothing_enabled = true
		else:
			print("Advertencia: No se encontró un jugador en el grupo 'player'.")
	else:
		print("Advertencia: No se encontró un Spawn Point con ID: ", current_spawn_door_id)
