extends Area2D

# Ruta de la escena a la que queremos ir (ej: res://scenas/casa/cocina.tscn)
@export_file("*.tscn") var next_scene_path: String
# El ID de la puerta donde apareceremos en la siguiente escena (ej: "puerta_entrada")
@export var destination_door_id: String = ""

var _triggered: bool = false

func _ready() -> void:
	# Detectar cuerpos en TODAS las capas de colisión
	# (la puerta filtra por grupo "player", no por capa)
	collision_mask = 0xFFFFFFFF
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	
	# Solo nos importa el jugador
	if not (body.is_in_group("player") or body.name.to_lower() == "player"):
		return
	
	_triggered = true
	set_deferred("monitoring", false)
	
	if next_scene_path == "":
		print("Error: Door '", name, "' no tiene ruta de escena asignada en el Inspector.")
		return
	
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.change_scene(next_scene_path, destination_door_id)
	else:
		print("Error: Autoload 'SceneManager' no encontrado. Ve a Proyecto > Configuración > Autoload.")
