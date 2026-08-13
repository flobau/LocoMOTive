extends Node

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var global_counts: Dictionary = {}
var length_counts: Dictionary = {}

var global_frequencies: Dictionary = {}
var length_freq: Dictionary = {}

var word_counts_by_length: Dictionary = {}
var length_distribution: Dictionary = {}

var letter_cooccurrence_by_length: Dictionary = {}
var word_letter_presence_by_length: Dictionary = {}

var dictionary_hash: String = ""

func compute_stat(words: Dictionary):
	initialize_counts()

	word_letter_presence_by_length.clear()
	letter_cooccurrence_by_length.clear()

	for word in words:
		var length = word.length()

		if not length_counts.has(length):
			length_counts[length] = {}

			for letter in ALPHABET:
				length_counts[length][letter] = 0

		if not word_counts_by_length.has(length):
			word_counts_by_length[length] = 0

		word_counts_by_length[length] += 1

		var letters_in_word := {}

		for character in word:

			# On ignore tout caractère qui n'est pas une lettre de l'alphabet
			if not character in ALPHABET:
				continue

			if global_counts.has(character):
				global_counts[character] += 1

			if length_counts[length].has(character):
				length_counts[length][character] += 1

			letters_in_word[character] = true

		# -----------------------------------------
		# Présence des lettres
		# -----------------------------------------

		if not word_letter_presence_by_length.has(length):
			word_letter_presence_by_length[length] = {}

			for letter in ALPHABET:
				word_letter_presence_by_length[length][letter] = 0

		for letter in letters_in_word:
			if word_letter_presence_by_length[length].has(letter):
				word_letter_presence_by_length[length][letter] += 1

		# -----------------------------------------
		# Cooccurrences
		# -----------------------------------------

		if not letter_cooccurrence_by_length.has(length):
			letter_cooccurrence_by_length[length] = {}

			for letter_a in ALPHABET:
				letter_cooccurrence_by_length[length][letter_a] = {}

				for letter_b in ALPHABET:
					letter_cooccurrence_by_length[length][letter_a][letter_b] = 0

		var letters := letters_in_word.keys()

		for letter_a in letters:
			for letter_b in letters:
				letter_cooccurrence_by_length[length][letter_a][letter_b] += 1
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
	
	for length in word_counts_by_length:

		word_letter_presence_by_length[length] = \
			word_letter_presence_by_length.get(length, {})

		var total_words_length: int = word_counts_by_length[length]

		for letter in ALPHABET:

			var count: int = \
				word_letter_presence_by_length[length].get(letter, 0)

			if total_words_length > 0:
				word_letter_presence_by_length[length][letter] = \
					float(count) / total_words_length
			else:
				word_letter_presence_by_length[length][letter] = 0.0

	for length in word_counts_by_length:

		if not letter_cooccurrence_by_length.has(length):
			continue

		var total_words_length: int = word_counts_by_length[length]

		if total_words_length <= 0:
			continue

		for letter_a in ALPHABET:
			for letter_b in ALPHABET:

				var count: int = \
					letter_cooccurrence_by_length[length][letter_a][letter_b]

				letter_cooccurrence_by_length[length][letter_a][letter_b] = \
					float(count) / total_words_length

func test_cooccurrences() -> void:

	print("")
	print("==============================================")
	print("       TEST DES COOCCURRENCES")
	print("==============================================")

	var test_pairs = [
		["E", "R"],
		["E", "S"],
		["E", "T"],
		["A", "R"],
		["A", "S"],
		["I", "R"],
		["I", "S"]
	]

	for length in [3, 4, 5, 6, 7]:

		print("")
		print("Mots de %d lettres" % length)
		print("----------------------------------------------")

		for pair in test_pairs:

			var a = pair[0]
			var b = pair[1]

			var value = get_letter_cooccurrence(
				length,
				a,
				b
			)

			print(
				"%s + %s : %.4f (%.2f%%)"
				% [
					a,
					b,
					value,
					value * 100.0
				]
			)

func test_cooccurrence_consistency() -> void:

	for length in word_counts_by_length:

		for letter in ALPHABET:

			var presence = \
				word_letter_presence_by_length[length][letter]

			var cooccurrence = \
				letter_cooccurrence_by_length[length][letter][letter]

			var difference = abs(presence - cooccurrence)

			if difference > 0.00001:

				print(
					"ERREUR length=%d letter=%s : presence=%f cooccurrence=%f"
					% [
						length,
						letter,
						presence,
						cooccurrence
					]
				)

func get_letter_cooccurrence(length: int, letter_a: String, letter_b: String) -> float:

	if not letter_cooccurrence_by_length.has(length):
		return 0.0

	if not letter_cooccurrence_by_length[length].has(letter_a):
		return 0.0

	if not letter_cooccurrence_by_length[length][letter_a].has(letter_b):
		return 0.0

	return letter_cooccurrence_by_length[length][letter_a][letter_b]

func print_word_letter_presence() -> void:

	print("")
	print("==============================================")
	print("     PRESENCE DES LETTRES DANS LES MOTS")
	print("==============================================")
	print("")

	for length in word_letter_presence_by_length.keys():

		print("")
		print("Mots de %d lettres" % length)
		print("----------------------------------------------")

		for letter in ALPHABET:

			var frequency: float = \
				word_letter_presence_by_length[length][letter]

			print(
				"%s : %.4f (%.2f%%)"
				% [
					letter,
					frequency,
					frequency * 100.0
				]
			)

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
