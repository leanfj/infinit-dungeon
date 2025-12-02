extends Control

@onready var _character_grid: GridContainer = $VBoxContainer/CharacterGrid
@onready var _back_button: Button = $VBoxContainer/BackButton
@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _info_label: Label = $VBoxContainer/InfoLabel

var _buttons: Array[Button] = []
var _selected_index: int = 0
var _selections: Dictionary = {} # player_index -> character_name

# Available characters
const CHARACTERS = [
	{"name": "Mage", "scene": "res://entities/player/player_character_body_2d.tscn", "description": "Master of magic"}
]

func _ready() -> void:
	_setup_character_buttons()
	_update_info_label()
	
	# Música já está tocando do menu anterior
	
	_back_button.pressed.connect(_on_back_pressed)
	_start_button.pressed.connect(_on_start_pressed)
	
	# Connect mouse hover and button press
	for i in range(_buttons.size()):
		_buttons[i].mouse_entered.connect(_on_button_hovered.bind(i))
		_buttons[i].pressed.connect(_on_button_pressed)
	
	_update_focus()

func _setup_character_buttons() -> void:
	# Create buttons for each character
	for character in CHARACTERS:
		var button := Button.new()
		button.text = character["name"]
		button.custom_minimum_size = Vector2(60, 20)
		button.add_theme_font_size_override("font_size", 8)
		button.pressed.connect(_on_character_selected.bind(character["name"]))
		_character_grid.add_child(button)
		_buttons.append(button)
	
	# Add navigation buttons to the list
	_buttons.append(_start_button)
	_buttons.append(_back_button)

func _input(event: InputEvent) -> void:
	# Navigate left
	if event.is_action_pressed("move_left"):
		MenuAudio.play_button_hover()
		_navigate_grid(-1)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	
	# Navigate right
	elif event.is_action_pressed("move_right"):
		MenuAudio.play_button_hover()
		_navigate_grid(1)
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
	
	# Navigate up
	elif event.is_action_pressed("move_up"):
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

func _navigate_grid(direction: int) -> void:
	var char_buttons_count := CHARACTERS.size()
	
	# Only navigate horizontally if in the character grid
	if _selected_index < char_buttons_count:
		var new_index := _selected_index + direction
		if new_index >= 0 and new_index < char_buttons_count:
			_selected_index = new_index
	
	_update_focus()

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

func _on_character_selected(character_name: String) -> void:
	var next_player := _get_next_player_to_select()
	if next_player != -1:
		_selections[next_player] = character_name
		_update_info_label()
		
		# Auto-select start button if all players selected
		if _selections.size() == GameState.player_count:
			_selected_index = _buttons.size() - 2 # Start button
			_update_focus()

func _get_next_player_to_select() -> int:
	for i in range(GameState.player_count):
		if not _selections.has(i):
			return i
	return -1

func _update_info_label() -> void:
	var next_player := _get_next_player_to_select()
	if next_player != -1:
		_info_label.text = "Player %d - Select Character" % (next_player + 1)
	else:
		_info_label.text = "All players ready! Press Start"

func _on_start_pressed() -> void:
	# Check if all players have selected
	if _selections.size() != GameState.player_count:
		_info_label.text = "Please select characters for all players!"
		return
	
	# Parar música do menu ao iniciar o jogo
	MenuAudio.stop_menu_music()
	
	# Store selections in GameState
	GameState.selected_characters.clear()
	for i in range(GameState.player_count):
		GameState.selected_characters.append(_selections[i])
	
	# Start the game
	get_tree().change_scene_to_file("res://scenes/world_node_2d.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/player_count_menu.tscn")
