class_name SistemaSonidosPersonaje
extends Node2D

## Administrador modular de efectos de sonido (SFX) para PersonajeBase.
## Implementa un pool de reproductores AudioStreamPlayer2D para permitir sonidos concurrentes
## sin cortes bruscos, variación de pitch sutil para evitar fatiga auditiva y manejo de buses de audio.

@export var max_reproductores: int = 6

var _pool_reproductores: Array[AudioStreamPlayer2D] = []
var _indice_actual: int = 0

var audio_bus: String = "Master"
var volumen_base_db: float = 0.0
var variar_pitch_defecto: bool = true
var pitch_min_defecto: float = 0.95
var pitch_max_defecto: float = 1.05

func _ready() -> void:
	_crear_pool()

func configurar(bus: String, volumen_db: float, variar_pitch: bool = true, p_min: float = 0.95, p_max: float = 1.05) -> void:
	audio_bus = bus
	volumen_base_db = volumen_db
	variar_pitch_defecto = variar_pitch
	pitch_min_defecto = p_min
	pitch_max_defecto = p_max
	
	# Asegurar que el bus exista en AudioServer
	var bus_valido = "Master"
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == audio_bus:
			bus_valido = audio_bus
			break
	audio_bus = bus_valido
	
	for player in _pool_reproductores:
		if is_instance_valid(player):
			player.bus = audio_bus
			player.volume_db = volumen_base_db

func _crear_pool() -> void:
	if not _pool_reproductores.is_empty():
		return
		
	for i in range(max_reproductores):
		var player = AudioStreamPlayer2D.new()
		player.name = "AudioPlayer_%d" % i
		player.bus = audio_bus
		player.volume_db = volumen_base_db
		add_child(player)
		_pool_reproductores.append(player)

## Reproduce un AudioStream con soporte opcional de modulación de pitch y volumen adicional
func reproducir(stream: AudioStream, aplicar_pitch_random: bool = true, offset_db: float = 0.0, pitch_custom: float = 1.0) -> AudioStreamPlayer2D:
	if not stream:
		return null
		
	if _pool_reproductores.is_empty():
		_crear_pool()
		
	# Obtener el siguiente reproductor disponible o rotar en el pool
	var player = _obtener_siguiente_player()
	if not player:
		return null
		
	player.stream = stream
	player.volume_db = volumen_base_db + offset_db
	
	if aplicar_pitch_random and variar_pitch_defecto:
		player.pitch_scale = randf_range(pitch_min_defecto, pitch_max_defecto)
	else:
		player.pitch_scale = pitch_custom
		
	player.play()
	return player

func _obtener_siguiente_player() -> AudioStreamPlayer2D:
	if _pool_reproductores.is_empty():
		return null
		
	# Primero buscar uno que no esté reproduciendo actualmente
	for p in _pool_reproductores:
		if is_instance_valid(p) and not p.playing:
			return p
			
	# Si todos están ocupados, tomar el siguiente de manera rotativa
	var player = _pool_reproductores[_indice_actual]
	_indice_actual = (_indice_actual + 1) % _pool_reproductores.size()
	return player

## Detiene todos los reproductores de audio activos del personaje
func detener_todos() -> void:
	for player in _pool_reproductores:
		if is_instance_valid(player) and player.playing:
			player.stop()
