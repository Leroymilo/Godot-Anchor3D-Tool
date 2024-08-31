@tool
extends Node3D
class_name Anchor3D
## The base class for the custom Anchor3D tools by Leroymilo.[br]
## Do not use this class itself, use one of its inherited classes
## ([VertexAnchor3D]).

const Geometry = preload("res://resource/geometry.gd")
const MeshGeometry = preload("res://resource/mesh_geometry.gd")
const ShapeGeometry = preload("res://resource/shape_geometry.gd")

@export_group("Debug")

## Shows a debug model on this [Anchor3D]
@export var visualize: bool = true:
	set(value):
		visualize = value
		update_visual()
		notify_property_list_changed()
## The radius of the debug model
@export var visual_radius: float = 0.2:
	set(value):
		visual_radius = value
		update_visual()
## Shows 3 [RayCast3D] as x, y and z
@export var visual_axes: bool = true:
	set(value):
		visual_axes = value
		if is_node_ready():
			$Axes.visible = value
		notify_property_list_changed()
## The length and thickness of the debug axes
@export var visual_axes_size: float = 4:
	set(value):
		visual_axes_size = value
		if is_node_ready():
			for child: RayCast3D in $Axes.get_children():
				child.target_position = child.target_position.normalized() * value
				child.debug_shape_thickness = value

@export_group("Target")

enum ANCHORTYPE {
	SNAP,	## Snaps this [Anchor3D] to the target Node's geometry.
	GRAB,	## Snaps the target Node's geometry to this [Anchor3D].
}
## Chooses in which way this [Anchor3D] works
@export var anchor_type: ANCHORTYPE:
	set(value):
		anchor_type = value
		anchor()

enum TARGETTYPE {
	MESH,	## Snaps to/grabs on the [Mesh] of a [MeshInstance3D]
	SHAPE	## Snaps to/grabs on the [Shape3D] of a [CollisionShape3D]
}
## Chooses which type of node you want this to snap to/grab on.[br]
## [b][color=yellow]Some features will be unavailable if the target is a Shape3D.[/color][/b]
@export var target_type: TARGETTYPE:
	set(value):
		if value != target_type:
			target_node = null
		target_type = value
		notify_property_list_changed()

## The [MeshInstance3D] or [CollisionShape3D] to snap to or grab on.[br]
## List of consistent [Shape3D] types: [BoxShape3D]
@export var target_node: Node3D:
	set(value):
		if value != null and is_ancestor_of(value):
			print("target is a child of the anchor")
			node_loaded = false
			target_node = null
			return
		
		target_node = value
		
		if setup_geometry():
			print("target is valid")
			node_loaded = true	# will call anchor
		else:
			node_loaded = false
			target_node = null

## internal
var node_loaded: bool = false:
	set(value):
		node_loaded = value
		free_movement = not node_loaded
		notify_property_list_changed()

@export_group("Transform Settings")

## Allows to move this Anchor3D freely in the editor.[br]
## Unchecking this will snap to/grab on the "first" primitive of the target.[br]
## [color=yellow]This is not meant to be left "On",
## it will turn back off if the scene is reloaded with a valid [member Anchor3D.target_node][/color]
@export var free_movement: bool = false:
	set(value):
		free_movement = value
		anchor()

## If this is checked, the Anchor3D's rotation will follow
## the rotation of the selected node.[br]
## This is required for [member Anchor3D.follow_primitive_rotation].
@export var follow_node_rotation: bool = false:
	set(value):
		if value == follow_node_rotation: return
		
		follow_node_rotation = value
		if not value:
			follow_primitive_rotation = false
		anchor()

## If this is checked, the Anchor3D's basis (x, y, z) will follow
## the basis (normal, binormal, tangent) of the selected primitive (vertex/edge/face).[br]
## This requires [member Anchor3D.follow_node_rotation] and a [MeshInstance3D] target.
@export var follow_primitive_rotation: bool = false:
	set(value):
		follow_primitive_rotation = value
		update_count()
		
		if value:
			follow_node_rotation = true
		anchor()

## internal
var geometry: Geometry = null

## internal
var self_transf: Transform3D = Transform3D.IDENTITY
## internal
var target_transf: Transform3D = Transform3D.IDENTITY
## internal
var target_pos: Vector3 = Vector3.ZERO
## internal
var target_rot: Vector3 = Vector3.ZERO
## internal
var self_pos: Vector3 = Vector3.ZERO
## internal
var self_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	self_pos = global_position
	self_rot = global_rotation

func _validate_property(property: Dictionary) -> void:
	if property.name in ["visual_radius"] and not visualize:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["visual_axes_size"] and not visual_axes:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	
	if property.name == "target_node":
		if target_type == TARGETTYPE.MESH:
			property.hint_string = "MeshInstance3D"
		if target_type == TARGETTYPE.SHAPE:
			property.hint_string = "CollisionShape3D"
	
	if property.name in ["free_movement", "follow_node_rotation", "follow_primitive_rotation"]:
		if not node_loaded:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
		elif property.name == "follow_primitive_rotation" and target_type == TARGETTYPE.SHAPE:
			property.usage = PROPERTY_USAGE_NO_EDITOR

func setup_geometry() -> bool:
	if target_node == null:
		geometry = null
		return false
	
	var arr_mesh: ArrayMesh = ArrayMesh.new()
	
	if target_node is MeshInstance3D:
		geometry = MeshGeometry.new(target_node.mesh)
	
	elif target_node is CollisionShape3D:
		geometry = ShapeGeometry.new(target_node.shape)
	
	return geometry.is_valid

func _process(_delta: float) -> void:
	if target_node == null or not node_loaded:
		return
	
	if not free_movement:
		if anchor_type == ANCHORTYPE.SNAP:
			global_position = self_pos
			if follow_node_rotation:
				global_rotation = self_rot
			
			if target_node.global_transform != target_transf:
				anchor()
		
		if anchor_type == ANCHORTYPE.GRAB:
			target_node.global_position = target_pos
			if follow_node_rotation:
				target_node.global_rotation = target_rot
			
			if global_transform != self_transf:
				anchor()

func update_count():
	# to override
	pass

func update_visual():
	# to override
	pass

func anchor():
	if not is_node_ready() or not node_loaded or free_movement: return
	
	if anchor_type == ANCHORTYPE.SNAP:
		snap()
	elif anchor_type == ANCHORTYPE.GRAB:
		grab()
	
	self_pos = global_position
	self_rot = global_rotation
	target_pos = target_node.global_position
	target_rot = target_node.global_rotation
	self_transf = global_transform
	target_transf = target_node.global_transform

func snap():
	pass

func grab():
	pass
