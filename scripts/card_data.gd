class_name CardData
extends Resource

enum Suit {
	HEARTS,
	CLUBS,
	SPADES,
	DIAMONDS
}


enum Rank {
	ACE,
	TWO,
	THREE,
	FOUR,
	FIVE,
	SIX,
	SEVEN,
	EIGHT,
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING
}

@export var suit: Suit
@export var rank: Rank


func _to_string() -> String:
	var suit_name: String = Suit.keys()[suit]
	var rank_name: String = Rank.keys()[rank]
	
	return rank_name + " of " + suit_name

func get_display_name() -> String:
	var suit_name: String = Suit.keys()[suit]
	var rank_name: String = Rank.keys()[rank]
	
	return rank_name + " of " + suit_name	
