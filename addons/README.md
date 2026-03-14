# Godot addons

These addons are installed for the Milky World (isometric point-and-click) project.

## How to enable

1. Open the project in Godot 4.x.
2. Go to **Project → Project Settings → Plugins**.
3. Check **Enable** for each addon you want to use.

---

## AStar2DGridNode (`astar2d_grid_node`)

- **Source:** [Firemanarg/godot-astar-2d-grid-node](https://github.com/Firemanarg/godot-astar-2d-grid-node)
- **Use:** A `Node2D` that wraps Godot’s `AStar2D` for grid-based pathfinding. Useful for isometric/top-down grid movement and pathfinding (Phase 1).
- **Contains:** Example scenes under `examples/` (simple movement, obstacles) you can open for reference.

---

## Tilemap Merger (`tilemap_merger`)

- **Source:** [airreader/tilemap-merger](https://github.com/airreader/tilemap-merger)
- **Use:** Editor tool to merge multiple TileMaps into one and edit the result. Handy when building or cleaning up isometric tile layers.

---

## Other useful resources (not in this folder)

- **Godot Asset Library** (in editor: **Project → Asset Library**): Search for “isometric”, “grid”, “pathfinding”, or “2D RPG” for more addons and demos.
- **Official AStarGrid2D demo:** [godot-demo-projects/2d/navigation_astar](https://github.com/godotengine/godot-demo-projects/tree/master/2d/navigation_astar) — reference for grid pathfinding and steering.
