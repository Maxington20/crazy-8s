class_name Crazy8Rules
extends RefCounted


func can_play_card(
	card: CardData,
	top_card: CardData,
	game_state: GameState
) -> bool:
	
	return (
		card.rank == CardData.Rank.EIGHT
		or card.rank == top_card.rank
		or card.suit == game_state.active_suit
	)

func two_is_played(game_state: GameState) -> void:
	game_state.pending_draw_count += 2
	if game_state.is_player_turn:
		game_state.active_draw_target = game_state.DrawTarget.CPU
	else:
		game_state.active_draw_target = game_state.DrawTarget.PLAYER


func eight_is_played(game_state: GameState, hand: Array[CardData] = []) -> void:
	
	# allow the user or cpu to select the suit
	if !game_state.is_player_turn:
		var suit_to_pick = game_state.cpu_strategy.get_most_common_suit(hand)
		game_state.active_suit = suit_to_pick
