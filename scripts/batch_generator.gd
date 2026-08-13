extends Node


@export var batch_size: int = 7

var rng := RandomNumberGenerator.new()

var dictionary_stats
var word_manager

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

@export var difficulty: Difficulty = Difficulty.MEDIUM

func initialize(
	stats,
	manager
) -> void:

	dictionary_stats = stats
	word_manager = manager
	
func weighted_random_letter(
	freq: Dictionary,
	excluded: Array[String],
	mask: Dictionary = {}
) -> String:

	var available := []
	var total_probability := 0.0

	for letter in freq:
		if letter in excluded:
			continue

		var probability: float = freq[letter]

		if mask.has(letter):
			probability *= mask[letter]

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

func generate_batch(
	batch_difficulty: Difficulty = Difficulty.MEDIUM
) -> Array[String]:

	if dictionary_stats == null:
		push_error("BatchGenerator : DictionaryStats non initialisé.")
		return []

	if word_manager == null:
		push_error("BatchGenerator : WordManager non initialisé.")
		return []

	var batch: Array[String] = []

	while batch.size() < batch_size:

		var frequencies := get_letter_frequencies_for_batch(
			batch,
			batch_difficulty
		)

		var letter := weighted_random_letter(
			frequencies,
			batch
		)

		if letter == "":
			break

		batch.append(letter)

	return batch

func get_letter_frequencies_for_batch(
	batch: Array[String],
	difficulty: Difficulty
) -> Dictionary:

	var frequencies: Dictionary = {}

	for letter in dictionary_stats.ALPHABET:

		var global_freq: float = \
			dictionary_stats.global_frequencies.get(letter, 0.0)

		var score := global_freq

		# --------------------------------
		# Difficulté
		# --------------------------------

		match difficulty:

			Difficulty.EASY:
				# Favorise les lettres fréquentes
				score = global_freq

			Difficulty.MEDIUM:
				# Mélange fréquence globale
				# et légère préférence pour les
				# lettres utiles aux mots longs
				score = global_freq * 0.7

			Difficulty.HARD:
				# Réduit l'avantage des lettres
				# extrêmement fréquentes
				score = sqrt(global_freq)

		# --------------------------------
		# Bonus basé sur les longueurs
		# --------------------------------

		if not batch.is_empty():

			var length_freq = dictionary_stats.length_freq

			var length_score := 0.0
			var length_count := 0

			for length in [3, 4, 5, 6]:

				if length_freq.has(length):

					length_score += \
						length_freq[length].get(letter, 0.0)

					length_count += 1

			if length_count > 0:
				length_score /= length_count

				score *= (0.7 + length_score)

		frequencies[letter] = score

	return frequencies

func generate_batch_for_difficulty(
	difficulty: Difficulty,
	number_of_candidates: int = 30,
	required_letters: Array[String] = []
) -> Dictionary:

	var candidates: Array = []

	for i in range(number_of_candidates):

		var batch := generate_batch_with_required_letters(
			difficulty,
			required_letters
		)

		if batch.size() != batch_size:
			continue

		var result := evaluate_batch(batch)

		candidates.append(result)

	if candidates.is_empty():
		return {}

	# --------------------------------------
	# Score cible selon difficulté
	# --------------------------------------

	var target_score := 0.0

	match difficulty:

		Difficulty.EASY:
			target_score = 65.0

		Difficulty.MEDIUM:
			target_score = 35.0

		Difficulty.HARD:
			target_score = 18.0

	# --------------------------------------
	# Cherche le candidat le plus proche
	# du score cible
	# --------------------------------------

	var best_result: Dictionary = {}
	var best_distance := INF

	for result in candidates:

		var distance = abs(
			float(result["score"]) - target_score
		)

		if distance < best_distance:

			best_distance = distance
			best_result = result

	return best_result

func generate_batch_with_required_letters(
	difficulty: Difficulty,
	required_letters: Array[String]
) -> Array[String]:

	var batch: Array[String] = []

	# --------------------------------
	# Ajout des lettres obligatoires
	# --------------------------------

	for letter in required_letters:

		if batch.size() >= batch_size:
			break

		if letter not in dictionary_stats.ALPHABET:
			continue

		if letter not in batch:
			batch.append(letter)

	# --------------------------------
	# Complète le batch normalement
	# --------------------------------

	while batch.size() < batch_size:

		var frequencies := get_letter_frequencies_for_batch(
			batch,
			difficulty
		)

		var letter := weighted_random_letter(
			frequencies,
			batch
		)

		if letter == "":
			break

		batch.append(letter)

	return batch

###################################################################
###################################################################
###################################################################
###################################################################
###################################################################


func test_difficulties(number_of_batches: int = 20) -> void:

	print("")
	print("==========================================")
	print("       TEST DES DIFFICULTÉS")
	print("==========================================")

	for difficulty_level in [
		Difficulty.EASY,
		Difficulty.MEDIUM,
		Difficulty.HARD
	]:

		difficulty = difficulty_level

		var scores: Array[float] = []

		print("")
		
		match difficulty:
			Difficulty.EASY:
				print("===== EASY =====")
			Difficulty.MEDIUM:
				print("===== MEDIUM =====")
			Difficulty.HARD:
				print("===== HARD =====")

		for i in range(number_of_batches):

			var result := generate_batch_for_difficulty(Difficulty.MEDIUM)

			if result.is_empty():
				continue

			scores.append(result["score"])

			print(
				"  ",
				" ".join(result["batch"]),
				" | score = ",
				result["score"],
				" | 3L=",
				result["n3"],
				" 4L=",
				result["n4"],
				" 5L=",
				result["n5"],
				" 6L=",
				result["n6"]
			)

		if not scores.is_empty():

			print("")
			print(
				"Score moyen : ",
				"%.2f" % average(scores)
			)

			print(
				"Score min : ",
				"%.2f" % scores.min()
			)

			print(
				"Score max : ",
				"%.2f" % scores.max()
			)


func evaluate_batch(batch: Array[String]) -> Dictionary:

	var words_by_length: Dictionary = \
		word_manager.get_words_from_batch(batch)

	var n3 := 0
	var n4 := 0
	var n5 := 0
	var n6 := 0

	var total_words := 0
	var total_letters := 0
	

	for length in words_by_length:

		var words: Array = words_by_length[length]
		var count := words.size()

		total_words += count
		total_letters += count * int(length)

		match int(length):
			3:
				n3 = count
			4:
				n4 = count
			5:
				n5 = count
			6:
				n6 = count

	var mean_length := 0.0

	if total_words > 0:
		mean_length = float(total_letters) / total_words

	var long_words := n5 + n6
	var long_ratio := 0.0

	if total_words > 0:
		long_ratio = float(long_words) / total_words
	
	var ratio_3 := 0.0
	var ratio_4 := 0.0
	var ratio_5 := 0.0
	var ratio_6 := 0.0

	if total_words > 0:
		ratio_3 = float(n3) / total_words
		ratio_4 = float(n4) / total_words
		ratio_5 = float(n5) / total_words
		ratio_6 = float(n6) / total_words

	var result := {
		"batch": batch,
		"words_by_length": words_by_length,

		"n3": n3,
		"n4": n4,
		"n5": n5,
		"n6": n6,

		"total_words": total_words,
		"mean_length": mean_length,
		"long_words": long_words,
		"long_ratio": long_ratio,
		"ratio_3": ratio_3,
		"ratio_4": ratio_4,
		"ratio_5": ratio_5,
		"ratio_6": ratio_6,

		"score": 0.0
	}

	result["score"] = calculate_playability_score(result)

	return result
	

func calculate_playability_score(result: Dictionary) -> float:

	var score := 0.0

	score += result["n3"] * 1.0
	score += result["n4"] * 2.0
	score += result["n5"] * 5.0
	score += result["n6"] * 8.0

	return score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	#test_difficulties(10)

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

func analyze_letter_effects(results: Array) -> void:

	var stats := {}

	# Initialisation
	for letter in dictionary_stats.ALPHABET:
		stats[letter] = {
			"present": 0,
			"absent": 0,

			"score_present": 0.0,
			"score_absent": 0.0,

			"n3_present": 0.0,
			"n4_present": 0.0,
			"n5_present": 0.0,
			"n6_present": 0.0,

			"n3_absent": 0.0,
			"n4_absent": 0.0,
			"n5_absent": 0.0,
			"n6_absent": 0.0
		}

	# Analyse de chaque batch
	for result in results:

		var batch: Array = result["batch"]

		var batch_letters := {}

		for letter in batch:
			batch_letters[letter] = true

		for letter in dictionary_stats.ALPHABET:

			var is_present: bool = batch_letters.has(letter)

			if is_present:
				stats[letter]["present"] += 1

				stats[letter]["score_present"] += result["score"]

				stats[letter]["n3_present"] += result["n3"]
				stats[letter]["n4_present"] += result["n4"]
				stats[letter]["n5_present"] += result["n5"]
				stats[letter]["n6_present"] += result["n6"]

			else:

				stats[letter]["absent"] += 1

				stats[letter]["score_absent"] += result["score"]

				stats[letter]["n3_absent"] += result["n3"]
				stats[letter]["n4_absent"] += result["n4"]
				stats[letter]["n5_absent"] += result["n5"]
				stats[letter]["n6_absent"] += result["n6"]

	# Calcul des moyennes et différences
	for letter in dictionary_stats.ALPHABET:

		var s: Dictionary = stats[letter]

		if s["present"] > 0:

			s["score_present"] /= s["present"]

			s["n3_present"] /= s["present"]
			s["n4_present"] /= s["present"]
			s["n5_present"] /= s["present"]
			s["n6_present"] /= s["present"]

		if s["absent"] > 0:

			s["score_absent"] /= s["absent"]

			s["n3_absent"] /= s["absent"]
			s["n4_absent"] /= s["absent"]
			s["n5_absent"] /= s["absent"]
			s["n6_absent"] /= s["absent"]
	
	print_letter_analysis(stats)

func print_letter_analysis(stats: Dictionary) -> void:

	print("")
	print("==============================================")
	print("             ANALYSE DES LETTRES")
	print("==============================================")
	print("")

	print(
        "Lettre | Présence | Score+ | Score- | ΔScore"
	)

	print("----------------------------------------------")

	for letter in dictionary_stats.ALPHABET:

		var s: Dictionary = stats[letter]

		var delta_score : float  = (
			s["score_present"]
			- s["score_absent"]
		)

		print(
            "%s | %4d | %6.2f | %6.2f | %+7.2f"
			% [
				letter,
				s["present"],
				s["score_present"],
				s["score_absent"],
				delta_score
			]
		)

	print("")
	print("----------------------------------------------")
	print("             EFFET PAR LONGUEUR")
	print("----------------------------------------------")
	print("")

	print(
        "Lettre | ΔN3 | ΔN4 | ΔN5 | ΔN6"
	)

	print("----------------------------------------------")

	for letter in dictionary_stats.ALPHABET:

		var s: Dictionary = stats[letter]

		var d3 : float = float(s["n3_present"] - s["n3_absent"])
		var d4 :float = float(s["n4_present"] - s["n4_absent"])
		var d5 :float = float(s["n5_present"] - s["n5_absent"])
		var d6 :float = float(s["n6_present"] - s["n6_absent"])

		print(
            "%s | %+5.2f | %+5.2f | %+5.2f | %+5.2f"
			% [
				letter,
				d3,
				d4,
				d5,
				d6
			]
		)

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

func get_batch_key(batch: Array[String]) -> String:

	var sorted_batch := batch.duplicate()
	sorted_batch.sort()

	return "".join(sorted_batch)

func test_ranked_batches(
	number_of_batches: int = 1000,
	number_to_display: int = 20
) -> void:

	var results := generate_ranked_batches(
		number_of_batches
	)
	analyze_letter_effects(results)

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

	return (
        "%s | score=%.1f | "
		+ "3L=%d | "
		+ "4L=%d | "
		+ "5L=%d | "
		+ "6L=%d | "
		+ "total=%d | "
		+ "moy=%.2f | "
		+ "long=%d"
		+ " | ratio_long=%.2f"
		+ " | ratios=%.2f/%.2f/%.2f/%.2f"
	) % [
		" ".join(batch),
		result["score"],

		result["n3"],
		result["n4"],
		result["n5"],
		result["n6"],

		result["total_words"],
		result["mean_length"],
		result["long_words"],
		result["long_ratio"],
		result["ratio_3"],
		result["ratio_4"],
		result["ratio_5"],
		result["ratio_6"]
	]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
