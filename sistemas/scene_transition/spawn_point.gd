extends Marker2D

# El ID que usará una Door para encontrar este lugar exacto
@export var door_id: String = ""

func _ready() -> void:
	# Agregarlo al grupo global automáticamente
	add_to_group("spawn_points")
	
	# Ocultarlo en el juego, por si le pusiste algún sprite de guía en el editor
	visible = false

func get_door_id() -> String:
	return door_id
