extends Node2D

const ARC_POINTS:int = 8

@export var area2D:Area2D
@export var card_arc:Line2D

var current_card:CardUI
var targeting:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.card_aim_started.connect(_on_card_aim_started)
	EventBus.card_aim_ended.connect(_on_card_aim_ended)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not targeting:
		return
	
	area2D.position = get_local_mouse_position()
	card_arc.points = _get_points()

func _get_points()->Array:
	var points:Array = []
	var start = current_card.global_position
	start.x += current_card.size.x/2
	
	var target= get_local_mouse_position()
	var distance = target-start
	
	for i in range(ARC_POINTS):
		var t = 1.0/ARC_POINTS*i
		var x = start.x + (distance.x/ARC_POINTS) *i
		var y = start.y + ease_out_cubic(t) * distance.y
		points.append(Vector2(x,y))
	
	points.append(target)	
	return points
	
func ease_out_cubic(number:float)->float:
	return 1.0 - pow(1.0-number,3.0)

func _on_card_aim_started(card_ui:CardUI):
	if not card_ui.card_resource.is_single_targeted():
		return
	targeting = true
	area2D.monitoring = true
	area2D.monitorable = true
	current_card = card_ui
	
	
func _on_card_aim_ended(_card_ui:CardUI):
	targeting = false
	card_arc.clear_points()
	area2D.position = Vector2.ZERO
	area2D.monitoring = false
	area2D.monitorable = false
	current_card = null
	


func _on_area_2d_area_entered(area:Area2D):
	if not current_card or not targeting:
		return
	
	if not current_card.targets.has(area):
		current_card.targets.append(area)


func _on_area_2d_area_exited(area:Area2D):
	if not current_card or not targeting:
		return
	current_card.targets.erase(area)
