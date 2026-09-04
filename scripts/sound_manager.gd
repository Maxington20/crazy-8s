extends Node

const CARD_PLAY_SOUND := preload("res://sfx/571577__el_boss__playing-card-deal-variation-1.wav")
const PLAYER_COUNT := 4

var players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		
		player.volume_db = -30.0
		
		add_child(player)
		players.append(player)



func play_card() -> void:
	for player in players:
		if !player.playing:
			player.stream = CARD_PLAY_SOUND
			player.play()
			return
