extends "geometry.gd"

func _init(mesh: Mesh) -> void:
	var MDT = MeshDataTool.new()
	MDT.clear()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		mesh.get_mesh_arrays()
	)
	if MDT.create_from_surface(array_mesh, 0) != 0:
		# MDT creation failed
		return
	
	is_valid = true
	
	offsets.clear()
	bases.clear()
	indices.clear()
	var unique_vertices: Dictionary = {}
	
	var sorted_indices: Array[int]
	sorted_indices.assign(range(MDT.get_vertex_count()))
	sorted_indices.sort_custom(func(a,b): return MDT.get_vertex(a) < MDT.get_vertex(b))
	
	for i in sorted_indices:
		var vertex: Vector3 = MDT.get_vertex(i)
		if not unique_vertices.has(vertex):
			unique_vertices[vertex] = true
			indices.append(offsets.size())
		offsets.append(vertex)
		
		var normal: Vector3 = align(MDT.get_vertex_normal(i))
		var t_plane: Plane = MDT.get_vertex_tangent(i)
		var tangent: Vector3 = align(t_plane.normal)
		var binormal: Vector3 = align(t_plane.d * tangent.cross(normal))
		bases.append_array([normal, binormal, tangent])

static func align(vect: Vector3) -> Vector3:
	if abs(vect.x) < 0.0001: vect.x = 0
	if abs(vect.y) < 0.0001: vect.y = 0
	if abs(vect.z) < 0.0001: vect.z = 0
	return vect

func get_count(with_rot: bool = false) -> int:
	if with_rot:
		return offsets.size()
	return indices.size()

func get_transform(id: int, with_rot: bool = false) -> Transform3D:
	if not with_rot:
		id = indices[id]
	var transform = Transform3D.IDENTITY.translated(offsets[id])
	if with_rot:
		transform *= Transform3D(
			Basis(bases[3*id], bases[3*id+1], bases[3*id+2]),
			Vector3.ZERO
		)
	return transform
