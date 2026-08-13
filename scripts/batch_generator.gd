extends Node


@export var batch_size: int = 6

var rng := RandomNumberGenerator.new()

var dictionary_stats
var word_manager

func initialize(
	stats,
	manager
) -> void:

	dictionary_stats = stats
	word_manager = manager

func weighted_random_letter(
	freq: Dictionary,
	excluded: Array[String]
) -> String:
	
	var available := []
	
	var total_probability := 0.0
	
	for letter in freq:
		if letter in excluded:
			continue
		
		var probability: float = freq[letter]
		
		if probability <= 0:
			continue
		
		available.append({
			"letter": letter,
			"probability": probability
		})
		
		total_probability += probability
	
	if available.is_empty():
		return ""
	
	var value := rng.randf() * total_probability
	
	var accumulated := 0.0
	
	for candidate in available:
		accumulated += candidate["probability"]
		
		if value <= accumulated:
			return candidate["letter"]
	
	return available.back()["letter"]


func generate_batch() -> Array[String]:
	
	if dictionary_stats == null:
		push_error("BatchGenerator : DictionaryStats non initialisé.")
		return []

	if word_manager == null:
		push_error("BatchGenerator : WordManager non initialisé.")
		return []
		
	var batch: Array[String] = []
	
	var freq = dictionary_stats.global_frequencies
	
	while batch.size() < batch_size:
		var letter := weighted_random_letter(
			freq,
			batch
		)
		
		if letter == "":
			break
		
		batch.append(letter)
	
	return batch

func get_batch_key(batch: Array[String]) -> String:

	var sorted_batch := batch.duplicate()
	sorted_batch.sort()

	return "".join(sorted_batch)

func evaluate_batch(batch: Array[String]) -> Dictionary:

	var words_by_length = get_parent().get_node("WordManager").get_words_from_batch(batch)

	var result := {
		"batch": batch,
		"words_by_length": words_by_length,
		"score": 0
	}

	result["score"] = calculate_playability_score(result)

	return result
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()

func test_batches(number_of_batches: int = 100) -> void:

	print("")
	print("==========================================")
	print("       TEST DE GENERATION DE BATCHS")
	print("==========================================")
	print("")

	var scores: Array[float] = []
	var word_counts: Array[int] = []

	var length_totals: Dictionary = {}

	var best_result: Dictionary = {}
	var worst_result: Dictionary = {}

	var score_min := INF
	var score_max := -INF

	for i in range(number_of_batches):

		var batch := generate_batch()
		var result := evaluate_batch(batch)

		var score: int = result["score"]

		scores.append(score)

		var total_words := 0

		for length in result["words_by_length"]:

			var count: int = result["words_by_length"][length].size()

			total_words += count

			if not length_totals.has(length):
				length_totals[length] = 0

			length_totals[length] += count

		word_counts.append(total_words)

		if score > score_max:
			score_max = score
			best_result = result

		if score < score_min:
			score_min = score
			worst_result = result

		print_batch_result(i + 1, result)

	# --------------------------------------
	# Statistiques générales
	# --------------------------------------

	var score_average := average(scores)
	var word_average := average(word_counts)

	print("")
	print("------------------------------------------")
	print("STATISTIQUES")
	print("------------------------------------------")

	print("Nombre de batches : ", number_of_batches)

	print(
		"Score moyen : ",
		"%.2f" % score_average
	)

	print(
		"Score médian : ",
		"%.2f" % median(scores)
	)

	print(
		"Score minimum : ",
		score_min
	)

	print(
		"Score maximum : ",
		score_max
	)

	print(
		"Nombre moyen de mots : ",
		"%.2f" % word_average
	)

	print("")
	print("Moyenne de mots par longueur :")

	for length in length_totals.keys():
		var average_count := \
			float(length_totals[length]) / number_of_batches

		print(
				"  ",
				length,
				" lettres : ",
				"%.2f" % average_count
			)

	# --------------------------------------
	# Meilleur / pire
	# --------------------------------------

	print("")
	print("MEILLEUR BATCH")
	print_batch_result(0, best_result)

	print("")
	print("PIRE BATCH")
	print_batch_result(0, worst_result)

	print("")
	print("==========================================")

func average(values: Array) -> float:

	if values.is_empty():
		return 0.0

	var total := 0.0

	for value in values:
		total += value

	return total / values.size()

func median(values: Array) -> float:

	if values.is_empty():
		return 0.0

	var sorted_values := values.duplicate()

	sorted_values.sort()

	var middle := sorted_values.size() / 2

	if sorted_values.size() % 2 == 1:
		return sorted_values[middle]

	return (
		sorted_values[middle - 1]
		+ sorted_values[middle]
	) / 2.0

func print_batch_result(
	index: int,
	result: Dictionary
) -> void:

	var batch: Array = result["batch"]
	var words_by_length: Dictionary = result["words_by_length"]
	var score: int = result["score"]

	print(
		"#",
		index,
		" | ",
		" ".join(batch),
		" | score = ",
		score
	)

	for length in words_by_length.keys():

		var words: Array = words_by_length[length]

		print(
			"    ",
			length,
			" lettres : ",
			words.size(),
            " mots"
		)

func calculate_playability_score(result: Dictionary) -> float:

	var words_by_length: Dictionary = result["words_by_length"]

	var score := 0.0

	for length in words_by_length:

		var count: int = words_by_length[length].size()

		match int(length):
			3:
				score += count * 1.0
			4:
				score += count * 2.0
			5:
				score += count * 4.0
			6:
				score += count * 8.0

	return score

func generate_ranked_batches(
	number_of_batches: int = 1000
) -> Array:

	var results: Array = []
	var seen := {}

	var attempts := 0
	var max_attempts := number_of_batches * 10

	while results.size() < number_of_batches and attempts < max_attempts:

		attempts += 1

		var batch := generate_batch()

		var key := get_batch_key(batch)

		if seen.has(key):
			continue

		seen[key] = true

		var result := evaluate_batch(batch)

		results.append(result)

	results.sort_custom(
		func(a, b):
			return a["score"] > b["score"]
	)

	return results

func test_ranked_batches(
	number_of_batches: int = 1000,
	number_to_display: int = 20
) -> void:

	var results := generate_ranked_batches(
		number_of_batches
	)

	print("")
	print("==========================================")
	print("        CLASSEMENT DES BATCHS")
	print("==========================================")
	print("")

	var limit: int = min(
		number_to_display,
		results.size()
	)

	for i in range(limit):

		print(
			"Rang ",
			i + 1,
			" | ",
			format_batch_result(results[i])
		)

	print("")
	print("==========================================")

func format_batch_result(result: Dictionary) -> String:

	var batch: Array = result["batch"]
	var words_by_length: Dictionary = result["words_by_length"]
	var score: float = result["score"]

	var text := ""

	text += " ".join(batch)
	text += " | score = "
	text += "%.1f" % score

	for length in [3, 4, 5, 6, 7]:

		var count := 0

		if words_by_length.has(length):
			count = words_by_length[length].size()

		text += " | "
		text += str(length)
		text += "L="
		text += str(count)

	return text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
