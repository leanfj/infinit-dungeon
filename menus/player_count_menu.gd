extends Control

@onready var _one_player: Button = $VBoxContainer/PlayerButtons/OnePlayerButton
@onready var _two_players: Button = $VBoxContainer/PlayerButtons/TwoPlayersButton
@onready var _back_button: Button = $VBoxContainer/BackButton

var _buttons: Array[Button] = []
var _selected_index: int = 0

func _ready() -> void:
	_buttons = [_one_player, _two_players, _back_button]
	_selected_index = 0
	
	# Música já está tocando do menu anterior
	
	_one_player.pressed.connect(_on_player_count_selected.bind(1))
	_two_players.pressed.connect(_on_player_count_selected.bind(2))
	_back_button.pressed.connect(_on_back_pressed)
	
	# Connect mouse hover and button press
	for i in range(_buttons.size()):
		_buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
		_buttons[i].pressed.connect(_on_button_pressed)
	
	_update_focus()

func _input(event: InputEvent) -> void:
	# Navigate up
	if event.is_action_pressed("move_up"):
		MenuAudio.play_button_hover()
		_selected_index = (_selected_index - 1 + _buttons.size()) % _buttons.size()
		_update_focus()
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	
	# Navigate down
	elif event.is_action_pressed("move_down"):
		MenuAudio.play_button_hover()
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
	MenuAudio.play_button_hover()
	_selected_index = index
	_update_focus()

func _on_button_pressed() -> void:
	MenuAudio.play_button_click()

func _on_player_count_selected(count: int) -> void:
	# Store player count globally
	GameState.player_count = count
	get_tree().change_scene_to_file("res://menus/character_select_menu.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
