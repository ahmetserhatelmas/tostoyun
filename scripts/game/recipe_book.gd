extends Node

var recipes: Dictionary = {}
var order: Array = []


func _ready() -> void:
	var file := FileAccess.open("res://data/recipes.json", FileAccess.READ)
	if file == null:
		push_error("recipes.json okunamadı")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("recipes.json bozuk")
		return
	for entry in parsed.get("recipes", []):
		recipes[str(entry["id"])] = entry
		order.append(str(entry["id"]))


func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})


func price(recipe_id: String) -> int:
	return int(get_recipe(recipe_id).get("price", 10))


func display_name(recipe_id: String) -> String:
	return str(get_recipe(recipe_id).get("name", recipe_id))


func icon(recipe_id: String) -> Texture2D:
	var icon_id := str(get_recipe(recipe_id).get("icon", recipe_id))
	return load(ItemLogic.icon_path(icon_id))
