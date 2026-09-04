extends Node2D

const STARTING_HAND_SIZE := 7
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")

@onready var game_view: GameView = $GameView

var game_state: GameState = GameState.new()

signal suit_selected(suit: CardData.Suit)
signal game_started()
signal turn_ended()

func _ready() -> void:
	game_view.initialize(game_state)
	
	game_view.draw_pile_clicked.connect(_on_draw_pile_card_clicked)
	game_view.player_card_double_clicked.connect(_on_player_card_double_clicked)
	
	game_view.game_status_box.visible = false
	game_view.message_container.visible = false 
	game_view.suit_selector_container.visible = false
	game_view.main_menu_container.visible = true
	game_view.end_turn_button_container.visible = false
	
	await game_started
	
	game_state.deck = Deck.new()

	game_state.deck.create_standard_deck()
	game_state.deck.shuffle()

	await play_opening_deal()
	
	var num = randf()
	
	if num >= 0.5:
		game_state.is_player_turn = true
	else:
		game_state.is_player_turn = false
		
		
	game_view.set_turn_label()
	
	game_view.set_suit_label()
	
	game_view.game_status_box.visible = true
	
	if game_state.is_player_turn == false:
		await cpu_turn()


func play_opening_deal() -> void:
	var deck_view := game_view.create_deck_view()

	await deal_starting_hands_from(deck_view)

	await deck_view.move_to(
		game_view.draw_pile_container.global_position,
		0.4
	)

	await deal_starting_discard()

	deck_view.queue_free()

	game_view.display_draw_pile()
	
	game_view.display_player_hand()





func deal_starting_hands_from(deck_view: CardView) -> void:
	for i in STARTING_HAND_SIZE:
		var player_card: CardData = game_state.deck.draw_card()

		await game_view.animate_deal_card(
			player_card,
			deck_view.global_position,
			get_player_draw_target()
		)

		game_state.player_hand.append(player_card)
		game_view.display_player_hand()

		await get_tree().create_timer(0.08).timeout

		var cpu_card: CardData = game_state.deck.draw_card()

		await game_view.animate_deal_card(
			cpu_card,
			deck_view.global_position,
			get_cpu_draw_target()
		)

		game_state.cpu_hand.append(cpu_card)
		game_view.display_cpu_hand(game_state)

		await get_tree().create_timer(0.08).timeout





func deal_starting_discard() -> void:
	var starting_card: CardData = game_state.deck.draw_card()

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	game_view.animation_layer.add_child(card_view)

	card_view.show_back(starting_card)
	card_view.global_position = game_view.draw_pile_container.global_position

	await card_view.move_to(
		game_view.discard_pile_container.global_position,
		0.35
	)

	card_view.show_card(starting_card)

	game_state.discard_pile.append(starting_card)

	await get_tree().create_timer(0.2).timeout

	card_view.queue_free()

	game_view.display_discard_pile()
	
	game_state.active_suit = starting_card.suit



	

func _on_player_card_double_clicked(
	card_view: CardView,
	card: CardData
) -> void:
	if !game_state.is_player_turn or game_state.is_game_over or game_state.is_choosing_suit:
		return
	
	var top_card: CardData = game_state.discard_pile.back()
	
	if !game_state.rules.can_play_card(card, top_card, game_state):
		return
	
	# check for special cards
	if card.rank == CardData.Rank.EIGHT:
		game_state.rules.eight_is_played(game_state)
		# remove below after suit selectin for player complete
		game_state.is_choosing_suit = true
		game_view.suit_selector_container.visible = true
		var suit = await suit_selected
		game_state.is_choosing_suit = false
		game_state.message_to_display = "Player changed it to " + CardData.Suit.keys()[suit]
	
	else:
		game_state.active_suit = card.suit
		
	if card.rank == CardData.Rank.TWO:
		game_state.rules.two_is_played(game_state)
		game_state.message_to_display = "Pick Up " + str(game_state.pending_draw_count) + " Cards CPU!"
	else:
		game_state.pending_draw_count = 0
		game_state.active_draw_target = game_state.DrawTarget.NONE
	
	if card.rank == CardData.Rank.JACK:
		game_state.extra_turn = true
		game_state.message_to_display = "Miss A Turn CPU!"
		
	game_state.cards_played_this_turn += 1
	game_state.rank_being_played_this_turn = card.rank

	await animate_card_to_discard(card_view)

	game_state.player_hand.erase(card)
	game_state.discard_pile.append(card)

	card_view.queue_free()

	game_view.display_player_hand()
	game_view.display_discard_pile()
	
	if game_state.message_to_display.length() > 0:
		await game_view.show_message(game_state.message_to_display)
		game_state.message_to_display = ""
			
	if game_state.player_hand.size() == 1:
		game_state.message_to_display = "Knock Knock, Last Card!"
		await game_view.show_message(game_state.message_to_display)
		game_state.message_to_display = ""
	
	if game_state.player_hand.is_empty():
		game_state.is_game_over = true
		game_state.message_to_display = "Player Wins!"
		await game_view.show_message(game_state.message_to_display, true)
		get_tree().reload_current_scene()
		return
	
	game_view.set_suit_label()
	
	game_view.end_turn_button_container.visible = true

		

func _on_draw_pile_card_clicked(
	_card: CardData
) -> void:
	if !game_state	.is_player_turn or game_state.is_game_over or game_state.is_choosing_suit or game_state.has_drawn_this_turn or game_state.cards_played_this_turn > 0:
		return

	if !refill_draw_pile():
		return
	
	game_state.active_draw_target = game_state.DrawTarget.NONE

	var drawn_card: CardData = game_state.deck.draw_card()

	game_state.has_drawn_this_turn = true

	await animate_draw_to_player(drawn_card)

	game_state.player_hand.append(drawn_card)
	
	game_view.display_player_hand()
	game_view.display_draw_pile()

	await get_tree().create_timer(1.0).timeout
	
	game_view.end_turn_button_container.visible = true

func cpu_turn() -> void:
	if game_state.is_game_over:
		return
	
	await begin_cpu_turn()
	
	for card in game_state.cpu_hand:
		
		var card_to_play := game_state.cpu_strategy.find_cpu_playable_card(game_state)
			
		if card_to_play:
			
			await cpu_play_card(card_to_play)
			
		elif !game_state.has_drawn_this_turn and game_state.cards_played_this_turn == 0:
			if refill_draw_pile():
				var drawn_card: CardData = game_state.deck.draw_card()

				await animate_draw_to_cpu(drawn_card)
				game_state.active_draw_target = game_state.DrawTarget.NONE
				game_state.cpu_hand.append(drawn_card)

				game_view.display_cpu_hand(game_state)
				game_view.display_draw_pile()
				
				var top_card: CardData = game_state.discard_pile.back()
				
				game_state.has_drawn_this_turn = true
				
				if game_state.rules.can_play_card(drawn_card, top_card, game_state):
					await cpu_play_card(drawn_card)
		
		if game_state.cpu_hand.size() == 1:
			game_state.message_to_display = "Knock Knock, Last Card!"
			await game_view.show_message(game_state.message_to_display)
			game_state.message_to_display = ""
		
		if game_state.cpu_hand.is_empty():
			game_state.is_game_over = true
			game_state.message_to_display = "CPU Wins!"
			await game_view.show_message(game_state.message_to_display, true)
			get_tree().reload_current_scene()
			return
		
		#if extra_turn:
			#await get_tree().create_timer(1.0).timeout
			#await cpu_turn()
			#return
	#
	#game_state.is_player_turn = true
	
	#await begin_player_turn()
	end_turn()
	


func refill_draw_pile() -> bool:
	if !game_state.deck.cards.is_empty():
		return true

	if game_state.discard_pile.size() <= 1:
		return false

	var top_card: CardData = game_state.discard_pile.pop_back()

	for card in game_state.discard_pile:
		game_state.deck.cards.append(card)

	game_state.discard_pile.clear()
	game_state.discard_pile.append(top_card)

	game_state.deck.shuffle()

	game_view.display_draw_pile()

	return true


func animate_card_to_discard(
	card_view: CardView
) -> void:
	var starting_position := card_view.global_position

	card_view.reparent(game_view.animation_layer)

	card_view.global_position = starting_position

	await card_view.move_to(
		game_view.discard_pile_container.global_position
	)


func animate_draw_to_player(
	card: CardData
) -> void:
	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	game_view.animation_layer.add_child(card_view)

	card_view.show_back(card)

	card_view.global_position = game_view.draw_pile_container.global_position
	
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

	game_view.animation_layer.add_child(card_view)

	card_view.show_back(card)

	card_view.global_position = game_view.draw_pile_container.global_position

	await card_view.move_to(
		get_cpu_draw_target()
	)

	card_view.queue_free()


func get_player_draw_target() -> Vector2:
	var card_count := game_state.player_hand.size()

	return game_view.player_hand_container.global_position + Vector2(
		card_count * 48,
		0
	)


func get_cpu_draw_target() -> Vector2:
	var card_count := game_state.cpu_hand.size()

	return game_view.cpu_hand_container.global_position + Vector2(
		card_count * 48,
		0
	)


func find_cpu_card_view(
	card: CardData
) -> CardView:
	for child in game_view.cpu_hand_container.get_children():
		if child is CardView and child.card_data == card:
			return child

	return null
	
	
func begin_player_turn() -> void:
	
	game_view.set_turn_label()
	game_view.display_player_hand()
	
	if game_state.pending_draw_count and game_state.active_draw_target == game_state.DrawTarget.PLAYER:
		for card in game_state.pending_draw_count:
			if refill_draw_pile():
				var drawn_card: CardData = game_state.deck.draw_card()

				await animate_draw_to_player(drawn_card)

				game_state.player_hand.append(drawn_card)

				game_view.display_player_hand()
				game_view.display_draw_pile()

				await get_tree().create_timer(0.5).timeout
		

func begin_cpu_turn() -> void:	
	game_view.set_turn_label()
	await get_tree().create_timer(1.5).timeout	
	
	# draw cards if 2 was played
	if game_state.pending_draw_count and game_state.active_draw_target == game_state.DrawTarget.CPU:
		# draw pending count of cards before playing
		for count in game_state.pending_draw_count:
			if refill_draw_pile():
				var drawn_card: CardData = game_state.deck.draw_card()

				await animate_draw_to_cpu(drawn_card)

				game_state.cpu_hand.append(drawn_card)

				game_view.display_cpu_hand(game_state)
				game_view.display_draw_pile()
				
				await get_tree().create_timer(0.5).timeout


func _on_spades_pressed() -> void:
	game_state.active_suit = CardData.Suit.SPADES
	suit_selected.emit(CardData.Suit.SPADES)
	game_view.suit_selector_container.visible = false
	

func _on_clubs_pressed() -> void:
	game_state.active_suit = CardData.Suit.CLUBS
	suit_selected.emit(CardData.Suit.CLUBS)
	game_view.suit_selector_container.visible = false
	

func _on_diamonds_pressed() -> void:
	game_state.active_suit = CardData.Suit.DIAMONDS
	suit_selected.emit(CardData.Suit.DIAMONDS)
	game_view.suit_selector_container.visible = false


func _on_hearts_pressed() -> void:
	game_state.active_suit = CardData.Suit.HEARTS
	suit_selected.emit(CardData.Suit.HEARTS)
	game_view.suit_selector_container.visible = false


func _on_play_pressed() -> void:
	game_view.main_menu_container.visible = false
	game_started.emit()


func _on_button_pressed() -> void:
	game_view.end_turn_button_container.visible = false
	await end_turn()
	
	
func end_turn() -> void:
	game_state.has_drawn_this_turn = false
	game_state.rank_being_played_this_turn = -1
	game_state.cards_played_this_turn = 0
	
	if !game_state.extra_turn:
		game_state.is_player_turn = !game_state.is_player_turn
	
	game_state.extra_turn = false
	
	if game_state.is_player_turn:
		await begin_player_turn()
		
	else:
		await cpu_turn()
	

func cpu_play_card(card_to_play: CardData) -> void:
	
	if card_to_play.rank == CardData.Rank.EIGHT:
			game_state.rules.eight_is_played(game_state, game_state.cpu_hand)
			game_state.message_to_display = "CPU Changed Suit To " + str(CardData.Suit.keys()[game_state.active_suit])
	
	else:
		game_state.active_suit = card_to_play.suit
		
	if card_to_play.rank == CardData.Rank.TWO:
		game_state.rules.two_is_played(game_state)
		game_state.message_to_display = "Pick Up " + str(game_state.pending_draw_count) + " Cards Player!" 
	else:
		game_state.pending_draw_count = 0
		game_state.active_draw_target = game_state.DrawTarget.NONE
	
	if card_to_play.rank == CardData.Rank.JACK:
		game_state.message_to_display = "Miss A Turn Player!"
		game_state.extra_turn = true
	
	var card_view := find_cpu_card_view(card_to_play)

	if card_view:
		card_view.show_card(card_to_play)

		await animate_card_to_discard(card_view)

	game_state.cpu_hand.erase(card_to_play)
	game_state.discard_pile.append(card_to_play)

	if card_view:
		card_view.queue_free()

	game_view.display_cpu_hand(game_state)
	game_view.display_discard_pile()
	game_view.set_suit_label()
	
	if game_state.message_to_display.length() > 0:
		await game_view.show_message(game_state.message_to_display)
		game_state.message_to_display = ""
	
	game_state.cards_played_this_turn += 1
	game_state.rank_being_played_this_turn = card_to_play.rank
	
