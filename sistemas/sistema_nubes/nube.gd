class_name Nube
extends Sprite2D

## =====================================================================
## SISTEMA DE NUBES EN MOVIMIENTO LENTO (AETHERIA)
## =====================================================================
## Modo de uso:
## 1. Arrastra la escena "nube.tscn" a tu nivel (tantas como quieras).
## 2. En el Inspector, en la propiedad "Texture", arrastra el sprite que quieras.
## 3. ¡Listo! Cada nube se moverá suavemente y volverá a hacer ciclo automáticamente.
## =====================================================================

enum ModoCiclo {
	POR_DISTANCIA,         ## Recomendado: se desplaza en un rango continuo alrededor de donde la colocaste.
	POR_PANTALLA_O_CAMARA, ## Reaparece en el otro extremo cuando sale de la vista de la cámara.
	SIN_CICLO              ## Continúa avanzando indefinidamente sin reiniciar.
}

@export_group("Movimiento")
## Velocidad base de desplazamiento en píxeles por segundo.
@export var velocidad: float = 20.0
## Pequeña variación aleatoria para que cada nube duplicada viaje a un ritmo sutilmente diferente y no marchen en bloque.
@export var variacion_velocidad: float = 6.0
## Dirección del viento hacia donde flota la nube (por defecto hacia la derecha).
@export var direccion: Vector2 = Vector2.RIGHT

@export_group("Flotación Suave (Vaivén Vertical)")
## Activa un balanceo suave arriba y abajo para que las nubes se sientan vivas y orgánicas.
@export var flotacion_activa: bool = true
## Cuántos píxeles sube y baja durante el vaivén.
@export var amplitud_flotacion: float = 4.0
## Qué tan rápido realiza el vaivén vertical.
@export var velocidad_flotacion: float = 1.0

@export_group("Ciclo y Reaparición")
## Método de ciclo continuo cuando la nube avanza.
@export var modo_ciclo: ModoCiclo = ModoCiclo.POR_DISTANCIA
## Distancia en píxeles desde el origen antes de volver al otro extremo (para modo POR_DISTANCIA).
@export var distancia_maxima: float = 1400.0
## Variación aleatoria de altura Y cada vez que reaparece para darle frescura y evitar trayectorias repetitivas.
@export var variacion_altura_al_reaparecer: float = 25.0
## Margen fuera de la pantalla antes de reaparecer (para modo POR_PANTALLA_O_CAMARA).
@export var margen_pantalla: float = 120.0

@export_group("Detalles Visuales Opcionales")
## Si está activo, añade una sutil transparencia aleatoria a cada nube para dar sensación de profundidad y capas.
@export var opacidad_aleatoria: bool = false
@export_range(0.3, 1.0) var opacidad_minima: float = 0.65
@export_range(0.3, 1.0) var opacidad_maxima: float = 0.95
## Si está activo, varía ligeramente el tamaño de cada nube al iniciar el juego.
@export var escala_aleatoria: bool = false
@export var escala_min: float = 0.85
@export var escala_max: float = 1.15

# Variables de control interno
var _posicion_origen: Vector2
var _posicion_base_actual: Vector2
var _velocidad_final: float = 20.0
var _tiempo_acumulado: float = 0.0
var _desfase_flotacion: float = 0.0
var _direccion_normalizada: Vector2 = Vector2.RIGHT
var _notifier: VisibleOnScreenNotifier2D = null

func _ready() -> void:
	# Guardar la posición inicial donde la ubicaste en el editor
	_posicion_origen = global_position
	_posicion_base_actual = global_position
	_direccion_normalizada = direccion.normalized() if direccion != Vector2.ZERO else Vector2.RIGHT
	
	# Desfase aleatorio para que cada nube tenga su propio tiempo de ondulación
	_desfase_flotacion = randf() * TAU
	_velocidad_final = maxf(1.0, velocidad + randf_range(-variacion_velocidad, variacion_velocidad))
	
	# Aplicar variaciones visuales si están activadas
	if opacidad_aleatoria:
		modulate.a = randf_range(opacidad_minima, opacidad_maxima)
		
	if escala_aleatoria:
		var factor: float = randf_range(escala_min, escala_max)
		scale *= factor

	# Obtener o crear detector de pantalla
	_notifier = get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
	if not _notifier:
		_notifier = VisibleOnScreenNotifier2D.new()
		add_child(_notifier)
	
	_actualizar_tamano_notifier()

func _actualizar_tamano_notifier() -> void:
	if _notifier and texture:
		var tamano: Vector2 = texture.get_size()
		_notifier.rect = Rect2(-tamano / 2.0, tamano)

func _process(delta: float) -> void:
	_tiempo_acumulado += delta * velocidad_flotacion
	
	# 1. Movimiento constante en la dirección seleccionada
	_posicion_base_actual += _direccion_normalizada * _velocidad_final * delta
	
	# 2. Control de ciclo infinito
	match modo_ciclo:
		ModoCiclo.POR_DISTANCIA:
			_procesar_ciclo_distancia()
		ModoCiclo.POR_PANTALLA_O_CAMARA:
			_procesar_ciclo_pantalla()
		ModoCiclo.SIN_CICLO:
			pass
			
	# 3. Flotación suave vertical (ondulación sinusoidal)
	var offset_flotacion: Vector2 = Vector2.ZERO
	if flotacion_activa:
		var vaiven: float = sin(_tiempo_acumulado + _desfase_flotacion) * amplitud_flotacion
		offset_flotacion = Vector2(0.0, vaiven)
		
	global_position = _posicion_base_actual + offset_flotacion

func _procesar_ciclo_distancia() -> void:
	var vector_distancia: Vector2 = _posicion_base_actual - _posicion_origen
	var avance: float = vector_distancia.dot(_direccion_normalizada)
	
	# Si sobrepasó la distancia máxima hacia adelante
	if avance > distancia_maxima:
		# Reposicionar detrás del origen exactamente a la misma distancia
		_posicion_base_actual = _posicion_origen - (_direccion_normalizada * distancia_maxima)
		if variacion_altura_al_reaparecer > 0.0:
			_posicion_base_actual.y = _posicion_origen.y + randf_range(-variacion_altura_al_reaparecer, variacion_altura_al_reaparecer)

func _procesar_ciclo_pantalla() -> void:
	var rect_vista: Rect2 = _obtener_rect_camara_o_viewport()
	if rect_vista.size == Vector2.ZERO:
		return
		
	var tamano_sprite: Vector2 = texture.get_size() * scale if texture else Vector2(120.0, 60.0)
	var mitad_ancho: float = (tamano_sprite.x / 2.0) + margen_pantalla
	
	# Si se mueve hacia la derecha y salió por el borde derecho
	if _direccion_normalizada.x > 0.0:
		var limite_derecho: float = rect_vista.position.x + rect_vista.size.x + mitad_ancho
		if _posicion_base_actual.x > limite_derecho:
			_posicion_base_actual.x = rect_vista.position.x - mitad_ancho
			if variacion_altura_al_reaparecer > 0.0:
				_posicion_base_actual.y = _posicion_origen.y + randf_range(-variacion_altura_al_reaparecer, variacion_altura_al_reaparecer)
				
	# Si se mueve hacia la izquierda y salió por el borde izquierdo
	elif _direccion_normalizada.x < 0.0:
		var limite_izquierdo: float = rect_vista.position.x - mitad_ancho
		if _posicion_base_actual.x < limite_izquierdo:
			_posicion_base_actual.x = rect_vista.position.x + rect_vista.size.x + mitad_ancho
			if variacion_altura_al_reaparecer > 0.0:
				_posicion_base_actual.y = _posicion_origen.y + randf_range(-variacion_altura_al_reaparecer, variacion_altura_al_reaparecer)

func _obtener_rect_camara_o_viewport() -> Rect2:
	var vp = get_viewport()
	if not vp:
		return Rect2()
	var camara: Camera2D = vp.get_camera_2d()
	var vp_rect: Rect2 = vp.get_visible_rect()
	if camara:
		var centro: Vector2 = camara.get_screen_center_position()
		var zoom: Vector2 = camara.zoom if camara.zoom != Vector2.ZERO else Vector2.ONE
		var tamano: Vector2 = vp_rect.size / zoom
		return Rect2(centro - tamano / 2.0, tamano)
	else:
		return vp_rect
