class_name GameView

extends Node

const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const CARD_BACK_TEXTURE := preload("res://art/CardBack.png")
const CARD_BACK_DARK_TEXTURE := preload("res://art/CardBackDark.png")
const CARD_FRONT_TEXTURE := preload("res://art/CardFrontStock.png")
const CARD_FRONT_TEXTURE_DARK := preload("res://art/CardFrontStockDark.png")

@onready var player_hand_container: HBoxContainer = $UI/GameUI/PlayerHand
@onready var cpu_hand_container: HBoxContainer = $UI/GameUI/CpuHand
@onready var draw_pile_container: Control = $UI/GameUI/DrawPile
@onready var discard_pile_container: Control = $UI/GameUI/DiscardPile
@onready var animation_layer: Control = $UI/GameUI/AnimationLayer
@onready var turn_label: Label = $UI/GameUI/GameStatus/VBoxContainer/TurnDisplay
@onready var active_suit_label: Label = $UI/GameUI/GameStatus/VBoxContainer/ActiveSuit
@onready var game_status_box: PanelContainer = $UI/GameUI/GameStatus
@onready var message_label : Label = $UI/GameUI/MessageContainer/HBoxContainer/Message
@onready var message_container: PanelContainer = $UI/GameUI/MessageContainer
@onready var suit_selector_container: PanelContainer = $UI/GameUI/SuitSelector
@onready var main_menu_container: Panel = $UI/GameUI/MainMenuContainer
@onready var end_turn_button_container: PanelContainer = $UI/GameUI/EndTurnButtonContainer

signal draw_pile_clicked(card: CardData)
signal player_card_double_clicked(card_view: CardView, card: CardData)

var game_state: GameState

func initialize(state: GameState) -> void:
	game_state = state

func show_message(message: String, hide_after_wait: bool = true) -> void:
	message_label.text = message
	message_container.visible = true
	if hide_after_wait:
		await get_tree().create_timer(2).timeout
		message_container.visible = false


func create_deck_view() -> CardView:
	var deck_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(deck_view)
	deck_view.show_back()
	deck_view.global_position = Vector2(296, 148)

	return deck_view
	

func animate_deal_card(
	card: CardData,
	start_position: Vector2,
	target_position: Vector2
) -> void:
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(card_view)

	card_view.show_back(card)
	card_view.global_position = start_position
	
	var sound_timer := get_tree().create_timer(0.08)
	sound_timer.timeout.connect(SoundManager.play_card)
	
	await card_view.move_to(
		target_position,
		0.25
	)

	card_view.queue_free()



func display_player_hand() -> void:
	
	adjust_card_separation(game_state.player_hand, true)
	
	for child in player_hand_container.get_children():
		child.queue_free()

	sort_player_hand()

	for card in game_state.player_hand:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		
		player_hand_container.add_child(card_view)
		
		card_view.show_card(card)			
		
		if game_state.discard_pile.size() > 0:
		
			var playable := game_state.rules.can_play_card(
				card, game_state.discard_pile.back(),
				game_state
			)
		
			card_view.set_playable(playable)
		
		card_view.card_double_clicked.connect(
			func(card_view: CardView, card: CardData):
				player_card_double_clicked.emit(card_view, card)
		)


func display_cpu_hand(game_state: GameState) -> void:
	
	adjust_card_separation(game_state.cpu_hand, false)
	
	for child in cpu_hand_container.get_children():
		child.queue_free()

	for card in game_state.cpu_hand:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()

		cpu_hand_container.add_child(card_view)

		card_view.show_back(card)


func display_draw_pile() -> void:
	for child in draw_pile_container.get_children():
		child.queue_free()

	#if deck.cards.is_empty():
		#return
	
	var offset = populate_draw_pile_visuals()
	
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()
	
	card_view.position = Vector2(offset, offset)
	
	draw_pile_container.add_child(card_view)

	card_view.show_back()

	card_view.card_clicked.connect(
		func(card: CardData):
			draw_pile_clicked.emit(card)
	)


func display_discard_pile() -> void:
	for child in discard_pile_container.get_children():
		child.queue_free()

	if game_state.discard_pile.is_empty():
		return

	var offset = populate_discard_pile_visuals()

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()
	
	card_view.position = Vector2(offset, offset)
	
	discard_pile_container.add_child(card_view)

	var top_card: CardData = game_state.discard_pile.back()

	card_view.show_card(top_card)
	
	
	
func adjust_card_separation(hand: Array[CardData], is_player_hand: bool) -> void:
	var normal_separation = 4
	if hand.size() > 12:	
		var separation = (605 - hand.size() * 48) / (hand.size() - 1)
		
		if is_player_hand:
			player_hand_container.add_theme_constant_override("separation", separation)
			
		else:
			cpu_hand_container.add_theme_constant_override("separation", separation)
	
	else:
		if is_player_hand:
			player_hand_container.add_theme_constant_override("separation", normal_separation)
			
		else:
			cpu_hand_container.add_theme_constant_override("separation", normal_separation)
			
			
			
func sort_player_hand() -> void:
	game_state.player_hand.sort_custom(compare_cards)




func populate_draw_pile_visuals() -> float:
	var offset = 0
	for i in game_state.deck.cards.size() - 1:
		var visual := TextureRect.new()
		if i % 2 == 0:
			visual.texture = CARD_BACK_TEXTURE
		else:
			visual.texture = CARD_BACK_DARK_TEXTURE
		
		visual.size = Vector2(48, 64)
		visual.position = Vector2(offset, offset)
		draw_pile_container.add_child(visual)
		offset += 0.2
	return offset
		
		
func populate_discard_pile_visuals() -> float:
	var offset = 0
	for i in game_state.discard_pile.size() -1:
		var visual := TextureRect.new()
		if i % 2 == 0:
			visual.texture = CARD_FRONT_TEXTURE_DARK	
		else:
			visual.texture = CARD_FRONT_TEXTURE
		
		visual.size = Vector2(48, 64)
		visual.position = Vector2(offset, offset)
		discard_pile_container.add_child(visual)
		offset += 0.2
	return offset


func compare_cards(a: CardData, b: CardData) -> bool:
	if a.suit < b.suit:
		return true
		
	elif a.suit == b.suit:
		if(a.rank < b.rank):
			return true
		else:
			return false
	
	else:
		return false
		
		
func set_turn_label() -> void:
	
	var label_text: String
	
	if game_state.is_player_turn:
		label_text = "Player Turn"
	else:
		label_text = "CPU Turn"
		
	turn_label.text = label_text
		


func set_suit_label() -> void:
	var label_text : String = CardData.Suit.keys()[game_state.active_suit]
	label_text = label_text.substr(0, 1).to_upper() + label_text.substr(1).to_lower()
	
	active_suit_label.text = label_text
