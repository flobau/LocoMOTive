extends Node

var words: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	load_dictionary() # Replace with function body.

func load_dictionary():
	var file = FileAccess.open("res://data/francais.txt", FileAccess.READ)
	
	if file == null:
		push_error("Impossible de charger le dictionnaire")
		return
	
	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_upper()
		
		if word.length() >= 3:
			words[word] = true
	
	file.close()
	
	print("Dictionnaire chargé : ", words.size(), " mots")
	
func is_valid_word(word: String) -> bool:
	return words.has(word)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
