extends CanvasLayer

@onready var _panel: Control = $Control
@onready var _resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var _quit_button: Button = $Control/VBoxContainer/QuitButton

var _buttons: Array[Button] = []
var _selected_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false

	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	
	_buttons = [_resume_button, _restart_button, _quit_button]
	_selected_index = 0
	
	# Connect mouse hover to update selection
	for i in range(_buttons.size()):
		_buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))


func _input(event: InputEvent) -> void:
	# Extra guard to catch input even if unhandled_input is consumed elsewhere.
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo):
		_toggle_pause()
	
	if not _panel.visible:
		return
	
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
func _toggle_pause() -> void:
	if _panel.visible:
		_resume_game()
	else:
		_show_menu()


func _update_focus() -> void:
	for i in range(_buttons.size()):
		if i == _selected_index:
			_buttons[i].grab_focus()


func _on_button_hovered(index: int) -> void:
	_selected_index = index
	_update_focus()

func _show_menu() -> void:
	_panel.visible = true
	get_tree().paused = true
	_selected_index = 0
	_update_focus()


func _resume_game() -> void:
	_panel.visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_resume_game()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
