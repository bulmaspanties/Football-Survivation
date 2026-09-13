# Football Survivation

Football Survivation is a Godot 4 project foundation for a top-down survival game.

## Project status

The current foundation provides a playable arena, a reusable player scene, an automatic football weapon, and the first enemy loop: enemies spawn around the arena perimeter, pursue the player, and deal contact damage. Footballs automatically target nearby enemies and deal damage on impact. Player health is shown in the HUD and reaching zero displays a game-over state. Future gameplay can build on this structure with additional weapons and experience without changing the project entry point.

## Open and run

1. Install [Godot 4](https://godotengine.org/download/).
2. Import this repository in the Godot Project Manager, or open the repository folder from Godot.
3. Press **F6** to run the current scene or **F5** to run the project. The project starts in `scenes/Main.tscn`.

The current scene is a bounded placeholder arena with a player character and a following camera. It uses only built-in Godot nodes and shapes, so no asset setup is required.

## Project structure

- `project.godot`: project settings and input actions
- `scenes/Main.tscn`: project entry scene and bounded arena
- `scenes/Player.tscn`: reusable player scene
- `scenes/Enemy.tscn`: reusable pursuing enemy scene
- `scenes/Football.tscn`: reusable football projectile scene
- `scripts/player.gd`: player movement behavior
- `scripts/enemy.gd`: enemy pursuit, health, and contact damage
- `scripts/enemy_spawner.gd`: controlled perimeter spawning
- `scripts/football.gd`: projectile movement, collision, and damage
- `scripts/auto_weapon.gd`: automatic nearby-enemy targeting and firing
- `scripts/main.gd`: HUD and game-over wiring

## Controls

- **W / Up Arrow**: move up
- **S / Down Arrow**: move down
- **A / Left Arrow**: move left
- **D / Right Arrow**: move right

Movement supports all eight directions and is normalized so diagonal movement is not faster.

Enemies appear around the arena perimeter and damage the player on contact. Player health is displayed in the top-left HUD; the game-over panel appears when health reaches zero.

The player automatically throws footballs at nearby enemies. No additional input is required; footballs disappear after hitting an enemy or reaching their lifetime.

## Development notes

This project currently uses Godot's Compatibility renderer and built-in placeholder visuals only. Keep reusable gameplay objects in `scenes/` with their behavior in `scripts/` as new systems are introduced.
