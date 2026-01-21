package state

import clay "vendor:clay-odin"
import render "../render"
import ui "../ui"
import game "../game"
import "core:fmt"

playstate_update :: proc(data: ^game.Play_Data, delta: f64) -> State_Type {
	// Handle auto-death/crunch (add CRUNCH if needed; for now reset to MENU on death)
	if game.playdata_is_dead(data) {
		return .MENU // Or .CRUNCH
	}
	// Other logic (e.g., if esc pressed → .MENU)
	return .PLAY
}

playstate_build_ui :: proc(data: ^game.Play_Data) {
	// Your existing UI code, but use data for values
	if clay.UI(clay.ID("GameRoot"))({
		// ... (update texts with data.seeds_remaining, etc.)
	}) {
		// Add grid cells as UI elements for click
		grid_size := game.playdata_get_grid_size(data)
		for y in 0..<grid_size {
			for x in 0..<grid_size {
				cell_id := clay.ID(fmt.tprintf("Cell_%d_%d", x, y))
				cell_btn := ui.button_config(cell_id)
				cell_color := ui.COLOR_CELL_DEAD
				cell := game.grid_get_cell(game.playdata_get_grid(data), x, y)
				if cell == .LIVE { cell_color = ui.COLOR_CELL_LIVE }
				if cell == .CRYSTALLIZED { cell_color = ui.COLOR_CELL_CRYSTALLIZED }

				if clay.UI(cell_id)({
					// Layout for cell (fixed 20x20, in grid container)
					backgroundColor = ui.button_style(cell_btn, cell_color),
					// ...
				}) {
					if ui.button_click(cell_btn) {
						game.playdata_place_cell(data, x, y)
					}
				}
			}
		}
		// Harvest overlay on center
		// Run/Stop/Reset/Menu buttons with on_click calling controller funcs via data
	}
}

playstate_render_dynamic_text :: proc(data: ^game.Play_Data, renderer: ^render.Renderer) {
	// Draw GP popups, etc.
	fmt.sprintf("Seeds: %d/%d", data.seeds_remaining, data.seeds_initial) // Use SDL_ttf to draw
	// ...
}

playstate_handle_right_click :: proc(data: ^game.Play_Data) {
	// Your existing logic to find hovered cell, call playdata_remove_cell
	grid_size := game.playdata_get_grid_size(data)
	for y in 0..<grid_size {
		for x in 0..<grid_size {
			cell_id := clay.ID(fmt.tprintf("Cell_%d_%d", x, y))
			bounds, found := ui.get_element_bounds_by_id(cell_id.id)
			if found && /* hovered */ {
				game.playdata_remove_cell(data, x, y)
				return
			}
		}
	}
}

playstate_handle_input :: proc(data: ^game.Play_Data) {
	// Check buttons for Run/Stop/Reset/Menu
	run_btn_id := clay.ID("RunButton")
	run_btn := ui.button_config(run_btn_id)
	if ui.button_click(run_btn) {
		game.playdata_transition_to_simulating(data)
	}
	// Similar for stop, reset, menu (return to MENU)
}