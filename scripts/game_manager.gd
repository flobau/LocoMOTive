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
@onready var dictionary_stats = get_parent().get_node("DictionaryStats")
@onready var batch_generator = get_parent().get_node("BatchGenerator")
	
func initialize_dictionary():
	word_manager.load_dictionary()
	
	if word_manager.words.is_empty():
		push_error("Le dictionnaire est vide.")
		return
	
	var dictionary_hash = dictionary_stats.get_file_hash("res://data/francais.txt")
	
	if dictionary_stats.load_from_json(dictionary_hash):
		return
	
	print("Calcul des statistiques en cours...")
	
	dictionary_stats.dictionary_hash = dictionary_hash
	
	dictionary_stats.compute_stat(word_manager.words)
	
	dictionary_stats.print_stat()
	
	dictionary_stats.save_to_json()

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	initialize_dictionary()
	batch_generator.initialize(
		dictionary_stats,
		word_manager
)
	update_letters_ui()
	update_ui()
	
	batch_generator.test_ranked_batches(1000, 20)

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
