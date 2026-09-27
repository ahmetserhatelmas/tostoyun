class_name MeshKit
extends RefCounted


static func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func mat(color: Color, roughness: float = 0.62, metallic: float = 0.0, texture: Texture2D = null, uv: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if texture:
		material.albedo_texture = texture
		material.uv1_scale = Vector3(uv, uv, uv)
	return material


static func emit_mat(color: Color, energy: float = 1.6) -> StandardMaterial3D:
	var material := mat(color, 0.35, 0.1)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


static func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, n: String = "") -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, pos, material, n)


static func cyl(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, n: String = "", top := 1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return _mesh(parent, mesh, pos, material, n)


static func sphere(parent: Node3D, pos: Vector3, radius: float, material: Material, n: String = "") -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 10
	return _mesh(parent, mesh, pos, material, n)


static func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, material: Material, n: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	if n != "":
		node.name = n
	parent.add_child(node)
	return node


static func area(parent: Node3D, pos: Vector3, size: Vector3, meta: Dictionary) -> Area3D:
	var area := Area3D.new()
	area.position = pos
	area.input_ray_pickable = true
	area.monitoring = false
	area.monitorable = true
	area.collision_layer = 1
	area.collision_mask = 0
	for key in meta.keys():
		area.set_meta(str(key), meta[key])
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	parent.add_child(area)
	return area
