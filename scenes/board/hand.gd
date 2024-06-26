class_name Hand
extends HBoxContainer

func _ready():
	for child in get_children():
		var card_ui:CardUI = child as CardUI
		card_ui.parent=self
		card_ui.card_position = child.get_index()
		card_ui.reparent_requested.connect(_on_card_ui_reparent_requested)
		
		
func _on_card_ui_reparent_requested(child:CardUI):
	child.reparent(self)
	move_child(child,child.card_position)
