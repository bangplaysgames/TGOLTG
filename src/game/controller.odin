package game

import "core:fmt"
import clay "vendor:clay-odin"
import render "../render"
import ui "../ui"
import state "../state"

Controller :: struct {
	current_state: State_Type = .MENU,
	play_data: Play_Data,
}

controller_create :: proc() -> Controller {
	controller: Controller
	controller.play_data = playdata_create()
	return controller
}

controller_update :: proc(controller: ^Controller, delta_time: f64) -> State_Type {
	next_state := State_Type(controller.current_state) // Default stay
	#switch controller.current_state {
	case .MENU:
		next_state = state.menustate_update()
	case .PLAY:
		playdata_update(&controller.play_data, delta_time)
		next_state = state.playstate_update(&controller.play_data, delta_time)
	}

	if next_state != controller.current_state {
		controller.current_state = next_state
		if next_state == .PLAY {
			// Init PLAY if needed
		} else if next_state == .MENU {
			controller_reset_round(controller)
		}
	}
	return next_state // Not used, but for completeness
}

controller_build_ui :: proc(controller: ^Controller) {
	#switch controller.current_state {
	case .MENU:
		state.menustate_build_ui()
	case .PLAY:
		state.playstate_build_ui(&controller.play_data)
	}
}

controller_render_dynamic_text :: proc(controller: ^Controller, renderer: ^render.Renderer) {
	#switch controller.current_state {
	case .MENU:
		// No dynamic for menu
	case .PLAY:
		state.playstate_render_dynamic_text(&controller.play_data, renderer)
	}
}

controller_handle_right_click :: proc(controller: ^Controller) {
	#switch controller.current_state {
	case .MENU:
		// No right click for menu
	case .PLAY:
		state.playstate_handle_right_click(&controller.play_data)
	}
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