# Wolf Prototype — Agent Implementation Plan

**Game:** Survive now, evolve if you can  
**Repo root:** `E:\projects\survive-evolve`  
**Engine:** Godot 4.3+ (GDScript)  
**Rendering:** Romestead-like 2.5D — see `docs/RENDERING_25D.md`  
**Species (prototype):** Wolf  

---

## 0. How agents must use this document

### Conventions

| Tag | Meaning |
|-----|---------|
| **STEP-XX** | Atomic task. Do not skip. Complete acceptance criteria before next step. |
| **BLOCKED_BY** | Prerequisite step IDs |
| **TOUCHES** | Files you may create or edit |
| **DO_NOT** | Out of scope for this step |
| **VERIFY** | How to prove the step is done (F5 in Godot + observable behavior) |

### Rules for every agent

1. Read `docs/RENDERING_25D.md` before adding any visible entity — all creatures/props extend `Entity25D`.
2. One step = one focused PR-sized change. Do not implement future steps early.
3. After each step: run project (F5), confirm **VERIFY** section passes, update `docs/PROTOTYPE_STATUS.md` with step ID + date.
4. Use **signals** for cross-system events (death, mate, evolve, game over). Do not hard-wire scene paths across systems.
5. Placeholder art only (`Polygon2D` / colored rects) until STEP-20.

### Target player fantasy (prototype)

```
Survive hunger/thirst → find mate → produce son → die → evolution tree advances → play as son
                                                                              ↘ no son = GAME OVER
```

Evolution is the **roguelike progression**: each death is a run boundary; the son continues with mutated stats/traits drawn from **your evolution tree** + **partner genetics**.

---

## 1. Architecture overview

```
┌─────────────────────────────────────────────────────────────┐
│  Autoloads                                                  │
│  EventBus · GameState · EvolutionRegistry                   │
└─────────────────────────────────────────────────────────────┘
         │ signals                    │ reads/writes
         ▼                            ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐
│  RunManager     │───▶│  LineageManager  │───▶│ Evolution   │
│  (death/succ.)  │    │  (partner/son)   │    │ Resolver    │
└─────────────────┘    └──────────────────┘    └─────────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────────────────────────┐
│  world.tscn                                                 │
│  Ground · YSort · PlayerWolf · PartnerWolf? · SonWolf?      │
│  Resources: WaterSource, FoodCarcass                          │
│  UI: NeedsHUD · LineageHUD · EvolutionPopup · GameOverScreen │
└─────────────────────────────────────────────────────────────┘
```

### Folder layout (create as needed)

```
scripts/
  autoload/          # EventBus, GameState, EvolutionRegistry
  components/        # NeedsComponent, GeneticsComponent, WolfStats
  creatures/         # wolf.gd, partner_wolf.gd, son_wolf.gd
  systems/           # run_manager, lineage_manager, evolution_resolver
  resources/         # evolution_node.gd, evolution_tree.gd, wolf_genes.gd
  ui/                # HUD scripts
data/
  evolution/
    wolf_tree.tres   # authored evolution DAG for wolves
scenes/
  creatures/
  resources/
  ui/
```

---

## 2. Core data model (reference for all steps)

Agents must implement these types exactly (names may be prefixed but shapes must match).

### 2.1 `NeedsComponent` (Node)

```gdscript
# Exported or @onready on wolf
var hunger: float = 100.0   # 0 = starving
var thirst: float = 100.0   # 0 = dehydrating
var hunger_decay_per_sec: float = 1.5
var thirst_decay_per_sec: float = 2.0
var starve_damage_per_sec: float = 5.0   # when hunger==0
var dehydrate_damage_per_sec: float = 8.0 # when thirst==0
```

### 2.2 `WolfStats` (Resource)

```gdscript
class_name WolfStats
extends Resource
@export var max_health: float = 100.0
@export var move_speed: float = 220.0
@export var bite_damage: float = 10.0
@export var metabolism: float = 1.0      # multiplies need decay
```

### 2.3 `WolfGenes` (Resource) — partner contribution

```gdscript
class_name WolfGenes
extends Resource
@export var branch_weights: Dictionary = {}  # evolution_node_id -> float weight
@export var stat_bias: Dictionary = {}         # e.g. {"move_speed": 1.1}
```

### 2.4 `EvolutionNode` (Resource)

```gdscript
class_name EvolutionNode
extends Resource
@export var id: String
@export var display_name: String
@export var description: String
@export var stat_deltas: Dictionary = {}           # applied to son WolfStats
@export var child_ids: Array[String] = []          # possible next nodes
@export var child_base_weights: Dictionary = {}    # child_id -> weight
```

### 2.5 `EvolutionTree` (Resource)

```gdscript
class_name EvolutionTree
extends Resource
@export var species_id: String = "wolf"
@export var root_node_id: String
@export var nodes: Dictionary = {}  # id -> EvolutionNode
```

### 2.6 `LineageRecord` (plain class or Resource)

```gdscript
var generation: int = 0
var current_node_id: String          # position on evolution tree
var partner_genes: WolfGenes = null  # last mate (persists for death roll)
var living_son: NodePath = NodePath() # path to SonWolf in tree, empty if none
var is_game_over: bool = false
```

---

## 3. EventBus signals (implement in STEP-01)

```gdscript
# scripts/autoload/event_bus.gd
signal wolf_died(wolf: Node, cause: String)
signal wolf_needs_critical(wolf: Node, need: String)  # "hunger" | "thirst"
signal mate_completed(partner: Node, son: Node)
signal evolution_applied(generation: int, node_id: String, son: Node)
signal succession_started(from_wolf: Node, to_wolf: Node)
signal game_over(reason: String)
signal consume_food(wolf: Node, amount: float)
signal consume_water(wolf: Node, amount: float)
```

---

## 4. Evolution on death — algorithm (implement in STEP-12)

**Input:** `LineageRecord`, `EvolutionTree`, optional `partner_genes`  
**Output:** `next_node_id: String`, updated `WolfStats` for son  

```
1. current = lineage.current_node_id
2. node = tree.nodes[current]
3. candidates = node.child_ids
4. if candidates.is_empty(): stay at current (or roll root children — document choice)
5. For each child_id in candidates:
     weight = node.child_base_weights.get(child_id, 1.0)
     weight *= partner_genes.branch_weights.get(child_id, 1.0) if partner_genes else 1.0
6. Pick child_id via weighted random
7. Apply tree.nodes[child_id].stat_deltas to son base stats
8. lineage.current_node_id = child_id
9. lineage.generation += 1
10. Emit evolution_applied
```

**Son requirement:** If `lineage.living_son` is invalid/null at death → `game_over("no_heir")`.

---

## 5. Wolf evolution tree content (author in STEP-11)

Minimum **7 nodes** for prototype. Store in `data/evolution/wolf_tree.tres`.

| id | name | stat_deltas (example) | children |
|----|------|----------------------|----------|
| `wolf_base` | Grey Wolf | `{}` | `keen_nose`, `long_legs` |
| `keen_nose` | Keen Nose | `{"hunger_decay": -0.1}` | `pack_hunter` |
| `long_legs` | Long Legs | `{"move_speed": 30}` | `sprinter` |
| `pack_hunter` | Pack Hunter | `{"bite_damage": 5}` | `alpha_instinct` |
| `sprinter` | Sprinter | `{"move_speed": 20, "metabolism": 1.2}` | `alpha_instinct` |
| `alpha_instinct` | Alpha Instinct | `{"max_health": 25}` | `ancient_wolf` |
| `ancient_wolf` | Ancient Wolf | `{"max_health": 40, "bite_damage": 10}` | `[]` |

Partner genes example: mate with `forest_wolf` preset → `branch_weights = {"keen_nose": 2.0, "long_legs": 0.5}`.

---

## 6. Step-by-step implementation

---

### STEP-01 — Autoload skeleton + status doc

**BLOCKED_BY:** none  
**TOUCHES:**
- `scripts/autoload/event_bus.gd` (new)
- `scripts/autoload/game_state.gd` (new)
- `project.godot` (register autoloads)
- `docs/PROTOTYPE_STATUS.md` (new)

**Tasks:**
1. Create `EventBus` with all signals from §3.
2. Create `GameState` holding one `LineageRecord` instance, reset on new game.
3. Register autoloads: `EventBus`, `GameState`.

**VERIFY:**
- F5 runs without errors.
- Debugger: `GameState.lineage.generation == 0`.

**DO_NOT:** gameplay logic.

---

### STEP-02 — Resource scripts (data types)

**BLOCKED_BY:** STEP-01  
**TOUCHES:**
- `scripts/resources/wolf_stats.gd`
- `scripts/resources/wolf_genes.gd`
- `scripts/resources/evolution_node.gd`
- `scripts/resources/evolution_tree.gd`
- `scripts/lineage/lineage_record.gd`

**Tasks:**
1. Implement all classes from §2 with `class_name` registered.
2. `LineageRecord` as `RefCounted` or `Resource` with fields from §2.6.

**VERIFY:**
- Godot **Project → Tools → Orphan Resource Picker** shows no script errors.
- Create a temp scene script that instantiates `WolfStats.new()` — no crash.

---

### STEP-03 — `NeedsComponent`

**BLOCKED_BY:** STEP-02  
**TOUCHES:**
- `scripts/components/needs_component.gd`

**Tasks:**
1. `class_name NeedsComponent`, extends `Node`.
2. `_process(delta)`: decay hunger/thirst by rates × wolf metabolism.
3. When hunger ≤ 0 or thirst ≤ 0, emit damage via method `get_passive_damage() -> float` for parent to apply to health.
4. Methods: `eat(amount)`, `drink(amount)`, `is_starving()`, `is_dehydrated()`.
5. Emit `EventBus.wolf_needs_critical` once when crossing below 25%.

**VERIFY:**
- Unit-style: attach to any Node2D in test scene, watch exported vars tick down in inspector.

---

### STEP-04 — `Wolf` base creature

**BLOCKED_BY:** STEP-02, STEP-03  
**TOUCHES:**
- `scripts/creatures/wolf.gd`
- `scenes/creatures/wolf.tscn` (inherits `entity_25d.tscn`)

**Tasks:**
1. `Wolf extends Entity25D`.
2. Child nodes: `NeedsComponent`, `Health` (simple `var health: float` in script ok).
3. Export `WolfStats stats: WolfStats`.
4. `_process`: apply passive damage from needs; if health ≤ 0 → `EventBus.wolf_died.emit(self, cause)`.
5. Movement: copy from `player.gd` but use `stats.move_speed`.
6. `is_player_controlled: bool` — only player wolf reads input.
7. Body color default: grey `Color(0.55, 0.55, 0.58)`.

**VERIFY:**
- Instance wolf in empty scene; health drops when hunger/thirst hit 0.
- Death emits signal (print connected in temp script).

**DO_NOT:** replace `player.tscn` yet.

---

### STEP-05 — Player wolf swap

**BLOCKED_BY:** STEP-04  
**TOUCHES:**
- `scripts/creatures/player_wolf.gd` (extends Wolf)
- `scenes/creatures/player_wolf.tscn`
- `scenes/world.tscn` (replace Player with PlayerWolf)
- `scenes/player.tscn` (deprecate or delete — agent choice, update refs)

**Tasks:**
1. `PlayerWolf` sets `is_player_controlled = true` in `_ready`.
2. Wire camera `target_path` to PlayerWolf.
3. Initialize `GameState.lineage.current_node_id = "wolf_base"`.

**VERIFY:**
- F5: WASD moves grey wolf placeholder in `world.tscn`.
- Needs decay over time.

---

### STEP-06 — World resources: water + food

**BLOCKED_BY:** STEP-04  
**TOUCHES:**
- `scripts/resources/world/water_source.gd` + `scenes/resources/water_source.tscn`
- `scripts/resources/world/food_carcass.gd` + `scenes/resources/food_carcass.tscn`
- `scenes/world.tscn` (place 2 water, 3 carcass nodes)

**Tasks:**
1. `WaterSource extends Area2D` — on `body_entered`, if body is Wolf: `wolf.needs.drink(40)`, emit `consume_water`, one-time or cooldown 2s.
2. `FoodCarcass extends Area2D` — same pattern, `eat(35)`.
3. Visual: flat `Polygon2D` (blue puddle, red/brown carcass), y-sort as child of YSort OR static prop on YSort.

**VERIFY:**
- Walk wolf into water → thirst increases.
- Walk into carcass → hunger increases.

---

### STEP-07 — Needs HUD

**BLOCKED_BY:** STEP-05  
**TOUCHES:**
- `scripts/ui/needs_hud.gd`
- `scenes/ui/needs_hud.tscn`
- `scenes/world.tscn` (instance HUD)

**Tasks:**
1. Two `ProgressBar`s: Hunger, Thirst.
2. Bind to current player wolf's `NeedsComponent` via `GameState.get_player_wolf()`.
3. Add helper on `GameState`: `var player_wolf: Wolf` set on succession.

**VERIFY:**
- Bars drain in real time; eating/drinking updates bars.

---

### STEP-08 — `LineageManager` + partner wolf

**BLOCKED_BY:** STEP-05, STEP-01  
**TOUCHES:**
- `scripts/systems/lineage_manager.gd`
- `scripts/creatures/partner_wolf.gd`
- `scenes/creatures/partner_wolf.tscn`
- `scenes/world.tscn`

**Tasks:**
1. `LineageManager` (Node in world): listens for mate flow.
2. `PartnerWolf extends Wolf` — `is_player_controlled = false`, wander AI (random direction every 2–4s).
3. Export `partner_genes: WolfGenes` preset on partner instance.
4. Place 1 partner in world away from spawn.
5. **Mate interaction:** when player within 48px, partner fed (hunger>50) and player fed, press **`E`** (`interact` input action — add to project.godot):
   - Spawn `SonWolf` at partner position.
   - Store `GameState.lineage.partner_genes = partner.genes`.
   - Store son `NodePath` in lineage.
   - Emit `mate_completed`.

**VERIFY:**
- Approach partner with food/water needs met, press E → son appears.
- Son visible as smaller wolf (body_size × 0.7).

---

### STEP-09 — `SonWolf` (NPC heir)

**BLOCKED_BY:** STEP-08  
**TOUCHES:**
- `scripts/creatures/son_wolf.gd`
- `scenes/creatures/son_wolf.tscn`

**Tasks:**
1. `SonWolf extends Wolf` — follows player at distance 60–100px (simple follow steering).
2. Cannot mate in prototype.
3. Does not decay needs faster than adult (same rates ok for v1).
4. Tagged `is_heir = true` for RunManager lookup.

**VERIFY:**
- After mating, son follows player around map.

---

### STEP-10 — `RunManager` death + succession

**BLOCKED_BY:** STEP-08, STEP-09, STEP-01  
**TOUCHES:**
- `scripts/systems/run_manager.gd`
- `scenes/world.tscn` (add RunManager node)

**Tasks:**
1. Listen `EventBus.wolf_died`.
2. If dead wolf is **not** current player → ignore (future: pack members).
3. If dead wolf **is** player:
   - If `lineage.living_son` valid → call succession (STEP-12 applies evolution first if STEP-12 done; else stub).
   - Else → `EventBus.game_over.emit("no_heir")`.
4. **Succession (stub before evolution):**
   - `son.is_player_controlled = true`
   - `GameState.player_wolf = son`
   - Disable old wolf (queue_free or ghost)
   - Camera retarget
   - Emit `succession_started`

**VERIFY:**
- Mate → kill player wolf (debug key `K` to deal 999 damage ok) → control transfers to son.
- Mate skipped → die → game over screen or print.

---

### STEP-11 — Author wolf evolution tree asset

**BLOCKED_BY:** STEP-02  
**TOUCHES:**
- `data/evolution/wolf_tree.tres`
- `scripts/autoload/evolution_registry.gd` (new autoload)
- `project.godot`

**Tasks:**
1. Build `EvolutionTree` resource with nodes from §5.
2. `EvolutionRegistry.get_tree("wolf")` returns wolf tree.

**VERIFY:**
- Inspector shows 7 linked nodes on resource.
- `EvolutionRegistry.get_tree("wolf").nodes.size() == 7`.

---

### STEP-12 — `EvolutionResolver` on death

**BLOCKED_BY:** STEP-10, STEP-11  
**TOUCHES:**
- `scripts/systems/evolution_resolver.gd`
- `scripts/systems/run_manager.gd` (call resolver before succession)

**Tasks:**
1. Implement algorithm from §4 exactly.
2. Apply resulting `stat_deltas` to son's `WolfStats` (duplicate resource before mutating).
3. Update `lineage.current_node_id` and `generation`.
4. Emit `evolution_applied`.

**VERIFY:**
- Die twice with same partner → generation increments; son stats change.
- Print/log shows which node was rolled.

---

### STEP-13 — Evolution + lineage HUD

**BLOCKED_BY:** STEP-12  
**TOUCHES:**
- `scripts/ui/lineage_hud.gd`
- `scenes/ui/lineage_hud.tscn`
- `scenes/world.tscn`

**Tasks:**
1. Show: `Gen: N`, `Trait: <display_name>`, `Heir: Yes/No`.
2. On `evolution_applied`, flash trait name 2s.

**VERIFY:**
- HUD updates after death succession.

---

### STEP-14 — Game over + restart flow

**BLOCKED_BY:** STEP-10  
**TOUCHES:**
- `scripts/ui/game_over_screen.gd`
- `scenes/ui/game_over_screen.tscn`
- `scripts/systems/run_manager.gd`

**Tasks:**
1. Listen `game_over`.
2. Show reason text (`no_heir`, etc.).
3. Button **Restart Run**: reload `world.tscn`, reset `GameState`.

**VERIFY:**
- Die without son → overlay → Restart works.

---

### STEP-15 — Debug tools (dev only)

**BLOCKED_BY:** STEP-10  
**TOUCHES:**
- `scripts/debug/debug_overlay.gd`
- `project.godot` (`debug/enable` config or always-on for prototype)

**Tasks:**
1. Keys: `K` kill player, `M` force mate, `R` refill needs.
2. Only active when `OS.is_debug_build()` or export var.

**VERIFY:**
- Debug keys work in F5 from editor.

---

### STEP-16 — Integration pass + doc update

**BLOCKED_BY:** STEP-01 through STEP-15  
**TOUCHES:**
- `docs/GAME_CONCEPT.md`
- `README.md`
- `docs/PROTOTYPE_STATUS.md`

**Tasks:**
1. Rewrite `GAME_CONCEPT.md` with wolf lineage loop (replace old survivor bullets).
2. README: controls table (`WASD`, `E`, debug keys).
3. Full playthrough checklist in `PROTOTYPE_STATUS.md`.

**VERIFY — full prototype loop:**
1. Spawn as wolf. Needs drain.
2. Eat/drink from world.
3. Mate with partner (E) → son spawns.
4. Die → evolution rolls → play as son with new trait.
5. Die without prior mate → game over.

---

## 7. Input actions (add when step requires)

| Action | Key | Step |
|--------|-----|------|
| `move_up/down/left/right` | WASD + arrows | exists |
| `interact` | E | STEP-08 |
| `debug_kill` | K | STEP-15 |
| `debug_mate` | M | STEP-15 |
| `debug_refill` | R | STEP-15 |

---

## 8. Scene instance map (final `world.tscn`)

```
World (world_25d.gd)
├── Ground
├── YSort
│   ├── PlayerWolf
│   ├── PartnerWolf
│   ├── SonWolf          # hidden until mate
│   ├── WaterSource ×2
│   ├── FoodCarcass ×3
│   └── (existing props optional)
├── Camera2D
├── RunManager
├── LineageManager
├── UI
│   ├── NeedsHUD
│   ├── LineageHUD
│   └── GameOverScreen
└── DebugOverlay (optional)
```

---

## 9. Out of scope for prototype (DO NOT BUILD)

- Multiplayer
- More than one playable species
- Full procedural terrain generation (scatter only)
- Real authored sprite art required (atlas drop-in supported)

**Note:** Items once listed here but now shipped: combat/predators, pack mechanics, day/night, save/load, main menu, resource respawn, procedural scatter on New Lineage.

---

## 10. Completed step index (historical)

Steps STEP-01–16 (core), STEP-20–31 (content/polish), STEP-32–35 (Phase 3 meta), STEP-36–38 (pack + lifecycle). See `PROTOTYPE_STATUS.md` for dates and notes.

---

## 12. Phase 3 — meta progression & run variety

| ID | Summary |
|----|---------|
| STEP-32 | `WorldGenerator` — scatter resources, prey, partners, predators, props on **New Lineage** (seed in `GameState.run_seed`; skip on Continue) |
| STEP-33 | `LineageCodex` autoload — record traits on evolve / game over; **Lineage Codex** panel on main menu |
| STEP-34 | `DifficultyScaler` — predator contact damage + chase speed scale with `lineage.generation`; player needs decay scales slightly |
| STEP-35 | Threat tier label on `LineageHUD` (Calm / Tense / Harsh / Deadly) |

### STEP-32 VERIFY

1. Main menu → **New Lineage** — resource/partner positions differ from default editor layout.
2. **Continue** after save — world layout unchanged.

### STEP-33 VERIFY

1. Mate once — codex count increases on main menu.
2. Codex panel lists discovered trait names.

### STEP-34 VERIFY

1. After several generations, predators deal more damage and move faster (observe HUD threat tier + combat).

---

## 13. Phase 4 — pack & pup lifecycle

| ID | Summary |
|----|---------|
| STEP-36 | `PackNeedsManager` + `PackHUD` — shared feeding for player + partners + **dependent pups**; pack-size difficulty scaling |
| STEP-37 | Litters **1–3** per gestation; **each pup rolls trait at birth**; spawn cluster beside mother |
| STEP-38 | `SonWolf` lifecycle: **Pup** (60s) → **Young wolf** (independent, self-feeds) → **Rogue** (+90s, hostile, still genetic heir) |

### STEP-36 VERIFY

1. Mate → Pack HUD shows partner + pup hunger/thirst.
2. Player eats → pack bars rise together (dependent pups only).

### STEP-37 VERIFY

1. Mate several times — birth toast may show 2–3 pups.
2. Pups spawn next to gestating partner, not at den.

### STEP-38 VERIFY

1. Wait ~60s after birth — toast: pup left the pack; removed from Pack HUD.
2. Wait ~90s more — rogue toast; pup attacks; still appears in heir picker on death.

---

## 14. Phase 4b — polish before meta expansion

| ID | Summary |
|----|---------|
| STEP-39 | Balance pass — `docs/BALANCE.md`, tuned predator counts, needs decay, lifecycle timers |
| STEP-40 | `assets/sprites/wolf/wolf_sheet.png` — 8-frame strip via `generate_wolf_sheet.gd` |
| STEP-41 | `Minimap` HUD (entities + territory ring) + pup lifecycle badges on `SonWolf` |
| STEP-42 | Hare prey type, `SeasonManager` (120s cycle), `TerritoryManager` (den radius 320px) |

### STEP-39 VERIFY

1. New lineage — fewer early predators (base 5); pack growth raises pressure gradually.
2. Winter season toast — needs drain faster than spring.

### STEP-40 VERIFY

1. `wolf_sheet.png` exists; wolves use sheet atlas (not single-frame procedural).

### STEP-41 VERIFY

1. Minimap bottom-right shows player, partners, pups, prey, predators.
2. Pups display **Pup** / **Young** / **Rogue** label above sprite.

### STEP-42 VERIFY

1. Hunt hares — faster, smaller, less food than deer.
2. Stand near den — needs decay slower; predators chase slower inside territory ring.

---

## 15. Phase 5 — meta expansion

| ID | Summary |
|----|---------|
| STEP-43 | `LineageMeta` autoload — persist runs started/failed/won, best generation (`user://lineage_meta.json`) |
| STEP-44 | Run summary on game over / victory — meta stats panel |
| STEP-45 | Meta milestones — Scout (5 traits), Hunter (12), Alpha (20): starting refill + needs decay bonus on New Lineage |
| STEP-46 | Codex v2 — branch sections (Senses / Mobility / …) with `???` for undiscovered traits |

### STEP-43 VERIFY

1. Play New Lineage twice — main menu shows runs started ≥ 2.
2. Fail a run — `runs_failed` increments on next game over screen.

### STEP-44 VERIFY

1. Game over or apex victory — meta block shows best generation and run counts.

### STEP-45 VERIFY

1. With ≥5 codex traits, New Lineage toast shows tier bonus refill.
2. Player needs decay slightly lower at Hunter/Alpha tiers.

### STEP-46 VERIFY

1. Codex panel groups traits by branch; undiscovered show as `???`.

---

## 16. Phase 6 — combat, biomes & session

| ID | Summary |
|----|---------|
| STEP-47 | Pack feeding scope — only **gestating** partners + partners **with dependent pups** share player meals; wandering partners self-feed; each pup rolls trait **at birth** |
| STEP-48 | Hybrid combat — player **auto-bites** nearest predator/rogue/prey in range (cooldown); **E** still prioritizes context interact |
| STEP-49 | Biome needs — **Tundra** +hunger, **Desert** +thirst while inside biome zones |
| STEP-50 | Run session HUD — elapsed time + Early/Mid/Late phase; persisted in save |

### STEP-47 VERIFY

1. Mate once — partner appears in Pack HUD during gestation; disappears after pups independent (if no other gestation).
2. Litter of 2+ may show different trait names in birth toast.

### STEP-48 VERIFY

1. Walk into prey/predator range without pressing E — bites fire on cooldown.
2. Press E near food still eats (not blocked by auto-bite).

### STEP-49 VERIFY

1. Enter Desert — thirst drains faster (toast on enter).
2. Enter Tundra — hunger drains slightly faster.

### STEP-50 VERIFY

1. Lineage HUD shows `Run: Xm YYs (Early/Mid/Late)`.
2. Continue after save — timer restores.

---

## 17. Phase 7 — world depth & presentation

| ID | Summary |
|----|---------|
| STEP-51 | **Forest** + **Plains** biome zones with needs modifiers |
| STEP-52 | Session phase **meta rewards** — Mid/Late in-run refill + New Lineage bonus |
| STEP-53 | Mate **evolution preview** in interact hint (top 3 likely traits) |
| STEP-54 | **Prey** + **partner** sprite sheet pipeline (`prey_sheet.png`, `partner_sheet.png`) |

### STEP-51 VERIFY

1. Enter Forest — slightly lower hunger decay; Plains — lower thirst.
2. Four biome toasts: Forest, Plains, Tundra, Desert.

### STEP-52 VERIFY

1. Survive 8+ min — Mid toast + needs bonus; meta tracks mid runs.
2. New Lineage after mid run — extra starting refill.

### STEP-53 VERIFY

1. Approach partner — hint shows `[E] Mate Forest blood → Keen Nose, …`.

### STEP-54 VERIFY

1. `prey_sheet.png` and `partner_sheet.png` exist under `assets/sprites/`.
2. Deer/hare use prey atlas; partners use partner atlas.

---

## 11. `PROTOTYPE_STATUS.md` template

Agents append after each step:

```markdown
| Step | Done | Date | Agent notes |
|------|------|------|-------------|
| STEP-01 | yes | 2026-06-26 | autoloads ok |
```

Create this file in STEP-01.
