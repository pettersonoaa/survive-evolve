# Design decisions needed from you

**Purpose:** Answer these so agents can implement without guessing.  
**How to use:** Fill in `YOUR ANSWER:` under each item (or pick A/B/C). When done, tell agents: *"Follow docs/DESIGN_DECISIONS.md"*.

**Legend**
- 🔴 **Blocks agents now** — needed before STEP-08 or affects core loop
- 🟡 **Blocks later** — needed before STEP-11/12 or tuning
- 🟢 **Optional** — agents use listed default if you skip

---

## Quick path (if you want to unblock today)

Answer only the **5 bold questions** in §A; accept **recommended defaults** everywhere else.

| # | Question | Recommended default |
|---|----------|---------------------|
| **A1** | One son or many? | **One son** — remating does nothing |
| **A2** | When does evolution happen? | **On your death**, auto-roll, son gets trait |
| **A3** | Son dies before you — then what? | **Game over** (lineage ends) |
| **A4** | Eat/drink how? | **Walk over** resource (auto) |
| **A5** | Mate how? | **Press E** when near fed partner |

---

## §A — Lineage & succession (🔴 core loop)

### DEC-01 — How many offspring can you have per life?

**Blocks:** STEP-08, STEP-09, STEP-10

**Context:** Plan assumes one heir. Multiple sons changes UI, succession, and game-over rules.

| Option | Behavior |
|--------|----------|
| **A** | **One son per player life.** Mate once; remate ignored or blocked. |
| **B** | **One living heir at a time.** New mate replaces old son. |
| **C** | **Multiple sons.** On death, you pick which son to play (needs UI). |

**YOUR ANSWER:**

---

### DEC-02 — What happens if your son dies while you still play the parent?

**Blocks:** STEP-10, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | **Game over immediately** — lineage broken. |
| **B** | **Parent continues;** can mate again for a new heir. |
| **C** | **Son respawns** at den (needs den system — out of prototype scope). |

**YOUR ANSWER:**

---

### DEC-03 — What happens when you die as the son (second generation)?

**Blocks:** STEP-10, STEP-12, STEP-14

| Option | Behavior |
|--------|----------|
| **A** | **Need a grandson** — son must mate before death or game over. |
| **B** | **Son can die without heir** — game over (prototype stays 1 mate → 1 succession demo). |
| **C** | **Infinite chain** — son auto-spawns a generic heir at age X (no mate required). |

**YOUR ANSWER:**

---

### DEC-04 — When is evolution applied?

**Blocks:** STEP-12, STEP-13

| Option | Behavior |
|--------|----------|
| **A** | **Automatic on death** — weighted roll, son spawns in with new stats (plan default). |
| **B** | **Player picks** from 2–3 rolled options (roguelike draft). |
| **C** | **Evolution happens at mate time** — son born with trait; death only transfers control. |

**YOUR ANSWER:**

---

### DEC-05 — Evolution tree position: lineage or per-wolf?

**Blocks:** STEP-11, STEP-12

**Context:** When you die and roll `keen_nose`, does the whole lineage stay at `keen_nose` for future deaths?

| Option | Behavior |
|--------|----------|
| **A** | **Lineage-wide tree position** — `current_node_id` is shared; each death advances one node along tree. |
| **B** | **Per individual** — son has own branch state; tree is personal. |
| **C** | **Hybrid** — lineage position advances, but son only inherits *some* stat deltas. |

**YOUR ANSWER:**

---

### DEC-06 — At max evolution node (`ancient_wolf`), further deaths…

**Blocks:** STEP-12

| Option | Behavior |
|--------|----------|
| **A** | **Stay at max** — no more trait gains, still play succession. |
| **B** | **Reroll root branches** — sideways mutation. |
| **C** | **Game over** — lineage “completed”. |

**YOUR ANSWER:**

---

## §B — Partner & mating (🔴 STEP-08)

### DEC-07 — How do you find a partner in the prototype?

| Option | Behavior |
|--------|----------|
| **A** | **One fixed partner** on map (plan default). |
| **B** | **Wandering partner** — must chase before mate. |
| **C** | **Partner at den** — go to landmark first. |

**YOUR ANSWER:**

---

### DEC-08 — Mate requirements

**Blocks:** STEP-08 tuning

Confirm or change thresholds:

| Requirement | Plan default | Your value |
|-------------|--------------|------------|
| Player hunger min | > 50% | |
| Player thirst min | > 50% | |
| Partner hunger min | > 50% | |
| Proximity | 48 px | |
| Input | Press **E** | |

**YOUR ANSWER (ok to write “defaults”):**

---

### DEC-09 — Mate timing

| Option | Behavior |
|--------|----------|
| **A** | **Instant son** on successful E press (prototype). |
| **B** | **Gestation timer** (e.g. 60s) — son spawns later. |
| **C** | **Return to den** to birth. |

**YOUR ANSWER:**

---

### DEC-10 — Partner genetics in prototype

**Blocks:** STEP-11 (partner presets)

| Option | Behavior |
|--------|----------|
| **A** | **One partner type** — `forest_wolf` genes baked in. |
| **B** | **Two partner types** — different `branch_weights` (more authoring). |
| **C** | **Random partner genes** each run. |

**YOUR ANSWER:**

---

### DEC-11 — Does `partner_genes.stat_bias` matter in v1?

| Option | Behavior |
|--------|----------|
| **A** | **No** — only `branch_weights` affect evolution roll (simpler). |
| **B** | **Yes** — also multiply son base stats at birth. |

**YOUR ANSWER:**

---

## §C — Survival & world (🟡 STEP-03–06)

### DEC-12 — How do you consume food and water?

| Option | Behavior |
|--------|----------|
| **A** | **Auto on overlap** (plan default). |
| **B** | **Press E** at resource. |
| **C** | **Auto eat / manual drink** (split). |

**YOUR ANSWER:**

---

### DEC-13 — Are resources finite or respawning?

| Option | Behavior |
|--------|----------|
| **A** | **Infinite** — carcass/puddle never depletes (prototype). |
| **B** | **Finite** — each node one use, respawn after N seconds. |
| **C** | **Finite, no respawn** — must find next node (harder). |

**YOUR ANSWER:**

---

### DEC-14 — What kills the wolf in the prototype?

Check all that apply for v1:

- [ ] Starvation (hunger → 0)
- [ ] Dehydration (thirst → 0)
- [ ] Combat / predators (out of scope unless checked)
- [ ] Debug key only for testing

**YOUR ANSWER:**

---

### DEC-15 — Target time until critical needs (tuning)

**Blocks:** STEP-03 balancing

Rough target from spawn until hunger/thirst hit “critical” (25%) with no eating:

| | Plan default | Your target |
|---|--------------|-------------|
| Hunger | ~67 seconds | |
| Thirst | ~50 seconds | |

**YOUR ANSWER (ok to write “defaults”):**

---

## §D — Evolution tree design (🟡 STEP-11)

### DEC-16 — Approve example tree or replace?

Plan proposes 7 nodes: `wolf_base` → `keen_nose` / `long_legs` → … → `ancient_wolf`.

| Option | Behavior |
|--------|----------|
| **A** | **Approve as-is** — agents implement §5 of PROTOTYPE_PLAN.md |
| **B** | **Approve structure, I’ll rename/flavor** — provide names later |
| **C** | **I’ll provide custom tree** — paste table before STEP-11 |

**YOUR ANSWER:**

---

### DEC-17 — Tree shape

| Option | Behavior |
|--------|----------|
| **A** | **Branching DAG** — choices matter (plan). |
| **B** | **Single linear path** — no partner influence needed |
| **C** | **Wide shallow tree** — many tier-1 traits, few merges |

**YOUR ANSWER:**

---

### DEC-18 — Should partner influence be visible to the player?

| Option | Behavior |
|--------|----------|
| **A** | **Hidden** — players learn by experimenting |
| **B** | **Show partner tags** in UI (“Forest blood: favors Keen Nose”) |
| **C** | **Show on death** — evolution screen shows weights |

**YOUR ANSWER:**

---

## §E — Presentation & session (🟢 defaults ok)

### DEC-19 — Game over vs “lineage complete”

| Option | Behavior |
|--------|----------|
| **A** | **Same screen** — “Lineage ended: no heir” |
| **B** | **Different screens** for no heir vs voluntary end |
| **C** | **Stats summary** — generations reached, traits unlocked |

**YOUR ANSWER:**

---

### DEC-20 — Restart behavior

| Option | Behavior |
|--------|----------|
| **A** | **Full reset** — generation 0, tree at `wolf_base` (prototype). |
| **B** | **Meta unlocks persist** (needs meta system — not in prototype). |

**YOUR ANSWER:**

---

### DEC-21 — Camera / map scope

| Option | Behavior |
|--------|----------|
| **A** | **Single small arena** — current `world.tscn` grid |
| **B** | **Larger map** — agents expand `ground_grid` extent |
| **C** | **Procedural map** — defer to post-prototype |

**YOUR ANSWER:**

---

## §F — Controls (🟢 confirm keys)

| Action | Default | Your key |
|--------|---------|----------|
| Move | WASD + arrows | |
| Interact (mate) | E | |
| Debug kill | K | |
| Debug mate | M | |
| Debug refill | R | |

**YOUR ANSWER (ok to write “defaults”):**

---

## Decision → step unblock map

| Decision | Unblocks |
|----------|----------|
| DEC-01, 02, 03, 04, 05 | STEP-08–10, 12–14 (succession rules) |
| DEC-06 | STEP-12 (edge case) |
| DEC-07–11 | STEP-08, 11–12 (partner & genetics) |
| DEC-12–15 | STEP-03, 06 (needs & resources) |
| DEC-16–18 | STEP-11–13 (tree & UI) |
| DEC-19–21 | STEP-14, 16 (polish) |

**Agents may start STEP-01–07** using recommended defaults while you decide §A–§C.

---

## After you answer

1. Fill answers in this file.
2. Message: *“Decisions locked — see DESIGN_DECISIONS.md”*
3. Agents copy final rules into `docs/GAME_CONCEPT.md` during STEP-16.
