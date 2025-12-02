extends Node

# Configurações de áudio - podem ser alteradas facilmente
@export var menu_music_path: String = "res://assets/audio/menu_music.ogg"
@export var button_hover_sound_path: String = "res://assets/audio/button_hover.ogg"
@export var button_click_sound_path: String = "res://assets/audio/button_click.ogg"
@export var music_volume_db: float = -15.0
@export var sfx_volume_db: float = -30.0

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_setup_audio_players()
	_load_audio_resources()

func _setup_audio_players() -> void:
	# Player para música de fundo
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MenuMusicPlayer"
	_music_player.bus = "Music"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)
	
	# Player para efeitos sonoros
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "MenuSFXPlayer"
	_sfx_player.bus = "SFX"
	_sfx_player.volume_db = sfx_volume_db
	add_child(_sfx_player)

func _load_audio_resources() -> void:
	# Carrega a música do menu se existir
	if ResourceLoader.exists(menu_music_path):
		var music_stream = load(menu_music_path)
		if music_stream:
			_music_player.stream = music_stream
			_music_player.autoplay = false

func play_menu_music() -> void:
	if _music_player.stream and not _music_player.playing:
		_music_player.play()

func stop_menu_music() -> void:
	if _music_player.playing:
		_music_player.stop()

func play_button_hover() -> void:
	if ResourceLoader.exists(button_hover_sound_path):
		var sfx = load(button_hover_sound_path)
		if sfx:
			_sfx_player.stream = sfx
			_sfx_player.play()

func play_button_click() -> void:
	if ResourceLoader.exists(button_click_sound_path):
		var sfx = load(button_click_sound_path)
		if sfx:
			_sfx_player.stream = sfx
			_sfx_player.play()

func set_music_volume(volume_db: float) -> void:
	music_volume_db = volume_db
	_music_player.volume_db = volume_db

func set_sfx_volume(volume_db: float) -> void:
	sfx_volume_db = volume_db
	_sfx_player.volume_db = volume_db

func change_menu_music(new_music_path: String) -> void:
	menu_music_path = new_music_path
	if ResourceLoader.exists(new_music_path):
		var music_stream = load(new_music_path)
		if music_stream:
			var was_playing := _music_player.playing
			_music_player.stop()
			_music_player.stream = music_stream
			if was_playing:
				_music_player.play()
