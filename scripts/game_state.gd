class_name GameState
extends RefCounted

var pending_draw_count: int = 0
var active_suit: CardData.Suit
var is_player_turn: bool = true
var is_game_over: bool = false

enum DrawTarget{
	PLAYER,
	CPU,
	NONE
}
	

var active_draw_target: DrawTarget = DrawTarget.NONE
var message_to_display: String
var is_choosing_suit: bool = false
var cpu_strategy: CpuStrategy = CpuStrategy.new()
var deck: Deck
var player_hand: Array[CardData] = []
var cpu_hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var rules: Crazy8Rules = Crazy8Rules.new()
var rank_being_played_this_turn: int = -1
var cards_played_this_turn: int = 0
var has_drawn_this_turn: bool = false
var extra_turn: bool = false
