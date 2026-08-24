class_name CardView
extends Control

@export var card_sheet: Texture2D
@export var card_back: Texture2D

@onready var card_image: TextureRect = $CardImage

signal card_clicked(card: CardData)
signal card_double_clicked(
	card_view: CardView,
	card: CardData
)

var card_data: CardData
var is_face_up := true


func show_card(
	card: CardData
) -> void:
	card_data = card
	is_face_up = true

	var atlas := AtlasTexture.new()

	atlas.atlas = card_sheet

	atlas.region = Rect2(
		card.rank * 48,
		card.suit * 64,
		48,
		64
	)

	card_image.texture = atlas


func show_back(
	card: CardData = null
) -> void:
	card_data = card
	is_face_up = false

	card_image.texture = card_back


func _gui_input(
	event: InputEvent
) -> void:
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			if event.double_click:
				if card_data:
					card_double_clicked.emit(
						self,
						card_data
					)

			else:
				card_clicked.emit(card_data)


func move_to(
	target_global_position: Vector2,
	duration: float = 0.75
) -> void:
	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position",
		target_global_position,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await tween.finished
