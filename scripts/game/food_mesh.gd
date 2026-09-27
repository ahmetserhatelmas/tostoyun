class_name FoodMesh
extends RefCounted


static func make(item_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Food_%s" % item_id
	match item_id:
		"bread":
			_toast(root, Color(0.86, 0.7, 0.46), false)
		"toast", "sade":
			_toast(root, Color(0.72, 0.48, 0.26), true)
		"toast_cheese", "kasarli":
			_toast(root, Color(0.72, 0.48, 0.26), true)
			_cheese(root)
		"toast_sucuk", "sucuklu":
			_toast(root, Color(0.72, 0.48, 0.26), true)
			_sucuk(root)
		"toast_mixed", "toast_mixed_cooked", "karisik":
			_toast(root, Color(0.72, 0.48, 0.26), true)
			_cheese(root)
			_sucuk(root)
			if item_id == "karisik" or item_id == "toast_mixed_cooked":
				_ketchup(root)
		"ayran":
			_ayran(root)
		"burnt":
			_toast(root, Color(0.12, 0.09, 0.07), true)
		_:
			_toast(root, Color(0.8, 0.62, 0.38), false)
	return root


static func replace(anchor: Node3D, item_id: String) -> void:
	for child in anchor.get_children():
		if child is Area3D or child is CollisionShape3D:
			continue
		child.queue_free()
	if item_id == "":
		return
	anchor.add_child(make(item_id))


static func _toast(root: Node3D, color: Color, marks: bool) -> void:
	var bread := MeshKit.mat(color, 0.78)
	MeshKit.box(root, Vector3(0, 0.03, 0), Vector3(0.28, 0.045, 0.2), bread)
	MeshKit.box(root, Vector3(0, 0.07, 0), Vector3(0.27, 0.04, 0.19), MeshKit.mat(color.lightened(0.08), 0.8))
	if marks:
		var grill := MeshKit.mat(Color(0.28, 0.16, 0.08), 0.9)
		for x in [-0.07, 0.0, 0.07]:
			MeshKit.box(root, Vector3(x, 0.095, 0), Vector3(0.018, 0.008, 0.16), grill)


static func _cheese(root: Node3D) -> void:
	MeshKit.box(root, Vector3(0, 0.11, 0), Vector3(0.22, 0.018, 0.15), MeshKit.mat(Color(0.96, 0.8, 0.22), 0.45))


static func _sucuk(root: Node3D) -> void:
	var meat := MeshKit.mat(Color(0.48, 0.12, 0.12), 0.55)
	MeshKit.cyl(root, Vector3(-0.05, 0.13, 0.01), 0.035, 0.02, meat)
	MeshKit.cyl(root, Vector3(0.05, 0.13, -0.02), 0.032, 0.02, meat)


static func _ketchup(root: Node3D) -> void:
	MeshKit.box(root, Vector3(0.07, 0.145, 0.02), Vector3(0.05, 0.012, 0.08), MeshKit.mat(Color(0.78, 0.16, 0.14), 0.35))


static func _ayran(root: Node3D) -> void:
	var glass := MeshKit.mat(Color(0.85, 0.93, 0.95, 0.35), 0.08, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	MeshKit.cyl(root, Vector3.ZERO, 0.055, 0.14, glass)
	MeshKit.cyl(root, Vector3(0, -0.01, 0), 0.045, 0.1, MeshKit.mat(Color(0.96, 0.96, 0.93), 0.4))
