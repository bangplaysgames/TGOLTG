package state

import clay "vendor:clay-odin"
import render "../render"
import ui "../ui"
import "core:fmt"

/////////////////////////////////////////////////////////////////////////////
// Play State - EVERYTHING happens through init()
/////////////////////////////////////////////////////////////////////////////

Phase :: enum {
	SEEDING,
	SIMULATING,
}

Cell_State :: enum {
	DEAD,
	LIVE,
	CRYSTALLIZED,
}

// THE SINGLE INIT FUNCTION - initializes play state
// Takes rawptr to avoid cyclic imports
transition_to_play :: proc(play_data: rawptr) {
	fmt.println("Initializing Play State")
	_ = play_data
}

playstate_build_ui :: proc(play_data: rawptr) {
	// TODO: Get actual play data and call game functions
	_ = play_data

	// Root container
	if clay.UI(clay.ID("GameRoot"))({
		layout = {
			layoutDirection = .TopToBottom,
			sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
			padding = clay.PaddingAll(8),
			childGap = 8,
		},
	}) {
		// Top bar
		if clay.UI(clay.ID("TopBar"))({
			layout = {
				layoutDirection = .LeftToRight,
				sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(50) },
				childGap = 8,
				padding = clay.PaddingAll(8),
			},
			backgroundColor = ui.COLOR_PANEL,
			border = {width = {2, 2, 2, 2, 0}, color = ui.COLOR_PANEL_BORDER},
			cornerRadius = ui.CornerRadius(6.0),
		}) {
			// Stats - left side
			if clay.UI(clay.ID("StatsContainer"))({
				layout = {
					layoutDirection = .LeftToRight,
					sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
					childGap = 16,
					childAlignment = { x = .Left, y = .Center },
				},
			}) {
				// Seeds
				if clay.UI(clay.ID("SeedsLabel"))({
					layout = {
						layoutDirection = .TopToBottom,
						sizing = { width = clay.SizingFixed(120), height = clay.SizingGrow({}) },
						childGap = 2,
					},
				}) {
					clay.Text("Seeds:", clay.TextConfig({
						fontSize = 12,
						textColor = ui.COLOR_TEXT_DIM,
					}))
					if clay.UI(clay.ID("SeedsLabel_Value"))({
						layout = {
							sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(20) },
						},
					}) {
						clay.Text("", clay.TextConfig({
							fontSize = 14,
							textColor = {0, 0, 0, 0},
						}))
					}
				}

				// Harvested
				if clay.UI(clay.ID("HarvestedLabel"))({
					layout = {
						layoutDirection = .TopToBottom,
						sizing = { width = clay.SizingFixed(120), height = clay.SizingGrow({}) },
						childGap = 2,
					},
				}) {
					clay.Text("Harvested:", clay.TextConfig({
						fontSize = 12,
						textColor = ui.COLOR_GP_DIM,
					}))
					if clay.UI(clay.ID("HarvestedLabel_Value"))({
						layout = {
							sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(20) },
						},
					}) {
						clay.Text("", clay.TextConfig({
							fontSize = 14,
							textColor = {0, 0, 0, 0},
						}))
					}
				}

				// Total GP
				if clay.UI(clay.ID("CurrencyLabel"))({
					layout = {
						layoutDirection = .TopToBottom,
						sizing = { width = clay.SizingFixed(120), height = clay.SizingGrow({}) },
						childGap = 2,
					},
				}) {
					clay.Text("Total GP:", clay.TextConfig({
						fontSize = 12,
						textColor = ui.COLOR_GP_DIM,
					}))
					if clay.UI(clay.ID("CurrencyLabel_Value"))({
						layout = {
							sizing = { width = clay.SizingGrow({}), height = clay.SizingFixed(20) },
						},
					}) {
						clay.Text("", clay.TextConfig({
							fontSize = 14,
							textColor = {0, 0, 0, 0},
						}))
					}
				}
			}

			// Controls - right side
			if clay.UI(clay.ID("ControlsContainer"))({
				layout = {
					layoutDirection = .LeftToRight,
					sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
					childGap = 6,
					childAlignment = { x = .Right, y = .Center },
				},
			}) {
				// Run button
				run_btn_id := clay.ID("RunButton")
				run_btn := ui.button_config(run_btn_id)
				if clay.UI(run_btn_id)({
					layout = {
						sizing = { width = clay.SizingFixed(70), height = clay.SizingFixed(32) },
						padding = clay.PaddingAll(6),
					},
					backgroundColor = ui.button_style(run_btn, ui.COLOR_BUTTON),
					border = ui.button_border(run_btn),
					cornerRadius = ui.button_corner_radius(run_btn),
				}) {
					clay.Text("Run", clay.TextConfig({
						fontSize = 13,
						textColor = ui.COLOR_TEXT,
					}))
					_ = ui.button_click(run_btn)
				}

				// Stop button
				stop_btn_id := clay.ID("StopButton")
				stop_btn := ui.button_config(stop_btn_id)
				if clay.UI(stop_btn_id)({
					layout = {
						sizing = { width = clay.SizingFixed(70), height = clay.SizingFixed(32) },
						padding = clay.PaddingAll(6),
					},
					backgroundColor = ui.button_style(stop_btn, ui.COLOR_BUTTON),
					border = ui.button_border(stop_btn),
					cornerRadius = ui.button_corner_radius(stop_btn),
				}) {
					clay.Text("Stop", clay.TextConfig({
						fontSize = 13,
						textColor = ui.COLOR_TEXT,
					}))
					_ = ui.button_click(stop_btn)
				}

				// Reset button
				reset_btn_id := clay.ID("ResetButton")
				reset_btn := ui.button_config(reset_btn_id)
				if clay.UI(reset_btn_id)({
					layout = {
						sizing = { width = clay.SizingFixed(70), height = clay.SizingFixed(32) },
						padding = clay.PaddingAll(6),
					},
					backgroundColor = ui.button_style(reset_btn, ui.COLOR_BUTTON),
					border = ui.button_border(reset_btn),
					cornerRadius = ui.button_corner_radius(reset_btn),
				}) {
					clay.Text("Reset", clay.TextConfig({
						fontSize = 13,
						textColor = ui.COLOR_TEXT,
					}))
					_ = ui.button_click(reset_btn)
				}

				// Menu button
				menu_btn_id := clay.ID("MenuButton")
				menu_btn := ui.button_config(menu_btn_id)
				if clay.UI(menu_btn_id)({
					layout = {
						sizing = { width = clay.SizingFixed(70), height = clay.SizingFixed(32) },
						padding = clay.PaddingAll(6),
					},
					backgroundColor = ui.button_style(menu_btn, ui.COLOR_BUTTON),
					border = ui.button_border(menu_btn),
					cornerRadius = ui.button_corner_radius(menu_btn),
				}) {
					clay.Text("Menu", clay.TextConfig({
						fontSize = 13,
						textColor = ui.COLOR_TEXT,
					}))
					_ = ui.button_click(menu_btn)
				}
			}
		}

		// Main content - grid and info
		if clay.UI(clay.ID("MainContent"))({
			layout = {
				layoutDirection = .LeftToRight,
				sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
				childGap = 8,
			},
		}) {
			// Grid container
			if clay.UI(clay.ID("GridContainer"))({
				layout = {
					layoutDirection = .TopToBottom,
					sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
					childAlignment = { x = .Center, y = .Center },
					padding = clay.PaddingAll(8),
				},
				backgroundColor = ui.COLOR_PANEL,
				border = {width = {2, 2, 2, 2, 0}, color = ui.COLOR_PANEL_BORDER},
				cornerRadius = ui.CornerRadius(6.0),
			}) {
				clay.Text("[Grid will be rendered here]", clay.TextConfig({
					fontSize = 14,
					textColor = ui.COLOR_TEXT_DIM,
				}))
			}

			// Info panel
			if clay.UI(clay.ID("InfoPanel"))({
				layout = {
					layoutDirection = .TopToBottom,
					sizing = { width = clay.SizingFixed(200), height = clay.SizingGrow({}) },
					childGap = 8,
					padding = clay.PaddingAll(12),
				},
				backgroundColor = ui.COLOR_PANEL,
				border = {width = {2, 2, 2, 2, 0}, color = ui.COLOR_PANEL_BORDER},
				cornerRadius = ui.CornerRadius(6.0),
			}) {
				clay.Text("Instructions", clay.TextConfig({
					fontSize = 16,
					textColor = ui.COLOR_TEXT,
				}))

				clay.Text("• Left-click: place", clay.TextConfig({
					fontSize = 12,
					textColor = ui.COLOR_TEXT_DIM,
				}))

				clay.Text("• Right-click: remove", clay.TextConfig({
					fontSize = 12,
					textColor = ui.COLOR_TEXT_DIM,
				}))

				clay.Text("• Center 3x3: harvest", clay.TextConfig({
					fontSize = 12,
					textColor = ui.COLOR_TEXT_DIM,
				}))

				clay.Text("", clay.TextConfig({fontSize = 8}))

				clay.Text("Status: Seeding", clay.TextConfig({
					fontSize = 13,
					textColor = ui.COLOR_ACCENT,
				}))
			}
		}
	}
}

playstate_render_dynamic_text :: proc(play_data: rawptr, renderer: ^render.Renderer) {
	_ = play_data
	_ = renderer
	// TODO: Implement
}

playstate_handle_input :: proc(play_data: rawptr) {
	_ = play_data
	// TODO: Implement
}
