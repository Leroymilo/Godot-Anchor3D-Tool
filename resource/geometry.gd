extends Resource

var offsets: PackedVector3Array = []
var bases: PackedVector3Array = []
var indices: PackedInt64Array = []

var is_valid = false

func get_count(with_rot: bool = false) -> int:
	return 0

func get_transform(id: int, with_rot: bool = false) -> Transform3D:
	return Transform3D.IDENTITY
