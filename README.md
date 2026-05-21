# Milky World

Early-phase **2D isometric grid prototype** (Fallout-style click-to-move) built in Godot 4 — foundation for a tile-based world with A* pathfinding and camera follow.

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

Keyboard movement is planned; current build is click-only.

## Project layout

```
milky-world/
├── scenes/world.tscn      # Main scene
├── scripts/               # Player, pathfinding, camera
├── addons/                # A* grid + tilemap tools
└── project.godot
```

## Status

Active prototype — grid, pathfinding, and camera are in place; content and mechanics are still expanding.

## License

MIT (see repository license if present).
