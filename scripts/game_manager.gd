extends Node

var score: int = 0
var min_speed = 0
var valid_words = [
	"TRAIN",
	"RAT",
	"TIR",
	"ART",
	"RIEN",
	"REIN",
    "TAIRE"
]

@onready var train = get_parent().get_node("Train")
@onready var score_label = get_parent().get_node("GameUI/Score")
@onready var speed_label = get_parent().get_node("GameUI/Speed")
@onready var word_input = get_parent().get_node("GameUI/WordInput")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_word_input_text_submitted(new_text: String) -> void:
	var word = new_text.strip_edges().to_upper()
	
	if word in valid_words:
		validate_word(word)
	else:
		reject_word()
	word_input.clear()# Replace with function body.

func validate_word(word: String):
	score += word.length()*10
	train.speed += word.length()*20
	update_ui()
	
func reject_word():
	train.speed = max(train.speed -20, min_speed)
	update_ui()
	
func update_ui():
	score_label.text = "Score : " + str(score)
	speed_label.text = "Vitesse : " + str(round(train.speed))
