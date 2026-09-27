class_name Customer
extends Control

signal tapped(customer: Customer)
signal left_angry(customer: Customer)
signal served(customer: Customer, recipe_id: String, patience_ratio: float)
signal served_wrong(customer: Customer)

const VARIANTS := ["a", "b", "c", "d"]

var seat_index: int = -1
var recipe_id: String = "sade"
var max_patience: float = 20.0
var patience: float = 20.0
var state: String = "entering"
var variant: String = "a"

@onready var _body: TextureRect = $Body
@onready var _bubble: Panel = $Bubble
@onready var _order_icon: TextureRect = $Bubble/OrderIcon
@onready var _order_name: Label = $Bubble/OrderName
@onready var _bar: ProgressBar = $Bubble/Patience
@onready var _reaction: TextureRect = $Reaction


func setup(p_recipe: String, p_patience: float, p_seat: int) -> void:
	recipe_id = p_recipe
	max_patience = p_patience
	patience = p_patience
	seat_index = p_seat
	variant = VARIANTS[randi() % VARIANTS.size()]
	if is_node_ready():
		_apply_look()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_bubble.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 0.99, 0.97, 0.96), 16, Color(0.85, 0.8, 0.74)))
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.82, 0.5)
	fill.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.93, 0.91, 0.88)
	bg.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", bg)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Avenir Next", "Helvetica Neue", "Arial"])
	_order_name.add_theme_font_override("font", font)
	_apply_look()
	_bubble.visible = false
	_fit_order()


func _apply_look() -> void:
	_body.texture = load("res://assets/art/customer_%s.png" % variant)
	_body.visible = true
	_order_icon.texture = RecipeBook.icon(recipe_id)
	if _order_name:
		_order_name.text = RecipeBook.display_name(recipe_id)
	_bar.max_value = 1.0
	_bar.value = 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_order()


func _fit_order() -> void:
	if _bubble == null or _order_name == null or _order_icon == null or _bar == null:
		return
	var w := maxf(size.x, 168.0)
	_bubble.offset_left = 0.0
	_bubble.offset_top = 0.0
	_bubble.offset_right = w
	_bubble.offset_bottom = 92.0
	_order_icon.offset_left = 6.0
	_order_icon.offset_top = 8.0
	_order_icon.offset_right = 62.0
	_order_icon.offset_bottom = 64.0
	_order_name.offset_left = 66.0
	_order_name.offset_top = 4.0
	_order_name.offset_right = w - 8.0
	_order_name.offset_bottom = 56.0
	_order_name.add_theme_font_size_override("font_size", 15)
	_order_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bar.offset_left = 66.0
	_bar.offset_top = 60.0
	_bar.offset_right = w - 10.0
	_bar.offset_bottom = 80.0


func sit_down() -> void:
	state = "seated"
	_bubble.visible = true


func try_serve(item_id: String) -> bool:
	if state != "seated":
		return false
	if ItemLogic.serve_id(item_id) == recipe_id:
		state = "leaving"
		_bubble.visible = false
		show_reaction(true)
		served.emit(self, recipe_id, patience / max_patience)
		return true
	show_reaction(false)
	served_wrong.emit(self)
	return false


func show_reaction(happy: bool) -> void:
	if _reaction == null:
		return
	_reaction.texture = load("res://assets/ui/face_happy.png" if happy else "res://assets/ui/face_sad.png")
	_reaction.visible = true
	_reaction.modulate = Color(1, 1, 1, 1)
	_reaction.scale = Vector2(0.4, 0.4)
	_reaction.pivot_offset = _reaction.size * 0.5
	var tween := create_tween()
	tween.tween_property(_reaction, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.55)
	tween.tween_property(_reaction, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void: _reaction.visible = false)


func reject() -> void:
	patience = maxf(0.0, patience - 3.0)
	var tween := create_tween()
	tween.tween_property(self, "position:x", position.x + 8, 0.05)
	tween.tween_property(self, "position:x", position.x - 8, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)


func _process(delta: float) -> void:
	if state != "seated":
		return
	patience -= delta
	var ratio := clampf(patience / max_patience, 0.0, 1.0)
	_bar.value = ratio
	if ratio < 0.35:
		_bar.modulate = Color(0.85, 0.25, 0.2)
	elif ratio < 0.6:
		_bar.modulate = Color(0.95, 0.75, 0.2)
	else:
		_bar.modulate = Color(1, 1, 1)
	if patience <= 0.0:
		_go_angry()


func _go_angry() -> void:
	if state != "seated":
		return
	state = "leaving"
	_bubble.visible = false
	_body.modulate = Color(1.0, 0.62, 0.58)
	left_angry.emit(self)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
		accept_event()
