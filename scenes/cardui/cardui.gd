class_name CardUI
extends Control


#region Export Var

# color of the card
@export var color:ColorRect
# the text label on the card
@export var state:Label

# state chart object to handle state
@export var state_chart:StateChart

# area2d node used to detect when we enter the play area to play a card
@export var drop_point_detector:Area2D

#endregion

# list of area2d nodes to
# keeps track of what area2Ds we have hovered over
@onready var targets:Array[Node] = []


@onready var played:bool = false

#region StateChart Events
var card_clicked = "card_clicked"
var card_dragging = "card_dragging"
var card_canceled = "card_canceled"
var card_released = "card_released"
#endregion

signal reparent_requested(which_cardui: CardUI)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#region Godot signals
func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		pivot_offset = get_global_mouse_position() - global_position
		state_chart.send_event(card_clicked)

#endregion



#region drop_point_detector signals
func _on_drop_point_detector_area_entered(area:Area2D):
	if not targets.has(area):
		targets.append(area)



func _on_drop_point_detector_area_exited(area:Area2D):
	targets.erase(area)


#endregion



#region StateChart signals
func _on_base_state_entered():
	reparent_requested.emit(self)
	color.color = Color.WEB_GREEN
	state.text = "BASE"
	pivot_offset = Vector2.ZERO

func _on_clicked_state_entered():
	color.color = Color.ORANGE
	state.text = "CLICKED"
	drop_point_detector.monitoring =true
	
func _on_clicked_state_input(event:InputEvent):
	if event is InputEventMouseMotion:
		state_chart.send_event(card_dragging)


func _on_dragging_state_entered():
	var ui_layer:CanvasLayer = get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		reparent(ui_layer)
	color.color = Color.RED
	state.text ="DRAGGING"
	
func _on_dragging_state_input(event:InputEvent):
	var mouse_motion:bool = event is InputEventMouseMotion
	var cancel:bool = event.is_action_pressed("right_mouse")
	var confirm:bool = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	
	if mouse_motion:
		global_position = get_global_mouse_position() - pivot_offset
		
	if cancel:
		state_chart.send_event(card_canceled)
	elif confirm:
		get_viewport().set_input_as_handled()
		state_chart.send_event(card_released)
		
func _on_released_state_entered():
	color.color = Color.DARK_VIOLET
	state.text ="RELEASED"
	
	played = false
	
	if not targets.is_empty():
		played =true
		print("played card for target(s) ", targets)
	else:
		state_chart.send_event(card_canceled)

	
#endregion





