extends Node2D
## World root: holds FloorLayer (TileMapLayer) and NavigationRegion2D.
## Paints the initial floor grid at runtime (single source of truth for floor size).
##
## Isometric layout (floor_tileset.tres): tile_layout = 4 (DIAMOND_RIGHT), tile_offset_axis = 0 (horizontal).
## We fill a rectangle in grid space (0,0)-(FLOOR_GRID_WIDTH-1, FLOOR_GRID_HEIGHT-1). In DIAMOND_RIGHT
## that maps to one contiguous diamond on screen. If you change to DIAMOND_DOWN (5) or tile_offset_axis = 1,
## run the game and confirm the floor is still one contiguous block; if checkerboard returns, the layout
## may expect a different placement pattern (e.g. half-offset indexing) and tile placement logic must match.
##
## Seamless edges: If tiles don't "bleed" together (visible seams at quadrant boundaries), check
## FloorLayer.rendering_quadrant_size (default 16). Setting it to 1 removes quadrant-boundary artifacts
## but hurts performance. Also ensure TileSet.uv_clipping is false and use_texture_padding is false.
##
## Half-height/half-width: Godot has no separate "Vertical Offset" or "Horizontal Offset" for isometric.
## Row/column stagger (half-tile nestling) comes from tile_layout (DIAMOND_RIGHT) and tile_offset_axis;
## the step is derived from tile_size (half = tile_size/2). texture_origin should be bottom-center
## (tile_size.x/2, tile_size.y) so the diamond's bottom sits on the cell and rows nestle.

const FLOOR_GRID_WIDTH := 5
const FLOOR_GRID_HEIGHT := 5
const FLOOR_SOURCE_ID := 0
const FLOOR_ATLAS_COORDS := Vector2i(0, 0)

@onready var floor_layer: TileMapLayer = $FloorLayer


func _ready() -> void:
	_log_cell_texture_parity()
	_log_tile_origin()
	_log_rendering_quadrant()
	_paint_floor()
	var count := _count_floor_cells()
	print("[World] _ready: floor painted %dx%d, cells with tile: %d (expected %d)" % [FLOOR_GRID_WIDTH, FLOOR_GRID_HEIGHT, count, FLOOR_GRID_WIDTH * FLOOR_GRID_HEIGHT])


func _log_cell_texture_parity() -> void:
	var ts: TileSet = floor_layer.tile_set
	if ts == null:
		return
	var cell_size: Vector2i = ts.tile_size
	var src := ts.get_source(FLOOR_SOURCE_ID) as TileSetAtlasSource
	if src == null:
		return
	var region_size: Vector2i = src.texture_region_size
	var tex := src.texture
	var tex_size := Vector2i(tex.get_width(), tex.get_height()) if tex else Vector2i.ZERO
	var ok := (cell_size == region_size and (tex_size == Vector2i.ZERO or tex_size == region_size))
	print("[World] cell-texture parity: tile_size=%s texture_region_size=%s texture_size=%s match=%s" % [cell_size, region_size, tex_size, ok])
	_log_aspect_ratio(cell_size, region_size, tex_size)


func _log_aspect_ratio(cell_size: Vector2i, region_size: Vector2i, tex_size: Vector2i) -> void:
	const EXPECTED_ISO_RATIO := 2.0
	if cell_size.y == 0:
		return
	var cell_ratio: float = float(cell_size.x) / float(cell_size.y)
	var region_ratio: float = float(region_size.x) / float(region_size.y) if region_size.y != 0 else 0.0
	var tex_ratio: float = float(tex_size.x) / float(tex_size.y) if tex_size.y != 0 else 0.0
	var cell_ok: bool = abs(cell_ratio - EXPECTED_ISO_RATIO) < 0.01
	var region_ok: bool = abs(region_ratio - EXPECTED_ISO_RATIO) < 0.01
	var tex_ok: bool = tex_size == Vector2i.ZERO or abs(tex_ratio - EXPECTED_ISO_RATIO) < 0.01
	print("[World] diamond vs square: tile_size ratio=%.2f (2:1=%.2f) texture_region ratio=%.2f texture ratio=%.2f cell_2:1=%s region_2:1=%s tex_2:1=%s" % [cell_ratio, EXPECTED_ISO_RATIO, region_ratio, tex_ratio, cell_ok, region_ok, tex_ok])
	if not (cell_ok and region_ok and tex_ok):
		print("[World] WARNING: Isometric expects 2:1 aspect (e.g. 64x32). If ratio is 1:1 (square), grid treats tiles as square and you get staircase effect. Fix tile_size and texture_region_size to 2:1.")


func _log_tile_origin() -> void:
	var ts: TileSet = floor_layer.tile_set
	if ts == null:
		return
	var src := ts.get_source(FLOOR_SOURCE_ID) as TileSetAtlasSource
	if src == null or not src.has_alternative_tile(FLOOR_ATLAS_COORDS, 0):
		return
	var tile_data: TileData = src.get_tile_data(FLOOR_ATLAS_COORDS, 0)
	if tile_data == null:
		return
	var origin: Vector2i = tile_data.texture_origin
	var cell_size: Vector2i = ts.tile_size
	var expected_center := cell_size / 2
	var expected_bottom_center := Vector2i(cell_size.x / 2, cell_size.y)
	var is_corner := (origin == Vector2i.ZERO)
	var is_center := (origin == expected_center)
	var is_bottom_center := (origin == expected_bottom_center)
	print("[World] tile origin: texture_origin=%s tile_size=%s half_step=%s (for nestling) corner=%s center=%s bottom_center=%s" % [origin, cell_size, cell_size / 2, is_corner, is_center, is_bottom_center])
	if is_corner:
		print("[World] WARNING: tile origin is top-left (0,0). For isometric nestling use bottom-center (%s) or center (%s)." % [expected_bottom_center, expected_center])


func _log_rendering_quadrant() -> void:
	var rq: int = floor_layer.rendering_quadrant_size
	var pq: int = floor_layer.physics_quadrant_size
	var ts: TileSet = floor_layer.tile_set
	var uv_clip: bool = ts.uv_clipping if ts else false
	print("[World] rendering: rendering_quadrant_size=%d physics_quadrant_size=%d TileSet.uv_clipping=%s" % [rq, pq, uv_clip])
	if rq > 1:
		print("[World] tip: If you see seams between tiles, try FloorLayer.rendering_quadrant_size=1 (costs performance).")


func _paint_floor() -> void:
	for x in FLOOR_GRID_WIDTH:
		for y in FLOOR_GRID_HEIGHT:
			floor_layer.set_cell(Vector2i(x, y), FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS, 0)


func _count_floor_cells() -> int:
	var n := 0
	for x in FLOOR_GRID_WIDTH:
		for y in FLOOR_GRID_HEIGHT:
			if floor_layer.get_cell_source_id(Vector2i(x, y)) != -1:
				n += 1
	return n
