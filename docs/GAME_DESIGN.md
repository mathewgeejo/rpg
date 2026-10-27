# The Unwritten Atlas: Lantern Vale

## The complete small adventure

Lantern Vale is a fixed valley with four connected places. Lanternwick offers safety, neighbors, equipment choices, and supplies. Wispwood introduces combat and memory fragments. Stonewater teaches branching exploration, bridge crossings, and stairs to a raised terrace. The Observatory ends the story with the Unremembered Keeper and a consequential decision.

Mira's brother Elian volunteered to sustain the seal protecting the village from restless echoes. The seal learned to keep taking memories without asking. Nobody except Mira remembers him. The player collects fragments of the lost history, defeats its guardian, and either returns the memory to the community or ends the seal's claim over human memory. Both paths conclude with Mira. Geography remains fixed.

Three neighbor quests concern the road lanterns, Sella's memory garden, and Elian's unsent letter. Three fixed commissions offer additional reasons to explore. Fishing supplies food; fallen wood can become a permanent willow charm. There are no generated quest layouts, random towns, or inaccessible placeholder regions.

## One source of power, two disciplines

The world calls the underlying power **remembrance**: the ability of a practiced pattern to persist. Circles inscribe a pattern outside the body; stars embody one inside it. A class describes what someone believes power is for. Classes do not determine moral worth.

Circle rank and knight star rank are distinct from training levels. This adventure advances characters through ranks I-III. Practice levels reach 1-9 and improve proficiency. Higher circle/star tiers exist in the setting's hierarchy, but are not advertised as playable unlocks in this small adventure.

| Tier | Circle discipline | Knight discipline |
|---|---|---|
| I | Inscription: sustain a stable external circle | Ember: sustain an internal vow under pressure |
| II | Weaving: coordinate nested patterns | Pulse: carry intent through a movement or weapon form |
| III | Resonance: stabilize a governing relationship | Aura: project the vow beyond the body |
| IV | Domain: maintain an area of altered conditions | Mantle: sustain a defensive or offensive presence |
| V | Fold: connect separated positions or states | Aspect: embody one practiced ideal |
| VI | Convergence: combine independent spell structures | Constellation: coordinate multiple internal stars |
| VII | Edict: impose a temporary local rule | Sovereignty: extend a vow across a battlefield |
| VIII | Axiom: contest the assumptions beneath a rule | Horizon: carry a form beyond conventional limits |
| IX | Worldscript: permanently change a rule with a lasting cost | First Star: become the enduring source of a chosen form |

## Playable combat rules

- Each class has its own basic pattern: arcs, fans, piercing lines, pulses, poison bolts, delayed strikes, or spirit commands. Basics cost 5, 5, then 9 stamina; combos expire after 2.5 seconds. Class-specific third attacks change the pattern or debuff. Fans strike each target once per volley and can cover multiple foes.
- A circle bolt costs 12 mana for Aether, 15 for Ember, or 14 for Frost. Aether returns 3 mana on impact; Ember burns for 3 seconds; Frost slows for 3 seconds. Bolts have a 0.65-second recovery and train circle weaving when they hit.
- Casting builds circle strain. It dissipates at 16 per second. Casting at 80 or more strain costs 6 health, leaving at least one health, and increases recovery to 1.4 seconds. Higher rank reduces strain added per cast. The HUD displays strain.
- Starstep has a 4-second recovery. Flowing costs 25 stamina and travels up to 200 world units; Resolute costs 35, travels up to 140, and grants a ward; Rending costs 35, travels up to 140, deals more damage, and exposes nearby weaknesses. Walls, water, and height transitions stop the movement.
- Ward costs 18 mana, grants 35 protection before armor bonuses, and recovers in 9 seconds. Protection gradually fades.
- Evading costs 22 stamina, or 15 for Gravity Dancer. The dash lasts 0.23 seconds with 0.32 seconds of invulnerability. Taking a hit grants a brief recovery window to prevent simultaneous enemies from erasing all health.
- Mana normally recovers at 4 per second. Stamina recovers at 25 while idle and 17 otherwise. Class passives and specializations can modify recovery.
- Cloth improves spell power by 10% and mana recovery by 15%, with slightly weaker sword strikes. Leather improves movement by 8%. Plate improves sword power by 8%, protection by 20%, and reduces incoming damage by 10%, with 6% slower movement and slightly weaker circles.
- Defeat returns the player to the village with restored resources and a loss of up to 10 coins. Completed quests and defeated enemies remain recorded. The guardian enters a stronger second phase below half health; its floor warnings remain the source of truth for avoiding attacks.

Overall adventure experience advances rank at 140 and 420 XP. Rank II adds a class specialization and 20% signature power. Rank III reaches 40% signature power and reduces signature recovery by 15%. Signature abilities normally cost 20 mana and recover in 8 seconds; their individual mechanics can change this, such as a Gambler rolling six.

## Classes and summoning

The 20 live classes are defined in `data/classes.json`. Each has a basic attack, special, passive, debuff or control effect, rarity, and its own pixel emblem. The codex explains the kit. Luck, vow, prisms, and stored growth appear beside the special in the HUD. Specializations have explicit strengths and costs.

The Constellation Well replaces the former class questionnaire. The first summon is free, later pulls cost 30 earned coins, and duplicates refund 15 coins. Base tier odds: B 50%, A 30%, S 15%, SS 4%, SSS 1%. Classes within a tier are equally likely. The tenth pull without S-or-higher guarantees S; the eightieth without SSS guarantees SSS. Higher results can occur before either guarantee. Collection and pity counters persist. Classes are freely equipped once owned. No paid currency or network service is involved.

## Guardians and bonds

The root-court contains the optional Briar Crown (900 HP): delayed roots surround the player's last position, with more roots in phase two. Stonewater's optional Drowned Bell (1,250 HP) sends staggered wave marks and shortens its targeted warning in phase two. The Keeper (1,800 HP) marks a falling star, then adds four satellite marks below half health. Guardians remain rooted, engage at short range or when hit, and stop attacking distant players. Their pending attacks clear on defeat. Each awards adventure experience and coins; only the Keeper unlocks the story seal. Their lore plaques and journal guide explain the patterns.

Five species can be tamed below 40% health by offering one river fish within 110 world units. Taming is guaranteed and consumes the fish without granting kill rewards. Wild creatures return after a lantern rest; permanent quest/defeat records and companion collection remain. One active companion follows, recalls around obstructions, fights nearby targets, and gains bond damage up to +10. Mossling heals, River Fang exposes, Cinder Moth burns, Stone Sprout shields, and Star Wisp replenishes mana. Companions stop attacking weakened wild creatures and do not initiate dormant boss fights.

F10 opens the test chamber. God mode prevents damage and restores combat resources/cooldowns. It is session-only. Testing grants, class unlocks, companion unlocks, and story progress are deliberately saved. Travel and encounter respawn controls make all three boss fights repeatable for testing.

## Training and village economy

Swordcraft, circle weaving, knight stars, wood gathering, and fishing earn separate XP. A training level is `min(9, 1 + floor(sqrt(XP / 20)))`. Sword and circle proficiency improve their respective damage; star proficiency improves Starstep.

Resource spots yield three items before a lantern rest restores them. A river fish heals 25 health. The village stall sells fish for 10 coins and buys fish for 6 or willow wood for 4, providing renewable summon income. Three pieces of willow wood and 10 coins create a single permanent charm granting 10 maximum health. Quest, charm, and class bonuses remain intact when rank increases.
