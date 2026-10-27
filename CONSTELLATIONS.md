# Constellations expansion

The completed expansion keeps Lantern Vale as four fixed authored places and replaces class questions with a collectible 20-class summoning system. See [README](README.md) for play controls and [verification](docs/VERIFICATION.md) for evidence and performance limits.

## What is playable

- Twenty classes have distinct basic attack patterns, specials, passives, debuffs/control effects, and authored pixel emblems. Circle magic, knight stances, equipment, ranks and practice levels remain active.
- The Constellation Well gives a free first summon, then uses 30 earned coins per pull. Base rarity odds are B 50%, A 30%, S 15%, SS 4%, SSS 1%. Class chances are equal within a tier. S-or-higher is guaranteed by ten pulls without one; SSS by eighty without one. Duplicate classes refund 15 coins. Owned classes equip freely. Collection, pity, and RNG state persist.
- Five tameable species follow, fight, gain bond damage and provide healing, exposure, burning, protection, or mana. Weaken a creature below 40% health and press T nearby with one river fish. P opens the roster, habitats, and support descriptions. Lantern rest brings wildlife back while preserving permanent victories and companion collection.
- Three bosses have original pixel art, telegraphed attack patterns, second phases and rewards. The optional Briar Crown guards the root-court; the Drowned Bell guards the chapel; the Keeper guards the Observatory ending. Lore plaques and the journal's guardian guide explain their histories and tactics.
- F10 opens the test chamber: god mode, all-class/companion unlocks, supplies, travel, enemy respawns, rank/recovery, and story fragments. God mode is session-only; deliberate unlocks and progress grants are saved.
- The chapter includes the main mystery, six fragments, neighbor quests, commissions, two endings, the concluding conversation, gathering, fishing, selling, food, crafting, equipment, and save/resume. Selling fish and wood provides renewable summon income.
- New pixel landmarks include a root gate, ruined bell chapel, and Observatory dome with masonry faces, depth, shadows and occlusion. Projectile silhouettes, summon reveal, glyphs, and smaller combat impacts improve readability. No image-generation service was used.

## Requirement evidence

| Request | Implementation and verification |
|---|---|
| 20 differentiated classes, attacks, specials and debuffs | `data/classes.json`, `class_attacks.gd`, `combat.gd`; every basic/special/control effect asserted; all 60 class/boss pairings cleared with ordinary resources |
| Gacha replaces questions, SSS rarest | `summoning.gd` and live menu; no questionnaire loaded; odds, cost, duplicates, pity and save/resume checked |
| Pet / monster taming | `companions.gd`, five species in authored maps, animated sprites; input, costs, support, preservation of weakened creatures and resume checked |
| God mode for testing | F10 and pause entry; actual keyboard/mouse tests toggle god mode, unlock and equip classes, and call companions; damage/resource checks pass |
| Complete adventure and boss fights | Four fixed areas, three two-phase bosses, both endings, quests, economy and persistence; chapter regression plus ordinary-resource boss playthroughs |
| Better original 2D visuals and depth, optimized | 30 editable original pixel assets, distinct landmarks and glyphs; raster source audit, 1,604 art checks, inspected runtime captures and measured Intel UHD boss stress |

The detailed design and live combat rules are in [GAME_DESIGN.md](docs/GAME_DESIGN.md). The former questionnaire JSON and response profiles are retained as historical design data; they are not used for class selection or loaded by the game.
