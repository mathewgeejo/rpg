# The Unwritten Atlas

An original, playable Windows 2D action RPG set in a small, fixed valley. The art direction combines classic Pokemon-style exploration with expressive pixel characters, readable silhouettes, and a dark mystery. Training, equipment choices, fishing, and gathering provide the RuneScape influence.

## Play

Open `project.godot` in Godot 4 and press **F5**, or run `./Play.ps1` from PowerShell. Godot 4.7.1 is installed on the development machine. No exported build is required to play locally.

Choose **Begin your journey** for a free class summon at the Constellation Well. Continue an existing journey if you have one. New players can also choose **Explore Lantern Vale** and summon later through Pause or the village shrine. The temporary Wanderer uses the Gambler kit. Speak with Mira beside the village path to begin the story.

| Action | Input |
|---|---|
| Move | WASD or arrow keys |
| Aim / class basic attack | Mouse / left click or F |
| Circle magic | Right click or 2 |
| Class signature | Q |
| Knight Starstep | 3 |
| Ward | R |
| Evade | Space |
| Interact | E |
| Equipment, focuses, stances, training, food | K |
| Journal / atlas / class codex | J / M / C |
| Tame a weakened creature / companion roster | T / P |
| God mode and testing controls | F10 |
| Pause, save, settings | Escape |

Controller: left stick moves, right stick aims, RT or right-stick click attacks, A interacts, B evades, X uses the signature, Y wards, RB casts a circle, and LB performs Starstep. Keyboard controls are remappable. Saves and settings normally live in `%APPDATA%/Godot/app_userdata/The Unwritten Atlas/`.

## The playable adventure

- **Four fixed places:** Lanternwick, Wispwood Path, Stonewater Crossing, and the Unremembered Observatory. Tile maps, landmarks, encounters, and neighbor requests are deliberately authored. Terrain does not change with a seed.
- **Complete story loop:** Mira's missing brother, six memory fragments, three neighbor quests, three commissions, three bosses with second phases, two seal decisions, and a concluding conversation. Exploration remains available afterward.
- **Twenty collectible classes:** distinct basic attack patterns, specials, debuffs, passives, three adventure ranks, specialization tradeoffs, and a searchable codex. Earned-coin summoning uses B/A/S/SS/SSS rarities, with SSS rarest and visible pity guarantees. Owned classes can be equipped freely.
- **Combat:** sword arcs, dice fans, poison seeds, shard volleys, binding threads, delayed impacts, spirit strikes, three magic focuses, casting strain, three knight stances, wards, evasion, distinct class resources, and visible enemy warnings.
- **Monster bonds:** five tameable species follow, fight, gain bond damage, and provide distinct support. Weaken a wild creature below 40% health and offer one river fish with T. Companions preserve weakened creatures for taming. Resting brings wild creatures back.
- **Test chamber:** F10 exposes god mode, all-class and companion unlocks, supplies, travel, rank/recovery, story fragments, and encounter respawns. God mode is session-only; deliberate progression grants are saved.
- **Village life:** NPCs follow fixed walking routes and stop to face nearby players. Fishing, gathering, food, a provisions stall, a crafted willow charm, training levels, and three visible armor styles are functional.
- **Depth and presentation:** layered roofs and canopies, foreground occlusion, terrain height restrictions, stairs, bridges, shadows, moving water, trees, particles, portraits, typewriter dialogue, a unified bottom HUD, and local/regional maps.

The live adventure covers ranks I-III. The setting's larger circle/star hierarchy is defined in [the game design](docs/GAME_DESIGN.md). This project is a compact playable adventure, with room for additional content later.

## Original pixel art

**No AI image-generation tools or images are used.** The active renderer uses original pixel patterns and deliberately authored animation poses, including cloth, leather, plate, townspeople, creatures, guardian poses, houses, trees, and terrain. The title screen renders the actual village.

The editable art sources are `tools/draw_pixel_art.py`, `tools/pixel_details.py`, `tools/draw_guardians.py`, and `tools/draw_landmarks.py`. Character sheets use 48x48 cells so full sword swings remain inside each frame. See [the art guide](assets/custom/README.md). These are code-authored pixel designs, not work attributed to a human illustrator.

The credited LPC reference packs remain under `assets/pixel/` with their original licenses and [attribution](assets/pixel/ATTRIBUTION.md). Fonts include their SIL Open Font License texts. No account, API key, downloads, or network connection is required at runtime.

## Checks and performance

```powershell
python tools/check_art.py
python tests/test_pixel_art.py
godot --headless --path . --script res://tests/test_game.gd
godot --headless --path . --script res://tests/test_constellations.gd
godot --headless --path . --script res://tests/test_expansion_input.gd
godot --headless --path . --script res://tests/test_boss_playthrough.gd
```

The checks cover summoning and pity, class switching, taming, companion support and persistence, god mode, fixed maps, objective access, enemy spawns, all 60 class/boss pairings with ordinary resources, every special and debuff, spell focuses, strain, stances, equipment, gathering, crafting, food, shop transactions, boss phases, both story endings, saves, and actual mouse/keyboard UI input.

The renderer caches nearby 16x16-tile chunks, culls offscreen props, uses a spatial collision index, keeps native sprite pixels crisp, caches audio tones, and refreshes HUD data at 10 Hz. The game caps at 60 FPS. See [measured verification](docs/VERIFICATION.md) for the tested machine and limits of the samples.
