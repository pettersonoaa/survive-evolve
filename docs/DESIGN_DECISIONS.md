# Design decisions — LOCKED

**Status:** Decisions locked (2026-06-27)  
**Owner:** Renata  
**Purpose:** Agents implement from this file — do not guess.

Tell agents: *"Follow docs/DESIGN_DECISIONS.md"*

---

## Summary (your vision)

| Pillar | Choice |
|--------|--------|
| **Lineage** | Multiple sons; on death pick which to play |
| **Heir loss** | Son dies → parent continues, can remate |
| **Chain** | Each generation must mate before dying or game over |
| **Evolution** | At **mate time** (gestation ~60s), per-wolf tree position |
| **Victory** | Reach max evolution node → lineage “complete” (game over win) |
| **Survival** | Press **E** to eat/drink; finite resources, no respawn |
| **Combat** | Starvation, dehydration, **and** predators/combat in v1 |
| **World** | Wandering partners, larger map, **30+ node** evolution DAG |

**Note for agents:** This diverges from `PROTOTYPE_PLAN.md` defaults (1 son, evolution on death, auto-consume). **This file wins** when they conflict. Update `PROTOTYPE_PLAN.md` / `GAME_CONCEPT.md` during implementation.

---

## Quick path (filled — reference only)

| # | Question | Your answer |
|---|----------|-------------|
| **A1** | One son or many? | **Multiple** — pick heir on death |
| **A2** | When does evolution happen? | **At mate** — son born with trait after gestation |
| **A3** | Son dies before you — then what? | **Remate** — parent continues |
| **A4** | Eat/drink how? | **Press E** at resource |
| **A5** | Mate how? | **Press E** when near fed partner |

---

## §A — Lineage & succession (🔴 core loop)

### DEC-01 — How many offspring can you have per life?

**Blocks:** STEP-08, STEP-09, STEP-10

| Option | Behavior |
|--------|----------|
| **A** | One son per player life. |
| **B** | One living heir at a time. |
| **C** | **Multiple sons.** On death, pick which son to play. |

**YOUR ANSWER:** **C** — Multiple sons per life. On player death, show heir picker UI (list living sons). Remating can add more sons over time. Sons that already exist stay in the world as NPCs until selected or they die.

---

### DEC-02 — What happens if your son dies while you still play the parent?

**Blocks:** STEP-10, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | Game over immediately. |
| **B** | **Parent continues;** can mate again. |
| **C** | Son respawns at den. |

**YOUR ANSWER:** **B** — Parent continues playing. Dead son is removed from heir list. Player may mate again (after gestation rules) to produce a new heir. Game over only if player dies with **no living sons** (see DEC-01 picker).

---

### DEC-03 — What happens when you die as the son (second generation)?

**Blocks:** STEP-10, STEP-12, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | **Need a grandson** — must mate before death. |
| **B** | Son can die without heir. |
| **C** | Infinite chain with auto-heir. |

**YOUR ANSWER:** **A** — Every controlled wolf (any generation) must have at least one living offspring before death, or **game over (`no_heir`)**. Playing as son: mate during gestation window → grandson exists → on son death, pick grandson (or game over if none). Same rule applies for grandson, great-grandson, etc.

---

### DEC-04 — When is evolution applied?

**Blocks:** STEP-12, STEP-13

| Option | Behavior |
|--------|----------|
| **A** | Automatic on death. |
| **B** | Player picks from rolled options. |
| **C** | **At mate time** — son gets trait; death only transfers control. |

**YOUR ANSWER:** **C** — On successful mate (E press + requirements met), roll evolution **immediately** and store trait on pending offspring. After **gestation (~60s)** (DEC-09), son spawns with rolled stats/trait applied. Death does **not** roll evolution; it only triggers succession / heir picker.

---

### DEC-05 — Evolution tree position: lineage or per-wolf?

**Blocks:** STEP-11, STEP-12

| Option | Behavior |
|--------|----------|
| **A** | Lineage-wide tree position. |
| **B** | **Per individual** — each wolf has own branch state. |
| **C** | Hybrid. |

**YOUR ANSWER:** **B** — Each wolf stores `current_node_id` on their `WolfGenes` / individual record. Mate roll uses **parent’s** node + **partner’s** `branch_weights`. Son starts at rolled child node; siblings can diverge if parents remate with different partners.

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

**YOUR ANSWER:** **B** — Partner wolf wanders the map (random direction every 2–4s). Player must find and catch them. Prototype: spawn **2–3** wandering partners (one per archetype: forest, plains, tundra) or random archetype per spawn.

---

### DEC-08 — Mate requirements

| Requirement | Plan default | Your value |
|-------------|--------------|------------|
| Player hunger min | > 50% | **> 50%** |
| Player thirst min | > 50% | **> 50%** |
| Partner hunger min | > 50% | **> 50%** |
| Proximity | 48 px | **48 px** |
| Input | Press **E** | **E** |

**YOUR ANSWER:** **Defaults** — all thresholds as above. **E** is shared with resource interact (DEC-12); context resolves target (nearest valid interactable).

---

### DEC-09 — Mate timing

| Option | Behavior |
|--------|----------|
| **A** | Instant son. |
| **B** | **Gestation ~60s** — son spawns later. |
| **C** | Return to den to birth. |

**YOUR ANSWER:** **B** — After mate, **60 second gestation**. During gestation: parent can still move/fight/survive; optional UI timer. Son spawns at parent position when timer ends, with evolution from DEC-04 already applied. Only one active gestation per parent at a time.

---

### DEC-10 — Partner genetics in prototype

| Option | Behavior |
|--------|----------|
| **A** | One partner type. |
| **B** | **Multiple partner types** — different `branch_weights`. |
| **C** | Random partner genes each run. |

**YOUR ANSWER:** **B** — Three wandering partner archetypes with distinct `WolfGenes.branch_weights`:

| archetype | UI tag | Bias | Placeholder color |
|-----------|--------|------|-------------------|
| `forest_wolf` | *Forest blood* | Senses, metabolism, scavenger | Cinza / preto — `Color(0.42, 0.42, 0.45)` |
| `plains_wolf` | *Plains blood* | Mobility, pack, sprint | Marrom / bege — `Color(0.58, 0.44, 0.32)` |
| `tundra_wolf` | *Tundra blood* | Physique, winter survival | Branco — `Color(0.93, 0.94, 0.96)` |

Visible tags in UI (DEC-18). Random which archetype each spawned partner uses. Full weights in `docs/EVOLUTION_TREE_WOLF.md`.

---

### DEC-11 — Does `partner_genes.stat_bias` matter in v1?

| Option | Behavior |
|--------|----------|
| **A** | No — only `branch_weights`. |
| **B** | **Yes** — multiply son base stats at birth. |

**YOUR ANSWER:** **B** — `stat_bias` applies to son’s base `WolfStats` at birth (after evolution roll). Example: `{"move_speed": 1.1}` → son 10% faster before trait deltas.

---

## §C — Survival & world (🟡 STEP-03–06)

### DEC-12 — How do you consume food and water?

| Option | Behavior |
|--------|----------|
| **A** | Auto on overlap. |
| **B** | **Press E** at resource. |
| **C** | Auto eat / manual drink. |

**YOUR ANSWER:** **B** — Stand within interact range of `FoodCarcass` / `WaterSource`, press **E**. Same key as mate; nearest eligible target wins. Show interact hint when in range.

---

### DEC-13 — Are resources finite or respawning?

| Option | Behavior |
|--------|----------|
| **A** | Infinite. |
| **B** | Finite with respawn. |
| **C** | **Finite, no respawn** — find next node. |

**YOUR ANSWER:** **C** — Each resource node **one use** then depleted (hidden or greyed out). No respawn in prototype. Map must have enough scattered nodes for a full gestation + mate loop (favors **larger map**, DEC-21).

---

### DEC-14 — What kills the wolf in the prototype?

**YOUR ANSWER:**

- [x] Starvation (hunger → 0)
- [x] Dehydration (thirst → 0)
- [x] **Combat / predators** — include basic predator or hostile NPC damage in v1 (STEP-21+ or parallel combat step)
- [x] Debug key **K** for testing (STEP-15)

---

### DEC-15 — Target time until critical needs (tuning)

| | Plan default | Your target |
|---|--------------|-------------|
| Hunger | ~67 seconds | **~67 seconds** |
| Thirst | ~50 seconds | **~50 seconds** |

**YOUR ANSWER:** **Defaults** — tune in STEP-03; finite resources (DEC-13) make these timings matter more.

---

## §D — Evolution tree design (🟡 STEP-11)

### DEC-16 — Approve example tree or replace?

**YOUR ANSWER:** **Custom — minimum 30 nodes.** Do **not** use the 7-node example as-is. Expand `wolf_tree` into a **branching DAG** with ≥30 `EvolutionNode`s, multiple mid-tier branches, 2–3 merge nodes, and 1–2 final “apex” nodes (e.g. `ancient_wolf` line). Keep §5 of `PROTOTYPE_PLAN.md` as **structural inspiration** only. Author in `data/evolution/wolf_tree.tres` before STEP-12.

---

### DEC-17 — Tree shape

| Option | Behavior |
|--------|----------|
| **A** | **Branching DAG** — choices matter. |
| **B** | Single linear path. |
| **C** | Wide shallow tree. |

**YOUR ANSWER:** **A** — Branching DAG required for 30+ nodes. Partner `branch_weights` bias which child nodes are likely at mate roll (DEC-04).

---

### DEC-18 — Should partner influence be visible to the player?

| Option | Behavior |
|--------|----------|
| **A** | Hidden. |
| **B** | **Show partner tags** in UI. |
| **C** | Show on death only. |

**YOUR ANSWER:** **B** — Label wandering partners (e.g. “Forest blood”, “Plains blood”, “Tundra blood”). On son birth after gestation, briefly show rolled trait name + partner influence.

---

## §E — Presentation & session (🟢)

### DEC-19 — Game over vs “lineage complete”

| Option | Behavior |
|--------|----------|
| **A** | Same screen. |
| **B** | Different screens per reason. |
| **C** | **Stats summary** — generations, traits. |

**YOUR ANSWER:** **C** — **Three outcomes, distinct copy:**

1. **`no_heir`** — failure; stats summary (gens reached, traits seen).
2. **`lineage_complete`** — victory at max node (DEC-06); stats + “Ancient lineage”.
3. **Restart** from either screen (DEC-20).

---

### DEC-20 — Restart behavior

| Option | Behavior |
|--------|----------|
| **A** | **Full reset** — gen 0, fresh map resources. |
| **B** | Meta unlocks persist. |

**YOUR ANSWER:** **A** — Full reset on restart. No meta persistence in prototype.

---

### DEC-21 — Camera / map scope

| Option | Behavior |
|--------|----------|
| **A** | Small arena. |
| **B** | **Larger map** — expand `ground_grid`. |
| **C** | Procedural map. |

**YOUR ANSWER:** **B** — Expand `ground_grid` extent (suggest **40–48** tiles radius vs current 24). Scatter more finite resources and wandering partners. Procedural deferred.

---

## §F — Controls

| Action | Default | Your key |
|--------|---------|----------|
| Move | WASD + arrows | **WASD + arrows** |
| Interact (mate, eat, drink) | E | **E** |
| Debug kill | K | **K** |
| Debug mate | M | **M** |
| Debug refill | R | **R** |

**YOUR ANSWER:** **Defaults** — add `interact` action (E) in `project.godot` at STEP-06/08.

---

## Decision → step unblock map

| Decision | Unblocks |
|----------|----------|
| DEC-01, 02, 03, 04, 05 | STEP-08–10, 12–14 (succession + heir picker) |
| DEC-06 | STEP-12, STEP-14 (victory path) |
| DEC-07–11 | STEP-08, 11–12 (wandering partners, gestation, genetics) |
| DEC-12–15 | STEP-03, 06 (needs, E-interact, finite resources) |
| DEC-14 | Combat / predator step (new or STEP-21 early) |
| DEC-16–18 | STEP-11–13 (30+ node tree, partner UI) |
| DEC-19–21 | STEP-14, 16 (screens, map size) |

**Agents:** All sections answered. Start STEP-01; revise `PROTOTYPE_PLAN.md` where this doc overrides it.

---

## After you answer

1. ~~Fill answers in this file.~~ **Done.**
2. Message: *“Decisions locked — see DESIGN_DECISIONS.md”*
3. Agents copy final rules into `docs/GAME_CONCEPT.md` during STEP-16.
