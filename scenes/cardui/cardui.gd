class_name CardUI
extends Control


#region Export Vars

# color of the card
@export var color:ColorRect

# the text label on the card
@export var state:Label

# state chart object to handle state
@export var state_chart:StateChart

# area2d node used to detect when we enter the play area to play a card
@export var drop_point_detector:Area2D

@export var card_resource:CardResource

@export var card_label:Label

@export var card_number:int
#endregion

#region OnReady Vars
# list of area2d nodes to
# keeps track of what area2Ds we have hovered over
@onready var targets:Array[Node] = []
@onready var played:bool = false
#endregion

var parent:Hand
var card_position:int
var tween:Tween

#region StateChart Events
var card_clicked = "card_clicked"
var card_dragging = "card_dragging"
var card_canceled = "card_canceled"
var card_released = "card_released"
var card_aiming = "card_aiming"
#endregion

signal reparent_requested(which_cardui: CardUI)

func _ready():
	card_label.text = str(card_number)

func animate_to_position(new_position:Vector2, duration:float):
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"global_position",new_position,duration)
	pass

#region Godot signal callbacks
# called when we click on a card_ui
func _on_gui_input(event:InputEvent):
	if event.is_action_pressed("left_mouse"):
		pivot_offset = get_global_mouse_position() - global_position
		# go into the clicked state
		state_chart.send_event(card_clicked)

#endregion

#region drop_point_detector signal callbacks
func _on_drop_point_detector_area_entered(area:Area2D):
	if not targets.has(area):
		targets.append(area)


func _on_drop_point_detector_area_exited(area:Area2D):
	targets.erase(area)

#endregion

#region StateChart signal callbacks
# every card enters this state by default when first loaded
func _on_base_state_entered():

	if tween and tween.is_running():
		tween.kill()
		
	reparent_requested.emit(self)
	color.color = Color.WEB_GREEN
	state.text = "BASE"
	pivot_offset = Vector2.ZERO

#called when we enter the clicked state
func _on_clicked_state_entered():
	# upon entering the click state, change color and text to signify state change
	color.color = Color.ORANGE
	state.text = "CLICKED"
	
	# turn on the area2D's monitoring so we can detect when we enter and exist the card drop area
	drop_point_detector.monitoring =true

# called when we recieve mouse input while we are in the clicked state
func _on_clicked_state_input(event:InputEvent):
	# if the event is mouse movement while we are in the clicked state, then we are dragging the card_ui
	if event is InputEventMouseMotion:
		# transition to the dragging state
		state_chart.send_event(card_dragging)

# called when we enter the dragging state
func _on_dragging_state_entered():
	# upon entering the drgging state, change color and text to signify state change
	color.color = Color.RED
	state.text ="DRAGGING"
	
	# reparent the card_ui to the CanvasLayer Node above so we can freely drag the card_iu around the screen
	var ui_layer:CanvasLayer = get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		reparent(ui_layer)

# called when we receive mouse input while we are in the dragging state
func _on_dragging_state_input(event:InputEvent):
	var single_targeted = card_resource.is_single_targeted()
	
	# determine what kind of mouse input we recieved
	var mouse_motion:bool = event is InputEventMouseMotion
	var cancel:bool = event.is_action_pressed("right_mouse")
	var confirm:bool = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	
	if single_targeted and mouse_motion and targets.size()>0:
		state_chart.send_event(card_aiming)
		return
		
	# if the type is mouse motion, then position the card_ui where the mouse is
	if mouse_motion:
		global_position = get_global_mouse_position() - pivot_offset
		
	# if we right clicked, cancel the cards selection and transition to the canceled state
	if cancel:
		state_chart.send_event(card_canceled)
	
	# if we left clicked, then we want to release the card, either to play it or put it back in our hand.
	# transition to the released state
	elif confirm:
		get_viewport().set_input_as_handled()
		state_chart.send_event(card_released)

# called when we enter the released state
func _on_released_state_entered():
	# upon entering the released state, change color and text to signify state change
	color.color = Color.DARK_VIOLET
	state.text ="RELEASED"
	
	# assume we arent playing the card when it is released
	played = false
	
	# if we hovered over the play area before releasing, then play the card
	if not targets.is_empty():
		played =true
		print("played card for target(s) ", targets)
	
	# else we just want to release the card and not play it
	# transition to the cancled state
	else:
		state_chart.send_event(card_canceled)

# called when we enter the aiming state
func _on_aiming_state_entered():
	# upon entering the released state, change color and text to signify state change
	color.color = Color.WEB_PURPLE
	state.text ="AIMING"
	
	#clear any previous targets we might have had since we are not aiming for our targets
	targets.clear()
	
	# we want to position the card in the center of our hand when aiming
	# so we calculate the center
	var offset:Vector2 = Vector2(parent.size.x/2, -size.y/2)
	offset.x -= size.x/2
	
	# then we animate the card to the center of the hand
	animate_to_position(parent.global_position + offset, 0.2)
	
	# we disable the detector that detects if we have hovered over the card drop area
	drop_point_detector.monitoring = false
	
	# we let everyone know that aiming has started
	EventBus.card_aim_started.emit(self)


# called when we exist the aiming state
func _on_aiming_state_exited():
	# we let everyone know that aiming has stopped
	EventBus.card_aim_ended.emit(self)

# called when we receive mouse input while we are in the aiming state
func _on_aiming_state_input(event:InputEvent):
	# set the minimum threshold for what we consider to be a canceled aim if the user drags the aiming below this threshold
	const MOUSE_Y_SNAPBACK_THRESHOLD = 1000
	
	# figure out if we have mouse motion and if we are below our threshold
	var mouse_motion:bool = event is InputEventMouseMotion
	var mouse_at_bottom:bool = get_global_mouse_position().y > MOUSE_Y_SNAPBACK_THRESHOLD
	
	# if we are moving the mouse and we move below the threshold
	# transition to the canceled state
	if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		state_chart.send_event(card_canceled)
	
	# else if we clicked the left mouse button or released the left mouse button
	# transition to the released state
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		state_chart.send_event(card_released)

#endregion
