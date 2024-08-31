extends Resource

var offsets: PackedVector3Array = []
var bases: PackedVector3Array = []
var indices: PackedInt64Array = []

var is_valid = false

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
