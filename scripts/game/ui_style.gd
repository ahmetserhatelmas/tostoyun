class_name UiStyle
extends RefCounted


static func panel(bg: Color, radius: int = 18, border: Color = Color(0.19, 0.13, 0.09, 1)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func apply_button(button: Button, bg: Color, text_color: Color = Color(1, 0.98, 0.94)) -> void:
	var normal := panel(bg)
	var hover := panel(bg.lightened(0.08))
	var pressed := panel(bg.darkened(0.08))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_font_size_override("font_size", 18)


static func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null
