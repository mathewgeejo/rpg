# Verification

Checked on 2026-10-27 with Godot 4.7.1 on Windows, an Intel Core i3-1115G4, and Intel UHD Graphics using the OpenGL compatibility renderer. Runtime is capped at 60 FPS. Verification used asset imports and runtime execution; no standalone build/export was run.

## Functional evidence

- `tests/test_game.gd`: **282 assertions passed**. Four fixed maps, safe spawns, reachable objectives and NPC routes, all 20 specials, shared circle/star skills, equipment, gathering, crafting, food, shop transactions, all story/neighbor quests, both seal outcomes and the concluding conversation, commissions, atomic saves/recovery, exact RNG resume, and actual title/summon/HUD/menu input.
- `tests/test_constellations.gd`: **154 assertions passed**. Free/paid summons, insufficient funds, both pity guarantees, all 20 basic attacks, every special's debuff/control effect, class switching, Oath vows, Glass setup/detonation, Smith mana recovery, memory mana, last-life/rest behavior, renewable wildlife, taming costs and rewards, five companion support abilities, taming opportunities, collection/pity/companion resume, god-mode recovery, all three boss phases, resolved warnings, evasion, attack cleanup, and story gating.
- `tests/test_expansion_input.gd`: **53 assertions passed**. Real viewport keyboard/mouse events open F10, toggle god mode, unlock all classes, equip Doorwright, call Star Wisp, tame through T, close menus, and inspect settings bounds. Every live class has an authored glyph.
- `tests/test_boss_playthrough.gd`: **all 60 class/guardian pairings cleared**. The scripted player uses ordinary resources, movement, basic attacks, specials, wards, and up to three fish. God mode is off. These are isolated boss simulations, not a claim of exhaustive human balance testing. Current scripted Keeper clears range from roughly 11 to 33 seconds across the roster.
- A simulated gamepad B press verifies evasion rather than accidental pause. No physical-controller playthrough was performed.

## Art and rendered evidence

- **1,604 pixel-art assertions passed**: six consistent 48x48-cell character sheets, distinct movement/action poses, hard alpha edges, 36 opaque terrain tiles, three guardian sheets, five distinct animated creature species, and native pixel landmark structures.
- The reviewed manifest verifies **30 original pixel assets and 71 credited reference images**. Active gameplay uses the original art. The manifest checks source identity and hashes; it is not an AI-image classifier.
- Inspected captures include summoning, the reveal screen, companions, test chamber, controls, the root court, bell chapel, and Observatory facade, alongside the earlier village/depth/equipment/story screens. Capture helpers reject runtime errors in stderr.
- Editable sources: `tools/draw_pixel_art.py`, `tools/pixel_details.py`, `tools/draw_guardians.py`, `tools/draw_landmarks.py`, and `scripts/class_emblem.gd`. No image-generation model or service was used.

## Performance

The boss stress scene moves the player around the second-phase Keeper while repeatedly using Glass Composer attacks, prisms and circle spells, with a Star Wisp companion active. It records 1,780 frames after 20 warm-up frames, about 30 seconds. The boss remains alive for the measurement. The map-streaming stress scene is also available as `benchmark`.

| Presentation | Average FPS | P95 frame interval | Peak terrain chunks |
|---|---:|---:|---:|
| 1440x900 boss stress | 59.6 | 16.95 ms | 4 |
| 1920x1080 fullscreen boss stress | 58.9 | 18.06 ms | 4 |

The fullscreen capture is 1728x1080 within a 1920x1080 window because the game preserves its 16:10 composition. These measurements cover the available machine and a 30-second stress scenario, not every device or a long-duration soak.

Each resident terrain chunk is a 512x512 RGBA texture; four represent 4 MiB of raw terrain data. Village views can use six chunks. This excludes other textures, process memory, engine and driver allocations. Static props are cached and culled, collision uses nearby cells, the HUD/minimap refresh at 10 Hz, and audio tones are cached. Pixel art uses nearest filtering. Combat impacts and status runes use restrained geometry to preserve attack readability.

## Reproduce

```powershell
python tools/check_art.py
python tests/test_pixel_art.py
godot --headless --path . --script res://tests/test_game.gd
godot --headless --path . --script res://tests/test_constellations.gd
godot --headless --path . --script res://tests/test_expansion_input.gd
godot --headless --path . --script res://tests/test_boss_playthrough.gd
./tools/capture.ps1 -Mode bossbenchmark
./tools/capture.ps1 -Mode bossbenchmark -Resolution 1920x1080
```

Use the installed `_console.exe` executable for visible Godot console output on Windows. Capture logs and screenshots are under `artifacts/`; run captures sequentially so they do not compete for the GPU. The fullscreen capture closes automatically. Saves used by checks are isolated from the player's normal save.
