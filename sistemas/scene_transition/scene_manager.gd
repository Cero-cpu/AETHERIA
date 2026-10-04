extends Node

var current_spawn_door_id: String = ""

# Componentes de UI para el fade creados por código 
# (así evitamos depender de un .tscn externo y es 100% escalable)
var canvas_layer: CanvasLayer
var color_rect: ColorRect

func _ready() -> void:
	# Creamos la capa que estará sobre todo el juego
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 
	add_child(canvas_layer)
	
	# Creamos el fondo negro
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) # Empieza totalmente transparente
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Cubre toda la pantalla
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(color_rect)

func change_scene(scene_path: String, destination_door_id: String) -> void:
	current_spawn_door_id = destination_door_id
	
	# 1. Fade Out (La pantalla se funde a negro)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5)
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
	_position_player_at_spawn()
	
	# 4. Fade In (La pantalla vuelve a la normalidad)
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, 0.5)

func _position_player_at_spawn() -> void:
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
		# Asumimos que tu jugador está en el grupo "player" o lo buscamos por nombre
		var players = get_tree().get_nodes_in_group("player") 
		if players.size() > 0:
			players[0].global_position = target_spawn.global_position
		else:
			print("Advertencia: No se encontró un jugador en el grupo 'player'.")
	else:
		print("Advertencia: No se encontró un Spawn Point con ID: ", current_spawn_door_id)
