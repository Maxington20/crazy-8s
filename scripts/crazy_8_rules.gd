class_name Crazy8Rules
extends RefCounted


func can_play_card(
	card: CardData,
	top_card: CardData,
	game_state: GameState
) -> bool:
	
	var suit: CardData.Suit
	
	if game_state.active_suit:
		suit = game_state.active_suit
	
	else:
		suit = top_card.suit
	
	return (
		card.rank == CardData.Rank.EIGHT
		or card.rank == top_card.rank
		or card.suit == suit
	)

func two_is_played(game_state: GameState) -> void:
	game_state.pending_draw_count += 2
	

func eight_is_played(game_state: GameState, hand: Array[CardData] = []) -> void:
	
	# allow the user or cpu to select the suit
	if !game_state.is_player_turn:
		var suit_to_pick = get_most_common_suit(hand)
		game_state.active_suit = suit_to_pick
		print("cpu changed suit to ", CardData.Suit.keys()[suit_to_pick])
	else:
		print("player played an eight! weeee")

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
