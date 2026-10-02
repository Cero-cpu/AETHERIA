extends Camera2D

@export_category("Enfoque y Zoom")
## Con tilesets de 38x38, un zoom de 2.5 a 3.0 enfoca mucho mejor al personaje
@export var target_zoom: Vector2 = Vector2(2.6, 2.6)
## Offset para centrar al personaje ligeramente más abajo en pantalla y ver más terreno
@export var camera_offset: Vector2 = Vector2(0, -15.0)

@export_category("Límites del Mapa")
@export var tilemap_group: String = "tilemap"
@export var smoothing_speed_val: float = 6.0

func _ready() -> void:
	# Aplicar el zoom para enfocar adecuadamente al personaje con tileset 38x38
	zoom = target_zoom
	offset = camera_offset
	
	# Asegura que el seguimiento de la cámara esté centrado y sea fluido
	position_smoothing_enabled = true
	position_smoothing_speed = smoothing_speed_val
	drag_horizontal_enabled = false
	drag_vertical_enabled = false

	await get_tree().process_frame
	setup_fixed_limits()

func setup_fixed_limits() -> void:
	var tilemaps = get_tree().get_nodes_in_group(tilemap_group)
	if tilemaps.is_empty():
		return

	var combined_rect: Rect2i
	var first: bool = true

	for map in tilemaps:
		if map is TileMapLayer:
			var used_rect = map.get_used_rect()
			if used_rect.size == Vector2i.ZERO:
				continue
			if first:
				combined_rect = used_rect
				first = false
			else:
				combined_rect = combined_rect.merge(used_rect)

	if first:
		return 

	var sample_map = tilemaps[0] as TileMapLayer
	var tile_size = sample_map.tile_set.tile_size

	# Convertimos el rectángulo total ocupado por los bloques a píxeles
	limit_left = combined_rect.position.x * tile_size.x
	limit_top = combined_rect.position.y * tile_size.y
	limit_right = combined_rect.end.x * tile_size.x
	limit_bottom = combined_rect.end.y * tile_size.y
