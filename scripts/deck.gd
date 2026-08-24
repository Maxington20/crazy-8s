class_name Deck
extends RefCounted

var cards: Array[CardData] = []


func create_standard_deck() -> void:
	cards.clear()
	
	for suit in CardData.Suit.values():
		for rank in CardData.Rank.values():
			var card := CardData.new()
			card.suit = suit
			card.rank = rank
			
			cards.append(card)
			


func shuffle() -> void:
	cards.shuffle()


func draw_card() -> CardData:
	if cards.is_empty():
		return null
	
	return cards.pop_back()
