extends Control


func _ready() -> void:
	var fill := ColorRect.new()
	fill.color = Color(0.05, 0.04, 0.03)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	move_child(fill, 0)
	$Title.visible = false
	$Subtitle.text = "Yaz panayırı, akşam tost tezgâhı"
	$HowTo.text = "Ekmek kasasından al, ızgarada kızart, tahtada malzeme ekle.\nKola, ayran ve su sağdaki dolapta."
	_fill_levels()
	UiStyle.apply_button($Quit, Color(0.55, 0.22, 0.18))
	$Quit.pressed.connect(func() -> void: get_tree().quit())


func _fill_levels() -> void:
	var box: VBoxContainer = $Levels
	for child in box.get_children():
		child.queue_free()
	for level in GameState.levels:
		var id := int(level.get("id", 1))
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 88)
		button.text = "%s\n%s" % [level.get("name", "Vardiya"), level.get("blurb", "")]
		UiStyle.apply_button(button, Color(0.62, 0.4, 0.24))
		button.pressed.connect(_start.bind(id))
		box.add_child(button)
		var stars := HBoxContainer.new()
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 3:
			var icon := TextureRect.new()
			icon.texture = load("res://assets/ui/star.png" if i < GameState.stars_for(id) else "res://assets/ui/star_empty.png")
			icon.custom_minimum_size = Vector2(26, 26)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars.add_child(icon)
		button.add_child(stars)
		stars.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		stars.offset_top = -32
		stars.offset_bottom = -4


func _start(level_id: int) -> void:
	Sfx.play("tap")
	GameState.start_level(level_id)
	get_tree().change_scene_to_file("res://scenes/game/Restaurant.tscn")
