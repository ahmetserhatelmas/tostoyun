extends Node

const SAVE_PATH := "user://save.json"

var current_level_id: int = 1
var levels: Array = []
var best_stars: Dictionary = {}


func _ready() -> void:
	var file := FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			levels = parsed.get("levels", [])
	_load_save()


func get_level(level_id: int) -> Dictionary:
	for level in levels:
		if int(level.get("id", 0)) == level_id:
			return level
	return {}


func start_level(level_id: int) -> void:
	current_level_id = level_id


func record_stars(level_id: int, stars: int) -> void:
	var key := str(level_id)
	best_stars[key] = maxi(int(best_stars.get(key, 0)), stars)
	_write_save()


func stars_for(level_id: int) -> int:
	return int(best_stars.get(str(level_id), 0))


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		best_stars = parsed.get("stars", {})


func _write_save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"stars": best_stars}))
