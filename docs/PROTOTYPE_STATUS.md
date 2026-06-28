# Prototype status

| Step | Done | Date | Notes |
|------|------|------|-------|
| STEP-01 | yes | 2026-06-27 | EventBus, GameState, EvolutionRegistry autoloads |
| STEP-02 | yes | 2026-06-27 | WolfStats, WolfGenes, EvolutionNode, EvolutionTree, LineageRecord |
| STEP-03 | yes | 2026-06-27 | NeedsComponent |
| STEP-04–05 | yes | 2026-06-27 | Wolf + PlayerWolf |
| STEP-06 | yes | 2026-06-27 | Finite water/food, E interact |
| STEP-07 | yes | 2026-06-27 | NeedsHUD |
| STEP-08–09 | yes | 2026-06-27 | 3 partners, gestation, SonWolf, multiple heirs |
| STEP-10 | yes | 2026-06-27 | RunManager + heir picker |
| STEP-11–12 | yes | 2026-06-27 | 34-node tree + mate-time evolution |
| STEP-13–14 | yes | 2026-06-27 | LineageHUD + game over / victory |
| STEP-15 | yes | 2026-06-27 | Debug overlay K/M/R |
| Combat | yes | 2026-06-27 | PredatorWolf ×2 |
| Polish pass | yes | 2026-06-27 | UX: interact hints, toasts, health bar, pause on modals, gestation fix |
| Bugfix pass | yes | 2026-06-27 | player_wolf reset race, mate range, HUD bars, heir needs, predator targets heirs |
| STEP-20 | yes | 2026-06-27 | Procedural wolf Sprite2D via WolfSpriteFactory |
| STEP-21 | yes | 2026-06-27 | Wandering deer prey, E to hunt, carcass on kill |
| STEP-22 | yes | 2026-06-27 | Wolf den safe zone, heirs spawn and rest at den |
| STEP-23 | yes | 2026-06-27 | JSON save/load lineage, player stats, heirs, gestation |
| STEP-24 | yes | 2026-06-27 | Tundra + Desert biome zones, Desert blood partner |
| STEP-25 | yes | 2026-06-27 | Main menu: Continue / New lineage |
| STEP-26 | yes | 2026-06-27 | Map extent 48 (DEC-21), game over returns to menu |

## Agent review (post-polish estimated)

| Area | Before | After |
|------|--------|-------|
| Gameplay / design | 7/10 | ~8.5/10 |
| UX / feedback | 5/10 | ~8/10 |
| Technical stability | 6/10 | ~8/10 |

## Playtest loop

1. WASD — move grey wolf
2. E at blue water / brown carcass — refill needs (one use each)
3. E on deer — hunt (bite until kill), then E on dropped carcass to eat
4. Find wandering partner (forest grey, plains brown, tundra white)
5. E to mate — 30s gestation, trait rolled
6. Son spawns at den — safe from predators while inside; slow needs drain
7. K debug or predators/needs — die → pick heir or game over
8. Apex death with heir → lineage complete
