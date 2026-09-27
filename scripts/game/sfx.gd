extends Node

var _players: Dictionary = {}


func _ready() -> void:
	for name in ["tap", "cook", "ding", "take", "coin", "angry", "burn", "trash", "wrong", "win", "lose"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/sfx/%s.wav" % name)
		add_child(player)
		_players[name] = player


func play(name: String) -> void:
	if _players.has(name):
		_players[name].play()
