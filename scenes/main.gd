extends Node2D

const STARTING_HAND_SIZE := 7
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")
const CARD_BACK_TEXTURE := preload("res://art/CardBack.png")
const CARD_BACK_DARK_TEXTURE := preload("res://art/CardBackDark.png")
const CARD_FRONT_TEXTURE := preload("res://art/CardFrontStock.png")
const CARD_FRONT_TEXTURE_DARK := preload("res://art/CardFrontStockDark.png")

var deck: Deck
var player_hand: Array[CardData] = []
var cpu_hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var game_state: GameState = GameState.new()
var rules: Crazy8Rules = Crazy8Rules.new()

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


signal suit_selected(suit: CardData.Suit)

func _ready() -> void:
	game_status_box.visible = false
	message_container.visible = false 
	suit_selector_container.visible = false
	deck = Deck.new()

	deck.create_standard_deck()
	deck.shuffle()

	await play_opening_deal()
	
	var num = randf()
	
	if num >= 0.5:
		game_state.is_player_turn = true
	else:
		game_state.is_player_turn = false
		
		
	set_turn_label()
	
	set_suit_label()
	
	game_status_box.visible = true
	
	if game_state.is_player_turn == false:
		await cpu_turn()


func play_opening_deal() -> void:
	var deck_view := create_deck_view()

	await deal_starting_hands_from(deck_view)

	await deck_view.move_to(
		draw_pile_container.global_position,
		0.4
	)

	await deal_starting_discard()

	deck_view.queue_free()

	display_draw_pile()
	
	display_player_hand()


func create_deck_view() -> CardView:
	var deck_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(deck_view)
	deck_view.show_back()

	# Starting position of the deck before dealing.
	# Adjust this if you want the dealer deck somewhere else.
	deck_view.global_position = Vector2(296, 148)

	return deck_view


func deal_starting_hands_from(deck_view: CardView) -> void:
	for i in STARTING_HAND_SIZE:
		var player_card: CardData = deck.draw_card()

		await animate_deal_card(
			player_card,
			deck_view.global_position,
			get_player_draw_target()
		)

		player_hand.append(player_card)
		display_player_hand()

		await get_tree().create_timer(0.08).timeout

		var cpu_card: CardData = deck.draw_card()

		await animate_deal_card(
			cpu_card,
			deck_view.global_position,
			get_cpu_draw_target()
		)

		cpu_hand.append(cpu_card)
		display_cpu_hand()

		await get_tree().create_timer(0.08).timeout


func animate_deal_card(
	card: CardData,
	start_position: Vector2,
	target_position: Vector2
) -> void:
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(card_view)

	card_view.show_back(card)
	card_view.global_position = start_position

	await card_view.move_to(
		target_position,
		0.25
	)

	card_view.queue_free()


func deal_starting_discard() -> void:
	var starting_card: CardData = deck.draw_card()

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(card_view)

	card_view.show_back(starting_card)
	card_view.global_position = draw_pile_container.global_position

	await card_view.move_to(
		discard_pile_container.global_position,
		0.35
	)

	card_view.show_card(starting_card)

	discard_pile.append(starting_card)

	await get_tree().create_timer(0.2).timeout

	card_view.queue_free()

	display_discard_pile()
	
	game_state.active_suit = starting_card.suit


func display_player_hand() -> void:
	
	adjust_card_separation(player_hand, true)
	
	for child in player_hand_container.get_children():
		child.queue_free()

	sort_player_hand()

	for card in player_hand:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		
		player_hand_container.add_child(card_view)
		
		card_view.show_card(card)			
		
		if discard_pile.size() > 0:
		
			var playable := rules.can_play_card(
				card, discard_pile.back(),
				game_state
			)
		
			card_view.set_playable(playable)
		
		card_view.card_double_clicked.connect(
			_on_player_card_double_clicked
		)


func display_cpu_hand() -> void:
	
	adjust_card_separation(cpu_hand, false)
	
	for child in cpu_hand_container.get_children():
		child.queue_free()

	for card in cpu_hand:
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
		_on_draw_pile_card_clicked
	)


func display_discard_pile() -> void:
	for child in discard_pile_container.get_children():
		child.queue_free()

	if discard_pile.is_empty():
		return

	var offset = populate_discard_pile_visuals()

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()
	
	card_view.position = Vector2(offset, offset)
	
	discard_pile_container.add_child(card_view)

	var top_card: CardData = discard_pile.back()

	card_view.show_card(top_card)
	

func _on_player_card_double_clicked(
	card_view: CardView,
	card: CardData
) -> void:
	if !game_state.is_player_turn or game_state.is_game_over or game_state.is_choosing_suit:
		return
	
	var top_card: CardData = discard_pile.back()
	var extra_turn: bool = false
	
	if !rules.can_play_card(card, top_card, game_state):
		return
	
	# check for special cards
	if card.rank == CardData.Rank.EIGHT:
		rules.eight_is_played(game_state)
		# remove below after suit selectin for player complete
		game_state.is_choosing_suit = true
		suit_selector_container.visible = true
		var suit = await suit_selected
		game_state.is_choosing_suit = false
		game_state.message_to_display = "Player changed it to " + CardData.Suit.keys()[suit]
	
	else:
		game_state.active_suit = card.suit
		
	if card.rank == CardData.Rank.TWO:
		rules.two_is_played(game_state)		
		game_state.message_to_display = "Pick Up " + str(game_state.pending_draw_count) + " Cards CPU!"
	else:
		game_state.pending_draw_count = 0
		game_state.active_draw_target = game_state.DrawTarget.NONE
	
	if card.rank == CardData.Rank.JACK:
		extra_turn = true
		game_state.message_to_display = "Miss A Turn CPU!"
	
	if !extra_turn:
		game_state.is_player_turn = false

	await animate_card_to_discard(card_view)

	player_hand.erase(card)
	discard_pile.append(card)

	card_view.queue_free()

	display_player_hand()
	display_discard_pile()
	
	if game_state.message_to_display.length() > 0:
		await show_message(game_state.message_to_display)
		game_state.message_to_display = ""
			
	if player_hand.size() == 1:
		game_state.message_to_display = "Knock Knock, Last Card!"
		await show_message(game_state.message_to_display)
		game_state.message_to_display = ""
	
	if player_hand.is_empty():
		game_state.is_game_over = true
		game_state.message_to_display = "Player Wins!"
		await show_message(game_state.message_to_display, false)
		return
	
	set_suit_label()
	
	if !extra_turn:
		await cpu_turn()

		

func _on_draw_pile_card_clicked(
	_card: CardData
) -> void:
	if !game_state	.is_player_turn or game_state.is_game_over or game_state.is_choosing_suit:
		return

	if !refill_draw_pile():
		return
	
	game_state.active_draw_target = game_state.DrawTarget.NONE
	game_state.is_player_turn = false

	var drawn_card: CardData = deck.draw_card()

	await animate_draw_to_player(drawn_card)

	player_hand.append(drawn_card)

	display_player_hand()
	display_draw_pile()

	await get_tree().create_timer(1.0).timeout
	
	await cpu_turn()


func find_cpu_playable_card() -> CardData:
	var top_card: CardData = discard_pile.back()

	for card in cpu_hand:
		if rules.can_play_card(card, top_card, game_state):
			return card

	return null


func cpu_turn() -> void:
	print("Entered cpu turn")
	if game_state.is_game_over:
		return
	
	var extra_turn = false
	
	await begin_cpu_turn()
	
	var card_to_play := find_cpu_playable_card()
	
	print("card to play ", card_to_play)
	
	if card_to_play:
		
		if card_to_play.rank == CardData.Rank.EIGHT:
			rules.eight_is_played(game_state, cpu_hand)
			game_state.message_to_display = "CPU Changed Suit To " + str(CardData.Suit.keys()[game_state.active_suit])
		
		else:
			game_state.active_suit = card_to_play.suit
			
		if card_to_play.rank == CardData.Rank.TWO:
			rules.two_is_played(game_state)
			game_state.message_to_display = "Pick Up " + str(game_state.pending_draw_count) + " Cards Player!" 
		else:
			game_state.pending_draw_count = 0
			game_state.active_draw_target = game_state.DrawTarget.NONE
		
		if card_to_play.rank == CardData.Rank.JACK:
			game_state.message_to_display = "Miss A Turn Player!"
			extra_turn = true
		
		var card_view := find_cpu_card_view(card_to_play)

		if card_view:
			card_view.show_card(card_to_play)

			await animate_card_to_discard(card_view)

		cpu_hand.erase(card_to_play)
		discard_pile.append(card_to_play)

		if card_view:
			card_view.queue_free()

		display_cpu_hand()
		display_discard_pile()
		set_suit_label()
		
		if game_state.message_to_display.length() > 0:
			await show_message(game_state.message_to_display)
			game_state.message_to_display = ""
		
	else:
		if refill_draw_pile():
			var drawn_card: CardData = deck.draw_card()

			await animate_draw_to_cpu(drawn_card)
			game_state.active_draw_target = game_state.DrawTarget.NONE
			cpu_hand.append(drawn_card)

			display_cpu_hand()
			display_draw_pile()
	
	if cpu_hand.size() == 1:
		game_state.message_to_display = "Knock Knock, Last Card!"
		await show_message(game_state.message_to_display)
		game_state.message_to_display = ""
	
	if cpu_hand.is_empty():
		game_state.is_game_over = true
		game_state.message_to_display = "CPU Wins!"
		await show_message(game_state.message_to_display, false)
		return
	
	if extra_turn:
		await get_tree().create_timer(1.0).timeout
		await cpu_turn()
		return
	
	game_state.is_player_turn = true
	
	await begin_player_turn()
	
	


func refill_draw_pile() -> bool:
	if !deck.cards.is_empty():
		return true

	if discard_pile.size() <= 1:
		return false

	var top_card: CardData = discard_pile.pop_back()

	for card in discard_pile:
		deck.cards.append(card)

	discard_pile.clear()
	discard_pile.append(top_card)

	deck.shuffle()

	display_draw_pile()

	return true


func animate_card_to_discard(
	card_view: CardView
) -> void:
	var starting_position := card_view.global_position

	card_view.reparent(animation_layer)

	card_view.global_position = starting_position

	await card_view.move_to(
		discard_pile_container.global_position
	)


func animate_draw_to_player(
	card: CardData
) -> void:
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(card_view)

	card_view.show_back(card)

	card_view.global_position = draw_pile_container.global_position
	
	var target_positioin = get_player_draw_target()
	
	var halfway_point = card_view.global_position.lerp(target_positioin, 0.5)
	
	await card_view.move_to(halfway_point)
	
	card_view.show_card(card)
	
	await card_view.move_to(target_positioin)
	
	card_view.queue_free()


func animate_draw_to_cpu(
	card: CardData
) -> void:
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	animation_layer.add_child(card_view)

	card_view.show_back(card)

	card_view.global_position = draw_pile_container.global_position

	await card_view.move_to(
		get_cpu_draw_target()
	)

	card_view.queue_free()


func get_player_draw_target() -> Vector2:
	var card_count := player_hand.size()

	return player_hand_container.global_position + Vector2(
		card_count * 48,
		0
	)


func get_cpu_draw_target() -> Vector2:
	var card_count := cpu_hand.size()

	return cpu_hand_container.global_position + Vector2(
		card_count * 48,
		0
	)


func find_cpu_card_view(
	card: CardData
) -> CardView:
	for child in cpu_hand_container.get_children():
		if child is CardView and child.card_data == card:
			return child

	return null
	
	
func begin_player_turn() -> void:
	
	set_turn_label()
	display_player_hand()
	
	if game_state.pending_draw_count and game_state.active_draw_target == game_state.DrawTarget.PLAYER:
		for card in game_state.pending_draw_count:
			if refill_draw_pile():
				var drawn_card: CardData = deck.draw_card()

				await animate_draw_to_player(drawn_card)

				player_hand.append(drawn_card)

				display_player_hand()
				display_draw_pile()

				await get_tree().create_timer(0.5).timeout
		

func begin_cpu_turn() -> void:	
	set_turn_label()
	await get_tree().create_timer(1.5).timeout	
	
	# draw cards if 2 was played
	if game_state.pending_draw_count and game_state.active_draw_target == game_state.DrawTarget.CPU:
		# draw pending count of cards before playing
		for count in game_state.pending_draw_count:
			if refill_draw_pile():
				var drawn_card: CardData = deck.draw_card()

				await animate_draw_to_cpu(drawn_card)

				cpu_hand.append(drawn_card)

				display_cpu_hand()
				display_draw_pile()
				
				await get_tree().create_timer(0.5).timeout
		
		

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


func _on_spades_pressed() -> void:
	game_state.active_suit = CardData.Suit.SPADES
	suit_selected.emit(CardData.Suit.SPADES)
	suit_selector_container.visible = false
	

func _on_clubs_pressed() -> void:
	game_state.active_suit = CardData.Suit.CLUBS
	suit_selected.emit(CardData.Suit.CLUBS)
	suit_selector_container.visible = false
	

func _on_diamonds_pressed() -> void:
	game_state.active_suit = CardData.Suit.DIAMONDS
	suit_selected.emit(CardData.Suit.DIAMONDS)
	suit_selector_container.visible = false


func _on_hearts_pressed() -> void:
	game_state.active_suit = CardData.Suit.HEARTS
	suit_selected.emit(CardData.Suit.HEARTS)
	suit_selector_container.visible = false
	
	
	
func populate_draw_pile_visuals() -> float:
	var offset = 0
	for i in deck.cards.size() - 1:
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
	for i in discard_pile.size() -1:
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
		

func sort_player_hand() -> void:
	player_hand.sort_custom(compare_cards)
	
	
func show_message(message: String, hide_after_wait: bool = true) -> void:
	message_label.text = message
	message_container.visible = true
	if hide_after_wait:
		await get_tree().create_timer(2).timeout
		message_container.visible = false
