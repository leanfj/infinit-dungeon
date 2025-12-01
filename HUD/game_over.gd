extends CanvasLayer

@onready var _panel: Control = $Control
@onready var _restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var _quit_button: Button = $Control/VBoxContainer/QuitButton
var _connected_to_player: bool = false

func _ready() -> void:
	# ensure this HUD and its panel keep processing while the scene is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_try_connect_player()


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


func _on_player_died() -> void:
	_panel.visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
