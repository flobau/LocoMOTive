extends Node

var available_letters: Array[String] = []

var letter_pool = [
	"A", "A", "A", "A", "A",
	"B", "B",
	"C", "C",
	"D", "D", "D",
	"E", "E", "E", "E", "E", "E", "E", "E",
	"F",
	"G", "G",
	"H",
	"I", "I", "I", "I",
	"J",
	"K",
	"L", "L", "L", "L",
	"M", "M",
	"N", "N", "N", "N", "N",
	"O", "O", "O", "O",
	"P", "P",
	"Q",
	"R", "R", "R", "R", "R",
	"S", "S", "S", "S",
	"T", "T", "T", "T", "T",
	"U", "U", "U",
	"V",
	"W",
	"X",
	"Y",
    "Z"
]

func generate_letters(count: int = 6):
	available_letters.clear()
	
	for i in range(count):
		var index = randi() % letter_pool.size()
		available_letters.append(letter_pool[index])
		
	return available_letters

func can_make_word(word : String) -> bool:
	var remaining_letters = available_letters.duplicate()
	
	for character in word:
		if character in remaining_letters:
			remaining_letters.erase(character)
		else:
			return false
	return true
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
