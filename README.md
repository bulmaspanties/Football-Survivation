# Football Survivation

Football Survivation is a Godot 4 project foundation for a top-down survival game.

## Project status

The current foundation provides a playable arena, a reusable player scene, an automatic football weapon, and a structured five-minute survival run. Enemies spawn around the arena perimeter, pursue the player, deal contact damage, drop collectible experience, and become more numerous and dangerous over time. Collected XP raises the player's level and pauses the game for an upgrade choice. Footballs automatically target nearby enemies and deal damage on impact. Reach the five-minute target for victory; player health reaching zero remains a distinct game-over state.

## Open and run

1. Install [Godot 4](https://godotengine.org/download/).
2. Import this repository in the Godot Project Manager, or open the repository folder from Godot.
3. Press **F6** to run the current scene or **F5** to run the project. The project starts in `scenes/Main.tscn`.

The current scene is a football-field arena with green turf, end zones, yard lines, midfield markings, a bright boundary, a player character, and a following camera. It uses only built-in Godot nodes, drawing primitives, and shapes, so no asset setup is required. Players, opponents, pickups, and footballs use distinct placeholder colors and silhouettes; enemy hits flash and defeated enemies emit a brief burst.

## Project structure

- `project.godot`: project settings and input actions
- `scenes/Main.tscn`: project entry scene and bounded arena
- `scenes/Player.tscn`: reusable player scene
- `scenes/Enemy.tscn`: reusable pursuing enemy scene
- `scenes/Football.tscn`: reusable football projectile scene
- `scenes/ExperiencePickup.tscn`: reusable collectible XP scene
- `scripts/player.gd`: player movement behavior
- `scripts/enemy.gd`: enemy pursuit, health, and contact damage
- `scripts/enemy_spawner.gd`: controlled perimeter spawning
- `scripts/football.gd`: projectile movement, collision, and damage
- `scripts/auto_weapon.gd`: automatic nearby-enemy targeting and firing
- `scripts/experience_pickup.gd`: XP pickup collection
- `scripts/main.gd`: HUD and game-over wiring

## Controls

- **W / Up Arrow**: move up
- **S / Down Arrow**: move down
- **A / Left Arrow**: move left
- **D / Right Arrow**: move right

Movement supports all eight directions and is normalized so diagonal movement is not faster.

Enemies appear around the arena perimeter and damage the player on contact. Player health is displayed in the top-left HUD; the game-over panel appears when health reaches zero.

The player automatically throws footballs at nearby enemies. No additional input is required; footballs disappear after hitting an enemy or reaching their lifetime.

Enemies drop green experience pickups. Collect enough to level up, then choose one of three upgrades while gameplay is paused: football damage, attack cooldown, projectile speed, max health, or movement speed.

Each run displays elapsed survival time and escalates enemy pressure after the opening period. Victory and game over both offer a restart button.

## Development notes

This project currently uses Godot's Compatibility renderer and built-in placeholder visuals only. Keep reusable gameplay objects in `scenes/` with their behavior in `scripts/` as new systems are introduced.
