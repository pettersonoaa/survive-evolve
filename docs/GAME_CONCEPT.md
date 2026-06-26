# Game concept

**Title:** Survive now, evolve if you can  
**Genre:** 2.5D roguelike / survivor  
**Visual reference:** [Romestead](https://store.steampowered.com/app/2660460/Romestead/) — top-down pixel world with depth, not flat isometric tiles

## Core fantasy

You are a fragile organism in a hostile biome. Survival is the default; evolution is optional, risky, and often irreversible for the run.

## Pillars

1. **Survive now** — constant movement, readable threats, short feedback loops
2. **Evolve if you can** — mutations trade safety for power; not every upgrade is pure upside
3. **2.5D clarity** — Y-sorted depth, telegraphed attacks, readable enemy swarms (Romestead-style readability)

## Rendering stance

We are **not** building a custom Candide/MonoGame engine like Romestead. We are matching the **player-facing goals**:

- Top-down camera
- Pixel art with consistent perspective
- Entities sort by ground position (feet), not sprite center
- Props and hordes occlude each other naturally

See `RENDERING_25D.md` and `ART_PIPELINE.md`.

## Open questions

- Auto-attack vs aimed attacks (or hybrid)
- Meta progression between runs vs pure roguelike
- Single lineage vs unlockable forms
- Session length (15 / 30 / 45 min)
