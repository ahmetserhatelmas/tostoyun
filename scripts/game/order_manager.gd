class_name OrderManager
extends RefCounted

var score: int = 0
var money: int = 0
var served: int = 0
var missed: int = 0
var lives: int = 3


func setup(level: Dictionary) -> void:
	score = 0
	money = 0
	served = 0
	missed = 0
	lives = int(level.get("lives", 3))


func pick_recipe(level: Dictionary) -> String:
	var ids: Array = level.get("recipes", ["sade"])
	var weights: Array = level.get("weights", [])
	if weights.size() != ids.size():
		return str(ids[randi() % ids.size()])
	var total := 0
	for w in weights:
		total += int(w)
	var roll := randi() % maxi(1, total)
	var acc := 0
	for i in ids.size():
		acc += int(weights[i])
		if roll < acc:
			return str(ids[i])
	return str(ids[0])


func serve(recipe_id: String, patience_ratio: float) -> int:
	var price := RecipeBook.price(recipe_id)
	var earned := int(round(float(price) * (0.7 + 0.9 * clampf(patience_ratio, 0.0, 1.0))))
	score += earned
	money += earned
	served += 1
	return earned


func penalize(amount: int = 15) -> int:
	var lost := mini(score, amount)
	score = maxi(0, score - amount)
	return lost


func fail_customer() -> void:
	missed += 1
	lives = maxi(0, lives - 1)


func star_count(thresholds: Array) -> int:
	var stars := 0
	for threshold in thresholds:
		if score >= int(threshold):
			stars += 1
	return stars
