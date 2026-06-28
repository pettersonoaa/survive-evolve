# Design decisions — LOCKED

**Status:** Decisions locked — revised **2026-06-28** to match shipped prototype  
**Owner:** Renata  
**Purpose:** Agents implement from this file — do not guess.

Tell agents: *"Follow docs/DESIGN_DECISIONS.md"*

---

## Summary (your vision)

| Pillar | Choice |
|--------|--------|
| **Lineage** | Multiple pups per life; on death pick which heir to play |
| **Litters** | Each gestation yields **1–3 pups** (siblings share rolled trait) |
| **Heir loss** | Pup dies → parent continues, can remate |
| **Chain** | Each generation must mate before dying or game over |
| **Evolution** | At **mate time** (gestation **30s**), per-wolf tree position |
| **Victory** | Reach max evolution node → lineage “complete” (game over win) |
| **Survival** | Press **E** to eat/drink; resources deplete then **respawn ~90s** |
| **Pack** | Player feeding sustains partners + **dependent pups** only |
| **Combat** | Starvation, dehydration, **predators** (scale with generation + pack size) |
| **World** | Large map (48-tile radius), **procedural scatter** on New Lineage, biomes + hunt |
| **Meta** | **Lineage Codex** persists discovered traits across runs; gameplay resets on New Lineage |

**Note for agents:** This file wins over older `PROTOTYPE_PLAN.md` defaults. The plan doc tracks implementation steps; this doc tracks **design truth**.

---

## Quick path (filled — reference only)

| # | Question | Your answer |
|---|----------|-------------|
| **A1** | One pup or many? | **Multiple** — litters of 1–3; pick heir on death |
| **A2** | When does evolution happen? | **At mate** — pups born with trait after gestation |
| **A3** | Pup dies before you — then what? | **Remate** — parent continues |
| **A4** | Eat/drink how? | **Press E** at resource — **pack eats together** |
| **A5** | Mate how? | **Press E** near partner; **multiple partners** can gestate at once |

---

## §A — Lineage & succession (🔴 core loop)

### DEC-01 — How many offspring can you have per life?

**Blocks:** STEP-08, STEP-09, STEP-10

| Option | Behavior |
|--------|----------|
| **A** | One pup per player life. |
| **B** | One living heir at a time. |
| **C** | **Multiple pups.** On death, pick which pup to play. |

**YOUR ANSWER:** **C** — Multiple pups per life. Each successful gestation spawns a **litter of 1–3 pups** (DEC-22). Siblings from the same litter share the rolled evolution trait/stats. On player death, show heir picker UI (list living pups). Remating can add more litters over time. Pups stay in the world as NPC heirs until selected or they die.

---

### DEC-02 — What happens if your pup dies while you still play the parent?

**Blocks:** STEP-10, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | Game over immediately. |
| **B** | **Parent continues;** can mate again. |
| **C** | Pup respawns at den. |

**YOUR ANSWER:** **B** — Parent continues playing. Dead pup is removed from heir list. Player may mate again (after gestation rules) to produce a new litter. Game over only if player dies with **no living heirs** (see DEC-01 picker).

---

### DEC-03 — What happens when you die as the pup (second generation)?

**Blocks:** STEP-10, STEP-12, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | **Need a grand-pup** — must mate before death. |
| **B** | Pup can die without heir. |
| **C** | Infinite chain with auto-heir. |

**YOUR ANSWER:** **A** — Every controlled wolf (any generation) must have at least one living heir before death, or **game over (`no_heir`)**. Same rule for pup → grand-pup → etc. If player dies during gestation with no heirs, gestation can still finish and auto-promote the first pup of the litter (succession deferral).

---

### DEC-04 — When is evolution applied?

**Blocks:** STEP-12, STEP-13

| Option | Behavior |
|--------|----------|
| **A** | Automatic on death. |
| **B** | Player picks from rolled options. |
| **C** | **At mate time** — pups get trait; death only transfers control. |

**YOUR ANSWER:** **C** — On successful mate (E + requirements), roll evolution **once per gestation** and store on pending offspring. After gestation (DEC-09), **all pups in the litter** spawn with that rolled trait/stats. Death does **not** roll evolution; it triggers succession / heir picker.

---

### DEC-05 — Evolution tree position: lineage or per-wolf?

**Blocks:** STEP-11, STEP-12

| Option | Behavior |
|--------|----------|
| **A** | Lineage-wide tree position. |
| **B** | **Per individual** — each wolf has own branch state. |
| **C** | Hybrid. |

**YOUR ANSWER:** **B** — Each wolf stores `current_node_id`. Mate roll uses **parent’s** node + **partner’s** `branch_weights`. Pups start at rolled child node; siblings from different litters/partners can diverge.

---

### DEC-06 — At max evolution node (`ancient_wolf` or final tier), further deaths…

**Blocks:** STEP-12

| Option | Behavior |
|--------|----------|
| **A** | Stay at max — no more traits. |
| **B** | Reroll root branches. |
| **C** | **Game over** — lineage completed. |

**YOUR ANSWER:** **C** — When a wolf at the **final tree node** dies (with valid heir succession resolved), show **lineage complete** screen (victory), not failure. Distinct from `no_heir` game over (DEC-19).

---

## §B — Partner & mating (🔴 STEP-08)

### DEC-07 — How do you find a partner in the prototype?

| Option | Behavior |
|--------|----------|
| **A** | Fixed partner on map. |
| **B** | **Wandering partner** — chase before mate. |
| **C** | Partner at den. |

**YOUR ANSWER:** **B** — Partner wolves wander (random direction every 2–4s). Player must find them. Prototype spawns **four** partners (forest, plains, tundra, desert) placed in/near biome zones. On **New Lineage**, `WorldGenerator` scatters partners, prey, resources, and predators.

---

### DEC-08 — Mate requirements

| Requirement | Design default | Shipped prototype |
|-------------|----------------|-------------------|
| Player hunger min | > 50% | **Disabled** (`MATE_REQUIRES_FED = false`) |
| Player thirst min | > 50% | **Disabled** |
| Partner hunger min | > 50% | **Disabled** |
| Proximity | 48 px | **100 px** (`MATE_RANGE`) |
| Input | Press **E** | **E** |

**YOUR ANSWER:** Design defaults above. Prototype toggles fed gate off for faster playtests; re-enable via `GameConstants.MATE_REQUIRES_FED`. **E** is shared with resource interact (DEC-12); context resolves nearest valid target.

---

### DEC-09 — Mate timing & birth

| Option | Behavior |
|--------|----------|
| **A** | Instant pups. |
| **B** | **Gestation ~30s** — litter spawns later. |
| **C** | Return to den to birth. |

**YOUR ANSWER:** **B** — After mate, **30 second gestation** (`GESTATION_SECONDS`). During gestation: parent moves/fights; partner follows player; slow needs drain on parent. When timer ends:

- **1–3 pups** spawn in a small cluster **beside the female partner** (not at den).
- Partner then **stays near her pups** (guard behavior).
- **Multiple gestations** allowed at once — **one per partner** (mate forest + tundra partners in parallel).
- `lineage.generation` increments **once per litter**, not per pup.

---

### DEC-10 — Partner genetics in prototype

| Option | Behavior |
|--------|----------|
| **A** | One partner type. |
| **B** | **Multiple partner types** — different `branch_weights`. |
| **C** | Random partner genes each run. |

**YOUR ANSWER:** **B** — Four wandering partner archetypes:

| archetype | UI tag | Bias | Placeholder color |
|-----------|--------|------|-------------------|
| `forest_wolf` | *Forest blood* | Senses, metabolism, scavenger | `Color(0.42, 0.42, 0.45)` |
| `plains_wolf` | *Plains blood* | Mobility, pack, sprint | `Color(0.58, 0.44, 0.32)` |
| `tundra_wolf` | *Tundra blood* | Physique, winter survival | `Color(0.93, 0.94, 0.96)` |
| `desert_wolf` | *Desert blood* | Ambush, heat survival | `Color(0.72, 0.58, 0.38)` |

Visible tags on partners and in birth toasts (DEC-18). Full weights in `docs/EVOLUTION_TREE_WOLF.md`.

---

### DEC-11 — Does `partner_genes.stat_bias` matter in v1?

| Option | Behavior |
|--------|----------|
| **A** | No — only `branch_weights`. |
| **B** | **Yes** — multiply pup base stats at birth. |

**YOUR ANSWER:** **B** — `stat_bias` applies to pups’ base `WolfStats` at birth (after evolution roll).

---

### DEC-22 — Litter size

| Option | Behavior |
|--------|----------|
| **A** | Always 1 pup. |
| **B** | **1–3 pups** per gestation. |
| **C** | Fixed 3. |

**YOUR ANSWER:** **B** — Roll `litter_size` ∈ [1, 3] at mate time. All siblings in a litter share the same rolled trait/stats. Pup **sprite color** reflects partner bloodline (`get_offspring_color`). Slightly offset spawn positions around the mother.

---

## §C — Survival & world (🟡 STEP-03–06)

### DEC-12 — How do you consume food and water?

| Option | Behavior |
|--------|----------|
| **A** | Auto on overlap. |
| **B** | **Press E** at resource. |
| **C** | Auto eat / manual drink. |

**YOUR ANSWER:** **B** — Stand within interact range, press **E**. When the **player** eats or drinks, **all living pack members** (partners + pups) receive the same hunger/thirst refill (`PackNeedsManager`). Pack HUD shows partner/pup needs bars.

---

### DEC-13 — Are resources finite or respawning?

| Option | Behavior |
|--------|----------|
| **A** | Infinite. |
| **B** | Finite with respawn. |
| **C** | Finite, no respawn. |

**YOUR ANSWER:** **B (revised)** — Each node **one use** then depleted (greyed out). **`ResourceRespawnManager`** respawns after **90s**. Larger map (DEC-21) + hunt loop (deer → carcass) support pack feeding pressure.

---

### DEC-14 — What kills the wolf in the prototype?

**YOUR ANSWER:**

- [x] Starvation (hunger → 0) — **player, partners, and pups**
- [x] Dehydration (thirst → 0)
- [x] **Combat / predators** — base count 6, scales with generation + pack size
- [x] Debug key **K** for testing (STEP-15)

---

### DEC-15 — Target time until critical needs (tuning)

| | Plan default | Shipped |
|---|--------------|---------|
| Hunger | ~67 seconds | ~67s base; **faster with larger pack** (`PACK_SIZE_DECAY_SCALE`) |
| Thirst | ~50 seconds | ~50s base; scales with pack |

**YOUR ANSWER:** Base decay as above. Player needs decay increases with **pack size** and **generation**. Partners/pups decay independently; pack must be fed via shared consumption (DEC-12).

---

## §D — Evolution tree design (🟡 STEP-11)

### DEC-16 — Approve example tree or replace?

**YOUR ANSWER:** **Custom — 34 nodes** in branching DAG (`wolf_tree`). Multiple mid-tier branches, apex node for victory (DEC-06).

---

### DEC-17 — Tree shape

**YOUR ANSWER:** **Branching DAG** — partner `branch_weights` bias mate roll (DEC-04).

---

### DEC-18 — Should partner influence be visible to the player?

**YOUR ANSWER:** **B** — Partner blood tags on map. On litter birth, toast shows trait + partner tag. Pup color matches bloodline. **Lineage Codex** (main menu) lists traits discovered across runs.

---

## §E — Presentation & session (🟢)

### DEC-19 — Game over vs “lineage complete”

**YOUR ANSWER:** **C** — Three outcomes:

1. **`no_heir`** — failure; stats summary.
2. **`lineage_complete`** — victory at apex (DEC-06).
3. **Main menu** — Continue / New Lineage (DEC-20).

---

### DEC-20 — Restart & persistence

| Option | Behavior |
|--------|----------|
| **A** | **Full reset** on New Lineage. |
| **B** | Meta unlocks persist. |

**YOUR ANSWER:** **Hybrid (revised):**

- **Continue** — JSON save: player, heirs, gestations (incl. litter size), world camera offset.
- **New Lineage** — full gameplay reset; **procedural world scatter** (`run_seed`).
- **Lineage Codex** (`user://lineage_codex.json`) — **persists** discovered traits across New Lineage (meta only, not stats).

---

### DEC-21 — Camera / map scope

| Option | Behavior |
|--------|----------|
| **A** | Small arena. |
| **B** | **Larger map** — expand `ground_grid`. |
| **C** | Procedural map. |

**YOUR ANSWER:** **B + partial C** — `ground_grid` extent **48** tiles. **New Lineage** scatters resources, partners, prey, predators, props via `WorldGenerator`. Continue restores saved layout. Biome zones: tundra, desert (+ forest/plains partners).

---

### DEC-23 — Pack management

| Topic | Behavior |
|-------|----------|
| Pack members | Player + partners + **dependent pups only** |
| Pup lifecycle | **Pup** (pack-fed, grows) → **Young wolf** (independent, self-feeds) → **Rogue** (hostile, still genetic heir) |
| Independence | ~**50s** after birth — leaves pack, hunts food/water alone |
| Rogue | ~**70s** after independence — attacks pack; still selectable as heir on death |
| Feeding | Player E-interact feeds **dependent pups** + partners only |
| Difficulty | More pack members → higher needs pressure + more predators + threat tier |
| Den | Safe zone for pups (reduced decay); **birth is at mother**, not den |
| Pack assist | Gestation partner joins player bites; pups assist when heir |

**YOUR ANSWER:** Implemented as above (STEP-31 pack assist, pack needs, Phase 3 scaling).

---

## §F — Controls

| Action | Default | Your key |
|--------|---------|----------|
| Move | WASD + arrows | **WASD + arrows** |
| Interact (mate, eat, drink, hunt, bite) | E | **E** |
| Debug kill | K | **K** |
| Debug mate | M | **M** |
| Debug refill | R | **R** |

---

## Decision → step unblock map

| Decision | Unblocks |
|----------|----------|
| DEC-01–06 | Succession, heir picker, victory |
| DEC-07–11, 22 | Partners, gestation, genetics, litters |
| DEC-12–15, 23 | Needs, pack feeding, predators, respawn |
| DEC-16–18 | 34-node tree, codex, pup colors |
| DEC-19–21 | Menus, save, procedural scatter |
| DEC-23 | Pack HUD, shared feeding, scaling |

**Agents:** This document reflects **shipped prototype** as of Phase 3 + pack pass. When adding features, update this file first.

---

## Implementation changelog (doc sync)

| Date | Change |
|------|--------|
| 2026-06-27 | Initial lock (DEC-01–21) |
| 2026-06-28 | Phase 3: procedural scatter, codex, predator scaling, threat HUD |
| 2026-06-28 | Pack loop: shared feeding, multi-gestation, litters 1–3, birth at mother |
| 2026-06-28 | Pup lifecycle: grow → independent → rogue heir; save v3 |
