extends Node2D
## World root: FloorLayer (TileMapLayer) + NavigationRegion2D.
##
## Map space only. We paint a rectangle in grid coords; Godot converts to screen via the TileSet.
## Single source of truth for floor size: FLOOR_GRID_WIDTH × FLOOR_GRID_HEIGHT.

const FLOOR_GRID_WIDTH := 5
const FLOOR_GRID_HEIGHT := 5
const FLOOR_SOURCE_ID := 0
const FLOOR_ATLAS_COORDS := Vector2i(0, 0)

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_paint_floor()
	_center_camera_on_floor()
	var count := _count_floor_cells()
	print("[World] _ready: floor painted %dx%d, cells with tile: %d" % [FLOOR_GRID_WIDTH, FLOOR_GRID_HEIGHT, count])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb.global_position)


func _handle_click(viewport_pos: Vector2) -> void:
	# Viewport pos is screen coords; convert to world so local_to_map sees correct position.
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * viewport_pos
	var cell: Vector2i = floor_layer.local_to_map(world_pos)
	var has_tile: bool = floor_layer.get_cell_source_id(cell) != -1
	print("[World] click -> cell %s (has_floor=%s)" % [cell, has_tile])


func _paint_floor() -> void:
	for x in FLOOR_GRID_WIDTH:
		for y in FLOOR_GRID_HEIGHT:
			floor_layer.set_cell(Vector2i(x, y), FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)


func _center_camera_on_floor() -> void:
	var top_left: Vector2 = floor_layer.map_to_local(Vector2i(0, 0))
	var bottom_right: Vector2 = floor_layer.map_to_local(Vector2i(FLOOR_GRID_WIDTH - 1, FLOOR_GRID_HEIGHT - 1))
	camera.position = (top_left + bottom_right) / 2.0
	camera.make_current()


func _count_floor_cells() -> int:
	var n := 0
	for x in FLOOR_GRID_WIDTH:
		for y in FLOOR_GRID_HEIGHT:
			if floor_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				n += 1
	return n
