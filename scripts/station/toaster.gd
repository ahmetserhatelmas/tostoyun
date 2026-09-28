class_name Toaster
extends Node

signal slot_tapped(index: int)
signal became_ready
signal became_burnt
signal slots_changed

var cook_scale: float = 1.0
var burn_window: float = 8.0
var slots: Array[Dictionary] = []
var _ready_played: Array[bool] = [false, false]


func _ready() -> void:
	slots = [_empty_slot(), _empty_slot()]


func is_empty(index: int) -> bool:
	return slots[index]["state"] == "empty"


func insert(index: int, item_id: String) -> bool:
	if not is_empty(index) or not ItemLogic.can_toast(item_id):
		return false
	var spec: Dictionary = ItemLogic.toaster_result(item_id)
	slots[index] = {
		"state": "cooking",
		"in_id": item_id,
		"out_id": str(spec.get("out", "toast")),
		"elapsed": 0.0,
		"cook": float(spec.get("time", 2.4)) * cook_scale,
	}
	_ready_played[index] = false
	slots_changed.emit()
	return true


func apply_ingredient(index: int, ingredient: String) -> bool:
	if is_empty(index):
		return false
	var slot: Dictionary = slots[index]
	if str(slot["state"]) == "burnt":
		return false
	var base := str(slot["out_id"] if slot["state"] == "ready" else slot["in_id"])
	var next_id := ItemLogic.add_ingredient(base, ingredient)
	if next_id == "":
		return false
	if slot["state"] == "cooking":
		slot["in_id"] = next_id
		var spec: Dictionary = ItemLogic.toaster_result(next_id)
		if not spec.is_empty():
			slot["out_id"] = str(spec.get("out", slot["out_id"]))
	else:
		slot["out_id"] = next_id
	slots_changed.emit()
	return true


func take(index: int) -> String:
	var slot: Dictionary = slots[index]
	var state := str(slot["state"])
	if state == "empty":
		return ""
	var item_id := ""
	if state == "burnt":
		item_id = "burnt"
	elif state == "ready":
		item_id = str(slot["out_id"])
	else:
		item_id = str(slot["in_id"])
	slots[index] = _empty_slot()
	_ready_played[index] = false
	slots_changed.emit()
	return item_id


func eject(index: int) -> bool:
	if is_empty(index):
		return false
	slots[index] = _empty_slot()
	_ready_played[index] = false
	slots_changed.emit()
	return true


func _process(delta: float) -> void:
	for i in slots.size():
		var slot: Dictionary = slots[i]
		if slot["state"] != "cooking" and slot["state"] != "ready":
			continue
		slot["elapsed"] = float(slot["elapsed"]) + delta
		var cook := float(slot["cook"])
		if slot["state"] == "cooking" and float(slot["elapsed"]) >= cook:
			slot["state"] = "ready"
			if not _ready_played[i]:
				_ready_played[i] = true
				became_ready.emit()
				slots_changed.emit()
		elif slot["state"] == "ready" and float(slot["elapsed"]) >= cook + burn_window:
			slot["state"] = "burnt"
			slot["out_id"] = "burnt"
			became_burnt.emit()
			slots_changed.emit()


func _empty_slot() -> Dictionary:
	return {"state": "empty", "in_id": "", "out_id": "", "elapsed": 0.0, "cook": 10.0}
