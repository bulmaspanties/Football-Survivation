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

## Validation and continuous integration

The repository validates and builds the project via GitHub Actions:

- **Headless validation** ([`.github/workflows/godot-check.yml`](.github/workflows/godot-check.yml)): runs on every push and pull request, downloading the pinned Godot 4.3 binary and verifying that all scenes and scripts import and parse cleanly without errors.
- **Export and build pipeline** ([`.github/workflows/export-builds.yml`](.github/workflows/export-builds.yml)): runs on pushes to `main` and feature branches, tag releases (`v*`), or via manual workflow dispatch. It verifies the pinned Godot 4.3 editor and official export templates via SHA-256 checksums, imports the project, compiles release packages for **Linux x86_64** and **Windows Desktop (x86_64)**, and publishes them as downloadable workflow artifacts:
  - `football-survivation-linux-x86_64` (contains `football_survivation.x86_64` and `football_survivation.pck`)
  - `football-survivation-windows-x86_64` (contains `football_survivation.exe` and `football_survivation.pck`)

To download builds, navigate to the **Actions** tab on GitHub, select the latest **Godot export and build** run, and scroll to the **Artifacts** section.

### Local export instructions

To export desktop binaries locally using the Godot CLI:

1. Install Godot 4.3 and the official Godot 4.3 export templates (`Godot_v4.3-stable_export_templates.tpz`).
2. Run the export command for your target platform:

```sh
# Export Linux x86_64 binary
mkdir -p builds/linux
godot --headless --path . --export-release "Linux/X11" builds/linux/football_survivation.x86_64

# Export Windows Desktop (x86_64) binary
mkdir -p builds/windows
godot --headless --path . --export-release "Windows Desktop" builds/windows/football_survivation.exe
```

> **Note on Windows export from Linux:** The Windows preset has `application/modify_resources=false` configured to avoid requiring external PE resource modification tools (such as `rcedit` / `rcodesign`) when building Windows executables in headless Linux environments.

To run the static validation check locally:

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
- `scripts/arena.gd`: data-driven arena background, turf, sideline, goalpost, yard line, crowd, and end zone styling
- `scripts/main.gd`: HUD, overlay transitions, map/character wiring, and game-over logic

## Controls

- **W / Up Arrow**: move up (default, rebindable)
- **S / Down Arrow**: move down (default, rebindable)
- **A / Left Arrow**: move left (default, rebindable)
- **D / Right Arrow**: move right (default, rebindable)
- **Space / Controller RB (R1)**: activate character Audible ability (default, rebindable)
- **Escape / P**: pause or resume during an active run (default, rebindable)

### Key remapping

From the Settings & Accessibility menu (accessible from the title screen or the in-game pause menu), select any movement, audible, or pause action to bind a new keyboard key. The menu validates against conflicting keys (preventing the same key from being assigned to multiple actions) and invalid keys, allows canceling with Escape, and offers a dedicated "Reset Default Keys" button to restore standard bindings. Keybindings persist during the session in `SettingsManager` and preserve all controller inputs.

### Controller & rumble support

Controller support uses the left stick or D-pad for movement, with deadzone and normalized eight-direction movement preserved. The controller Menu/Start button pauses or resumes an active run; A/Cross accepts focused controls, B/Circle cancels or backs out, and RB (Right Bumper) triggers the character's Audible ability.

A controller vibration / rumble toggle in Settings controls tactile haptic feedback. When enabled, rumble is safely dispatched for:
- Player damage taken, turnover defeat, and referee whistle flags
- Weapon impacts (Football, Tackle Burst, Hail Mary, and Stiff Arm hits)
- Audible ability activation (Pocket Protection, Juke Move, Bull Rush)
- Halftime Elite arrival warning and defeat
- Touchdown victory celebration

The rumble helper is guarded so platforms or controllers without vibration support do not error.

## Settings & accessibility

Accessible from both the title screen ("Settings & Accessibility") and the sideline pause menu ("Settings"), the settings panel provides:

- **Master volume & mute**: slider (0% to 100%) and instant mute toggle routing through Godot's `Master` audio bus.
- **Display mode**: fullscreen and windowed toggle.
- **Controller vibration**: toggle for all gameplay rumble and haptic cues.
- **Colorblind palette**: toggle for a high-contrast, colorblind-friendly theme that recolors the player roles, all six enemy archetypes (including Referee), the penalty zone, halftime Elite, XP gems, enemy projectiles, telegraphs, and HUD labels without relying on red/green distinction alone.
- **Text size scaling**: Small, Normal, and Large font-size options that scale HUD labels, buttons, and all overlays cleanly without clipping or breaking the layout.
- **Keyboard remapping**: per-action key rebinds for movement, audible ability, and pause with live validation and reset.
- **Reset all settings**: restores audio, display, haptics, colorblind palette, text size, and keybindings to factory defaults.

Settings persist across runs and screens for the duration of the session and remain completely decoupled from profile save slots.

## Audio

All sound effects are procedurally generated at runtime by an `AudioManager` autoload (`scripts/audio_manager.gd`) using built-in `AudioStreamWAV`/`AudioStreamPlayer` — no external audio files or dependencies. Each cue is a short synthesized tone, sweep, or noise burst defined in one central table, cached after first use, and played through the `Master` audio bus, so the Settings volume slider and mute toggle apply automatically. A small player pool keeps effects from stacking indefinitely. Because every call site only requests a named cue (for example `AudioManager.play_cue("football_throw")`), the generated tones could later be swapped for real audio assets without changing any gameplay code.

Distinct cues cover: football throw, Tackle Burst, Hail Mary, Stiff Arm, enemy hit, enemy defeat, referee penalty flag whistle, QB Pocket Protection shockwave, RB Juke dash, LB Bull Rush charge, Turf Hazard start/end alerts, halftime Elite warning/defeat, XP pickup, Playbook level-up, wave phase change banner, player damage, touchdown victory, turnover game-over, and menu navigate/confirm. Gameplay cues are skipped while the game is paused; menu navigation/confirmation and the victory/game-over stingers still play so pause and end-of-run screens remain responsive.

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
- Sign Running Back (playable character unlock) — 70 coins
- Sign Linebacker (playable character unlock) — 90 coins
- Bluegrass Turf (arena theme unlock) — 80 coins
- Pro Difficulty (toggle, free): tougher enemies via a higher pressure curve, in exchange for a +50% end-of-run coin reward. Toggling does not cost currency and can be switched off again at any time from Front Office.

Purchases are one-time (owned upgrades are marked and cannot be re-bought), reject insufficient funds, and — along with the Pro Difficulty toggle — only take effect starting with the next run; they never alter an active run mid-session. Weapons purchased as starting unlocks no longer need to be found via in-run level-ups, but the level-up unlock options remain available as a fallback for any weapon not already purchased, with no duplicate unlocks possible either way.

## Character select

From the title screen (after choosing a profile), use "Change Character" to open player select. Three playable characters share the same weapons, controls, and HUD, but differ in a small starting stat profile:

- **Quarterback** (unlocked by default): balanced all-around playmaker, no stat changes — the reference build.
- **Running Back** (unlock via Front Office, 70 coins): +40 starting movement speed, -15 starting max health. Built for evasive, high-mobility play.
- **Linebacker** (unlock via Front Office, 90 coins): +30 starting max health, -20 starting movement speed, +8 starting Tackle Burst and Stiff Arm damage. Built to punish contact.

Each character shows a distinct jersey color and a two-letter role tag (QB/RB/LB) on the player sprite. The character screen shows each option's lock state, stat blurb, and unlock cost if locked; picking a locked character does nothing until it's purchased from Front Office. The profile remembers its last-selected unlocked character (falling back to Quarterback if the saved pick is ever invalid or not owned) and applies it — stacked additively with meta stat upgrades and independent of the Pro Difficulty toggle — only when a new run starts, never mid-run.

## Map & arena selection

The arena presentation is built on a data-driven map framework (`scripts/arena.gd` and `ProfileManager.MAPS`). Maps configure visual parameters (turf color, end zone color, sideline and goalpost accents, yard line markings, boundary lines, center circle mark, crowd silhouettes, and end zone labels) while keeping all core gameplay logic—including spawner boundaries, wave director pacing, collision shapes, weapon interactions, and halftime boss events—completely map-agnostic and identical across arenas.

From the title screen, select "Change Arena" to open the arena selection menu:

- **Classic Field** (unlocked by default): traditional green turf stadium with gold sideline accents, white yard markings, and green/gold end zones.
- **Bluegrass Field** (unlock via Front Office, 80 coins): vibrant royal bluegrass turf with ice-blue yard lines, golden sidelines, and deep navy end zones.

### Persistence & future maps

- `selected_map` is persisted per profile across the three save slots. If a profile loads an invalid or unpurchased map ID, it safely defaults to `classic_field`.
- The selected map is previewed dynamically in the background on the title and selection menus and applied cleanly at kickoff and run restart without altering active gameplay state.
- **Adding new maps**: To introduce a new map theme, add an entry to the `MAPS` array in `scripts/profile_manager.gd` with its visual parameters (colors for turf, end zones, lines, etc.), and optionally add an unlock entry to `META_UPGRADES`. The `Arena` class (`scripts/arena.gd`) and `MapPanel` UI will automatically handle rendering and selection.

## Adding real sprite art

The project is architected with complete sprite-import scaffolding so finished pixel art sprite sheets can be dropped in without code refactoring.

### Visual architecture & procedural fallback

Every playable character, enemy archetype, and boss includes an `AnimatedSprite2D` node with a structured `SpriteFrames` resource (`idle`, `run`, `hit`, `death` animation tracks). If no frames/textures are assigned, the entity automatically falls back to its built-in procedural geometry, styleboxes, and colorblind-aware shaders/palettes. Once real sprite frames are attached, the procedural placeholders are hidden and the entity plays its animated sprite states with automatic horizontal flipping and damage flashing.

### Size, formatting & anchor expectations

- **File format**: 32-bit RGBA PNG with transparent background.
- **Frame size**: 48x48 pixels per frame for characters and enemies (64x64 or 96x96 for Boss/Elite).
- **Pixel art filtering**: Configured project-wide in `project.godot` (`rendering/textures/canvas_textures/default_texture_filter=0`, nearest-neighbor, no mipmaps).
- **Feet-anchor alignment**: Center-bottom aligned (origin at `X: 24, Y: 44` for 48x48 frames) to match physics collision capsules.
- **Animation states**:
  - `idle`: 4–6 frames, looped (5–6 FPS)
  - `run`: 6–8 frames, looped (8–12 FPS)
  - `hit`: 2–4 frames, non-looping (10–15 FPS)
  - `death`: 4–8 frames, non-looping (10–15 FPS)
- **Directional layout**: 8 directions (Down, Down-Right, Right, Up-Right, Up, Up-Left, Left, Down-Left) or 5 directions with horizontal flip.

### Asset folder hierarchy

Drop PNG sprite sheets into the designated subfolders under `assets/sprites/`:

- `assets/sprites/player/quarterback/`: Quarterback character sprite sheets
- `assets/sprites/player/running_back/`: Running Back character sprite sheets
- `assets/sprites/player/linebacker/`: Linebacker character sprite sheets
- `assets/sprites/enemies/defender/`: Defender enemy sprite sheets
- `assets/sprites/enemies/runner/`: Runner enemy sprite sheets
- `assets/sprites/enemies/thrower/`: Thrower enemy sprite sheets
- `assets/sprites/enemies/blocker/`: Blocker enemy sprite sheets
- `assets/sprites/enemies/coach/`: Coach support enemy sprite sheets
- `assets/sprites/enemies/referee/`: Referee enemy sprite sheets
- `assets/sprites/boss/elite/`: Halftime Elite boss sprite sheets
- `assets/sprites/maps/classic_field/`: Classic field decor/goalpost sprites
- `assets/sprites/maps/bluegrass_field/`: Bluegrass field decor/goalpost sprites

To assign frames in Godot: open the target scene (`Player.tscn`, `Enemy.tscn`, `Boss.tscn`, etc.), click the `AnimatedSprite2D` node, select the `SpriteFrames` resource in the Inspector, and use the SpriteFrames panel to slice your sheet into frames for the corresponding animation slot (`idle`, `run`, `hit`, `death`).

## Enemy roster & mechanics

- **Defender**: fundamental pursuing defensive back that damages on contact.
- **Runner**: fast, evasive rusher with lower health that tests perimeter positioning.
- **Thrower**: maintains range and launches enemy-only footballs at the player.
- **Blocker**: durable enforcer that knocks the player backward on contact.
- **Coach**: roaming coordinator that projects a support aura buffing nearby enemies' speed and damage.
- **Referee**: field official roaming the gridiron emitting a visible **Penalty Zone**. If the player attacks (fires any weapon) while standing inside an active Penalty Zone, they receive a 2-second **Flagged** debuff (45% speed penalty, auto/active weapons disabled, HUD warning banner, whistle cue), requiring tactical repositioning. Referees are damageable and drop XP like other roles.
- **Halftime Elite**: boss that takes the field at 2:30 with high durability, rewarding 25 XP and 50 permanent coins on defeat.

## Character Audible abilities

Each character possesses a signature active **Audible** ability on a 30-second cooldown, activated with **Space** or **Controller RB**:

- **Quarterback (Pocket Protection)**: 2.0s invincibility shield plus an explosive shockwave that knocks back and damages all nearby enemies within 220px.
- **Running Back (Juke Move)**: a high-speed forward dash (0.35s at 3.2x speed) that evades incoming contact damage and deals 35 damage to enemies passed through.
- **Linebacker (Bull Rush)**: a devastating forward charge (0.5s at 2.5x speed with 80% damage reduction) dealing 50 damage and heavy knockback along its path.

The HUD provides a live cooldown counter and "READY" indicator for the active Audible.

## Turf hazards & wave pacing

The five-minute drive is paced across structured wave phases with dynamic **Turf Hazards**:

1. **Kickoff (0:00 - 0:45)**: Defenders establish the line.
2. **First Quarter (0:45 - 1:45)**: Runners and Referees enter the fray.
3. **Second Quarter (1:45 - 2:30)**: **Muddy Turf Hazard** active — soggy turf darkens the field and slows player movement speed by 28%.
4. **Halftime Drive (2:30 - 3:30)**: Halftime Elite takes the field; standard field conditions return.
5. **Final Drive (3:30 - 4:30)**: **Sideline Chains Hazard** active — physical sideline chain barriers contract playable horizontal width from ±560 to ±385.
6. **Red Zone (4:30 - 5:00)**: All roles join the final stand across full turf.

Clear HUD banners and audio alerts announce all phase changes and hazard starts/ends.

## Playbook & weapons

- **Automatic Football**: primary projectile targeting the nearest enemy.
- **Tackle Burst**: close-range area-of-effect blast.
- **Hail Mary**: long-range high-impact bomb.
- **Stiff Arm**: melee arc sweep.

Collecting XP triggers the **Playbook** ("Call a Play") screen, pausing gameplay to offer choices categorized as **WEAPON UNLOCK**, **WEAPON UPGRADE**, or **PLAYER STAT** with current and upgraded stat comparisons. The live loadout HUD tracks unlocked state, damage, and cooldowns for all four weapons throughout the drive.

Player damage briefly flashes the player, nearby enemy attacks show short warning rings, weapon hits create floating impact numbers, and end-of-run summaries track survival time, enemies defeated, XP earned, and weapon hit statistics.

Starting or restarting a run creates a fresh player progression state and clears all active gameplay nodes before the timer begins.

## Development notes

This project currently uses Godot's Compatibility renderer and built-in placeholder visuals only. Keep reusable gameplay objects in `scenes/` with their behavior in `scripts/` as new systems are introduced.
