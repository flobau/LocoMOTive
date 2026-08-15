extends Node2D

@export var speed: float = 100.0
var movement_time := 0.0
@export var total_distance: float = 1000.0
var distance_remaining := total_distance
@export var target_x: float = 450
@onready var environment = get_parent().get_node("Environment")
@onready var sprite = $AnimatedSprite2D
var just_animated: bool = false


func add_movement_time(time: float) -> void:
	movement_time += time
	
func just_animation(time: float) -> void:
	just_animated = true
	movement_time += time
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if movement_time <= 0.0:
		sprite.stop()
		return
	
	sprite.play()
	
	if not just_animated:
		if position.x < target_x:
			position.x += speed * delta
			
			if position.x > target_x:
				position.x = target_x
		else:
			environment.add_movement_time(delta)

	movement_time -= delta
