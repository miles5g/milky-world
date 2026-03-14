extends Node2D
## World root: FloorLayer (TileMapLayer) + NavigationRegion2D.
##
## Reset: map space only. We place exactly two tiles using TileMapLayer's native
## coordinate system — no pixel or tile_size math. If (0,0) and (1,0) interlock
## in the editor, the TileSet/layout is correct and we can bring back the grid loop.
##
## In the editor: TileSet must have Tile Shape = Isometric (diamond). Check
## assets/tiles/floor_tileset.tres — tile_shape = 1.

const FLOOR_SOURCE_ID := 0
const FLOOR_ATLAS_COORDS := Vector2i(0, 0)

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_paint_diamond_test()
	_center_camera_on_tiles()
	_log_map_positions()


func _paint_diamond_test() -> void:
	# Map space only. Godot converts these to screen position using the TileSet.
	floor_layer.set_cell(Vector2i(0, 0), FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)
	floor_layer.set_cell(Vector2i(1, 0), FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)


func _center_camera_on_tiles() -> void:
	# Center view on (0,0) and (1,0) so both tiles are on-screen (isometric (1,0) can be up/right of viewport).
	var pos_00: Vector2 = floor_layer.map_to_local(Vector2i(0, 0))
	var pos_10: Vector2 = floor_layer.map_to_local(Vector2i(1, 0))
	camera.position = (pos_00 + pos_10) / 2.0
	camera.make_current()


func _log_map_positions() -> void:
	var pos_00: Vector2 = floor_layer.map_to_local(Vector2i(0, 0))
	var pos_10: Vector2 = floor_layer.map_to_local(Vector2i(1, 0))
	print("[World] Diamond test: (0,0) local=%s  (1,0) local=%s  step=%s" % [pos_00, pos_10, pos_10 - pos_00])
