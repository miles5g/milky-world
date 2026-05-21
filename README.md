# Isometric Grid Prototype

Early-phase **2D isometric, Fallout-style grid** prototype — click-to-move with A* pathfinding on a painted tile floor. Foundation for a tile-based tactics or exploration game.

## Highlights

- **25×25 procedural floor** painted from shared constants (single source of truth for tiles)
- **Cardinal A* pathfinding** on a `TileMapLayer` with blocked cells
- **Click-to-move** with hover and destination markers
- **Snap-follow camera** with deadzone so the view stays readable while the player moves

## Stack

- Godot **4.6** (Forward+), GDScript, `AStarGrid2D`
- Addons: [AStar2D grid node](https://github.com/Firemanarg/godot-astar-2d-grid-node), [Tilemap Merger](https://github.com/airreader/tilemap-merger)
- Jolt Physics (project setting; gameplay is 2D)

## Run locally

1. Install [Godot 4.6](https://godotengine.org/download).
2. Open this folder in Godot.
3. Open `scenes/world.tscn` and press **F6** (Play Scene).

Enable editor plugins under **Project → Project Settings → Plugins** if you use the addon examples.

## Controls

| Input | Action |
|-------|--------|
| **Left-click** | Move to tile (pathfinds on grid) |
| **Mouse hover** | Highlight tile under cursor |

## Status

Active prototype — grid, pathfinding, and camera are in place; content and mechanics still expanding.

## Author

Miles Johnson — [@miles5g](https://github.com/miles5g)

## License

MIT
