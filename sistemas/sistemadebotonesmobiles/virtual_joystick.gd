extends Control

signal joystick_vector_changed(vector: Vector2)

@export_category("Joystick Configuration")
@export var max_distance: float = 60.0
@export var deadzone: float = 0.15
@export var action_left: String = "ui_left"
@export var action_right: String = "ui_right"
@export var action_up: String = "ui_up"
@export var action_down: String = "ui_down"

@export_category("Visual Node References")
@export var base_node: Control
@export var knob_node: Control

var output_vector: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var touch_index: int = -1

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	if not base_node and has_node("Base"):
		base_node = $Base
	if not knob_node and has_node("Knob"):
		knob_node = $Knob
		
	_center_knob()

func _center_knob() -> void:
	if knob_node and base_node:
		var base_center = base_node.position + base_node.size / 2.0
		var knob_center_offset = knob_node.size / 2.0
		knob_node.position = base_center - knob_center_offset

func _gui_input(event: InputEvent) -> void:
	if not base_node or not knob_node:
		return
		
	var base_center = base_node.position + base_node.size / 2.0
	
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			var dist = (event.position - base_center).length()
			if dist <= (base_node.size.x / 2.0) * 1.4:
				touch_index = event.index
				is_pressed = true
				_update_knob_from_position(event.position, base_center)
				accept_event()
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()
			accept_event()
			
	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_knob_from_position(event.position, base_center)
		accept_event()
		
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_index == -1:
				var dist = (event.position - base_center).length()
				if dist <= (base_node.size.x / 2.0) * 1.4:
					touch_index = 999
					is_pressed = true
					_update_knob_from_position(event.position, base_center)
					accept_event()
			elif not event.pressed and touch_index == 999:
				_reset_joystick()
				accept_event()
				
	elif event is InputEventMouseMotion and touch_index == 999:
		_update_knob_from_position(event.position, base_center)
		accept_event()

func _update_knob_from_position(pos: Vector2, center: Vector2) -> void:
	var diff = pos - center
	if diff.length() > max_distance:
		diff = diff.normalized() * max_distance
		
	var knob_center_offset = knob_node.size / 2.0
	knob_node.position = (center + diff) - knob_center_offset
	
	var raw_vector = diff / max_distance
	if raw_vector.length() < deadzone:
		output_vector = Vector2.ZERO
	else:
		output_vector = raw_vector
		
	_dispatch_input_actions()
	joystick_vector_changed.emit(output_vector)

func _reset_joystick() -> void:
	touch_index = -1
	is_pressed = false
	_center_knob()
	output_vector = Vector2.ZERO
	_dispatch_input_actions()
	joystick_vector_changed.emit(output_vector)

func _dispatch_input_actions() -> void:
	if output_vector.x < -deadzone:
		_set_action(action_left, true, abs(output_vector.x))
		_set_action(action_right, false, 0.0)
	elif output_vector.x > deadzone:
		_set_action(action_right, true, output_vector.x)
		_set_action(action_left, false, 0.0)
	else:
		_set_action(action_left, false, 0.0)
		_set_action(action_right, false, 0.0)
		
	if output_vector.y < -deadzone:
		_set_action(action_up, true, abs(output_vector.y))
		_set_action(action_down, false, 0.0)
	elif output_vector.y > deadzone:
		_set_action(action_down, true, output_vector.y)
		_set_action(action_up, false, 0.0)
	else:
		_set_action(action_up, false, 0.0)
		_set_action(action_down, false, 0.0)

func _set_action(action: String, pressed: bool, strength: float) -> void:
	if action.is_empty():
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if pressed:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
