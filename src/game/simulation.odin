package game

import "core:math/rand"

// Simulation state tracking
Simulation_State :: struct {
	grid: Grid,
	generation: int,
	gp_this_round: int,
	shards_this_run: int,
}

// Create new simulation state
sim_create :: proc(grid_size: int) -> Simulation_State {
	sim: Simulation_State
	sim.grid = grid_create(grid_size)
	sim.generation = 0
	sim.gp_this_round = 0
	sim.shards_this_run = 0
	return sim
}

// Apply B3/S23 rules for one tick
// Returns GP earned this tick
sim_tick :: proc(sim: ^Simulation_State, crystallization_unlocked: bool, cross_chance_pct: f32) -> int {
	old_grid := sim.grid
	new_grid := grid_create(sim.grid.size)

	gp_this_tick := 0

	// Process each cell
	for y in 0 ..< sim.grid.size {
		for x in 0 ..< sim.grid.size {
			old_cell := grid_get_cell(&old_grid, x, y)
			neighbors := grid_count_neighbors(&old_grid, x, y)

			new_cell: Cell_State

			if old_cell == .DEAD {
				// Birth: dead cell with exactly 3 neighbors becomes live
				if neighbors == 3 {
					// Check if in harvest zone
					if grid_in_harvest_zone(&sim.grid, x, y) {
						// Harvest twist: births in harvest zone give GP but stay dead
						gp_this_tick += 1
						new_cell = .DEAD  // Cell stays dead (snuffed)
					} else {
						new_cell = .LIVE  // Normal birth outside harvest zone
					}
				} else {
					new_cell = .DEAD
				}
			} else { // LIVE or CRYSTALLIZED
				// Survival: live cell with 2 or 3 neighbors survives
				if neighbors == 2 || neighbors == 3 {
					new_cell = old_cell  // Survives, keeps state (live or crystallized)
				} else {
					// Death: cell dies
					if old_cell == .CRYSTALLIZED {
						// Crystallized cell deaths drop Shards
						sim.shards_this_run += 1
					}
					new_cell = .DEAD
				}
			}

			grid_set_cell(&new_grid, x, y, new_cell)
		}
	}

	// Apply crystallization (cross pattern detection)
	// Only if crystallization is unlocked
	if crystallization_unlocked {
		for y in 0 ..< sim.grid.size {
			for x in 0 ..< sim.grid.size {
				// Check if this is a cross center
				if grid_is_cross_center(&new_grid, x, y) {
					// Roll for crystallization
					roll: f32 = rand.float32()
					if roll < cross_chance_pct / 100.0 {
						grid_set_cell(&new_grid, x, y, .CRYSTALLIZED)
					}
				}
			}
		}
	}

	// Update grid
	sim.grid = new_grid
	sim.generation += 1
	sim.gp_this_round += gp_this_tick

	return gp_this_tick
}

// Clear grid (all cells dead)
sim_clear :: proc(sim: ^Simulation_State) {
	for i in 0 ..< len(sim.grid.cells) {
		sim.grid.cells[i] = .DEAD
	}
	sim.generation = 0
}

// Reset for new round (keeps grid size, resets counters)
sim_reset_round :: proc(sim: ^Simulation_State) {
	sim_clear(sim)
	sim.gp_this_round = 0
}

// Reset for prestige (resets everything except shard data)
// Note: Shard data is managed at higher level
sim_reset_prestige :: proc(sim: ^Simulation_State, new_size: int) {
	sim.grid = grid_create(new_size)
	sim.generation = 0
	sim.gp_this_round = 0
	// shards_this_run is NOT reset - accumulated across runs
}
