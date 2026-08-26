extends Node2D

const STARTING_HAND_SIZE := 7
const CARD_VIEW_SCENE := preload("res://scenes/card_view.tscn")

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


func _ready() -> void:
	deck = Deck.new()

	deck.create_standard_deck()
	deck.shuffle()

	await play_opening_deal()

	game_state.is_player_turn = true


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


func display_player_hand() -> void:
	for child in player_hand_container.get_children():
		child.queue_free()

	for card in player_hand:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()

		player_hand_container.add_child(card_view)

		card_view.show_card(card)

		card_view.card_double_clicked.connect(
			_on_player_card_double_clicked
		)


func display_cpu_hand() -> void:
	for child in cpu_hand_container.get_children():
		child.queue_free()

	for card in cpu_hand:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()

		cpu_hand_container.add_child(card_view)

		card_view.show_back(card)


func display_draw_pile() -> void:
	for child in draw_pile_container.get_children():
		child.queue_free()

	if deck.cards.is_empty():
		return

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

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

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	discard_pile_container.add_child(card_view)

	var top_card: CardData = discard_pile.back()

	card_view.show_card(top_card)


func _on_player_card_double_clicked(
	card_view: CardView,
	card: CardData
) -> void:
	if !game_state.is_player_turn or game_state.is_game_over:
		return

	var top_card: CardData = discard_pile.back()

	if !rules.can_play_card(card, top_card):
		return

	game_state.is_player_turn = false

	await animate_card_to_discard(card_view)

	player_hand.erase(card)
	discard_pile.append(card)

	card_view.queue_free()

	display_player_hand()
	display_discard_pile()

	if player_hand.is_empty():
		game_state.is_game_over = true
		print("Player wins!")
		return

	await get_tree().create_timer(1.0).timeout

	await cpu_turn()


func _on_draw_pile_card_clicked(
	_card: CardData
) -> void:
	if !game_state	.is_player_turn or game_state.is_game_over:
		return

	if !refill_draw_pile():
		return

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
		if rules.can_play_card(card, top_card):
			return card

	return null


func cpu_turn() -> void:
	if game_state.is_game_over:
		return

	var card_to_play := find_cpu_playable_card()

	if card_to_play:
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

	else:
		if refill_draw_pile():
			var drawn_card: CardData = deck.draw_card()

			await animate_draw_to_cpu(drawn_card)

			cpu_hand.append(drawn_card)

			display_cpu_hand()
			display_draw_pile()

	if cpu_hand.is_empty():
		game_state.is_game_over = true
		print("CPU wins!")
		return

	game_state.is_player_turn = true


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

	await card_view.move_to(
		get_player_draw_target()
	)

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
