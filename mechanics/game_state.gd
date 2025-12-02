extends Node

# Global game state
var player_count: int = 1
var selected_characters: Array[String] = []

func _ready() -> void:
	reset()

func reset() -> void:
	player_count = 1
	selected_characters.clear()
