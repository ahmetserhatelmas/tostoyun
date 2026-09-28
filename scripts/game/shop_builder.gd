class_name ShopBuilder
extends RefCounted


static func build(root: Node3D) -> Dictionary:
	var wood := MeshKit.mat(Color(0.92, 0.78, 0.55), 0.7, 0.0, MeshKit.tex("res://assets/textures/wood_light.png"), 2.4)
	var dark := MeshKit.mat(Color(0.55, 0.38, 0.24), 0.68, 0.0, MeshKit.tex("res://assets/textures/wood_dark.png"), 2.0)
	var plaster := MeshKit.mat(Color(1, 0.96, 0.88), 0.86, 0.0, MeshKit.tex("res://assets/textures/plaster.png"), 3.0)
	var floor := MeshKit.mat(Color(0.95, 0.86, 0.7), 0.72, 0.0, MeshKit.tex("res://assets/textures/floor_tile.png"), 6.0)
	var metal := MeshKit.mat(Color(0.72, 0.74, 0.78), 0.28, 0.72, MeshKit.tex("res://assets/textures/metal.png"), 1.4)
	var glass := MeshKit.mat(Color(0.7, 0.85, 0.95, 0.18), 0.05, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var window_tex := MeshKit.tex("res://assets/textures/window_view.png")
	var window := MeshKit.mat(Color.WHITE, 0.9, 0.0, window_tex, 1.0)
	window.uv1_scale = Vector3(1, 1, 1)
	window.emission_enabled = true
	window.emission = Color(1.0, 0.9, 0.7)
	window.emission_energy_multiplier = 0.35
	if window_tex:
		window.emission_texture = window_tex

	MeshKit.box(root, Vector3(0, -0.04, 0.2), Vector3(10.5, 0.08, 9.2), floor, "Floor")
	MeshKit.box(root, Vector3(0, 2.15, -3.55), Vector3(10.5, 4.2, 0.16), plaster, "BackWall")
	MeshKit.box(root, Vector3(-5.2, 2.15, 0.2), Vector3(0.16, 4.2, 9.2), plaster, "LeftWall")
	MeshKit.box(root, Vector3(5.2, 2.15, 0.2), Vector3(0.16, 4.2, 9.2), plaster, "RightWall")
	MeshKit.box(root, Vector3(0, 4.28, 0.2), Vector3(10.5, 0.12, 9.2), dark, "Ceiling")
	MeshKit.box(root, Vector3(0, 1.85, -3.46), Vector3(4.3, 2.3, 0.04), window, "WindowView")
	MeshKit.box(root, Vector3(0, 1.85, -3.42), Vector3(4.5, 2.5, 0.08), dark, "WindowFrame")
	MeshKit.box(root, Vector3(0, 1.85, -3.4), Vector3(0.08, 2.3, 0.06), dark)
	MeshKit.box(root, Vector3(0, 1.85, -3.38), Vector3(4.3, 2.3, 0.02), glass)

	for x in [-3.4, 0.0, 3.4]:
		_beam(root, Vector3(x, 4.12, 0.2), dark)
		_lamp(root, Vector3(x, 3.55, 0.35))

	var seats: Array[Vector3] = []
	for i in 3:
		var x := -2.3 + 2.3 * i
		_table(root, Vector3(x, 0, -1.55), wood, dark)
		seats.append(Vector3(x, 0, -1.35))

	_counter(root, wood, dark)
	_toaster(root, Vector3(-0.15, 1.02, 0.55), metal)
	var toaster_root: Node3D = root.get_node("Toaster")
	var toaster_slots: Array[Node3D] = [toaster_root.get_node("Slot0"), toaster_root.get_node("Slot1")]

	_basket(root, Vector3(-2.55, 1.02, 0.55), wood)
	_bin(root, Vector3(2.55, 0.72, 0.7), metal)
	_jar(root, Vector3(-2.35, 1.02, 1.28), Color(0.96, 0.8, 0.22), "cheese")
	_jar(root, Vector3(-0.75, 1.02, 1.28), Color(0.55, 0.14, 0.12), "sucuk")
	_bottle(root, Vector3(0.75, 1.08, 1.28))
	_fridge(root, Vector3(2.4, 0.78, 1.28), metal)
	var held := Node3D.new()
	held.name = "HeldPlate"
	held.position = Vector3(0, 1.08, 1.85)
	root.add_child(held)
	MeshKit.cyl(root, Vector3(0, 1.01, 1.85), 0.22, 0.03, MeshKit.mat(Color(0.93, 0.93, 0.9), 0.25))

	_plant(root, Vector3(-4.6, 0, -3.0))
	_plant(root, Vector3(4.6, 0, -3.0))
	_board(root, Vector3(3.7, 2.3, -3.42), dark)

	MeshKit.area(root, Vector3(-2.55, 1.15, 0.55), Vector3(0.85, 0.7, 0.75), {"kind": "station", "station_id": "bread"})
	MeshKit.area(root, Vector3(2.55, 1.05, 0.7), Vector3(0.7, 0.8, 0.7), {"kind": "station", "station_id": "trash"})
	MeshKit.area(root, Vector3(-2.35, 1.2, 1.28), Vector3(0.7, 0.7, 0.7), {"kind": "station", "station_id": "cheese"})
	MeshKit.area(root, Vector3(-0.75, 1.2, 1.28), Vector3(0.7, 0.7, 0.7), {"kind": "station", "station_id": "sucuk"})
	MeshKit.area(root, Vector3(0.75, 1.2, 1.28), Vector3(0.7, 0.7, 0.7), {"kind": "station", "station_id": "ketchup"})
	MeshKit.area(root, Vector3(2.4, 1.15, 1.28), Vector3(0.75, 0.8, 0.7), {"kind": "station", "station_id": "ayran"})
	MeshKit.area(root.get_node("Toaster/Slot0"), Vector3.ZERO, Vector3(0.55, 0.45, 0.55), {"kind": "toaster", "slot": 0})
	MeshKit.area(root.get_node("Toaster/Slot1"), Vector3.ZERO, Vector3(0.55, 0.45, 0.55), {"kind": "toaster", "slot": 1})

	_sun(root)
	return {
		"seats": seats,
		"toaster_slots": toaster_slots,
		"held_plate": held,
		"spawn": Vector3(-4.6, 0, -1.35),
		"exit": Vector3(4.8, 0, -1.35),
	}


static func _beam(root: Node3D, pos: Vector3, mat: Material) -> void:
	MeshKit.box(root, pos, Vector3(0.16, 0.14, 8.6), mat)


static func _lamp(root: Node3D, pos: Vector3) -> void:
	MeshKit.cyl(root, pos + Vector3(0, 0.25, 0), 0.015, 0.5, MeshKit.mat(Color(0.2, 0.15, 0.1), 0.4, 0.3))
	MeshKit.cyl(root, pos, 0.12, 0.12, MeshKit.mat(Color(0.95, 0.78, 0.42), 0.35), "", 0.55)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, -0.15, 0)
	light.light_color = Color(1.0, 0.86, 0.62)
	light.light_energy = 1.35
	light.omni_range = 5.5
	light.shadow_enabled = false
	root.add_child(light)


static func _table(root: Node3D, pos: Vector3, wood: Material, dark: Material) -> void:
	MeshKit.cyl(root, pos + Vector3(0, 0.78, 0), 0.46, 0.06, wood)
	MeshKit.cyl(root, pos + Vector3(0, 0.4, 0), 0.07, 0.78, dark)
	MeshKit.cyl(root, pos + Vector3(0, 0.04, 0), 0.2, 0.06, dark)
	MeshKit.box(root, pos + Vector3(0, 0.42, 0.38), Vector3(0.36, 0.08, 0.36), dark)
	MeshKit.box(root, pos + Vector3(0, 0.7, 0.46), Vector3(0.36, 0.42, 0.08), dark)


static func _counter(root: Node3D, wood: Material, dark: Material) -> void:
	MeshKit.box(root, Vector3(0, 0.48, 0.95), Vector3(7.4, 0.96, 1.7), dark)
	MeshKit.box(root, Vector3(0, 0.98, 0.95), Vector3(7.55, 0.08, 1.82), wood)
	MeshKit.box(root, Vector3(0, 1.35, 0.18), Vector3(7.4, 0.7, 0.08), MeshKit.mat(Color(0.45, 0.22, 0.16), 0.55))


static func _toaster(root: Node3D, pos: Vector3, metal: Material) -> Node3D:
	var body := Node3D.new()
	body.name = "Toaster"
	body.position = pos
	root.add_child(body)
	MeshKit.box(body, Vector3(0.25, 0.16, 0), Vector3(1.15, 0.32, 0.62), metal)
	MeshKit.box(body, Vector3(0.25, 0.02, 0), Vector3(1.2, 0.06, 0.66), MeshKit.mat(Color(0.2, 0.16, 0.14), 0.5, 0.4))
	var slot0 := Node3D.new()
	slot0.name = "Slot0"
	slot0.position = Vector3(-0.02, 0.28, 0)
	body.add_child(slot0)
	var slot1 := Node3D.new()
	slot1.name = "Slot1"
	slot1.position = Vector3(0.52, 0.28, 0)
	body.add_child(slot1)
	MeshKit.box(body, Vector3(-0.02, 0.34, 0), Vector3(0.38, 0.04, 0.42), MeshKit.mat(Color(0.12, 0.1, 0.09), 0.8))
	MeshKit.box(body, Vector3(0.52, 0.34, 0), Vector3(0.38, 0.04, 0.42), MeshKit.mat(Color(0.12, 0.1, 0.09), 0.8))
	MeshKit.box(body, Vector3(-0.42, 0.22, 0.0), Vector3(0.08, 0.18, 0.08), MeshKit.mat(Color(0.85, 0.2, 0.16), 0.4, 0.3))
	return slot0


static func _basket(root: Node3D, pos: Vector3, wood: Material) -> void:
	MeshKit.box(root, pos, Vector3(0.55, 0.16, 0.4), wood)
	FoodMesh.replace(_anchor(root, pos + Vector3(0, 0.12, 0), "BreadPile"), "bread")
	var extra := FoodMesh.make("bread")
	extra.position = pos + Vector3(0.08, 0.16, 0.04)
	extra.rotation_degrees.y = 25
	root.add_child(extra)


static func _bin(root: Node3D, pos: Vector3, metal: Material) -> void:
	MeshKit.cyl(root, pos, 0.16, 0.42, metal, "", 0.85)
	MeshKit.cyl(root, pos + Vector3(0, 0.22, 0), 0.18, 0.05, MeshKit.mat(Color(0.25, 0.25, 0.26), 0.4, 0.5))


static func _jar(root: Node3D, pos: Vector3, fill: Color, item: String) -> void:
	var glass := MeshKit.mat(Color(0.8, 0.9, 0.95, 0.28), 0.06, 0.04)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	MeshKit.cyl(root, pos + Vector3(0, 0.12, 0), 0.1, 0.22, glass)
	MeshKit.cyl(root, pos + Vector3(0, 0.08, 0), 0.08, 0.14, MeshKit.mat(fill, 0.5))
	MeshKit.cyl(root, pos + Vector3(0, 0.24, 0), 0.07, 0.04, MeshKit.mat(Color(0.35, 0.22, 0.14), 0.6))
	var label := FoodMesh.make(item)
	label.scale = Vector3(0.45, 0.45, 0.45)
	label.position = pos + Vector3(0, 0.32, 0)
	root.add_child(label)


static func _bottle(root: Node3D, pos: Vector3) -> void:
	var red := MeshKit.mat(Color(0.78, 0.14, 0.14), 0.28, 0.05)
	MeshKit.cyl(root, pos, 0.055, 0.22, red)
	MeshKit.cyl(root, pos + Vector3(0, 0.14, 0), 0.025, 0.1, red)
	MeshKit.cyl(root, pos + Vector3(0, 0.2, 0), 0.03, 0.03, MeshKit.mat(Color(0.15, 0.1, 0.08), 0.5))


static func _fridge(root: Node3D, pos: Vector3, metal: Material) -> void:
	MeshKit.box(root, pos + Vector3(0, 0.28, 0), Vector3(0.55, 0.7, 0.42), metal)
	MeshKit.box(root, pos + Vector3(0, 0.28, 0.2), Vector3(0.48, 0.58, 0.04), MeshKit.mat(Color(0.55, 0.75, 0.8, 0.35), 0.08))
	var extra := FoodMesh.make("ayran")
	extra.position = pos + Vector3(0, 0.42, 0.05)
	root.add_child(extra)


static func _plant(root: Node3D, pos: Vector3) -> void:
	MeshKit.cyl(root, pos + Vector3(0, 0.16, 0), 0.14, 0.28, MeshKit.mat(Color(0.55, 0.28, 0.2), 0.7))
	MeshKit.sphere(root, pos + Vector3(0, 0.48, 0), 0.22, MeshKit.mat(Color(0.22, 0.5, 0.24), 0.85))
	MeshKit.sphere(root, pos + Vector3(0.12, 0.58, 0.04), 0.14, MeshKit.mat(Color(0.3, 0.6, 0.28), 0.85))


static func _board(root: Node3D, pos: Vector3, dark: Material) -> void:
	MeshKit.box(root, pos, Vector3(1.1, 0.75, 0.05), dark)
	MeshKit.box(root, pos + Vector3(0, 0, 0.03), Vector3(0.95, 0.6, 0.02), MeshKit.mat(Color(0.18, 0.28, 0.2), 0.8))


static func _sun(root: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42, 28, 0)
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 24
	root.add_child(sun)


static func _anchor(root: Node3D, pos: Vector3, n: String) -> Node3D:
	var node := Node3D.new()
	node.name = n
	node.position = pos
	root.add_child(node)
	return node
