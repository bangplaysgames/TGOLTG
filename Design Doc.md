# The Game of Life - The Game Design Document v1.1

## 1. Game Overview
**The Game of Life - The Game** is an idle incremental roguelike built on Conway's Game of Life. Players manually seed a finite grid each "round," simulate generations until extinction, and harvest "GP" (Genesis Points) from births in a central zone—snuffing them instantly for currency. Crunch for prestige "Shards" to buy permanent upgrades, scaling to massive grids and exponential yields.

**Core Hook**: Tense manual placement → passive chaos watching → satisfying crunch & meta-grind. Finite grid ensures natural die-offs (no eternal patterns), emphasizing burst optimization.

**Target Platforms**: Desktop (Windows/Linux/Mac via Odin native builds). Potential for console ports later.
**Monetization**: None (pure itch.io/Steam idler).
**Win Condition**: Infinite scaling—prestige to absurd notation GP/s.

**Key Balance Goals**:
- Round 1 max: ~8 GP (sim-verified; close to 5-6 target).
- Initial GP upgrades: 3-10 GP each (accessible post-Round 1 best).
- Early game (10 rounds): 6-8 seeds, 5x5-7x7 grid, 15-30 GP/round.
- Mid-game unlock: Shards at 100 GP single-round milestone.
- Mid (100 rounds): 11x11+, 1k+ GP, Shards for advanced upgrades.
- Idle Focus: Offline sim proportional to time (cap log-shards).

## 2. Core Loop
1. **Seed Phase** (15s): Allocate **N seeds** (base 4-5, modified by prestige upgrades) by tapping grid cells live. Preview 3-gen sim (no harvest).
2. **Sim Phase** (Idle): Auto-tick 1 gen/sec (upgradable). Watch births snuff in harvest zone for GP popups. Watch crystallized cells shimmer and shatter for Shards (when unlocked).
3. **Shop Phase**: Spend GP on standard upgrades → next round.
4. **Prestige Phase** (Optional, Mid-game): Manual button → **RESETS RUN** → All GP, grid, standard upgrades reset → **Prestige upgrades (Shards) retained** → Next run starts with prestige bonuses.

**Shards are ONLY obtained through crystallized cell deaths** (1 Shard per crystal death). GP never converts to Shards.

**Round Length**: 1-5 gens early (10s-1min); scales with grid/upgrades.
**Run Length**: Multiple rounds until player chooses to prestige.

## 3. Grid & Simulation
- **Size**: Starts 5x5 finite (no wraparound—edges pad 0).
- **Harvest Zone**: Central 3x3 (rows/cols 1-3, 0-indexed).
- **Rules**: Standard B3/S23.
  - **Harvest Twist**: Births (dead→live via 3 neigh) in zone → +1 GP (base), **cell stays dead** (snuffed).
  - **Cellular Crystallization** (Mid-Game Upgrade): Live cells can become Crystallized
    - Crystallized cells follow standard B3/S23 rules
    - When a Crystallized cell dies (any death condition) → +1 Shard
    - **Initial Crystallization Pattern**: Cross formation (center cell with all 4 orthogonal neighbors alive)
      - Center cell of cross has chance to crystallize based on upgrades
      - Base chance: 0% (cells never crystallize without upgrade)
      - First upgrade: 5% crystallization chance per cross center
      - Pattern: Center at (x,y), requires live cells at (x,y±1) and (x±1,y)
    - **Cross-Crystallization Spread** (Separate Upgrade): Crystallized cells can spread crystallization to neighbors
      - Prerequisite: Crystallized cell must survive to next generation (stay alive)
      - Spread target: Each adjacent cell (orthogonal N,S,E,W) that is live or birthing
      - Each adjacent cell rolls independently for crystallization
      - Base chance: 0% (no spread without upgrade)
      - First upgrade: 1-2% spread chance per adjacent cell
      - Higher tiers: Incremental increases (+1-2% per tier)
- **Death**: <3 live cells for 3 gens.
- **Tick Rate**: 1 gen/sec base; upgrades to x10+.
- **Viz**:
  | Element | Style |
  |---------|-------|
  | Live Cell | Green glow pulse |
  | Crystallized Cell | Purple/crystal glow with shimmer |
  | Birth Snuff | Crimson implosion + "+1.2" gold float |
  | Crystal Shatter | Crystal explosion + "+1 Shard" silver float |
  | Preview | Ghost blue overlays |
  | Stats HUD | GP total/sec, live count, gen #, Shard count |

**Sim Impl**: Pure Odin arrays for grid (u8[GRID_SIZE*GRID_SIZE]). Bit-packed for perf on large grids. Cell states: 0=dead, 1=live, 2=crystallized. SDL3GPU bindings for rendering/windowing.

## 4. Currencies & Formulas
- **GP (Primary, Spendable)**: Harvest births. Display: Floats w/ mult (e.g., 1.21 GP).
  - **Round-Only Currency**: Earned and spent within each run
  - **Resets on Prestige**: All GP resets when prestiging
  - Used for standard upgrades (subtle, gradual improvements + crystallization unlock)
- **Shards (Prestige Currency)**:
  - **ONLY Source**: Crystallized cell deaths (1 Shard per crystal death)
  - **Locked until**: Cellular Crystallization purchased (150 GP) → Unlocks Shard shop & Prestige
  - **No milestone rewards**: Previous 100 GP milestone Shard rewards removed
  - **GP NEVER converts to Shards** - no direct purchase or crunch formula
  - **Permanent**: Shards are never spent; accumulated across all runs
  - Used for prestige upgrades (game-changing, retained after prestige)
- **Offline**: Sim at max speed, GP capped log10(time*base_rate). Shards from crystallized cell deaths accumulate (when unlocked).

## 5. Meta Shop & Upgrades

### Standard Upgrades (GP Shop)
**Purchased with GP within each run. Reset on prestige.**
- Initial costs affordable with Round 1 earnings (8 GP max)
- **Philosophy**: Mix of subtle bonuses (early) and major mechanics (mid-game)
- **Dependencies**: Upgrades unlock based on what you've purchased, not just GP

| Category | Upgrade | Cost | Effect | Dependencies |
|----------|---------|------|--------|--------------|
| **Seeds** | +1 Alloc/Round | **5 GP** | 5→6 seeds | None (available start) |
| **Harvest** | +5% GP/Birth | **3 GP** | x1.05 GP multiplier | None (available start) |
| **Speed** | x1.5 Tick Rate | 6 GP | 1→1.5/sec | None (available start) |
| **Grid** | +1 Size | 8 GP | 5x5→6x6 | Seeds Level 1 OR Harvest Level 1 |
| **Harvest Zone** | +1 Size | 10 GP | 3x3→4x4 | Grid Level 1 |
| **Seeds II** | +1 Alloc/Round | 12 GP | 6→7 seeds | Grid Level 1 |
| **Harvest II** | +5% GP/Birth | 15 GP | x1.05 → x1.10 | Seeds Level 2 |
| **Speed II** | x2 Tick Rate | 20 GP | 1.5→3/sec | Harvest Level 2 |
| **Grid II** | +1 Size | 25 GP | 6x6→7x7 | Seeds Level 2 + Harvest Level 2 |
| **Cellular Crystallization** | Unlock Crystal Cells | **150 GP** | NEW MECHANIC: Cross patterns create crystals; deaths drop Shards | Grid Level 2 + Seeds Level 2 |
| **Cross Chance** | +5% Crystallization | 50 GP | 5% → 10% → 15% per cross center | Cellular Crystallization purchased |
| **Grid III** | +1 Size | 40 GP | 7x7→8x8 | Cellular Crystallization |
| **Seeds III** | +1 Alloc/Round | 30 GP | 7→8 seeds | Cellular Crystallization |

**Shop UX**: Available between rounds. Upgrades grayed out if dependencies not met. Hover shows requirements.
"Buy x1 (Cost: X GP) - Requires: Grid Level 2 + Seeds Level 2"

**Note**: Cellular Crystallization unlocks around Round 15 (requires significant investment in prerequisite upgrades). This is the KEY mid-game milestone that starts Shard generation.

### Prestige Upgrades (Shard Shop)
**Purchased with permanent Shards. Game-changing upgrades. Retained after prestige.**
- **Locked until Cellular Crystallization is purchased at least once** (in ANY run)
- Once unlocked, persists across all future runs even after prestiging
- **Philosophy**: Permanent bonuses that make each run faster
- **Dependencies**: Similar dependency system as GP upgrades

| Category | Upgrade | Cost | Effect | Dependencies |
|----------|---------|------|--------|--------------|
| **Starter GP** | +5 Starting GP | 3 Shards | Start each run with +5 GP | None (available when shop unlocks) |
| **GP Mult** | +10% GP All Runs | 5 Shards | x1.1 GP multiplier (permanent, all future runs) | Starter GP purchased |
| **Starter Seeds** | +1 Starting Seeds | 6 Shards | +1 seed allocation per run | GP Mult purchased |
| **Cross-Crystallization Spread** | Unlock Crystal Spread | **10 Shards** | NEW MECHANIC: Surviving crystals spread to neighbors | Starter Seeds + GP Mult |
| **Spread Chance** | +1% Spread Chance | 8 Shards | 1% → 2% → 3% → 4% per adjacent cell | Cross-Crystallization Spread purchased |

**Shop UX**: Always available (after unlock). Upgrades grayed out if dependencies not met. "Total Shards: X" → Upgrade buttons.
"Buy (Cost: X Shards) - Requires: Starter GP + GP Mult"

**Unlock Condition**: Purchase Cellular Crystallization (150 GP) in any run → Shard shop unlocks permanently → Can now prestige → Shards accumulate from crystal deaths

**Note**: Shards are NEVER spent—accumulated permanently. Prestige upgrades are one-time purchases that persist through all future runs.

**Two-Stage Crystallization System**:
1. **Initial Formation** (Standard Upgrade - GP shop): Cross patterns create new crystallized cells (5% base, upgradable)
2. **Spread Mechanic** (Prestige Upgrade - Shard shop): Surviving crystallized cells spread to adjacent neighbors (1% base, upgradable)

Players unlock Stage 1 around Round 15 (150 GP cost).
Players unlock Stage 2 after accumulating 10 Shards from crystal deaths.

**Cross Pattern Details**:
```
  . X .      (neighbors at N, S, E, W)
  X X X
  . X .
```
- Only the center cell (X) can crystallize
- Cross patterns naturally emerge during Game of Life simulations
- Cross detection occurs after each generation tick
- Each cross center rolls for crystallization independently
- Crystallized cells retain their cross neighbors (can form new crosses in subsequent generations)

**Cross-Crystallization Spread Details**:
```
  . . .      Stage 1: Center cell becomes crystallized
  . C .      (C = Crystallized)
  . . .

  . . .      Stage 2: If C survives next tick, spread to neighbors
  ? C ?      Each ? (live or birthing) rolls for crystallization independently
  . . .      Base 1% chance per adjacent cell (upgradable)
```
- Spread occurs AFTER generation tick completes
- Only crystallized cells that survived (stayed alive) can spread
- Target cells: Any orthogonal neighbor that is live or about to be born
- Each neighbor rolls independently - some may crystallize, others may not
- Spread chance is low (1-4%) to prevent explosive crystal growth
- Creates strategic depth: players want crystallized cells to survive multiple generations

## 6. Balance & Verified Sims
**5x5 Finite, Base 5 Seeds** (53k configs brute-feasible; samples confirm):
- **Max GP**: 8 (achieved by full center lines: vertical col2 or horizontal row2).
  - Ex: Vertical col2 (pos 2,7,12,17,22): 8 GP gen1, dies.
  - Horizontal row2 (10-14): 8 GP gen1.
- **Min GP**: 0 (~40% bad clumps/lines).
- **Avg GP**: ~1.2 (estimated; bursts rare).
- **Shards**: 0-2 (floor(sqrt(8))=2).

| Seeds | Max GP | Max Shards | Example Config (Row-Major Pos) | Gens |
|-------|--------|------------|--------------------------------|------|
| 3 | 2 | 1 | Row1 partial (5,6,7) | 1 |
| 4 | 5-6* | 2 | Col2 partial (2,7,12,17) | 1 |
| **5** | **8** | **2** | **(2,7,12,17,22)** | **1** |

*4-seed est. from patterns.

**Progression Curve** (Best play, manual optimal):
```
Run 1: Learning the basics
Round | Seeds | Grid/Harvest | Max GP | GP Total | Shards | Upgrades Purchased (dependencies)
------|-------|--------------|--------|----------|--------|----------------------------------
1     | 5     | 5x5/3x3     | 8      | 8        | 0      | Harvest +5% (3 GP)
3     | 5     | 5x5/3x3     | 10     | 25       | 0      | Seeds +1 (5 GP) → Grid +1 unlocks!
5     | 6     | 6x6/3x3     | 12     | 50       | 0      | Grid +1 (8 GP), Harvest Zone +1 (10 GP)
8     | 6     | 6x6/4x4     | 18     | 100      | 0      | End run (cannot prestige yet)

Run 2-10: Following dependency tree, building toward crystallization
Run 2:
3     | 6     | 6x6/4x4     | 15     | 45       | 0      | Seeds II (12 GP, requires Grid L1)
6     | 7     | 6x6/4x4     | 20     | 100      | 0      | Harvest II (15 GP, requires Seeds L2)
10    | 7     | 7x7/4x4     | 30     | 200      | 0      | Grid II (25 GP, requires Seeds L2 + Harvest L2)

Run 3-10: Continue through dependency tree, accumulating GP
Cannot prestige - Shard shop locked until Cellular Crystallization purchased

Run 11: Finally unlock crystallization!
Round | Seeds | Grid/Harvest | Max GP | GP Total | Shards | Milestone
------|-------|--------------|--------|----------|--------|----------
5     | 8     | 7x7/4x4     | 40     | 150      | 0      | Cellular Crystallization (150 GP, requires Grid L2 + Seeds L2)
8     | 8     | 7x7/4x4     | 60     | 300+     | 5+     | First crystal deaths! Shard shop unlocks!

Run 12: First prestige possible
Round | Seeds | Grid/Harvest | Max GP | GP Total | Shards | Upgrades
------|-------|--------------|--------|----------|--------|---------
1     | 8     | 5x5/3x3     | 20     | 20       | 5+     | Accumulate more Shards
10    | 8     | 7x7/4x4     | 80     | 500+     | 20+    | PRESTIGE: Reset, keep Shards

Run 13: Shard shop unlocked, follow dependencies
Round | Seeds | Grid/Harvest | Max GP | GP Total | Shards | Upgrades Purchased
------|-------|--------------|--------|----------|--------|------------------
1     | 9     | 5x5/3x3     | 25     | 25       | 20+    | Starter GP (3 Shards)
5     | 9     | 7x7/4x4     | 50     | 200      | 17+    | GP Mult (5 Shards, requires Starter GP)
10    | 10    | 7x7/5x5     | 80     | 500+     | 40+    | Starter Seeds (6 Shards, requires GP Mult)
                                                  | 34+    | Cross-Crystallization Spread (10 Shards, reqs fulfilled)

Run 14+: Full economy active
Crystal spread + deaths → Exponential Shard accumulation
Prestige upgrades follow dependency tree
Each run faster than last
```

**7x7 Tease**: Max ~20 GP (longer lines/chaos); scales naturally.

## 7. UX/UI Flow
- **Screens**:
  1. **Seed Editor**: 5x5 pixel grid, seed counter "5/5". Preview btn. Start Sim.
  2. **Sim Viewer**: Zoom/pan, pause/FF x1000. GP rain effects (gold). Crystal shatter effects (silver, when unlocked). "End Round" button.
  3. **GP Shop** (Between Rounds): Post-round splash: "Earned X GP! (Total: Y)" → standard upgrade carousel.
  4. **Prestige Screen** (After 100 GP milestone): "Prestige Available!" button → Shows Shard calculation → Confirm → Animation → Reset → Next run.
  5. **Shard Shop** (Always Available): Persistent upgrade screen. "Total Shards: X" → prestige upgrade buttons.
  6. **Crystal Screen** (Post-Crystallization): Flash/pulse when cells crystallize. Counter: "X Crystallized Cells".
- **Input**: Mouse/keyboard for desktop (click to place seeds, hotkeys for sim control).
- **Audio**: Pop snuff, rising hum density, crystallization chime (magical sparkle), crystal shatter (glass breaking), spread whisper (subtle transmission sound), prestige boom (satisfying reset sound).
- **Achievements**: "First Harvest" (1 GP) → +1 starter GP. "Line God" (8 GP) → preview gens+1. "Shard Born" (100 GP single round) → Unlock Prestige. "Crystal Age" (buy Cellular Crystallization) → New era begins! "Viral Crystals" (buy Cross-Crystallization Spread) → Infection begins!

## 8. Potential Pitfalls & Fixes
| Issue | Fix |
|-------|-----|
| Bad seeds (0 GP) | Free retry once/round; tutorial tooltip "Lines near center!" |
| Short rounds | Events (5%): "Fertility" +1 GP random birth. |
| GP hoarding (no spending) | All upgrades are permanent investments; exponential costs encourage spending |
| Shard drought (pre-crystal) | Crunch mechanic provides baseline Shards; can accumulate over multiple rounds |
| Cross rarity (too few crosses) | Cross patterns emerge naturally in chaotic GoL simulations; larger grids = more crosses |
| Crystal explosion (spread too fast) | 1% base spread is very conservative; requires crystal to survive; exponential upgrade costs (×5) |
| Late stalls | Grid cap 101x101; GP cost x1.5^level, Shard cost x5^level. |
| Compute | Odin arenas/allocators for mem; gen cap 10k/round. |
| Mid-game transition | Clear milestone popup at 100 GP: "Shard System Unlocked!" |
| Crystal spam (too many Shards) | 5% cross chance + 1% spread chance = very conservative; requires specific patterns |

## 9. Prototype Roadmap
- **Week 1**: Odin core sim loop (grid array, B3/S23 tick func) + basic SDL3GPU window for 5x5 rendering/shop UI + Clay for a layout engine with custom made UI widgets.
- **Week 2**: 7x7+ expand, offline logic, input polish.
- **Polish**: Pattern scanner (label "Good Burst"), community seed shares (RLE export).