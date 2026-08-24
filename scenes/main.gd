extends Node2D

const STARTING_HAND_SIZE := 7
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")

var deck: Deck
var player_hand: Array[CardData] = []
var cpu_hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var is_player_turn: bool = true
var is_game_over: bool = false

func _ready() -> void:
	deck = Deck.new()
	
	deck.create_standard_deck()
	deck.shuffle()
	
	deal_starting_hands()	
	display_player_hand()
	display_cpu_hand()
	display_draw_pile()
	display_discard_pile()
	

func deal_starting_hands() -> void:
	for i in STARTING_HAND_SIZE:
		player_hand.append(deck.draw_card())
		cpu_hand.append(deck.draw_card())


func display_player_hand() -> void:
	var player_hand_container := $UI/GameUI/PlayerHand
	
	for child in player_hand_container.get_children():
		child.queue_free()
	
	for card in player_hand:
		var card_view := CARD_VIEW_SCENE.instantiate()
		player_hand_container.add_child(card_view)		
		card_view.show_card(card)
		card_view.card_clicked.connect(_on_player_card_clicked)
		

func display_cpu_hand() -> void:
	var cpu_hand_container := $UI/GameUI/CpuHand
	
	for child in cpu_hand_container.get_children():
		child.queue_free()
	
	for card in cpu_hand:
		var card_view := CARD_VIEW_SCENE.instantiate()
		cpu_hand_container.add_child(card_view)
		card_view.show_back()
		

func display_draw_pile() -> void:
	var draw_pile_container := $UI/GameUI/DrawPile
	
	for child in draw_pile_container.get_children():
		child.queue_free()
	
	var card_view := CARD_VIEW_SCENE.instantiate()
	draw_pile_container.add_child(card_view)
	card_view.show_back()
	card_view.card_clicked.connect(
		func(_card): _on_draw_pile_card_clicked()
	)
		
	
func display_discard_pile(card: CardData = null) -> void:
	var discard_pile_container := $UI/GameUI/DiscardPile
	
	for child in discard_pile_container.get_children():
		child.queue_free()
	
	var card_view := CARD_VIEW_SCENE.instantiate()
	
	if !card:
		card = deck.draw_card()
	
	discard_pile_container.add_child(card_view)
	card_view.show_card(card)
	discard_pile.append(card)


func can_play_card(card: CardData, top_card: CardData) -> bool:
	return (
		card.rank == CardData.Rank.EIGHT
		or card.rank == top_card.rank
		or card.suit == top_card.suit
	)
	
func _on_player_card_clicked(card: CardData) -> void:
	
	if !is_player_turn or is_game_over:
		return
	
	var top_card = discard_pile.back()
	if can_play_card(card, top_card):
		display_discard_pile(card)
		player_hand.erase(card)
		display_player_hand()
		
		if(player_hand.is_empty()):
			is_game_over = true
			return
		is_player_turn = false
		
		await get_tree().create_timer(3.0).timeout
		
		cpu_turn()
		
		

func _on_draw_pile_card_clicked() -> void:
	if !is_player_turn or is_game_over:
		return
		
	var drawn_card := deck.draw_card()

	if drawn_card:
		player_hand.append(drawn_card)
		display_player_hand()
		is_player_turn = false
		await get_tree().create_timer(3.0).timeout
		cpu_turn()

func find_cpu_playable_card() -> CardData:
	var top_card = discard_pile.back()
	
	for card in cpu_hand:
		if can_play_card(card, top_card):
			return card
	return null
	
	
func cpu_turn() -> void:
	var card_to_play := find_cpu_playable_card()
	
	if card_to_play:
		cpu_hand.erase(card_to_play)
		display_discard_pile(card_to_play)
		display_cpu_hand()
	
	else:
		var drawn_card = deck.draw_card()
		cpu_hand.append(drawn_card)
		display_cpu_hand()	
	
	if cpu_hand.is_empty():
		is_game_over = true
		return
	
	is_player_turn = true
