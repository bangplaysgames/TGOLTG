package game

import "core:fmt"

/////////////////////////////////////////////////////////////////////////////
// State Management
/////////////////////////////////////////////////////////////////////////////

State_Type :: enum {
	MENU,
	PLAY,
}

Game_State :: struct {
	type: State_Type,
}

state_create :: proc(state_type: State_Type) -> Game_State {
	return Game_State {
		type = state_type,
	}
}

state_transition_to :: proc(state: ^Game_State, new_type: State_Type) {
	state.type = new_type
}

state_get_type :: proc(state: ^Game_State) -> State_Type {
	return state.type
}

/////////////////////////////////////////////////////////////////////////////
// Play Data Management
/////////////////////////////////////////////////////////////////////////////

Phase :: enum {
	SEEDING,
	SIMULATING,
}

Play_Data :: struct {
	phase: Phase,
	grid_size: int,
	harvest_zone_size: int,
	seeds_remaining: int,
	seeds_initial: int,
	total_currency: int,
	harvested_this_round: int,
	simulation: Simulation_State,
	tick_timer: f64,
	tick_interval: f64,
	should_auto_tick: bool,
}

playdata_create :: proc(grid_size: int, harvest_zone_size: int, initial_seeds: int) -> Play_Data {
	data: Play_Data
	data.phase = .SEEDING
	data.grid_size = grid_size
	data.harvest_zone_size = harvest_zone_size
	data.seeds_remaining = initial_seeds
	data.seeds_initial = initial_seeds
	data.total_currency = 0
	data.harvested_this_round = 0
	data.simulation = sim_create(grid_size)
	data.tick_timer = 0.0
	data.tick_interval = 0.5
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
		gp_earned := sim_tick(&data.simulation, false, 0.0)
		data.total_currency += gp_earned
		if gp_earned > 0 {
			data.harvested_this_round += gp_earned
			fmt.printfln("Harvest: %d GP", gp_earned)
		}
	}
}

playdata_transition_to_simulating :: proc(data: ^Play_Data) {
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
}

playdata_place_cell :: proc(data: ^Play_Data, grid_x, grid_y: int) {
	if data.phase != .SEEDING || data.seeds_remaining <= 0 {
		return
	}

	harvest_start := data.grid_size / 2 - data.harvest_zone_size / 2
	harvest_end := harvest_start + data.harvest_zone_size

	if grid_x >= harvest_start && grid_x < harvest_end &&
	   grid_y >= harvest_start && grid_y < harvest_end {
		return
	}

	cell := grid_get_cell(&data.simulation.grid, grid_x, grid_y)
	if cell == .LIVE {
		return
	}

	grid_set_cell(&data.simulation.grid, grid_x, grid_y, .LIVE)
	data.seeds_remaining -= 1
}

playdata_remove_cell :: proc(data: ^Play_Data, grid_x, grid_y: int) {
	if data.phase != .SEEDING {
		return
	}

	cell := grid_get_cell(&data.simulation.grid, grid_x, grid_y)
	if cell == .DEAD {
		return
	}

	grid_set_cell(&data.simulation.grid, grid_x, grid_y, .DEAD)
	data.seeds_remaining += 1
}

// Accessors
playdata_get_phase :: proc(data: ^Play_Data) -> Phase { return data.phase }
playdata_get_grid :: proc(data: ^Play_Data) -> ^Grid { return &data.simulation.grid }
playdata_get_grid_size :: proc(data: ^Play_Data) -> int { return data.grid_size }
playdata_get_harvest_zone_size :: proc(data: ^Play_Data) -> int { return data.harvest_zone_size }
playdata_get_seeds_remaining :: proc(data: ^Play_Data) -> int { return data.seeds_remaining }
playdata_get_seeds_initial :: proc(data: ^Play_Data) -> int { return data.seeds_initial }
playdata_get_currency :: proc(data: ^Play_Data) -> int { return data.total_currency }
playdata_get_harvested :: proc(data: ^Play_Data) -> int { return data.harvested_this_round }
playdata_get_generation :: proc(data: ^Play_Data) -> int { return data.simulation.generation }
