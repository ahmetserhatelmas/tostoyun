extends Control

const CUSTOMER_SCENE := preload("res://scenes/customer/Customer.tscn")

@onready var seats_root: Control = $Dining/Seats
@onready var customer_layer: Control = $Dining/Customers
@onready var toaster_row: Control = $Kitchen/ToasterRow
@onready var toaster_slots_ui: Control = $ToasterSlots
@onready var prep_board: Control = $PrepBoard
@onready var prep_plate: TextureRect = $PrepBoard/Plate
@onready var prep_food: TextureRect = $PrepBoard/Food
@onready var prep_name: Label = $PrepBoard/Name
@onready var hud: GameHUD = $HUD
@onready var held_carry: TextureRect = $HeldCarry
@onready var result_layer: ColorRect = $ResultLayer
@onready var result_title: Label = $ResultLayer/Panel/Title
@onready var result_body: Label = $ResultLayer/Panel/Body
@onready var result_stars: HBoxContainer = $ResultLayer/Panel/Stars
@onready var recipe_panel: Panel = $RecipePanel
@onready var float_label: Label = $FloatLabel

var level: Dictionary = {}
var orders := OrderManager.new()
var toaster := Toaster.new()
var held_id: String = ""
var board_ids: Array[String] = ["", ""]
var held_extras: Array[String] = []
var board_extras: Array = [[], []]
var _locked_hint: String = ""
var remaining: float = 90.0
var spawn_in: float = 0.35
var running: bool = false
var occupied: Array = [null, null, null]
var seat_points: Array[Vector2] = []
var _slot_icons: Array[TextureRect] = []
var _pointer_down: bool = false
var _picked_this_press: bool = false
var _picked_from: String = ""
var _press_pos: Vector2 = Vector2.ZERO
var _art_cache: Dictionary = {}
var _board_bits: Array[TextureRect] = []
var _board_bits2: Array[TextureRect] = []
var _held_bits: Array[TextureRect] = []
var prep_food2: TextureRect = null
var _counter_front: TextureRect = null
var _ui_font: Font
const DRAG_SLACK := 48.0
const BG_TEX := Vector2(720, 1280)
const TABLE_IMG := [Vector2(130, 566), Vector2(300, 566), Vector2(460, 566)]
# Sağ plaka önce, sol plaka sonra. Uçlar üst kapağa bakar.
const SLOT_HOLE := [Vector2(136, 752), Vector2(62, 758)]
const SLICE_W := 48.0
# fill: ekmek yüzü genişliğine oran, squash: perspektif için dikey ezme,
# rot: derece, off: yüz merkezine göre kaydırma (yüz boyutuna oran)
const EXTRA_STYLE := {
	"sucuk": {"fill": 1.38, "squash": 0.86, "rot": 0.0, "off": Vector2(0.0, -0.04), "z": 1},
	"domates": {"fill": 0.62, "squash": 1.0, "rot": 0.0, "off": Vector2(0.0, 0.02)},
	"biber": {"fill": 0.64, "squash": 1.0, "rot": 0.0, "off": Vector2(0.0, 0.04)},
	"zeytin": {"fill": 0.58, "squash": 1.0, "rot": 0.0, "off": Vector2(0.0, 0.02)},
	"misir": {"fill": 0.56, "squash": 1.0, "rot": 0.0, "off": Vector2(0.04, 0.06)},
	"tursu": {"fill": 0.56, "squash": 1.0, "rot": 0.0, "off": Vector2(-0.04, 0.04)},
	"kekik": {"fill": 0.60, "squash": 1.0, "rot": 0.0, "off": Vector2(0.0, 0.0)},
	"mayo": {"fill": 0.88, "squash": 0.72, "rot": 0.0, "off": Vector2(0.0, 0.0), "z": 3},
	"salca": {"fill": 0.78, "squash": 0.72, "rot": -12.0, "off": Vector2(0.0, 0.02), "z": 2},
	"ketchup": {"fill": 0.92, "squash": 0.72, "rot": 0.0, "off": Vector2(0.0, -0.02), "z": 5},
}
const EXTRA_STAGGER := [
	Vector2(0, 0),
	Vector2(0.12, 0.08),
	Vector2(-0.10, 0.10),
	Vector2(0.06, -0.08),
]
const EXTRA_ART := {
	"sucuk": "res://assets/art/sucuk_bit.png",
	"biber": "res://assets/art/biber_bit.png",
	"domates": "res://assets/art/domates_bit.png",
	"zeytin": "res://assets/art/zeytin_bit.png",
	"mayo": "res://assets/art/mayo_bit.png",
	"ketchup": "res://assets/art/ketchup_bit.png",
}
const BOARD_IMG := Rect2(190, 848, 410, 190)
const BOARD_FOOD_IMG := Rect2(280, 868, 210, 108)
const BOARD_SLOT_IMG := [Rect2(212, 872, 180, 100), Rect2(398, 872, 180, 100)]
const BOARD_NAME_IMG := Rect2(200, 972, 360, 52)
const TRAY_X := [184.0, 266.0, 348.0, 430.0, 512.0, 594.0]
const TRAY_TOP := ["cheese", "sucuk", "salca", "domates", "biber"]
const TRAY_BOTTOM := ["zeytin", "misir", "tursu", "soslar", "kekik"]


func _ready() -> void:
	var fill := ColorRect.new()
	fill.color = Color(0.05, 0.04, 0.03)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	move_child(fill, 0)
	add_child(toaster)
	level = GameState.get_level(GameState.current_level_id)
	if level.is_empty():
		level = GameState.levels[0]
	orders.setup(level)
	remaining = float(level.get("duration", 90))
	spawn_in = 0.45
	toaster.cook_scale = float(level.get("cook_scale", 1.0))
	toaster.burn_window = float(level.get("burn_window", 4.0))
	toaster.became_ready.connect(func() -> void: Sfx.play("ding"))
	toaster.became_burnt.connect(func() -> void: Sfx.play("burn"))
	toaster.slots_changed.connect(_refresh_toaster)
	hud.set_lives(orders.lives)
	hud.set_score(0, 0)
	hud.set_hint("Soldaki ekmek kasasına bas, ızgaraya sürükle.")
	toaster.slots_changed.connect(func() -> void: hud.set_hint(_coach()))
	hud.recipes_toggled.connect(_toggle_how_to)
	hud.exit_pressed.connect(_to_menu)
	result_layer.visible = false
	recipe_panel.visible = false
	float_label.visible = false
	prep_food2 = TextureRect.new()
	prep_food2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prep_food2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prep_food2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prep_food.get_parent().add_child(prep_food2)
	_preload_art()
	_setup_counter_front()
	_setup_toaster_slots()
	_layout_to_bg()
	_style_hotspots()
	_mute_blocking_ui()
	_update_held()
	$HowTo.gui_input.connect(_on_howto_input)
	$HowTo/Panel/Play.pressed.connect(_close_how_to)
	$HowTo/Panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 0.98, 0.94, 0.98), 22))
	UiStyle.apply_button($HowTo/Panel/Play, Color(0.36, 0.58, 0.38))
	$HowTo.visible = true
	running = false
	$HeldChip.visible = false
	$RecipePanel.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 0.98, 0.94, 0.97), 18))
	$ResultLayer/Panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 0.97, 0.92), 22))
	$ResultLayer/Panel/Again.pressed.connect(_restart)
	$ResultLayer/Panel/Menu.pressed.connect(_to_menu)
	UiStyle.apply_button($ResultLayer/Panel/Again, Color(0.36, 0.58, 0.38))
	UiStyle.apply_button($ResultLayer/Panel/Menu, Color(0.55, 0.38, 0.24))
	_fill_recipe_panel()
	_apply_ui_font($HowTo)
	_apply_ui_font($HUD)
	$ResultLayer.z_index = 90
	$HowTo.z_index = 80
	$RecipePanel.z_index = 70
	$HUD.z_index = 60


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_to_bg()


func _bg_map() -> Dictionary:
	var dest := size
	if dest.x < 2.0 or dest.y < 2.0:
		dest = Vector2(720, 1280)
	var sc := minf(dest.x / BG_TEX.x, dest.y / BG_TEX.y)
	var drawn := BG_TEX * sc
	return {"origin": (dest - drawn) * 0.5, "scale": sc}


func _art(path: String) -> Texture2D:
	if not _art_cache.has(path):
		_art_cache[path] = load(path)
	return _art_cache[path]


func _img_to_local(p: Vector2) -> Vector2:
	var m := _bg_map()
	return m.origin + p * float(m.scale)


func _setup_counter_front() -> void:
	if _counter_front != null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = _art("res://assets/art/bg_restaurant.png")
	atlas.region = Rect2(0, 598, 720, 682)
	_counter_front = TextureRect.new()
	_counter_front.name = "CounterFront"
	_counter_front.texture = atlas
	_counter_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_counter_front.stretch_mode = TextureRect.STRETCH_SCALE
	_counter_front.z_index = 6
	add_child(_counter_front)
	if $Dining:
		$Dining.z_index = 2


func _layout_to_bg() -> void:
	if seats_root == null:
		return
	var m := _bg_map()
	var sc: float = m.scale
	seat_points.clear()
	for i in TABLE_IMG.size():
		var local := _img_to_local(TABLE_IMG[i] + Vector2(0, 58))
		var seat_size := Vector2(148, 210) * clampf(sc, 0.95, 1.15)
		var pos := local - Vector2(seat_size.x * 0.5, seat_size.y)
		seat_points.append(pos)
		var seat: Control = seats_root.get_node_or_null("Seat%d" % i)
		if seat:
			seat.position = pos
			seat.size = seat_size
		if i < occupied.size() and occupied[i] is Customer:
			occupied[i].position = pos
			occupied[i].size = seat_size
	if toaster_slots_ui:
		toaster_slots_ui.position = Vector2.ZERO
		toaster_slots_ui.size = size
		toaster_slots_ui.clip_contents = false
		toaster_slots_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _counter_front:
		_counter_front.position = _img_to_local(Vector2(0, 598))
		_counter_front.size = Vector2(720, 682) * sc
	_refresh_board()
	_refresh_toaster()


func _setup_toaster_slots() -> void:
	_slot_icons.clear()
	for i in 2:
		var btn: Button = toaster_row.get_node("Slot%d" % i)
		btn.pressed.connect(_on_toaster_slot.bind(i))
		var icon: TextureRect = toaster_slots_ui.get_node("Slot%d" % i)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot_icons.append(icon)


func _style_hotspots() -> void:
	var empty := StyleBoxEmpty.new()
	var buttons: Array = get_tree().get_nodes_in_group("stations")
	buttons.append(toaster_row.get_node("Slot0"))
	buttons.append(toaster_row.get_node("Slot1"))
	for node in buttons:
		if node is Button:
			node.add_theme_stylebox_override("normal", empty)
			node.add_theme_stylebox_override("hover", empty)
			node.add_theme_stylebox_override("pressed", empty)
			node.add_theme_stylebox_override("focus", empty)
			node.focus_mode = Control.FOCUS_NONE
			node.flat = true
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_ui_font(node: Node) -> void:
	if _ui_font == null:
		_ui_font = UiStyle.ui_font()
	if node is Label or node is Button:
		node.add_theme_font_override("font", _ui_font)
	for child in node.get_children():
		_apply_ui_font(child)


func _mute_blocking_ui() -> void:
	for node in [$HeldCarry, $HeldChip, $HUD/Top, $HUD/LivesBox, $HUD/Hint, $Kitchen, $PrepBoard]:
		if node:
			_ignore_mouse(node)


func _ignore_mouse(node: Node) -> void:
	if node is Control and node != $HUD/RecipeButton:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Button and child == $HUD/RecipeButton:
			continue
		_ignore_mouse(child)


func _playing() -> bool:
	return running and not $HowTo.visible and not result_layer.visible


func _input(event: InputEvent) -> void:
	if not _playing() or recipe_panel.visible:
		return
	if _over_hud_button():
		return
	if _is_press(event):
		_pointer_down = true
		_picked_this_press = false
		_picked_from = ""
		_press_pos = get_local_mouse_position()
		if held_id == "":
			_try_pickup_at(_norm_pointer())
			_picked_this_press = held_id != ""
		_move_held_to_pointer()
		if held_id != "":
			get_viewport().set_input_as_handled()
		return
	if _is_drag(event) and held_id != "":
		_move_held_to_pointer()
		get_viewport().set_input_as_handled()
		return
	if _is_release(event):
		_pointer_down = false
		if held_id == "":
			return
		_move_held_to_pointer()
		var dragged := _press_pos.distance_to(get_local_mouse_position()) > DRAG_SLACK
		if _picked_this_press and not dragged:
			_update_held()
			get_viewport().set_input_as_handled()
			return
		var result := _try_drop_at(_norm_pointer())
		if result == "used" or result == "changed":
			_picked_from = ""
			get_viewport().set_input_as_handled()
			return
		if _park_held_on_board():
			get_viewport().set_input_as_handled()
			return
		var throwaway := ItemLogic.is_topping(held_id) or ItemLogic.is_drink(held_id)
		if (result == "miss" or (result == "noop" and dragged)) and throwaway:
			_discard_held()
		elif result == "miss" or result == "noop":
			hud.set_hint("Bunu tahtaya, ızgaraya ya da çöpe bırakabilirsin.")
		get_viewport().set_input_as_handled()


func _on_howto_input(event: InputEvent) -> void:
	if _is_press(event):
		_close_how_to()


func _is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return event.pressed
	return false


func _is_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (not event.pressed) and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _is_drag(event: InputEvent) -> bool:
	return event is InputEventMouseMotion or event is InputEventScreenDrag


func _over_hud_button() -> bool:
	var point := get_global_mouse_position()
	return $HUD/RecipeButton.get_global_rect().has_point(point) or $HUD/ExitButton.get_global_rect().has_point(point)


func _norm_pointer() -> Vector2:
	if size.x <= 1.0 or size.y <= 1.0:
		return Vector2.ZERO
	return get_local_mouse_position() / size


func _move_held_to_pointer() -> void:
	if held_id == "" or not held_carry.visible:
		return
	var pos := get_local_mouse_position()
	held_carry.position = pos - held_carry.size * 0.5 + Vector2(0, -18)


func _try_pickup_at(n: Vector2) -> void:
	var hit := _station_at(n)
	if hit == "":
		return
	_picked_from = hit
	if hit.begins_with("toaster_"):
		_on_toaster_slot(int(hit.get_slice("_", 1)))
	elif hit == "board":
		_on_board()
	elif hit != "":
		_on_station(hit)
	_update_held()


func _try_drop_at(n: Vector2) -> String:
	var before := held_id
	var customer := _customer_at()
	if customer:
		_on_customer_tapped(customer)
		return "used"
	if ItemLogic.is_topping(held_id) and _board_has_any() and _over_prep_plate():
		_on_station("board")
		if held_id == "":
			return "used"
		if held_id != before:
			return "changed"
		return "noop"
	var hit := _station_at(n)
	if hit == "":
		return "miss"
	if hit.begins_with("toaster_"):
		_on_toaster_slot(int(hit.get_slice("_", 1)))
	else:
		_on_station(hit)
	if held_id == "":
		return "used"
	if held_id != before:
		return "changed"
	return "noop"


func _say(text: String) -> void:
	_locked_hint = text
	hud.set_hint(text)


func _preload_art() -> void:
	for base in ["res://assets/art", "res://assets/sprites"]:
		var dir := DirAccess.open(base)
		if dir == null:
			continue
		var seen := {}
		for file in dir.get_files():
			var name := file
			if name.ends_with(".import") or name.ends_with(".remap"):
				name = name.get_basename()
			if not name.ends_with(".png") or seen.has(name):
				continue
			seen[name] = true
			_art(base + "/" + name)


func _board_has_any() -> bool:
	return board_ids[0] != "" or board_ids[1] != ""


func _board_slot_at_pointer() -> int:
	return 0 if _pointer_img().x < 395.0 else 1


func _free_board_slot() -> int:
	for s in 2:
		if board_ids[s] == "":
			return s
	return -1


func _park_held_on_board() -> bool:
	if held_id == "" or not ItemLogic.can_place_on_board(held_id):
		return false
	var target := _free_board_slot()
	if target < 0:
		_say("Tahta dolu. Önce bir tostu al.")
		return false
	board_ids[target] = held_id
	board_extras[target] = held_extras.duplicate()
	held_id = ""
	held_extras.clear()
	_picked_from = ""
	Sfx.play("tap")
	_refresh_board()
	_update_held()
	return true


func _discard_held() -> void:
	if held_id == "":
		return
	held_id = ""
	held_extras.clear()
	_picked_from = ""
	Sfx.play("trash")
	_say("Boşa bıraktın, elin boş.")
	_update_held()


func _customer_at() -> Customer:
	var p := get_global_mouse_position()
	for node in occupied:
		if node is Customer and node.state == "seated":
			var customer: Customer = node
			var area := Rect2(customer.global_position, customer.size)
			area.position.y -= 20.0
			area.size.y += 90.0
			area.position.x -= 16.0
			area.size.x += 32.0
			if area.has_point(p):
				return customer
	return null


func _pointer_img() -> Vector2:
	var m := _bg_map()
	return (get_local_mouse_position() - m.origin) / float(m.scale)


func _over_prep_plate() -> bool:
	var img := _pointer_img()
	return img.x >= 190.0 and img.x <= 600.0 and img.y >= 848.0 and img.y <= 1045.0


func _tray_at(x: float, row: Array) -> String:
	for i in row.size():
		if x >= TRAY_X[i] and x < TRAY_X[i + 1]:
			var id := str(row[i])
			if id == "soslar":
				return "ketchup" if x < TRAY_X[i] + 41.0 else "mayo"
			return id
	return ""


func _station_at(_n: Vector2) -> String:
	var img := _pointer_img()
	var x := img.x
	var y := img.y
	if y >= 848.0 and y <= 1055.0:
		if x <= 180.0:
			return "bread"
		if x >= 600.0:
			return "trash"
		if x < 600.0:
			return "board"
	if y >= 575.0 and y <= 846.0 and x <= 175.0:
		return "toaster_1" if x < 80.0 else "toaster_0"
	if x >= 598.0 and y >= 506.0 and y <= 824.0:
		if y < 614.0:
			return "kola"
		if y < 716.0:
			return "ayran"
		return "su"
	if x >= TRAY_X[0] and x < TRAY_X[5]:
		if y >= 632.0 and y < 734.0:
			return _tray_at(x, TRAY_TOP)
		if y >= 734.0 and y <= 846.0:
			return _tray_at(x, TRAY_BOTTOM)
	return ""


func _process(delta: float) -> void:
	if held_id != "" and _pointer_down:
		_move_held_to_pointer()
	if _toaster_has("cooking"):
		_paint_grill()
	if not running:
		return
	remaining -= delta
	hud.set_clock(remaining, float(level.get("duration", 90)))
	if remaining <= 0.0:
		_end_shift(false)
		return
	spawn_in -= delta
	if spawn_in <= 0.0:
		_try_spawn()
		spawn_in = randf_range(float(level.get("spawn_min", 6)), float(level.get("spawn_max", 9)))


func _try_spawn() -> void:
	var free_seats: Array[int] = []
	for i in occupied.size():
		if occupied[i] == null:
			free_seats.append(i)
	if free_seats.is_empty() or (occupied.size() - free_seats.size()) >= int(level.get("max_customers", 3)):
		return
	var seat: int = free_seats[randi() % free_seats.size()]
	var customer: Customer = CUSTOMER_SCENE.instantiate()
	customer.setup(orders.pick_recipe(level), float(level.get("patience", 20)), seat)
	var seat_size := Vector2(148, 210)
	if seat < seat_points.size():
		var seat_node: Control = seats_root.get_node_or_null("Seat%d" % seat)
		if seat_node:
			seat_size = seat_node.size
	customer.position = Vector2(-240, seat_points[seat].y)
	customer_layer.add_child(customer)
	customer.size = seat_size
	occupied[seat] = customer
	customer.tapped.connect(_on_customer_tapped)
	customer.left_angry.connect(_on_customer_angry)
	customer.served.connect(_on_customer_served)
	customer.served_wrong.connect(_on_customer_wrong)
	var tween := create_tween()
	tween.tween_property(customer, "position", seat_points[seat], 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(customer.sit_down)


func _on_station(station_id: String) -> void:
	if not _playing():
		return
	if ItemLogic.is_topping(station_id):
		_take_or_add(station_id)
	elif ItemLogic.is_drink(station_id) or station_id == "bread":
		if held_id == "":
			held_id = station_id
			held_extras.clear()
			Sfx.play("tap")
		elif held_id == station_id and station_id == "bread":
			hud.set_hint("Ekmeği soldaki ızgaraya sürükle.")
		elif held_id == station_id:
			hud.set_hint("Bunu müşteriye sürükle.")
	elif station_id == "trash":
		_throw_away()
	elif station_id == "board":
		_on_board()
	_update_held()


func _on_board() -> void:
	var s := _board_slot_at_pointer()
	if held_id == "":
		if board_ids[s] == "":
			s = 1 - s
		if board_ids[s] == "":
			return
		held_id = board_ids[s]
		held_extras.assign(board_extras[s])
		board_ids[s] = ""
		board_extras[s] = []
		Sfx.play("take")
		_refresh_board()
		return
	if ItemLogic.can_place_on_board(held_id):
		var target := s
		if board_ids[target] != "":
			target = 1 - target
		if board_ids[target] != "":
			_say("Tahta dolu. Önce bir tostu al.")
			return
		board_ids[target] = held_id
		board_extras[target] = held_extras.duplicate()
		held_id = ""
		held_extras.clear()
		Sfx.play("tap")
		_refresh_board()
		return
	if board_ids[s] == "":
		s = 1 - s
	if board_ids[s] == "":
		if ItemLogic.is_topping(held_id):
			_say("Önce tostu tahtaya koy, sonra malzemeyi üstüne bırak.")
		elif held_id != "":
			_say("Bu tahtaya sadece tost konur.")
		return
	if held_id in ItemLogic.CORE_TOPPINGS:
		var prev_id := board_ids[s]
		var next_id := ItemLogic.add_ingredient(prev_id, held_id)
		if next_id != "":
			board_ids[s] = next_id
			if held_id == "cheese" and (prev_id.begins_with("toast_sucuk") or prev_id.begins_with("toast_mixed")):
				if not board_extras[s].has("sucuk"):
					board_extras[s].append("sucuk")
			held_id = ""
			Sfx.play("tap")
			_say("%s oldu." % _slot_text(s))
			_refresh_board()
			return
		if held_id == "ketchup" and (board_extras[s].has("ketchup") or ItemLogic.has_ketchup(board_ids[s])):
			Sfx.play("wrong")
			_say("Bu tosta zaten ketçap var.")
			return
		# Kaşarlı tosta sucuk vb. eklenince görseli değiştirme; üstüne koy.
	if ItemLogic.is_topping(held_id):
		if held_id in board_extras[s]:
			Sfx.play("wrong")
			_say("Bunu zaten ekledin.")
			return
		board_extras[s].append(held_id)
		held_id = ""
		Sfx.play("tap")
		_say("%s oldu." % _slot_text(s))
		_refresh_board()
		return
	_say("Bunu tahtaya koyamazsın.")


func _take_or_add(ingredient: String) -> void:
	if held_id == "":
		held_id = ingredient
		Sfx.play("tap")
		return
	Sfx.play("wrong")
	_say("Malzemeyi tabağın üstündeki tosta bırak.")


func _on_toaster_slot(index: int) -> void:
	if not _playing():
		return
	if ItemLogic.is_topping(held_id):
		Sfx.play("wrong")
		_say("Önce tostu tahtaya koy, sonra malzemeyi üstüne bırak.")
		return
	if ItemLogic.is_drink(held_id):
		Sfx.play("wrong")
		_say("İçecek ızgaraya girmez. Müşteriye ver.")
		return
	if held_id != "" and ItemLogic.can_toast(held_id):
		var dest := _next_grill_slot()
		if dest < 0:
			hud.set_hint("En fazla 2 ekmek. Önce birini çöpe at.")
			return
		if toaster.insert(dest, held_id):
			held_id = ""
			held_extras.clear()
			Sfx.play("cook")
			_update_held()
			_pop_into_slot(dest)
		return
	if not toaster.is_empty(index):
		if held_id != "":
			hud.set_hint("Bu delik dolu. Önce elindekini bırak.")
			return
		var taken := toaster.take(index)
		if taken != "":
			held_id = taken
			held_extras.clear()
			Sfx.play("take")
			_say("Tahtaya koy. Atmak istersen sağdaki çöpe sürükle.")
			_update_held()
		return
	if held_id == "":
		hud.set_hint("Önce soldaki ekmeği tut.")
		return
	if toaster.insert(index, held_id):
		held_id = ""
		Sfx.play("cook")
		_update_held()
		_pop_into_slot(index)
	else:
		Sfx.play("wrong")
		if ItemLogic.is_topping(held_id):
			_say("Önce tostu tahtaya koy, sonra malzemeyi üstüne bırak.")
		elif not ItemLogic.can_toast(held_id):
			hud.set_hint("Bu makineye giremez.")
		else:
			hud.set_hint("En fazla 2 ekmek. Deliği boşalt.")


func _on_customer_tapped(customer: Customer) -> void:
	if not running or customer.state != "seated":
		return
	if held_id == "":
		hud.set_hint("Önce siparişi hazırla.")
		return
	if customer.try_serve(held_id):
		held_id = ""
		held_extras.clear()
		_update_held()
	else:
		_say("Yanlış sipariş. Tost elinde kaldı, tahtaya ya da çöpe bırak.")
		_update_held()


func _on_customer_served(customer: Customer, recipe_id: String, patience_ratio: float) -> void:
	var earned := orders.serve(recipe_id, patience_ratio)
	hud.set_score(orders.score, orders.money)
	Sfx.play("coin")
	_popup("+%d" % earned, customer.global_position + Vector2(70, 120), Color(0.28, 0.55, 0.3))
	_depart(customer, true)


func _on_customer_wrong(customer: Customer) -> void:
	var lost := orders.penalize(15)
	hud.set_score(orders.score, orders.money)
	Sfx.play("wrong")
	_popup("-%d" % lost, customer.global_position + Vector2(70, 120), Color(0.75, 0.22, 0.18))


func _on_customer_angry(customer: Customer) -> void:
	orders.fail_customer()
	hud.set_lives(orders.lives)
	Sfx.play("angry")
	_depart(customer, false)
	if orders.lives <= 0:
		_end_shift(true)


func _depart(customer: Customer, happy: bool) -> void:
	var seat := customer.seat_index
	if seat >= 0 and seat < occupied.size() and occupied[seat] == customer:
		occupied[seat] = null
	var tween := create_tween()
	tween.tween_property(customer, "position", Vector2(760, customer.position.y + (-16 if happy else 12)), 0.5)
	tween.tween_callback(customer.queue_free)


func _update_held() -> void:
	if held_id == "":
		held_carry.texture = null
		held_carry.visible = false
		_place_extras(held_carry, _held_bits, [], Vector2.ZERO, held_carry.size, null)
	else:
		held_carry.texture = _art(ItemLogic.hold_icon_path(held_id))
		held_carry.visible = true
		held_carry.size = Vector2(120, 140)
		_move_held_to_pointer()
		_place_extras(held_carry, _held_bits, held_extras, Vector2.ZERO, held_carry.size, held_carry.texture)
	if _locked_hint != "":
		hud.set_hint(_locked_hint)
		_locked_hint = ""
		return
	hud.set_hint(_coach())


func _coach() -> String:
	if held_id == "bread":
		return "Ekmeği ızgaraya sürükle, bırak."
	if ItemLogic.is_drink(held_id):
		return "%s müşteriye sürükle." % ItemLogic.display_name(held_id)
	if ItemLogic.is_topping(held_id):
		return "%s tahtadaki tostun üstüne bırak." % ItemLogic.display_name(held_id)
	if held_id != "" and not ItemLogic.is_supply(held_id) and ItemLogic.serve_id(held_id) != "":
		return "Müşteriye ver ya da sağdaki çöpe at."
	if held_id == "burnt":
		return "Yanık. Tahtaya koyabilir ya da çöpe atabilirsin."
	if ItemLogic.can_toast(held_id):
		return "Bunu tekrar ızgaraya sürükle."
	if _toaster_has("burnt"):
		return "Yandı. Alıp sağdaki çöpe at."
	if _board_has_any():
		var bid: String = board_ids[0] if board_ids[0] != "" else board_ids[1]
		if ItemLogic.can_toast(bid):
			return "Tost tahtada. Kaşar, sucuk, salça ya da sos ekle."
		if ItemLogic.serve_id(bid) != "":
			return "Hazır. Tostu al, müşteriye sürükle."
		return "Tost tahtada. Üstüne malzeme bırak."
	if _toaster_has("ready"):
		return "Kızardı. Alıp ortadaki tahtaya koy."
	if _toaster_has("cooking"):
		return "Delikte kızarıyor, 10 saniye bekle."
	return "Soldaki ekmek kasasına bas, tut."


func _toaster_has(state: String) -> bool:
	for slot in toaster.slots:
		if str(slot.get("state", "")) == state:
			return true
	return false


func _next_grill_slot() -> int:
	if toaster.is_empty(0):
		return 0
	if toaster.is_empty(1):
		return 1
	return -1


func _throw_away() -> void:
	if held_id != "":
		held_id = ""
		held_extras.clear()
		_picked_from = ""
		Sfx.play("trash")
		_say("Çöpe attın.")
		return
	if _board_has_any():
		var s := _board_slot_at_pointer()
		if board_ids[s] == "":
			s = 1 - s
		board_ids[s] = ""
		board_extras[s] = []
		Sfx.play("trash")
		_say("Tahtadakini çöpe attın.")
		_refresh_board()
		return
	for i in [0, 1]:
		if toaster.eject(i):
			Sfx.play("trash")
			_say("Izgaradakini çöpe attın.")
			_refresh_toaster()
			return
	hud.set_hint("Atacak bir şey yok.")


func _bread_face(tex: Texture2D, area_pos: Vector2, area_size: Vector2) -> Rect2:
	var drawn_pos := area_pos
	var drawn_size := area_size
	if tex != null:
		var ts := tex.get_size()
		if ts.x > 1.0 and ts.y > 1.0:
			var scale := minf(area_size.x / ts.x, area_size.y / ts.y)
			drawn_size = ts * scale
			drawn_pos = area_pos + (area_size - drawn_size) * 0.5
	return Rect2(drawn_pos.x + drawn_size.x * 0.16, drawn_pos.y + drawn_size.y * 0.12, drawn_size.x * 0.68, drawn_size.y * 0.50)


func _place_extras(host: Control, bits: Array[TextureRect], extras: Array, area_pos: Vector2, area_size: Vector2, tex: Texture2D = null) -> void:
	while bits.size() < extras.size():
		var shadow := TextureRect.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shadow.z_index = 6
		shadow.self_modulate = Color(0.14, 0.07, 0.03, 0.35)
		host.add_child(shadow)
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.z_index = 6
		icon.set_meta("shadow", shadow)
		host.add_child(icon)
		bits.append(icon)
	for i in bits.size():
		var icon: TextureRect = bits[i]
		var shadow: TextureRect = icon.get_meta("shadow")
		if i >= extras.size() or area_size.x < 2.0:
			icon.visible = false
			shadow.visible = false
			continue
		var id := str(extras[i])
		var style: Dictionary = EXTRA_STYLE.get(id, {})
		var face := _bread_face(tex, area_pos, area_size)
		var art_path := str(EXTRA_ART.get(id, "res://assets/art/%s.png" % id))
		var art: Texture2D = _art(art_path)
		if art == null:
			icon.visible = false
			shadow.visible = false
			continue
		var width: float = face.size.x * float(style.get("fill", 0.58))
		var aspect: float = 1.0
		var art_size := art.get_size()
		if art_size.x > 1.0:
			aspect = art_size.y / art_size.x
		var height: float = width * aspect * float(style.get("squash", 1.0))
		var off: Vector2 = style.get("off", Vector2.ZERO)
		var stagger: Vector2 = Vector2.ZERO if id in ["sucuk", "salca", "mayo", "ketchup"] else EXTRA_STAGGER[i % EXTRA_STAGGER.size()]
		var center := face.position + face.size * 0.5 + Vector2((off.x + stagger.x) * face.size.x, (off.y + stagger.y) * face.size.y)
		var bit_size := Vector2(width, height)
		var rot: float = float(style.get("rot", 0.0))
		var layer := int(style.get("z", 0))
		icon.texture = art
		shadow.texture = art
		shadow.z_index = 6 + layer
		icon.z_index = 7 + layer
		for rect: TextureRect in [shadow, icon]:
			rect.visible = true
			rect.size = bit_size
			rect.pivot_offset = bit_size * 0.5
			rect.rotation_degrees = rot
		icon.position = center - bit_size * 0.5
		shadow.position = icon.position + Vector2(1.0, maxf(2.0, height * 0.06))


func _slot_text(s: int) -> String:
	if board_ids[s] == "":
		return ""
	var text := ItemLogic.plate_label(board_ids[s])
	for extra in board_extras[s]:
		text += " + " + ItemLogic.display_name(extra)
	return text


func _plate_text() -> String:
	var parts: Array[String] = []
	for s in 2:
		var t := _slot_text(s)
		if t != "":
			parts.append(t)
	return "  •  ".join(parts)


func _refresh_board() -> void:
	if prep_plate == null or prep_food == null or prep_food2 == null:
		return
	var sc: float = _bg_map().scale
	prep_plate.visible = false
	if prep_name:
		prep_name.position = _img_to_local(BOARD_NAME_IMG.position)
		prep_name.size = BOARD_NAME_IMG.size * sc
		prep_name.add_theme_font_size_override("font_size", int(16 * clampf(sc, 0.9, 1.3)))
		prep_name.add_theme_color_override("font_color", Color(0.28, 0.16, 0.08))
		prep_name.add_theme_color_override("font_shadow_color", Color(1, 0.96, 0.9, 0.9))
		prep_name.add_theme_constant_override("shadow_offset_y", 1)
		prep_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prep_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var foods := [prep_food, prep_food2]
	var bit_lists := [_board_bits, _board_bits2]
	for s in 2:
		var food: TextureRect = foods[s]
		var slot_rect: Rect2 = BOARD_SLOT_IMG[s]
		food.position = _img_to_local(slot_rect.position)
		food.size = slot_rect.size * sc
		if board_ids[s] == "":
			food.visible = false
			food.texture = null
			_place_extras($PrepBoard, bit_lists[s], [], food.position, food.size, null)
			continue
		food.visible = true
		food.texture = _art(ItemLogic.plate_icon_path(board_ids[s]))
		food.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_place_extras($PrepBoard, bit_lists[s], board_extras[s], food.position, food.size, food.texture)
	if prep_name:
		prep_name.visible = _board_has_any()
		prep_name.text = _plate_text()
		prep_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _paint_grill() -> void:
	for i in _slot_icons.size():
		if i >= toaster.slots.size():
			return
		var slot: Dictionary = toaster.slots[i]
		if str(slot.get("state", "")) != "cooking":
			continue
		var p := clampf(float(slot.get("elapsed", 0.0)) / maxf(0.1, float(slot.get("cook", 10.0))), 0.0, 1.0)
		_slot_icons[i].modulate = Color.WHITE.lerp(Color(1.08, 0.78, 0.48), p)


func _refresh_toaster() -> void:
	if _slot_icons.is_empty() or toaster.slots.size() < _slot_icons.size():
		return
	var sc: float = _bg_map().scale
	for i in _slot_icons.size():
		var icon: TextureRect = _slot_icons[i]
		var slot: Dictionary = toaster.slots[i]
		var state := str(slot.get("state", "empty"))
		if state == "empty":
			icon.visible = false
			icon.texture = null
			continue
		icon.visible = true
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		if state == "cooking":
			icon.texture = _art("res://assets/art/grill_raw.png")
			var p := clampf(float(slot.get("elapsed", 0.0)) / maxf(0.1, float(slot.get("cook", 10.0))), 0.0, 1.0)
			icon.modulate = Color.WHITE.lerp(Color(1.08, 0.78, 0.48), p)
		elif state == "ready":
			icon.texture = _art("res://assets/art/grill_done.png")
			icon.modulate = Color.WHITE
		else:
			icon.texture = _art("res://assets/art/grill_burnt.png")
			icon.modulate = Color.WHITE
		var aspect := 0.82
		var ts := icon.texture.get_size()
		if ts.x > 1.0:
			aspect = ts.y / ts.x
		var w := 72.0 * sc
		var sz := Vector2(w, w * aspect)
		icon.size = sz
		icon.pivot_offset = sz * 0.5
		icon.rotation_degrees = -30.0
		icon.position = _img_to_local(SLOT_HOLE[i]) - sz * 0.5
		var shadow: TextureRect = icon.get_meta("shadow") if icon.has_meta("shadow") else null
		if shadow == null:
			shadow = TextureRect.new()
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			shadow.stretch_mode = TextureRect.STRETCH_SCALE
			shadow.self_modulate = Color(0.1, 0.05, 0.02, 0.32)
			icon.get_parent().add_child(shadow)
			icon.get_parent().move_child(shadow, icon.get_index())
			icon.set_meta("shadow", shadow)
		shadow.visible = icon.visible
		shadow.texture = icon.texture
		shadow.size = sz
		shadow.pivot_offset = icon.pivot_offset
		shadow.rotation_degrees = icon.rotation_degrees
		shadow.position = icon.position + Vector2(2.0, maxf(3.0, sz.y * 0.08))


func _pop_into_slot(index: int) -> void:
	if index < 0 or index >= _slot_icons.size():
		return
	var icon: TextureRect = _slot_icons[index]
	icon.scale = Vector2(1.12, 0.88)
	var tween := create_tween()
	tween.tween_property(icon, "scale", Vector2.ONE, 0.16)


func _popup(text: String, pos: Vector2, color: Color) -> void:
	float_label.text = text
	float_label.modulate = color
	float_label.global_position = pos
	float_label.visible = true
	float_label.modulate.a = 1
	var tween := create_tween()
	tween.tween_property(float_label, "position:y", float_label.position.y - 36, 0.7)
	tween.parallel().tween_property(float_label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(func() -> void: float_label.visible = false)


func _toggle_how_to() -> void:
	$HowTo.visible = true
	running = false


func _close_how_to() -> void:
	$HowTo.visible = false
	if not result_layer.visible:
		running = true
	_update_held()


func _fill_recipe_panel() -> void:
	var box: VBoxContainer = $RecipePanel/Margin/List
	for child in box.get_children():
		child.queue_free()
	for line in [
		"Sade tost: ekmek → ızgara",
		"Kaşarlı: kızarmış tostu tahtaya koy + kaşar",
		"Sucuklu: tahtaya koy + sucuk",
		"Salça veya sos: tahtadaki tostun üstüne bırak",
		"Domates, biber, zeytin, mısır, turşu, kekik de tahtaya konur",
		"Karışık: kaşar + sucuk, sonra salça ya da ketçap",
		"Tahtaya yan yana 2 tost koyabilirsin",
		"İçecek: sağdaki dolaptan kola, ayran veya su",
	]:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.12))
		box.add_child(label)


func _end_shift(failed: bool) -> void:
	if not running:
		return
	running = false
	var thresholds: Array = level.get("stars", [80, 160, 240])
	var stars := 0 if failed else orders.star_count(thresholds)
	GameState.record_stars(int(level.get("id", 1)), stars)
	result_layer.visible = true
	if failed:
		result_title.text = "Müşteriler kaçtı"
		Sfx.play("lose")
	elif stars == 0:
		result_title.text = "Hedef tutmadı"
		Sfx.play("lose")
	else:
		result_title.text = "Vardiya bitti"
		Sfx.play("win")
	result_body.text = "Skor %d\nKazanç %d₺\nServis %d   •   Kaçan %d" % [orders.score, orders.money, orders.served, orders.missed]
	for child in result_stars.get_children():
		child.queue_free()
	for i in 3:
		var star := TextureRect.new()
		star.texture = load("res://assets/ui/star.png" if i < stars else "res://assets/ui/star_empty.png")
		star.custom_minimum_size = Vector2(56, 56)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		result_stars.add_child(star)


func _restart() -> void:
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
