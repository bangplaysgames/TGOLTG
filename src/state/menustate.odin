package state

import clay "vendor:clay-odin"
import ui "../ui"
import "core:fmt"

/////////////////////////////////////////////////////////////////////////////
// Menu State - EVERYTHING happens through init()
/////////////////////////////////////////////////////////////////////////////

transition_to_menu :: proc() {
	fmt.println("Initializing Menu State")
}

menustate_build_ui :: proc() {
	// Main container - fills screen
	if clay.UI(clay.ID("MainContainer"))({
		layout = {
			layoutDirection = .TopToBottom,
			sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
			padding = clay.PaddingAll(32),
			childGap = 24,
			childAlignment = { x = .Center, y = .Center },
		},
	}) {
		// Title
		clay.Text("Game of Life - The Game", clay.TextConfig({
			fontSize = 32,
			textColor = {220, 220, 230, 255},
		}))

		// Menu container - holds buttons
		if clay.UI(clay.ID("MenuContainer"))({
			layout = {
				layoutDirection = .TopToBottom,
				sizing = { width = clay.SizingFixed(300), height = clay.SizingGrow({}) },
				childGap = 12,
				padding = clay.PaddingAll(16),
			},
		}) {
			// Start Button
			start_btn_id := clay.ID("StartButton")
			start_btn := ui.button_config(start_btn_id)

			if clay.UI(start_btn_id)({
				layout = {
					sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(44) },
					padding = clay.PaddingAll(12),
				},
				backgroundColor = ui.button_style(start_btn, ui.COLOR_BUTTON),
				border = ui.button_border(start_btn),
				cornerRadius = ui.button_corner_radius(start_btn),
			}) {
				clay.Text("Start Simulation", clay.TextConfig({
					fontSize = 16,
					textColor = ui.COLOR_TEXT,
				}))
				_ = ui.button_click(start_btn)
			}

			// Options Button
			options_btn_id := clay.ID("OptionsButton")
			options_btn := ui.button_config(options_btn_id)
			options_btn.on_click = proc() {
				fmt.println("Options clicked!")
			}

			if clay.UI(options_btn_id)({
				layout = {
					sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(44) },
					padding = clay.PaddingAll(12),
				},
				backgroundColor = ui.button_style(options_btn, ui.COLOR_BUTTON),
				border = ui.button_border(options_btn),
				cornerRadius = ui.button_corner_radius(options_btn),
			}) {
				clay.Text("Options", clay.TextConfig({
					fontSize = 16,
					textColor = ui.COLOR_TEXT,
				}))
				_ = ui.button_click(options_btn)
			}

			// Quit Button
			quit_btn_id := clay.ID("QuitButton")
			quit_btn := ui.button_config(quit_btn_id)
			quit_btn.on_click = proc() {
				fmt.println("Quit clicked!")
			}

			if clay.UI(quit_btn_id)({
				layout = {
					sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(44) },
					padding = clay.PaddingAll(12),
				},
				backgroundColor = ui.button_style(quit_btn, ui.COLOR_BUTTON),
				border = ui.button_border(quit_btn),
				cornerRadius = ui.button_corner_radius(quit_btn),
			}) {
				clay.Text("Quit", clay.TextConfig({
					fontSize = 16,
					textColor = ui.COLOR_TEXT,
				}))
				_ = ui.button_click(quit_btn)
			}
		}
	}
}

menustate_was_start_clicked :: proc() -> bool {
	start_btn_id := clay.ID("StartButton")
	start_btn := ui.button_config(start_btn_id)
	return ui.button_click(start_btn)
}
