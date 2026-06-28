# Prototype status

| Step | Done | Date | Notes |
|------|------|------|-------|
| STEP-01 | yes | 2026-06-27 | EventBus, GameState, EvolutionRegistry autoloads |
| STEP-02 | yes | 2026-06-27 | WolfStats, WolfGenes, EvolutionNode, EvolutionTree, LineageRecord |
| STEP-03 | yes | 2026-06-27 | NeedsComponent |
| STEP-04–05 | yes | 2026-06-27 | Wolf + PlayerWolf |
| STEP-06 | yes | 2026-06-27 | Finite water/food, E interact |
| STEP-07 | yes | 2026-06-27 | NeedsHUD |
| STEP-08–09 | yes | 2026-06-27 | Partners, gestation, SonWolf, multiple heirs |
| STEP-10 | yes | 2026-06-27 | RunManager + heir picker |
| STEP-11–12 | yes | 2026-06-27 | 34-node tree + mate-time evolution |
| STEP-13–14 | yes | 2026-06-27 | LineageHUD + game over / victory |
| STEP-15 | yes | 2026-06-27 | Debug overlay K/M/R |
| Combat | yes | 2026-06-27 | PredatorWolf ×6 base (scales to 10 with generation + pack) |
| Polish pass | yes | 2026-06-27 | UX: interact hints, toasts, health bar, pause on modals, gestation fix |
| Bugfix pass | yes | 2026-06-27 | player_wolf reset race, mate range, HUD bars, heir needs, predator targets heirs |
| STEP-20 | yes | 2026-06-27 | Procedural wolf Sprite2D via WolfSpriteFactory |
| STEP-21 | yes | 2026-06-27 | Wandering deer prey, E to hunt, carcass on kill |
| STEP-22 | yes | 2026-06-27 | Wolf den safe zone for dependent pups |
| STEP-23 | yes | 2026-06-28 | JSON save/load (v3): player, heirs, gestations, lifecycle |
| STEP-24 | yes | 2026-06-27 | Tundra + Desert biome zones, Desert blood partner |
| STEP-25 | yes | 2026-06-27 | Main menu: Continue / New lineage |
| STEP-26 | yes | 2026-06-27 | Map extent 48 (DEC-21), game over returns to menu |
| STEP-27 | yes | 2026-06-27 | Wolf sprite atlas pipeline + assets/sprites/wolf drop-in |
| STEP-28 | yes | 2026-06-27 | Idle/walk AnimatedSprite2D, flip on facing |
| STEP-29 | yes | 2026-06-27 | Food/water respawn after 90s |
| STEP-30 | yes | 2026-06-27 | Day/night CanvasModulate cycle (180s) |
| STEP-31 | yes | 2026-06-27 | Pack assist — heirs + gestation partner join bites |
| STEP-32 | yes | 2026-06-27 | Procedural world scatter on New Lineage (`WorldGenerator`) |
| STEP-33 | yes | 2026-06-27 | Lineage Codex — traits persist across runs, menu panel |
| STEP-34 | yes | 2026-06-27 | Generation-scaled predator damage/speed + player needs decay |
| STEP-35 | yes | 2026-06-27 | Threat tier HUD (Calm → Deadly) |
| STEP-36 | yes | 2026-06-28 | Pack survival: shared feeding, PackHUD, multi-gestation |
| STEP-37 | yes | 2026-06-28 | Litters 1–3 per gestation; birth beside mother |
| STEP-38 | yes | 2026-06-28 | Pup lifecycle: grow → independent → rogue heir |
| STEP-39 | yes | 2026-06-26 | Balance pass — `docs/BALANCE.md`, tuned `GameConstants` |
| STEP-40 | yes | 2026-06-26 | `wolf_sheet.png` generated (8-frame idle/walk strip) |
| STEP-41 | yes | 2026-06-26 | Minimap HUD + pup lifecycle badges (Pup / Young / Rogue) |
| STEP-42 | yes | 2026-06-26 | Hare prey, `SeasonManager`, `TerritoryManager` (den radius) |

## Agent review (post-pack estimated)

| Area | Before | After |
|------|--------|-------|
| Gameplay / design | ~8.5/10 | ~9/10 |
| UX / feedback | ~8/10 | ~8.5/10 |
| Technical stability | ~8/10 | ~8.5/10 |

## Playtest loop

1. **Main menu** — Continue saved lineage or New Lineage (procedural scatter).
2. **WASD** — move; **E** — eat, drink, hunt deer/hares, bite predators/rogue heirs, mate.
3. Find partners (forest / plains / tundra / desert blood) — mate with several in parallel (one gestation per partner).
4. **30s gestation** → **1–3 pups** born beside the mother; trait + bloodline color applied.
5. **Feed the pack** — E at food/water refills you + partners + **dependent pups** (Pack HUD).
6. **~60s** — pups grow and leave the pack; hunt alone (still genetic heirs).
7. **~90s later** — independent pups may turn **rogue** and attack; still selectable as heirs on death.
8. Den + **territory** (320px) eases needs and slows predators; **seasons** cycle every 120s.
9. **Minimap** (bottom-right) shows pack, prey, predators, and territory ring.
10. Die → heir picker (shows Pup / Young wolf / Rogue) → or game over without heirs.
11. Apex death with heir → lineage complete; **Lineage Codex** tracks traits across New Lineage runs.

## Doc authority

| File | Role |
|------|------|
| `DESIGN_DECISIONS.md` | Locked design truth |
| `PROTOTYPE_PLAN.md` | Step-by-step implementation history |
| `GAME_CONCEPT.md` | High-level fantasy + pillars |
