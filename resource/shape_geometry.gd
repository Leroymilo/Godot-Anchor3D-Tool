extends "geometry.gd"

var array_mesh: ArrayMesh

func _init(shape: Shape3D) -> void:
	array_mesh = shape.get_debug_mesh()

func load_vertices(load_basis: bool = false) -> int:
	
	#transforms.clear()
	var loaded: Dictionary = {}
	
	for vertex in array_mesh.surface_get_arrays(0)[0]:
		
		var transform: Transform3D = Transform3D(
			Basis.IDENTITY,
			vertex
		)
		
		if not loaded.has(transform):
			loaded[transform] = true
			#transforms.append(transform)
	
	return 0
	#return transforms.size()
