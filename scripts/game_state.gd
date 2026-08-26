class_name GameState
extends RefCounted

var pending_draw_count: int = 0
var active_suit: CardData.Suit
var has_active_override: bool = false
var is_player_turn: bool = true
var is_game_over: bool = false
