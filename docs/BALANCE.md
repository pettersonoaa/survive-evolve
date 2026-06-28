# Balance reference (STEP-39)

Tuned for a **~15–25 minute** lineage run with pack pressure but recoverable mistakes.

## Needs

| Constant | Value | Rationale |
|----------|-------|-----------|
| `PLAYER_NEEDS_DECAY_MULT` | 1.6 | Slightly slower solo drain |
| `PACK_SIZE_DECAY_SCALE` | 0.09 | Large packs hurt, but not instantly |
| `HEIR_NEEDS_DECAY_MULT` | 0.38 | Dependent pups cheaper than player |
| `HEIR_INDEPENDENT_NEEDS_DECAY_MULT` | 0.92 | Independent heirs self-sustain with hunt |

## Pup lifecycle (seconds)

| Constant | Value | Rationale |
|----------|-------|-----------|
| `HEIR_INDEPENDENCE_SECONDS` | 60 | One gestation cycle to raise pups |
| `HEIR_ROGUE_AFTER_INDEPENDENCE_SECONDS` | 90 | Time to recruit heir before rogue threat |

## Predators

| Constant | Value | Rationale |
|----------|-------|-----------|
| `PREDATOR_BASE_COUNT` | 5 | Fewer early ambushes |
| `PREDATOR_MAX_COUNT` | 12 | Cap scales with pack + generation |
| `PREDATOR_PER_PACK_MEMBER` | 1 | +1 predator per extra pack member |

## Seasons (`SeasonManager`)

| Season | Needs mult | Notes |
|--------|------------|-------|
| Spring | 0.92 | Easiest feeding |
| Summer | 1.05 | Heat thirst |
| Autumn | 1.0 | Baseline |
| Winter | 1.18 | Hardest survival |

## Territory (den radius)

Inside `TERRITORY_RADIUS` (320px): pack needs decay ×0.82, predators slower chase.

## Hare prey

| Stat | Deer | Hare |
|------|------|------|
| HP | 30 | 18 |
| Food yield | 40 | 22 |
| Flee range | 150 | 180 |
| Speed | 36 / 105 | 48 / 130 |
