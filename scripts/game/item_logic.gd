class_name ItemLogic
extends RefCounted


const SERVE_MAP := {
	"toast": "sade",
	"toast_k": "sade",
	"sade": "sade",
	"toast_cheese": "kasarli",
	"toast_cheese_k": "kasarli",
	"kasarli": "kasarli",
	"kasarli_k": "kasarli",
	"toast_sucuk": "sucuklu",
	"toast_sucuk_k": "sucuklu",
	"sucuklu": "sucuklu",
	"sucuklu_k": "sucuklu",
	"toast_mixed": "karisik",
	"toast_mixed_k": "karisik",
	"toast_mixed_cooked": "karisik",
	"karisik": "karisik",
	"ayran": "ayran",
	"kola": "kola",
	"su": "su",
}

const DISPLAY_NAMES := {
	"bread": "Ekmek",
	"toast": "Sade Tost",
	"toast_cheese": "Kaşarlı (erimecek)",
	"kasarli": "Kaşarlı Tost",
	"toast_sucuk": "Sucuklu (kızaracak)",
	"sucuklu": "Sucuklu Tost",
	"toast_mixed": "Karışık (kızaracak)",
	"toast_mixed_cooked": "Karışık (ketçap)",
	"karisik": "Karışık Tost",
	"toast_k": "Sade + Ketçap",
	"toast_cheese_k": "Kaşar + Ketçap",
	"toast_sucuk_k": "Sucuk + Ketçap",
	"toast_mixed_k": "Kaşar + Sucuk + Ketçap",
	"kasarli_k": "Kaşarlı + Ketçap",
	"sucuklu_k": "Sucuklu + Ketçap",
	"ayran": "Ayran",
	"kola": "Kola",
	"meyve": "Meyve Suyu",
	"su": "Su",
	"cheese": "Kaşar",
	"sucuk": "Sucuk",
	"ketchup": "Ketçap",
	"salca": "Salça",
	"domates": "Domates",
	"biber": "Biber",
	"zeytin": "Zeytin",
	"misir": "Mısır",
	"tursu": "Turşu",
	"kekik": "Kekik",
	"mayo": "Mayonez",
	"burnt": "Yanık",
}

const TOPPINGS := [
	"cheese", "sucuk", "ketchup", "salca",
	"domates", "biber", "zeytin", "misir", "tursu", "kekik", "mayo",
]
const DRINKS := ["ayran", "kola", "su"]
const CORE_TOPPINGS := ["cheese", "sucuk", "ketchup"]

const TOASTER_IN := {
	"bread": {"out": "toast", "time": 10.0},
	"toast_cheese": {"out": "kasarli", "time": 10.0},
	"toast_sucuk": {"out": "sucuklu", "time": 10.0},
	"toast_mixed": {"out": "toast_mixed_cooked", "time": 10.0},
	"toast_cheese_k": {"out": "kasarli_k", "time": 10.0},
	"toast_sucuk_k": {"out": "sucuklu_k", "time": 10.0},
	"toast_mixed_k": {"out": "karisik", "time": 10.0},
}


static func can_toast(item_id: String) -> bool:
	return TOASTER_IN.has(item_id)


static func is_topping(item_id: String) -> bool:
	return item_id in TOPPINGS


static func is_drink(item_id: String) -> bool:
	return item_id in DRINKS


static func is_supply(item_id: String) -> bool:
	return item_id == "bread" or is_topping(item_id) or is_drink(item_id)


static func can_place_on_board(item_id: String) -> bool:
	if item_id == "bread" or item_id == "burnt":
		return true
	return item_id != "" and not is_supply(item_id)


static func toaster_result(item_id: String) -> Dictionary:
	return TOASTER_IN.get(item_id, {})


static func add_ingredient(item_id: String, ingredient: String) -> String:
	if ingredient == "cheese":
		if item_id == "toast":
			return "toast_cheese"
		if item_id == "toast_k":
			return "toast_cheese_k"
		if item_id == "toast_sucuk" or item_id == "toast_mixed":
			return "toast_cheese"
		if item_id == "toast_sucuk_k" or item_id == "toast_mixed_k":
			return "toast_cheese_k"
	elif ingredient == "sucuk":
		# Sıra fark etmez: sucuk her zaman kaşarın ya da ekmeğin üstüne biner.
		return ""
	elif ingredient == "ketchup":
		# Ketçap görsele gömülmez; sucuğun üstüne ayrı çizilir.
		return ""
	return ""


static func has_ketchup(item_id: String) -> bool:
	return item_id == "karisik" or item_id.ends_with("_k")


static func serve_id(item_id: String) -> String:
	return SERVE_MAP.get(item_id, "")


static func display_name(item_id: String) -> String:
	return DISPLAY_NAMES.get(item_id, item_id)


static func icon_path(item_id: String) -> String:
	var art := "res://assets/art/%s.png" % item_id
	if ResourceLoader.exists(art):
		return art
	var sprite := "res://assets/sprites/%s.png" % item_id
	if ResourceLoader.exists(sprite):
		return sprite
	return "res://assets/art/toast.png"


static func plate_label(item_id: String) -> String:
	return {
		"toast": "Sade",
		"sade": "Sade",
		"toast_cheese": "Kaşar",
		"toast_sucuk": "Sucuk",
		"toast_mixed": "Kaşar + Sucuk",
		"kasarli": "Kaşarlı",
		"sucuklu": "Sucuklu",
		"toast_mixed_cooked": "Karışık",
		"karisik": "Karışık + Ketçap",
		"toast_k": "Sade + Ketçap",
		"toast_cheese_k": "Kaşar + Ketçap",
		"toast_sucuk_k": "Sucuk + Ketçap",
		"toast_mixed_k": "Kaşar + Sucuk + Ketçap",
		"kasarli_k": "Kaşarlı + Ketçap",
		"sucuklu_k": "Sucuklu + Ketçap",
		"burnt": "Yanık",
	}.get(item_id, display_name(item_id))


static func plate_icon_path(item_id: String) -> String:
	match item_id:
		"bread":
			return "res://assets/art/grill_raw.png"
		"burnt":
			return "res://assets/art/grill_burnt.png"
	return icon_path(item_id)


static func hold_icon_path(item_id: String) -> String:
	match item_id:
		"bread":
			return "res://assets/art/grill_raw.png"
		"burnt":
			return "res://assets/art/grill_burnt.png"
	return icon_path(item_id)


static func icon_name(item_id: String) -> String:
	return item_id if ResourceLoader.exists(icon_path(item_id)) else "toast"
