extends Node

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var global_counts: Dictionary = {}
var length_counts: Dictionary = {}

var global_frequencies: Dictionary = {}
var length_freq: Dictionary = {}

var word_counts_by_length: Dictionary = {}
var length_distribution: Dictionary = {}

var dictionary_hash: String = ""

func compute_stat(words: Dictionary):
	initialize_counts()
	
	for word in words:
		var length = word.length()
		
		if not length_counts.has(length):
			length_counts[length]={}
			
			for letter in ALPHABET:
				length_counts[length][letter] = 0
		
		if not word_counts_by_length.has(length):
			word_counts_by_length[length] = 0
		
		word_counts_by_length[length] += 1
		
		for  character in word:
			if global_counts.has(character):
				global_counts[character] += 1
			
			if length_counts[length].has(character):
				length_counts[length][character] += 1
	
	compute_freq()

func compute_freq():
	global_frequencies.clear()
	length_freq.clear()
	length_distribution.clear()

	
	var global_total = 0
	
	for letter in ALPHABET:
		global_total += global_counts[letter]
	
	for letter in ALPHABET:
		if global_total > 0:
			global_frequencies[letter] = float(global_counts[letter]) / global_total
		else:
			global_frequencies[letter] = 0.0
			
	for length in length_counts:
		length_freq[length] = {}
		var total = 0
		for letter in ALPHABET:
			total += length_counts[length][letter]
		
		for letter in ALPHABET:
			if total > 0:
				length_freq[length][letter] = float(length_counts[length][letter]) / total
			else:
				length_freq[length][letter] = 0.0
				
	var total_words = 0
	
	for length in word_counts_by_length:
		total_words += word_counts_by_length[length]
	
	for length in word_counts_by_length:
		length_distribution[length] = float(word_counts_by_length[length]) / total_words
	
func initialize_counts() -> void:
	global_counts.clear()
	length_counts.clear()
	word_counts_by_length.clear()
	
	for letter in ALPHABET:
		global_counts[letter] = 0

func print_stat() -> void:

	print("")
	print("========== DICTIONARY STATISTICS ==========")

	print("")
	print("Nombre de mots par longueur :")

	for length in word_counts_by_length.keys():
		print(
			"  ",
			length,
			" lettres : ",
			word_counts_by_length[length]
		)

	print("")
	print("Fréquence globale des lettres :")

	for letter in ALPHABET:
		print(
			"  ",
			letter,
			" : ",
			"%.4f" % global_frequencies[letter]
		)

	print("")
	print("============================================")

func save_to_json(path: String = "res://data/dictionary_stats.json") -> void:

	var data := {
		"dictionary_hash": dictionary_hash,
		
		"global_counts": global_counts,
		"global_frequencies": global_frequencies,

		"length_counts": length_counts,
		"length_frequencies": length_freq,

		"word_counts_by_length": word_counts_by_length,
		"length_distribution": length_distribution
	}

	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		push_error("Impossible de créer : " + path)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("Statistiques sauvegardées dans : ", path)
	
	
	
func load_from_json(
	dictionary_current_hash: String,
	path: String = "res://data/dictionary_stats.json"
	) -> bool:

	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()

	if json.parse(content) != OK:
		push_error("JSON invalide : " + path)
		return false

	var data = json.data
	
	if not data.has("dictionary_hash"):
		print('Cache sans hash : recalcul nécessaire.')
		return false
	
	if data["dictionary_hash"] != dictionary_current_hash:
		print("Le dictionnaire a changé : recalcul nécessaire")
		return false

	global_counts = data["global_counts"]
	global_frequencies = data["global_frequencies"]

	length_counts.clear()
	length_freq.clear()
	word_counts_by_length.clear()
	length_distribution.clear()


	for length_string in data["length_counts"]:
		var length := int(length_string)

		length_counts[length] = data["length_counts"][length_string]
		length_freq[length] = data["length_frequencies"][length_string]

		word_counts_by_length[length] = \
			int(data["word_counts_by_length"][length_string])

		length_distribution[length] = \
			float(data["length_distribution"][length_string])

	dictionary_hash = dictionary_current_hash
	
	print("Statistiques chargées depuis le cache.")

	return true
# Called when the node enters the scene tree for the first time.

func get_file_hash(path: String) -> String:
	
	if not FileAccess.file_exists(path):
		return ""
	
	var file := FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		return ""
	
	var context := HashingContext.new()
	
	var error := context.start(HashingContext.HASH_MD5)
	
	if error != OK:
		file.close()
		return ""
		
	while not file.eof_reached():
		var buffer := file.get_buffer(64 * 1024)
		
		if buffer.size() > 0:
			context.update(buffer)
	
	file.close()
	
	return context.finish().hex_encode()

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
