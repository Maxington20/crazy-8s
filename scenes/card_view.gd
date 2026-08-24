class_name CardView
extends Control

@export var card_sheet: Texture2D
@export var card_back: Texture2D

@onready var card_image: TextureRect = $CardImage

signal card_clicked(card:CardData)


var card_data: CardData
var is_face_up := true


func show_card(card: CardData) -> void:
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


func show_back() -> void:
	is_face_up = false
	card_image.texture = card_back
	
	
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			card_clicked.emit(card_data)
