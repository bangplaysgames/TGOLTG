package main

import "core:fmt"
import SDL "vendor:sdl3"
import render "render"
import ui "ui"
import controller "game"

/////////////////////////////////////////////////////////////////////////////
// Main - Minimal initialization and handoff to game controller
/////////////////////////////////////////////////////////////////////////////

main :: proc() {
	fmt.println("Game of Life - The Game")
	fmt.println("Initializing renderer...")

	// Initialize UI state
	ui.init_ui_state()

	// Create game controller
	game_controller := controller.controller_create()

	renderer := render.renderer_create(cstring("Game of Life - The Game"), 1280, 720)
	if renderer == nil {
		fmt.println("Failed to create renderer")
		return
	}
	defer render.renderer_destroy(renderer)

	fmt.println("Renderer initialized successfully!")
	fmt.println("Press Close button to exit")

	running := true
	last_frame_time := SDL.GetTicks()

	for running {
		// Process all pending events
		event: SDL.Event
		have_event := SDL.PollEvent(&event)
		for have_event {
			// Handle Clay events
			render.handle_clay_events(renderer, &event)

			// Handle SDL events
			if event.type == .QUIT {
				running = false
			}

			if event.type == .MOUSE_BUTTON_DOWN {
				mouse_event := cast(^SDL.MouseButtonEvent)&event
				if mouse_event.button == 3 {  // Right mouse button
					controller.controller_handle_right_click(&game_controller)
				}
			}

			// Get next event
			have_event = SDL.PollEvent(&event)
		}

		// Calculate delta time
		current_time := SDL.GetTicks()
		delta_time := f64(current_time - last_frame_time) / 1000.0
		last_frame_time = current_time

		// Update game controller
		controller.controller_update(&game_controller, delta_time)

		// Render frame
		render.renderer_begin_frame(renderer)

		// Build UI (controller delegates to appropriate state)
		controller.controller_build_ui(&game_controller)

		// Render dynamic text overlays (controller delegates to appropriate state)
		controller.controller_render_dynamic_text(&game_controller, renderer)

		render.renderer_end_frame(renderer)
	}

	fmt.println("Exiting...")
}
