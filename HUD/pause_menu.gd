extends CanvasLayer

@onready var _panel: Control = $Control
@onready var _resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $Control/VBoxContainer/RestartButton
@onready var _quit_button: Button = $Control/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false

	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	# Extra guard to catch input even if unhandled_input is consumed elsewhere.
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo):
		_toggle_pause()


func _toggle_pause() -> void:
	if _panel.visible:
		_resume_game()
	else:
		_show_menu()


func _show_menu() -> void:
	_panel.visible = true
	get_tree().paused = true


func _resume_game() -> void:
	_panel.visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_resume_game()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
