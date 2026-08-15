extends Node2D

@export var speed: float = 200.0
@export var segment_width: float = 1152.0
var movement_time := 0.0

@onready var background = $Background
@onready var middleground = $Middleground
@onready var foreground = $Foreground
@onready var sprite = $AnimatedSprite2D



func add_movement_time(time: float) -> void:
	movement_time += time


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	if movement_time <= 0.0:
		return
		
	var movement := speed * delta
	
	move_layer(background, movement, 0)
	move_layer(middleground, movement, 0.5)
	move_layer(foreground, movement, 1)
	
	movement_time -= delta


func move_layer(layer: Node2D, movement: float, multiplier: float):

	for sprite in layer.get_children():

		sprite.position.x -= movement * multiplier

		# Si le sprite est complètement sorti à gauche
		print(sprite,sprite.position.x)
		if sprite.position.x + get_sprite_width(sprite) < 0:

			# Cherche le sprite le plus à droite
			var rightmost_x := -INF

			for other in layer.get_children():
				if other.position.x > rightmost_x:
					rightmost_x = other.position.x

			sprite.position.x = rightmost_x + 50 + get_sprite_width(sprite) + segment_width

func get_sprite_width(sprite: Node2D) -> float:

	if sprite is Sprite2D:
		return sprite.texture.get_width() * sprite.scale.x

	return 0.0
