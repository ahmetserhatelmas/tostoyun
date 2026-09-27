class_name GameHUD
extends Control

signal recipes_toggled

@onready var clock_label: Label = $Top/ClockBox/ClockLabel
@onready var score_label: Label = $Top/ScoreBox/ScoreLabel
@onready var money_label: Label = $Top/MoneyBox/MoneyLabel
@onready var lives_box: HBoxContainer = $LivesBox
@onready var hint_label: Label = $Hint
@onready var recipe_button: Button = $RecipeButton

var _heart_tex: Texture2D


func _ready() -> void:
	_heart_tex = load("res://assets/ui/heart.png")
	recipe_button.pressed.connect(func() -> void: recipes_toggled.emit())
	UiStyle.apply_button(recipe_button, Color(0.62, 0.4, 0.24))
	for label in [clock_label, score_label, money_label]:
		label.add_theme_color_override("font_color", Color(0.28, 0.18, 0.12))
	hint_label.add_theme_color_override("font_color", Color(0.32, 0.22, 0.16))


func set_clock(remaining: float, duration: float) -> void:
	var secs := maxi(0, int(ceil(remaining)))
	clock_label.text = "%d:%02d" % [secs / 60, secs % 60]
	var progress := 1.0 - clampf(remaining / maxf(1.0, duration), 0.0, 1.0)
	var minutes := int(lerp(11.0 * 60.0, 12.0 * 60.0, progress))
	clock_label.tooltip_text = "%02d:00" % (minutes / 60)


func set_score(score: int, money: int) -> void:
	score_label.text = str(score)
	money_label.text = str(money)


func set_lives(lives: int) -> void:
	for child in lives_box.get_children():
		child.queue_free()
	for i in lives:
		var heart := TextureRect.new()
		heart.texture = _heart_tex
		heart.custom_minimum_size = Vector2(32, 32)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lives_box.add_child(heart)


func set_hint(text: String) -> void:
	hint_label.text = text
