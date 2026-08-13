extends Node

var words: Dictionary = {}


func load_dictionary() -> void:
	var file = FileAccess.open("res://data/francais.txt", FileAccess.READ)
	
	if file == null:
		push_error("Impossible de charger le dictionnaire")
		return
	
	words.clear()
	
	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_upper()
		
		if word.length() >= 3:
			words[word] = true
	
	file.close()
	
	print("Dictionnaire chargé : ", words.size(), " mots")
	
func is_valid_word(word: String) -> bool:
	return words.has(word)

func can_form_word(word: String, batch: Array[String]) -> bool:

	var available := {}

	for letter in batch:
		available[letter] = available.get(letter, 0) + 1

	for character in word:

		if not available.has(character):
			return false

		if available[character] <= 0:
			return false

		available[character] -= 1

	return true
	
func get_words_from_batch(batch: Array[String]) -> Dictionary:
	var result := {}

	for word in words:

		if not can_form_word(word, batch):
			continue

		var length: int = word.length()

		if not result.has(length):
			result[length] = []

		result[length].append(word)

	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
