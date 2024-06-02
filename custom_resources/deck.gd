class_name Deck
extends Resource

signal  deck_size_changed(cards_amount)

@export var cards: Array[CardResource] = []

func empty()->bool:
	return cards.is_empty()
	
func draw_card()->CardResource:
	var card = cards.pop_front()
	deck_size_changed.emit(cards.size())
	return card

func add_card(card:CardResource)->void:
	cards.append(card)
	deck_size_changed.emit(cards.size())
	
func shuffle()->void:
	cards.shuffle()
	
func clear()->void:
	cards.clear()
	deck_size_changed.emit(cards.size())
	
func _to_string()->String:
	var _card_strings:PackedStringArray=[]
	for i in range(cards.size()):
		_card_strings.append("%s: %s" % [i+1, cards[i].id])
	return "\n".join(_card_strings)
