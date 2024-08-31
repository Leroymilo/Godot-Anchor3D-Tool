@tool
extends Anchor3D
class_name VertexAnchor3D

## internal
var vertex_count: int = 0:
	set(value):
		vertex_count = value
		notify_property_list_changed()
		
@export_range(-1, 1) var vertex_index: int = 0:
	set(value):
		if value == -1:
			value = vertex_count -1
		if value == vertex_count:
			value = 0
		vertex_index = value
		anchor()

@onready var debug_mesh: SphereMesh = $Visualization.mesh

func _validate_property(property: Dictionary) -> void:
	super(property)
	if property.name == "vertex_index":
		if node_loaded:
			property.hint_string = "-1,%d" % vertex_count
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR

func setup_geometry():
	if not super(): return false
	update_count()
	print("mesh data extracted: ", vertex_count, " vertices")
	return true

func update_count():
	if geometry != null:
		vertex_count = geometry.get_count(follow_primitive_rotation)
		vertex_index = clampi(vertex_index, 0, vertex_count - 1)

func update_visual():
	if is_node_ready():
		$Visualization.visible = visualize
		debug_mesh.radius = visual_radius
		debug_mesh.height = visual_radius * 2

func snap():
	var prev_rot: Vector3 = global_rotation
	
	global_transform = Transform3D.IDENTITY
	global_transform *= target_node.global_transform
	global_transform *= geometry.get_transform(
		vertex_index, follow_primitive_rotation
	)
	
	if not follow_node_rotation:
		global_rotation = prev_rot

func grab():
	var prev_rot: Vector3 = target_node.global_rotation
	
	target_node.global_transform = Transform3D.IDENTITY
	target_node.global_transform *= global_transform
	target_node.global_transform *= geometry.get_transform(
		vertex_index, follow_primitive_rotation
	).inverse()
	
	if not follow_node_rotation:
		target_node.global_rotation = prev_rot
