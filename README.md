# Football Survivation

[![Godot validation](https://github.com/bulmaspanties/Football-Survivation/actions/workflows/godot-check.yml/badge.svg)](https://github.com/bulmaspanties/Football-Survivation/actions/workflows/godot-check.yml)

Football Survivation is a Godot 4 project foundation for a top-down survival game.

## Project status

The current foundation provides a playable arena, a reusable player scene, an automatic football weapon, and a structured five-minute survival run. The current enemy roster is Defender, fast Runner, ranged Thrower, durable Blocker, and support Coach. Throwers maintain distance and launch slow footballs at the player; Blockers push the player on contact; Coaches maintain distance and periodically buff nearby enemies inside a visible support radius. All roles share the same enemy health, damage, XP, hit-flash, and death-burst behavior, while pressure gradually introduces the tactical roles. Collected XP raises the player's level and pauses the game for an upgrade choice. Reach the five-minute target for victory; player health reaching zero remains a distinct game-over state.

## Open and run

1. Install [Godot 4](https://godotengine.org/download/).
2. Import this repository in the Godot Project Manager, or open the repository folder from Godot.
3. Press **F6** to run the current scene or **F5** to run the project. The project starts in `scenes/Main.tscn`.

The project opens on a built-in title screen with a Start Run button and a short controls/objective guide. After starting, the scene is a football-field arena with green turf, end zones, yard lines, midfield markings, a bright boundary, a player character, and a following camera. It uses only built-in Godot nodes, drawing primitives, and shapes, so no asset setup is required. Players, opponents, pickups, and footballs use distinct placeholder colors and silhouettes; enemy hits flash and defeated enemies emit a brief burst.

## Validation

The repository runs a pinned Godot 4.3 headless import/parser check on every push and pull request through [`.github/workflows/godot-check.yml`](.github/workflows/godot-check.yml). To run the same check locally, install Godot 4.3 and execute:

```sh
godot --headless --editor --path . --quit
```

The command should exit successfully only when the project and its scripts/scenes import without parser or load errors.

## Project structure

- `project.godot`: project settings and input actions
- `scenes/Main.tscn`: project entry scene and bounded arena
- `scenes/Player.tscn`: reusable player scene
- `scenes/Enemy.tscn`: reusable pursuing enemy scene
- `scenes/Runner.tscn`: fast/light enemy archetype using the shared enemy script
- `scenes/Thrower.tscn`: preferred-distance ranged enemy role
- `scenes/Blocker.tscn`: durable space-control enemy role
- `scenes/Coach.tscn`: support enemy role with a bounded buff radius
- `scenes/EnemyFootball.tscn`: enemy-only projectile scene
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
- **Escape / P**: pause or resume during an active run

Movement supports all eight directions and is normalized so diagonal movement is not faster.

The pause menu provides Resume, Restart Run, Return to Title, and Settings controls. Settings include a session-persistent master volume slider, mute toggle, fullscreen/windowed toggle, and reset button. Settings remain active while navigating or restarting within the current Godot session.

Defenders appear around the arena perimeter and damage the player on contact. Fast runners begin joining the waves as survival pressure rises; they move faster but have lower health and contact damage. Player health is displayed in the top-left HUD; the game-over panel appears when health reaches zero.

Throwers maintain a preferred distance and periodically launch enemy footballs; Blockers are larger and push the player away on contact; Coaches periodically refresh bounded speed/contact-damage buffs on nearby enemies and remove their buffs when defeated. Enemy projectiles only damage the player, never enemies or player-owned weapons. Referee roles are not implemented yet.

The player automatically throws footballs at nearby enemies. Level-ups can unlock three additional weapons: **Tackle Burst** damages all nearby enemies with a close-range radius flash, **Hail Mary** launches a slow high-impact long-range shot, and **Stiff Arm** sweeps a short melee arc. Each weapon has its own cooldown and damage upgrades, and each unlock can only be selected once. No additional input is required; projectiles disappear after hitting an enemy or reaching their lifetime.

Enemies drop green experience pickups. Collect enough to level up, then choose one of three upgrades while gameplay is paused: football damage, attack cooldown, projectile speed, max health, or movement speed.

Each run displays elapsed survival time and escalates enemy pressure after the opening period. Victory and game over both offer a restart button.

Starting or restarting a run creates a fresh player progression state and clears all active gameplay nodes before the timer begins.

## Development notes

This project currently uses Godot's Compatibility renderer and built-in placeholder visuals only. Keep reusable gameplay objects in `scenes/` with their behavior in `scripts/` as new systems are introduced.
