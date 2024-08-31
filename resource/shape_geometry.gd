extends "geometry.gd"

var array_mesh: ArrayMesh

func _init(shape: Shape3D) -> void:
	array_mesh = shape.get_debug_mesh()
	
	is_valid = true
	
	offsets.clear()
	bases.clear()
	indices.clear()
	var unique_vertices: Dictionary = {}
	
	var vertices: PackedVector3Array = array_mesh.surface_get_arrays(0)[0]
	var sorted_indices: Array[int]
	sorted_indices.assign(range(vertices.size()))
	sorted_indices.sort_custom(func(a,b): return vertices[a] < vertices[b])
	
	for i in sorted_indices:
		var vertex: Vector3 = vertices[i]
		if not unique_vertices.has(vertex):
			unique_vertices[vertex] = true
			indices.append(offsets.size())
		offsets.append(vertex)
