extends CanvasLayer

@onready var _panel: Control = $Control
@onready var _restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var _quit_button: Button = $Control/VBoxContainer/QuitButton
var _connected_to_player: bool = false

var _buttons: Array[Button] = []
var _selected_index: int = 0

func _ready() -> void:
	# ensure this HUD and its panel keep processing while the scene is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_try_connect_player()
	
	_buttons = [_restart_button, _quit_button]
	_selected_index = 0
	
	# Connect mouse hover to update selection
	for i in range(_buttons.size()):
		_buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))


func _process(_delta: float) -> void:
	if not _connected_to_player:
		_try_connect_player()


func _try_connect_player() -> void:
	if _connected_to_player:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)
		_connected_to_player = true


func _input(event: InputEvent) -> void:
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


func _update_focus() -> void:
	for i in range(_buttons.size()):
		if i == _selected_index:
			_buttons[i].grab_focus()


func _on_button_hovered(index: int) -> void:
	_selected_index = index
	_update_focus()


func _on_player_died() -> void:
	_panel.visible = true
	get_tree().paused = true
	_selected_index = 0
	_update_focus()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
