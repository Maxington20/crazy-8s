class_name Crazy8Rules
extends RefCounted


func can_play_card(
	card: CardData,
	top_card: CardData
) -> bool:
	return (
		card.rank == CardData.Rank.EIGHT
		or card.rank == top_card.rank
		or card.suit == top_card.suit
	)
