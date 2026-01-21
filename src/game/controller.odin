package game

import clay "vendor:clay-odin"
import render "../render"
import ui "../ui"
import state "../state"
import "core:fmt"

/////////////////////////////////////////////////////////////////////////////
// Game Controller - Manager for runtime data and state coordination
/////////////////////////////////////////////////////////////////////////////

Controller :: struct {
	current_state: Game_State,
	play_data: Play_Data,
}

// Create new controller
controller_create :: proc() -> Controller {
	controller: Controller
	controller.current_state = state_create(.MENU)
	controller.play_data = Play_Data{}
	return controller
}

// Update controller
controller_update :: proc(controller: ^Controller, delta_time: f64) {
	if state_get_type(&controller.current_state) == .PLAY {
		playdata_update(&controller.play_data, delta_time)
	}
}

/////////////////////////////////////////////////////////////////////////////
// UI Building - Calls state package UI functions
/////////////////////////////////////////////////////////////////////////////

controller_build_ui :: proc(controller: ^Controller) {
	state_type := state_get_type(&controller.current_state)

	switch state_type {
		case .MENU:
			state.menustate_build_ui()

		case .PLAY:
			state.playstate_build_ui(
				&controller.play_data,
				playdata_get_phase,
				playdata_get_grid_size,
				playdata_get_harvest_zone_size,
				playdata_get_seeds_remaining,
				playdata_get_seeds_initial,
				playdata_get_currency,
				playdata_get_harvested,
				playdata_get_generation,
				get_grid_cell_wrapper,
			)
	}
}

// Wrapper to convert game.Cell_State to state.Cell_State
get_grid_cell_wrapper :: proc(ctx: rawptr, x, y: int) -> state.Cell_State {
	play_data := (^Play_Data)(ctx)
	cell := grid_get_cell(&play_data.simulation.grid, x, y)
	switch cell {
		case .DEAD: return .DEAD
		case .LIVE: return .LIVE
		case .CRYSTALLIZED: return .CRYSTALLIZED
		case: return .DEAD
	}
}

// Wrappers for playdata getters to convert rawptr to ^Play_Data
get_phase_wrapper :: proc(ctx: rawptr) -> state.Phase {
	data := (^Play_Data)(ctx)
	phase := playdata_get_phase(data)
	switch phase {
		case .SEEDING: return .SEEDING
		case .SIMULATING: return .SIMULATING
		case: return .SEEDING
	}
}

get_grid_size_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_grid_size((^Play_Data)(ctx))
}

get_harvest_zone_size_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_harvest_zone_size((^Play_Data)(ctx))
}

get_seeds_remaining_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_seeds_remaining((^Play_Data)(ctx))
}

get_seeds_initial_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_seeds_initial((^Play_Data)(ctx))
}

get_currency_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_currency((^Play_Data)(ctx))
}

get_harvested_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_harvested((^Play_Data)(ctx))
}

get_generation_wrapper :: proc(ctx: rawptr) -> int {
	return playdata_get_generation((^Play_Data)(ctx))
}

controller_render_dynamic_text :: proc(controller: ^Controller, renderer: ^render.Renderer) {
	state_type := state_get_type(&controller.current_state)

	switch state_type {
		case .MENU:
			// No dynamic text for menu
		case .PLAY:
			state.playstate_render_dynamic_text(
				&controller.play_data,
				renderer,
				playdata_get_phase,
				playdata_get_seeds_remaining,
				playdata_get_seeds_initial,
				playdata_get_harvested,
				playdata_get_currency,
				playdata_get_generation,
			)
	}
}

// Helper to create PlayStateCallbacks from Controller
create_playstate_callbacks :: proc(ctrl: ^Controller) -> state.PlayStateCallbacks {
	return state.PlayStateCallbacks {
		user_data = ctrl,

		get_phase = proc(ctx: rawptr) -> state.Phase {
			controller := (^Controller)(ctx)
			phase := playdata_get_phase(&controller.play_data)
			switch phase {
				case .SEEDING: return .SEEDING
				case .SIMULATING: return .SIMULATING
				case: return .SEEDING
			}
		},
		get_grid_size = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_grid_size(&controller.play_data)
		},
		get_harvest_zone_size = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_harvest_zone_size(&controller.play_data)
		},
		get_seeds_remaining = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_seeds_remaining(&controller.play_data)
		},
		get_seeds_initial = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_seeds_initial(&controller.play_data)
		},
		get_currency = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_currency(&controller.play_data)
		},
		get_harvested = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_harvested(&controller.play_data)
		},
		get_generation = proc(ctx: rawptr) -> int {
			controller := (^Controller)(ctx)
			return playdata_get_generation(&controller.play_data)
		},
		get_grid_cell = proc(ctx: rawptr, x, y: int) -> state.Cell_State {
			controller := (^Controller)(ctx)
			cell := grid_get_cell(&controller.play_data.simulation.grid, x, y)
			switch cell {
				case .DEAD: return .DEAD
				case .LIVE: return .LIVE
				case .CRYSTALLIZED: return .CRYSTALLIZED
				case: return .DEAD
			}
		},

		start_simulation = proc(ctx: rawptr) {
			controller := (^Controller)(ctx)
			controller_start_simulation(controller)
		},
		stop_simulation = proc(ctx: rawptr) {
			controller := (^Controller)(ctx)
			controller_stop_simulation(controller)
		},
		reset_round = proc(ctx: rawptr) {
			controller := (^Controller)(ctx)
			controller_reset_round(controller)
		},
		transition_to_menu = proc(ctx: rawptr) {
			controller := (^Controller)(ctx)
			controller_transition_to_menu(controller)
		},
	}
}

/////////////////////////////////////////////////////////////////////////////
// Input Handling
/////////////////////////////////////////////////////////////////////////////

controller_handle_input :: proc(controller: ^Controller) {
	if state_get_type(&controller.current_state) == .MENU {
		if state.menustate_was_start_clicked() {
			controller_transition_to_play(controller)
		}
	} else if state_get_type(&controller.current_state) == .PLAY {
		state.playstate_handle_input(
			proc() { controller_start_simulation(controller) },
			proc() { controller_stop_simulation(controller) },
			proc() { controller_reset_round(controller) },
			proc() { controller_transition_to_menu(controller) },
		)
	}
}

controller_handle_cell_click :: proc(controller: ^Controller, grid_x, grid_y: int, cell_id: clay.ElementId) {
	bounds, found := ui.get_element_bounds_by_id(cell_id.id)
	if !found {
		return
	}

	is_hovered := (
		ui.ui_state.mouse_pos.x >= bounds.x &&
		ui.ui_state.mouse_pos.x < bounds.x + bounds.width &&
		ui.ui_state.mouse_pos.y >= bounds.y &&
		ui.ui_state.mouse_pos.y < bounds.y + bounds.height
	)

	if is_hovered && ui.ui_state.mouse_down {
		playdata_place_cell(&controller.play_data, grid_x, grid_y)
	}
}

controller_handle_right_click :: proc(controller: ^Controller) {
	grid_size := playdata_get_grid_size(&controller.play_data)

	for y in 0 ..< grid_size {
		for x in 0 ..< grid_size {
			cell_id := clay.ID(fmt.tprintf("Cell_%d_%d", x, y))
			bounds, found := ui.get_element_bounds_by_id(cell_id.id)

			if found {
				is_hovered := (
					ui.ui_state.mouse_pos.x >= bounds.x &&
					ui.ui_state.mouse_pos.x < bounds.x + bounds.width &&
					ui.ui_state.mouse_pos.y >= bounds.y &&
					ui.ui_state.mouse_pos.y < bounds.y + bounds.height
				)

				if is_hovered {
					playdata_remove_cell(&controller.play_data, x, y)
					return
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////////////////
// State Transitions
/////////////////////////////////////////////////////////////////////////////

controller_transition_to_play :: proc(controller: ^Controller) {
	grid_size := 15
	harvest_zone_size := 3
	initial_seeds := 10
	controller.play_data = playdata_create(grid_size, harvest_zone_size, initial_seeds)
	state_transition_to(&controller.current_state, .PLAY)
	fmt.println("Entered play state!")
}

controller_transition_to_menu :: proc(controller: ^Controller) {
	state_transition_to(&controller.current_state, .MENU)
	fmt.println("Returned to menu!")
}

controller_start_simulation :: proc(controller: ^Controller) {
	playdata_transition_to_simulating(&controller.play_data)
}

controller_stop_simulation :: proc(controller: ^Controller) {
	playdata_transition_to_seeding(&controller.play_data)
}

controller_reset_round :: proc(controller: ^Controller) {
	playdata_reset_round(&controller.play_data)
}

/////////////////////////////////////////////////////////////////////////////
// Data Accessors
/////////////////////////////////////////////////////////////////////////////

get_play_data :: proc(controller: ^Controller) -> ^Play_Data {
	return &controller.play_data
}
