class_name CpuStrategy
extends RefCounted


func get_most_common_suit(hand: Array[CardData]) -> CardData.Suit:
	var suit_counts := {}
	
	for card in hand:
		suit_counts[card.suit] = suit_counts.get(card.suit, 0) + 1
		
	var max_suit: CardData.Suit
	var max_count := -1
	
	for suit in suit_counts.keys():
		if suit_counts[suit] > max_count:
			max_count = suit_counts[suit]
			max_suit = suit
	
	return max_suit


func find_cpu_playable_card(game_state: GameState) -> CardData:
	var top_card: CardData = game_state.discard_pile.back()

	for card in game_state.cpu_hand:
		if game_state.rules.can_play_card(card, top_card, game_state):
			return card

	return null
