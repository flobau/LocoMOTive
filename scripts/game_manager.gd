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
@onready var distance_label = get_parent().get_node("GameUI/Distance")
@onready var word_input = get_parent().get_node("GameUI/WordInput")
@onready var letter_manager = get_parent().get_node("LetterManager")
@onready var letters_label = get_parent().get_node("GameUI/Letters")
@onready var word_manager = get_parent().get_node("WordManager")
@onready var dictionary_stats = get_parent().get_node("DictionaryStats")
@onready var batch_generator = get_parent().get_node("BatchGenerator")
@export var total_distance: float = 5.0
@onready var environment = get_parent().get_node("Environment")
var distance_remaining: float = total_distance
@export var time_per_letter: float = 1.0
@export var target_x: float = 450

var is_moving: bool = false
var game_over: bool = false

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}


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
	dictionary_stats.test_cooccurrences()
	dictionary_stats.test_cooccurrence_consistency()
	dictionary_stats.print_word_letter_presence()
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
	generate_new_batch()
	update_ui()
	
	#batch_generator.test_ranked_batches(1000, 20)

func generate_new_batch() -> void:
	var result = batch_generator.generate_batch_for_difficulty(
		Difficulty.MEDIUM
	)

	if result.is_empty():
		push_error("Impossible de générer un batch.")
		return

	var batch: Array[String] = result["batch"]

	letter_manager.set_letters(batch)

	update_letters_ui()

func update_letters_ui():
	letters_label.text = "Lettres : " + "  " .join(letter_manager.available_letters)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_word_input_text_submitted(new_text: String) -> void:
	var word = new_text.strip_edges().to_upper()
	
	if word_manager.is_valid_word(word) and letter_manager.can_make_word(word):
		validate_word(word)
		
	word_input.clear()

func validate_word(word: String):
	if game_over:
		return
	var remaining_letters = letter_manager.available_letters.duplicate()
	var length := word.length()
	for character in word:
		remaining_letters.erase(character)

	var result = batch_generator.generate_batch_for_difficulty(
		Difficulty.MEDIUM,
		30,
		remaining_letters
	)

	if result.is_empty():
		push_error("Impossible de générer le nouveau batch.")
		return

	letter_manager.set_letters(result["batch"])
	
	var movement_time := length * time_per_letter

	if train.position.x < target_x:
		train.add_movement_time(movement_time)
	else :
		environment.add_movement_time(movement_time)
		train.just_animation(movement_time)
		
	score += length * 10
	
	distance_remaining -= length * 20.0

	update_letters_ui()
	update_ui()
	
	if distance_remaining <= 0:
		distance_remaining = 0
		#end_round()
	
func update_ui():
	score_label.text = "Score : " + str(score)
	distance_label.text = "Distance restante : " + str(distance_remaining)
