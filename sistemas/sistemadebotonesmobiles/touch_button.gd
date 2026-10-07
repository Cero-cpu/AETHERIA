extends Control

signal button_down
signal button_up

@export_category("Button Configuration")
@export var action_name: String = ""
@export var normal_modulate: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var pressed_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)

var is_pressed: bool = false
var touch_index: int = -1

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	modulate = normal_modulate
	_ensure_action_exists(action_name)

func _ensure_action_exists(action: String) -> void:
	if not action.is_empty() and not InputMap.has_action(action):
		InputMap.add_action(action)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_press_button()
			accept_event()
		elif not event.pressed and event.index == touch_index:
			_release_button()
			accept_event()
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_index == -1:
				touch_index = 999
				_press_button()
				accept_event()
			elif not event.pressed and touch_index == 999:
				_release_button()
				accept_event()

func _press_button() -> void:
	is_pressed = true
	modulate = pressed_modulate
	scale = Vector2(0.92, 0.92)
	pivot_offset = size / 2.0
	
	if not action_name.is_empty():
		_ensure_action_exists(action_name)
		Input.action_press(action_name)
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = true
		Input.parse_input_event(ev)
		
		# Si la acción es salto, enviamos también ui_accept para compatibilidad total
		if action_name == "salto":
			_ensure_action_exists("ui_accept")
			Input.action_press("ui_accept")
			var ev_acc = InputEventAction.new()
			ev_acc.action = "ui_accept"
			ev_acc.pressed = true
			Input.parse_input_event(ev_acc)

	button_down.emit()

func _release_button() -> void:
	touch_index = -1
	is_pressed = false
	modulate = normal_modulate
	scale = Vector2(1.0, 1.0)
	pivot_offset = size / 2.0
	
	if not action_name.is_empty():
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
			var ev = InputEventAction.new()
			ev.action = action_name
			ev.pressed = false
			Input.parse_input_event(ev)
		
		if action_name == "salto":
			if InputMap.has_action("ui_accept"):
				Input.action_release("ui_accept")
				var ev_acc = InputEventAction.new()
				ev_acc.action = "ui_accept"
				ev_acc.pressed = false
				Input.parse_input_event(ev_acc)

	button_up.emit()
