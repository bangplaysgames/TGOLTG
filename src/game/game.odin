package game

import "core:fmt"

State_Type :: enum {
	MENU,
	PLAY,
	// Add CRUNCH, SHOP later
}

Phase :: enum {
	SEEDING,
	SIMULATING,
}

Play_Data :: struct {
	phase: Phase,
	grid_size: int = 5,
	harvest_zone_size: int = 3,
	seeds_remaining: int,
	seeds_initial: int = 5,
	total_currency: int,
	harvested_this_round: int,
	simulation: Simulation_State,
	tick_timer: f64,
	tick_interval: f64 = 0.5,
	should_auto_tick: bool,
	// Add upgrades: harvest_mult f32 = 1.0, etc.
}

playdata_create :: proc() -> Play_Data {
	data: Play_Data
	data.phase = .SEEDING
	data.seeds_remaining = data.seeds_initial
	data.total_currency = 0
	data.harvested_this_round = 0
	data.simulation = sim_create(data.grid_size)
	data.tick_timer = 0.0
	data.should_auto_tick = false
	return data
}

playdata_update :: proc(data: ^Play_Data, delta_time: f64) {
	if data.phase != .SIMULATING || !data.should_auto_tick {
		return
	}

	data.tick_timer += delta_time
	if data.tick_timer >= data.tick_interval {
		data.tick_timer = 0.0
		gp_earned := sim_tick(&data.simulation, false, 0.0) // Crystallization locked early
		data.total_currency += gp_earned
		data.harvested_this_round += gp_earned
		if gp_earned > 0 {
			fmt.printfln("Harvested: %d GP", gp_earned)
		}
	}
}

playdata_transition_to_simulating :: proc(data: ^Play_Data) {
	if data.seeds_remaining > 0 {
		return // Can't start if seeds left
	}
	data.phase = .SIMULATING
	data.should_auto_tick = true
	data.tick_timer = 0.0
}

playdata_transition_to_seeding :: proc(data: ^Play_Data) {
	data.phase = .SEEDING
	data.should_auto_tick = false
}

playdata_reset_round :: proc(data: ^Play_Data) {
	sim_reset_round(&data.simulation)
	data.seeds_remaining = data.seeds_initial
	data.harvested_this_round = 0
	data.phase = .SEEDING
}

playdata_place_cell :: proc(data: ^Play_Data, grid_x, grid_y: int) -> bool {
	if data.phase != .SEEDING || data.seeds_remaining <= 0 {
		return false
	}
	harvest_start := data.grid_size / 2 - data.harvest_zone_size / 2
	harvest_end := harvest_start + data.harvest_zone_size
	if grid_x >= harvest_start && grid_x < harvest_end && grid_y >= harvest_start && grid_y < harvest_end {
		return false // Can't place in harvest
	}
	cell := grid_get_cell(&data.simulation.grid, grid_x, grid_y)
	if cell != .DEAD {
		return false
	}
	grid_set_cell(&data.simulation.grid, grid_x, grid_y, .LIVE)
	data.seeds_remaining -= 1
	return true
}

playdata_remove_cell :: proc(data: ^Play_Data, grid_x, grid_y: int) -> bool {
	if data.phase != .SEEDING {
		return false
	}
	cell := grid_get_cell(&data.simulation.grid, grid_x, grid_y)
	if cell == .DEAD {
		return false
	}
	grid_set_cell(&data.simulation.grid, grid_x, grid_y, .DEAD)
	data.seeds_remaining += 1
	return true
}

playdata_get_phase :: proc(data: ^Play_Data) -> Phase { return data.phase }
playdata_get_grid_size :: proc(data: ^Play_Data) -> int { return data.grid_size }
playdata_get_harvest_zone_size :: proc(data: ^Play_Data) -> int { return data.harvest_zone_size }
playdata_get_seeds_remaining :: proc(data: ^Play_Data) -> int { return data.seeds_remaining }
playdata_get_seeds_initial :: proc(data: ^Play_Data) -> int { return data.seeds_initial }
playdata_get_currency :: proc(data: ^Play_Data) -> int { return data.total_currency }
playdata_get_harvested :: proc(data: ^Play_Data) -> int { return data.harvested_this_round }
playdata_get_generation :: proc(data: ^Play_Data) -> int { return data.simulation.generation }
playdata_is_dead :: proc(data: ^Play_Data) -> bool {
	live_count := 0
	for cell in data.simulation.grid.cells {
		if cell == .LIVE || cell == .CRYSTALLIZED {
			live_count += 1
		}
	}
	return live_count < 3 // For auto-crunch
}