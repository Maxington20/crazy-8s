extends Node2D

const STARTING_HAND_SIZE := 7

var deck: Deck
var player_hand: Array[CardData] = []
var cpu_hand: Array[CardData] = []

func _ready() -> void:
	deck = Deck.new()
	
	deck.create_standard_deck()
	deck.shuffle()
	
	deal_starting_hands()
	
	


func deal_starting_hands() -> void:
	for i in STARTING_HAND_SIZE:
		player_hand.append(deck.draw_card())
		cpu_hand.append(deck.draw_card())
		
	print("Player Hand")
	for card in player_hand:
		print(card)
		
	print("CPU Hand")
	for card in cpu_hand:
		print(card)
		
	print("Cards remaining: ", deck.cards.size())
