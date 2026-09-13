# Sprite Assets Directory Structure & Conventions

This directory holds sprite sheets for Football Survivation.
When real PNG sprite assets are dropped into these folders, they can be assigned directly to the `SpriteFrames` resource on each scene's `AnimatedSprite2D` node. When no sprite textures are present, each entity automatically falls back to its built-in procedural visual representation.

## Specifications & Requirements

- **File format**: PNG with transparent background (32-bit RGBA).
- **Frame size**: 48x48 pixels per frame (or 64x64 / 96x96 for Boss/Elite scaled accordingly).
- **Pixel art filtering**: Nearest-neighbor filtering (configured globally in `project.godot` via `rendering/textures/canvas_textures/default_texture_filter=0`).
- **Anchor point**: Origin / feet centered at `(24, 44)` for 48x48 frames (bottom-center aligned).
- **Animation states**:
  - `idle`: 4-6 frames, looped (5-6 FPS)
  - `run`: 6-8 frames, looped (8-12 FPS)
  - `hit`: 2-4 frames, non-looping (10-15 FPS)
  - `death`: 4-8 frames, non-looping (10-15 FPS)
- **Directional layout**:
  - 8-direction sprite sheets (Down, Down-Right, Right, Up-Right, Up, Up-Left, Left, Down-Left)
  - Or 5-direction sheets with horizontal flipping for left-facing angles.

## Folder Hierarchy

```
assets/sprites/
├── player/
│   ├── quarterback/       # 48x48 sheets: idle.png, run.png, hit.png, death.png
│   ├── running_back/      # 48x48 sheets: idle.png, run.png, hit.png, death.png
│   └── linebacker/        # 48x48 sheets: idle.png, run.png, hit.png, death.png
├── enemies/
│   ├── defender/          # 48x48 sheets: idle.png, run.png, hit.png, death.png
│   ├── runner/            # 48x48 sheets: idle.png, run.png, hit.png, death.png
│   ├── thrower/           # 48x48 sheets: idle.png, run.png, attack.png, hit.png, death.png
│   ├── blocker/           # 48x48 sheets: idle.png, run.png, hit.png, death.png
│   └── coach/             # 48x48 sheets: idle.png, run.png, buff.png, hit.png, death.png
├── boss/
│   └── elite/             # 64x64 or 96x96 sheets: idle.png, run.png, attack.png, hit.png, death.png
└── maps/
    ├── classic_field/     # Stadium decorations, goalpost overlays, turf tiles
    └── bluegrass_field/   # Stadium decorations, goalpost overlays, turf tiles
```
