extends Node2D
## World root: FloorLayer (TileMapLayer) + NavigationRegion2D.
##
## Map space only. We paint a rectangle in grid coords; Godot converts to screen via the TileSet.
## Single source of truth for floor size: FLOOR_GRID_WIDTH × FLOOR_GRID_HEIGHT.
## AStarGrid2D provides the Fallout-style movement brain (1 tile = 1 AP).

const FLOOR_GRID_WIDTH := 25
const FLOOR_GRID_HEIGHT := 25
const FLOOR_SOURCE_ID := 0
const FLOOR_ATLAS_COORDS := Vector2i(0, 0)
const BLOCKED_CELLS := [Vector2i(2, 2)]  # logical tiles that are not walkable (obstacles)

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var camera: Camera2D = $Camera2D
@onready var player: Node2D = $Player
@onready var player_sprite: Sprite2D = $Player/Sprite2D
@onready var destination_marker: Sprite2D = Sprite2D.new()

var astar: AStarGrid2D
var player_cell: Vector2i = Vector2i(0, 0)  # logical tile where the player currently stands
var path_cells: Array[Vector2i] = []
var move_speed: float = 300.0  # pixels per second, snappy for testing
var is_moving: bool = false
var current_target_world: Vector2 = Vector2.ZERO
var camera_deadzone_margin: Vector2 = Vector2(64, 64)  # how far player can move from center before snap


func _ready() -> void:
	_paint_floor()
	_center_camera_on_floor()
	_init_astar()
	_position_player_on_grid()
	_init_destination_marker()
	_spawn_obstacles()
	var count := _count_floor_cells()
	print("[World] _ready: floor painted %dx%d, cells with tile: %d" % [FLOOR_GRID_WIDTH, FLOOR_GRID_HEIGHT, count])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_click(mb.global_position)


func _physics_process(delta: float) -> void:
	_update_player_movement(delta)
	_update_camera_snap()


func _update_player_movement(delta: float) -> void:
	if not is_moving:
		return

	var to_target: Vector2 = current_target_world - player.position
	var dist: float = to_target.length()
	if dist < 1.0:
		# Snap to target and advance to next cell.
		player.position = current_target_world
		if path_cells.is_empty():
			is_moving = false
			destination_marker.visible = false
			return
		_set_next_path_target()
		return

	# Flip player horizontally based on movement direction (left/right on screen).
	if to_target.x != 0.0:
		var facing_right: bool = to_target.x > 0.0
		player_sprite.flip_h = facing_right

	var step: float = move_speed * delta
	if step > dist:
		step = dist
	player.position += to_target.normalized() * step


func _update_camera_snap() -> void:
	# Snap-follow: only recenter camera when player walks off screen (beyond a deadzone).
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_size: Vector2 = viewport_size * 0.5

	# Player position in camera-local coordinates.
	var player_cam_local: Vector2 = camera.to_local(player.global_position)

	var exceeded_x: bool = abs(player_cam_local.x) > (half_size.x - camera_deadzone_margin.x)
	var exceeded_y: bool = abs(player_cam_local.y) > (half_size.y - camera_deadzone_margin.y)

	if exceeded_x or exceeded_y:
		# Snap camera so player returns to center of the view.
		camera.global_position = player.global_position


func _handle_click(viewport_pos: Vector2) -> void:
	# 1) viewport (screen) -> world (canvas)
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * viewport_pos
	# 2) world -> FloorLayer local
	var local_pos: Vector2 = floor_layer.to_local(world_pos)
	# 3) local -> map (grid) coords
	var cell: Vector2i = floor_layer.local_to_map(local_pos)

	var has_tile: bool = floor_layer.get_cell_source_id(cell) != -1
	print("[World] click -> cell %s (has_floor=%s)" % [cell, has_tile])

	if not has_tile:
		return

	_update_destination_marker(cell)

	# Ask the A* brain for a path from the player's current tile to the clicked tile.
	var path: PackedVector2Array = astar.get_point_path(player_cell, cell)
	print("[World] path from %s to %s has %d steps" % [player_cell, cell, path.size()])

	# Convert path points (Vector2) to grid cells (Vector2i) and skip the first point (current cell).
	path_cells.clear()
	for i in range(1, path.size()):
		var p: Vector2 = path[i]
		path_cells.append(Vector2i(round(p.x), round(p.y)))

	if path_cells.is_empty():
		return

	# Begin walking along the path, one tile at a time.
	is_moving = true
	_set_next_path_target()


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


func _position_player_on_grid() -> void:
	# Anchor the player at their feet on the starting tile (0,0).
	player_cell = Vector2i(0, 0)
	player.position = floor_layer.map_to_local(player_cell)


func _init_astar() -> void:
	astar = AStarGrid2D.new()
	astar.size = Vector2i(FLOOR_GRID_WIDTH, FLOOR_GRID_HEIGHT)
	astar.cell_size = Vector2(1, 1)
	astar.offset = Vector2(0, 0)  # logical (0,0) is top-left tile

	# Cardinal movement only: no diagonals (Fallout-style 4-direction grid).
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

	astar.update()

	# Fill walkability from the TileMapLayer.
	for x in FLOOR_GRID_WIDTH:
		for y in FLOOR_GRID_HEIGHT:
			var cell := Vector2i(x, y)
			var has_tile := floor_layer.get_cell_source_id(cell) != -1
			astar.set_point_solid(cell, not has_tile)

	# Apply additional blocked cells (obstacles), even if a floor tile exists.
	for blocked in BLOCKED_CELLS:
		# Manual in-bounds check for AStarGrid2D grid coords.
		if blocked.x < 0 or blocked.x >= FLOOR_GRID_WIDTH:
			continue
		if blocked.y < 0 or blocked.y >= FLOOR_GRID_HEIGHT:
			continue
		astar.set_point_solid(blocked, true)


func _set_next_path_target() -> void:
	if path_cells.is_empty():
		is_moving = false
		destination_marker.visible = false
		return

	var next_cell: Vector2i = path_cells.pop_front()
	player_cell = next_cell
	current_target_world = floor_layer.map_to_local(next_cell)


func _init_destination_marker() -> void:
	# Use the same floor texture as an overlay, tinted to "glow" the tile.
	destination_marker.texture = load("res://assets/tiles/placeholder_floor.svg")
	destination_marker.scale = Vector2(1, 1)
	destination_marker.modulate = Color(1, 1, 0, 0.5)  # semi-transparent yellow glow
	destination_marker.visible = false
	add_child(destination_marker)


func _update_destination_marker(target_cell: Vector2i) -> void:
	destination_marker.position = floor_layer.map_to_local(target_cell)
	destination_marker.visible = true


func _spawn_obstacles() -> void:
	# Simple visual obstacles on blocked tiles so path detours are obvious.
	for cell in BLOCKED_CELLS:
		if not floor_layer.get_cell_source_id(cell) != -1:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load("res://icon.svg")
		sprite.scale = Vector2(0.4, 0.4)
		sprite.modulate = Color(1, 0, 0)  # tint red so blocked tiles stand out
		sprite.position = floor_layer.map_to_local(cell) + Vector2(0, -16)  # lift so "feet" sit on tile
		add_child(sprite)
