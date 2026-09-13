# Football Survivation

[![Godot validation](https://github.com/bulmaspanties/Football-Survivation/actions/workflows/godot-check.yml/badge.svg)](https://github.com/bulmaspanties/Football-Survivation/actions/workflows/godot-check.yml)

Football Survivation is a Godot 4 project foundation for a top-down survival game.

## Project status

The current foundation provides a playable arena, a reusable player scene, an automatic football weapon, and a structured five-minute survival run. The current enemy roster is Defender, fast Runner, ranged Thrower, durable Blocker, and support Coach. Throwers maintain distance and launch slow footballs at the player; Blockers push the player on contact; Coaches maintain distance and periodically buff nearby enemies inside a visible support radius. All roles share the same enemy health, damage, XP, hit-flash, and death-burst behavior, while pressure gradually introduces the tactical roles. Collected XP raises the player's level and pauses the game for an upgrade choice. Reach the five-minute target for victory; player health reaching zero remains a distinct game-over state.

## Open and run

1. Install [Godot 4](https://godotengine.org/download/).
2. Import this repository in the Godot Project Manager, or open the repository folder from Godot.
3. Press **F6** to run the current scene or **F5** to run the project. The project starts in `scenes/Main.tscn`.

The project opens on a built-in kickoff screen with franchise selection and a short controls/objective guide. After starting, the scene is a football-field arena with green turf, end zones, yard lines, midfield markings, goalposts, sideline accents, lightweight crowd silhouettes, a scoreboard-style HUD, a player character, and a following camera. It uses only built-in Godot nodes, drawing primitives, and shapes, so no asset setup is required. Players, opponents, pickups, and footballs use distinct placeholder colors and silhouettes; enemy hits flash and defeated enemies emit a brief burst.

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
- `scenes/Boss.tscn`: reusable halftime Elite enemy
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

Controller support uses the left stick for movement, with the same 0.2 deadzone and normalized eight-direction movement. The controller Menu/Start button pauses or resumes an active run; A/Cross accepts focused controls and B/Circle cancels or backs out. Standard menu navigation uses the directional pad/stick; Enter/Space remain keyboard activation, and focus begins on the first available action for each title, profile, front-office, pause/settings, level-up, victory, and game-over overlay. The active field shows a compact controls hint briefly at kickoff and the start of each run, then fades so it does not cover the HUD.

The pause menu provides Resume, Restart Run, Return to Title, Profile Selection, and Settings controls. Escape/P only pauses an active run; level-up, title, victory, and game-over overlays keep their existing behavior. Settings include a session-persistent master volume slider, mute toggle, fullscreen/windowed toggle, and reset button. Settings remain active while navigating or restarting within the current Godot session.

## Audio

All sound effects are procedurally generated at runtime by an `AudioManager` autoload (`scripts/audio_manager.gd`) using built-in `AudioStreamWAV`/`AudioStreamPlayer` — no external audio files or dependencies. Each cue is a short synthesized tone, sweep, or noise burst defined in one central table, cached after first use, and played through the `Master` audio bus, so the Settings volume slider and mute toggle apply automatically. A small player pool keeps effects from stacking indefinitely. Because every call site only requests a named cue (for example `AudioManager.play_cue("football_throw")`), the generated tones could later be swapped for real audio assets without changing any gameplay code.

Distinct cues cover: football throw, Tackle Burst, Hail Mary, Stiff Arm, enemy hit, enemy defeat, halftime Elite defeat, XP pickup, level-up, wave phase change banner, halftime warning, player damage, touchdown victory, turnover game-over, and menu navigate/confirm. Gameplay cues are skipped while the game is paused; menu navigation/confirmation and the victory/game-over stingers still play so pause and end-of-run screens remain responsive.

Before a run, choose one of exactly three profile slots. Empty slots create a profile; occupied slots show created/last-played metadata and permanent currency/unlock placeholders. Profiles are stored as JSON at Godot's `user://football_survivation_profiles.json` location. Only profile metadata is saved: active run state, XP, upgrades, enemies, pickups, projectiles, and timer are always reset for a new run. Switching profiles never overwrites another slot.

Runs award permanent currency once at the end: victory grants 100 coins; game over grants 10 coins plus 1 per 30 seconds survived, capped at 50 (Pro Difficulty adds a further +50% bonus). The end overlay shows the reward and new total. From profile selection, open Front Office Upgrades to buy permanent upgrades and toggle a difficulty modifier:

- Goal Line Body: +20 starting max health — 50 coins
- Combine Speed: +30 starting movement speed — 50 coins
- Passing Game: +8 starting football damage — 75 coins
- Two-Way Signing: start with Tackle Burst already unlocked — 100 coins
- Deep Threat Scout: start with Hail Mary already unlocked — 120 coins
- Extra Muscle: +10 starting Tackle Burst and Stiff Arm damage — 70 coins
- Film Study: +15% XP gained for the whole run — 90 coins
- Pro Difficulty (toggle, free): tougher enemies via a higher pressure curve, in exchange for a +50% end-of-run coin reward. Toggling does not cost currency and can be switched off again at any time from Front Office.

Purchases are one-time (owned upgrades are marked and cannot be re-bought), reject insufficient funds, and — along with the Pro Difficulty toggle — only take effect starting with the next run; they never alter an active run mid-session. Weapons purchased as starting unlocks no longer need to be found via in-run level-ups, but the level-up unlock options remain available as a fallback for any weapon not already purchased, with no duplicate unlocks possible either way.

Defenders appear around the arena perimeter and damage the player on contact. Fast runners begin joining the waves as survival pressure rises; they move faster but have lower health and contact damage. Player health is displayed in the top-left HUD; the game-over panel appears when health reaches zero.

Throwers maintain a preferred distance and periodically launch enemy footballs; Blockers are larger and push the player away on contact; Coaches periodically refresh bounded speed/contact-damage buffs on nearby enemies and remove their buffs when defeated. Enemy projectiles only damage the player, never enemies or player-owned weapons. Referee roles are not implemented yet.

The player automatically throws footballs at nearby enemies. Level-ups can unlock three additional weapons: **Tackle Burst** damages all nearby enemies with a close-range radius flash, **Hail Mary** launches a slow high-impact long-range shot, and **Stiff Arm** sweeps a short melee arc. Each weapon has its own cooldown and damage upgrades, and each unlock can only be selected once. No additional input is required; projectiles disappear after hitting an enemy or reaching their lifetime.

During a run, the compact loadout HUD lists Football, Tackle Burst, Hail Mary, and Stiff Arm with locked/ready state plus live damage and cooldown values. Level-up cards identify **WEAPON UNLOCK**, **WEAPON UPGRADE**, or **PLAYER STAT** choices and show current and resulting values where applicable. Already-owned unlocks are removed from the choice pool, and the loadout resets with each new run.

Enemies drop green experience pickups. Collect enough to level up, then call one of three football-themed upgrades while gameplay is paused: Power Run, Quick Snap, Long Bomb, Goal Line Stand, Open Field Sprint, or weapon-specific drills.

Each run displays elapsed survival time and escalates enemy pressure after the opening period. Victory and game over both offer a restart button.

The five-minute drive is paced by named wave phases: Kickoff (0:00-0:45), First Quarter (0:45-1:45), Second Quarter (1:45-2:30), Halftime Drive (2:30-3:30), Final Drive (3:30-4:30), and Red Zone (4:30-5:00). Each phase has its own role mix, spawn interval, and enemy cap; a banner announces phase changes. The one-time Elite still arrives at 2:30, and the director pauses safely with gameplay.

Player damage briefly flashes the QB, nearby enemy attacks show short warning rings, and weapon hits create floating impact numbers. End-of-run panels include drive time, enemies defeated, XP collected, and total impact events in addition to the existing profile reward; these stats reset every kickoff and do not change currency rewards.

At 2:30, a one-time halftime event announces and spawns an Elite outside the field boundary while normal spawns continue under their cap. The Elite is larger, slower, much tougher, deals bounded contact damage, and drops 25 XP. Defeating it grants the selected profile a one-time 50-coin bonus and updates the scoreboard-style HUD; the bonus cannot repeat from duplicate damage or terminal transitions. The run uses football terminology throughout: kickoff, drive clock, downs, halftime huddle, turnover, touchdown, and front-office upgrades.

Starting or restarting a run creates a fresh player progression state and clears all active gameplay nodes before the timer begins.

## Development notes

This project currently uses Godot's Compatibility renderer and built-in placeholder visuals only. Keep reusable gameplay objects in `scenes/` with their behavior in `scripts/` as new systems are introduced.
