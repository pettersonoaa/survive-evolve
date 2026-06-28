# Game concept

**Title:** Survive now, evolve if you can  
**Genre:** 2.5D roguelike / lineage survivor  
**Visual reference:** [Romestead](https://store.steampowered.com/app/2660460/Romestead/) — top-down pixel world with depth, not flat isometric tiles

## Core fantasy

You are a wolf building a bloodline in a hostile open map. Survival is immediate—hunger, thirst, and predators never pause. Evolution happens through **mating**: each partner biases which trait your pups inherit. Death is not the end if you left living heirs; it is the end if you did not.

## Pillars

1. **Survive now** — movement, pack needs, predators, hunt loop
2. **Evolve if you can** — mate-time rolls on a branching 34-node tree; partner blood matters
3. **Lineage pressure** — you must produce heirs before you die, or the run ends
4. **2.5D clarity** — Y-sorted depth, readable silhouettes (Romestead-style readability)

## Implemented loop (prototype)

| Phase | Player experience |
|-------|-------------------|
| Explore | Large map, biomes, scattered resources, deer to hunt |
| Mate | Find wandering partners (4 bloodlines); parallel gestations (one per partner) |
| Birth | 30s gestation → 1–3 pups beside mother, colored by bloodline |
| Pack | Feed partners + dependent pups together; Pack HUD shows their needs |
| Growth | Pups age → leave pack → self-sufficient → may turn rogue (hostile, still heirs) |
| Succession | Die → pick an heir (pup, young wolf, or rogue) → continue lineage |
| Meta | Lineage Codex + **LineageMeta** tiers (Scout/Hunter/Alpha bonuses) |
| Combat | Auto-bite in range + **E** for explicit interact |

Full rules: `DESIGN_DECISIONS.md`. Implementation tracker: `PROTOTYPE_STATUS.md`.

## Rendering stance

We match Romestead’s **player-facing goals** in Godot:

- Top-down camera
- Pixel art with consistent perspective
- Entities sort by ground position (feet), not sprite center
- Props and creatures occlude each other naturally

See `RENDERING_25D.md` and `ART_PIPELINE.md`.

## Open questions (future)

- More species / biomes (forest/plains zones)
- Session length reward tuning beyond HUD phases
