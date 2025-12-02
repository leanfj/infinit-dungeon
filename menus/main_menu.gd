extends Control

@onready var _start_button: Button = $VBoxContainer/MenuButtons/StartButton
@onready var _quit_button: Button = $VBoxContainer/MenuButtons/QuitButton

var _buttons: Array[Button] = []
var _selected_index: int = 0

func _ready() -> void:
	_buttons = [_start_button, _quit_button]
	_selected_index = 0
	
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect mouse hover
	for i in range(_buttons.size()):
		_buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
	
	_update_focus()

func _input(event: InputEvent) -> void:
	# Navigate up
	if event.is_action_pressed("move_up"):
		_selected_index = (_selected_index - 1 + _buttons.size()) % _buttons.size()
		_update_focus()
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	
	# Navigate down
	elif event.is_action_pressed("move_down"):
		_selected_index = (_selected_index + 1) % _buttons.size()
		_update_focus()
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	
	# Select with primary_attack or Enter
	elif event.is_action_pressed("primary_attack") or (event is InputEventKey and event.keycode == KEY_ENTER and event.pressed and not event.echo):
		if _selected_index < _buttons.size():
			_buttons[_selected_index].pressed.emit()
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()

func _update_focus() -> void:
	for i in range(_buttons.size()):
		if i == _selected_index:
			_buttons[i].grab_focus()

func _on_button_hovered(index: int) -> void:
	_selected_index = index
	_update_focus()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/player_count_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
