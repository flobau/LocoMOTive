extends Node2D

@export var speed: float = 100.0
var movement_time := 0.0
@export var total_distance: float = 1000.0
var distance_remaining := total_distance
@export var target_x: float = 450




func add_movement_time(time: float) -> void:
	movement_time += time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	
	if movement_time <= 0.0:
		return
	if position.x <= target_x:
		var movement := speed * delta
		position.x += movement

	movement_time -= delta
