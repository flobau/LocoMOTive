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
	"TAIRE",
	"NATTE",
    "TANTE"
]

@onready var train = get_parent().get_node("Train")
@onready var score_label = get_parent().get_node("GameUI/Score")
@onready var speed_label = get_parent().get_node("GameUI/Speed")
@onready var word_input = get_parent().get_node("GameUI/WordInput")
@onready var letter_manager = get_parent().get_node("LetterManager")
@onready var letters_label = get_parent().get_node("GameUI/Letters")
@onready var word_manager = get_parent().get_node("WordManager")

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	letter_manager.generate_letters(6)
	
	update_letters_ui()
	update_ui()

func update_letters_ui():
	letters_label.text = "Lettres : " + "  " .join(letter_manager.available_letters)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_word_input_text_submitted(new_text: String) -> void:
	var word = new_text.strip_edges().to_upper()
	
	if word_manager.is_valid_word(word) and letter_manager.can_make_word(word):
		validate_word(word)
	else:
		reject_word()
		
	word_input.clear()

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
