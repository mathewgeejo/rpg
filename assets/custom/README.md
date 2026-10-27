# Original pixel artwork

The active game art is drawn from editable pixel patterns and deliberately authored animation poses. No image-generation model, image API, diffusion process, or photographic texture is used.

- `tools/draw_pixel_art.py` contains palettes, character pixel grids, directional heads and torsos, leg and arm poses, armor, sword trajectories, spell poses, creatures, buildings, and terrain.
- `tools/pixel_details.py` contains cottage roof palettes, individual leaf clusters, fences, benches, the market stall, courtyard paving, and guardian animation poses.
- `tools/draw_guardians.py` contains the Briar Crown and Drowned Bell designs and six deliberate poses each.
- `tools/draw_landmarks.py` contains the root gate, ruined bell chapel, and Observatory dome, with native pixel masonry, recessed faces, and pilasters.
- `scripts/class_emblem.gd` holds 20 explicit eight-pixel class glyphs. Combat projectiles are drawn with deliberate pixel geometry.
- Character sheets have six columns and twenty rows of **48 x 48** cells. Rows 0-3 walk/idle, 4-7 slash, 8-11 cast, 12-15 dodge, and 16-19 hurt. Each group uses down, left, right, up directions.
- Four walk frames create the step cycle. The fifth walk frame supplies a blink. Sword attacks and casting use six poses; evasion uses four. Oversized cells keep sword tips inside their frames.
- Cloth, leather, and plate have different pixel silhouettes and palettes. Mira, Orin, and Sella have their own sheets. Each of the three guardians has six animation cells. All five creature species have distinct designs and four animation cells.
- Source pixels use hard alpha edges and nearest filtering. Lighting, rune geometry, shadows, water movement, and canopy sway are rendered by the engine.

Recreate the art with `python tools/draw_pixel_art.py`. Pillow is the only drawing dependency. This also refreshes the reviewed source manifest. Verify it with `python tools/check_art.py` and `python tests/test_pixel_art.py`.

These are project-original code-authored pixel designs; they are not attributed to a human illustrator. The older artist-made LPC reference material retains its own attribution in `assets/pixel/ATTRIBUTION.md`. The active renderer uses the original art in this directory.
