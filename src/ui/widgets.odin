package ui

import clay "vendor:clay-odin"

/////////////////////////////////////////////////////////////////////////////
// Widget Foundation - Custom Rendering Support
/////////////////////////////////////////////////////////////////////////////

// UI State for interaction tracking
UI_State :: struct {
	hovered_id: u32,
	active_id:  u32,
	mouse_pos: clay.Vector2,
	mouse_down: bool,
	frame_count: u64,  // For frame-based animation
}

ui_state_create :: proc() -> UI_State {
	return UI_State {
		hovered_id = 0,
		active_id = 0,
		mouse_pos = {0, 0},
		mouse_down = false,
		frame_count = 0,
	}
}

// Global UI state instance
ui_state: UI_State

// Initialize UI state
init_ui_state :: proc() {
	ui_state = ui_state_create()
	element_bounds = {}
	button_animations = {}
}

// Update UI state with mouse position and button state
update_ui_state_mouse :: proc(pos: clay.Vector2, mouse_down: bool) {
	ui_state.mouse_pos = pos
	ui_state.mouse_down = mouse_down
}

// Update UI state on mouse button events
update_ui_state_mouse_down :: proc(pos: clay.Vector2, mouse_down: bool) {
	ui_state.mouse_pos = pos
	ui_state.mouse_down = mouse_down

	// Don't clear active state here - let button_click handle it
	// This allows the button to detect the click in the same frame
}

/////////////////////////////////////////////////////////////////////////////
// Color Palette - Game Theme
/////////////////////////////////////////////////////////////////////////////

// Game color scheme
COLOR_BG :: clay.Color{20, 20, 25, 255}
COLOR_PANEL :: clay.Color{35, 35, 40, 255}
COLOR_PANEL_BORDER :: clay.Color{120, 215, 130, 255} // {60, 60, 70, 255}
COLOR_TEXT :: clay.Color{15, 15, 20, 255}
COLOR_TEXT_DIM :: clay.Color{150, 150, 160, 255}
COLOR_ACCENT :: clay.Color{100, 200, 150, 255}  // Green-ish
COLOR_ACCENT_HOVER :: clay.Color{120, 220, 170, 255}

COLOR_GP :: clay.Color{255, 215, 100, 255}  // Gold
COLOR_GP_DIM :: clay.Color{180, 150, 60, 255}

COLOR_SHARD :: clay.Color{180, 150, 255, 255}  // Silver/purple
COLOR_SHARD_DIM :: clay.Color{120, 100, 180, 255}

COLOR_CELL_DEAD :: clay.Color{30, 30, 35, 255}
COLOR_CELL_LIVE :: clay.Color{80, 200, 120, 255}  // Green glow
COLOR_CELL_CRYSTALLIZED :: clay.Color{180, 100, 220, 255}  // Purple/crystal

// Button colors - grass green theme
COLOR_BUTTON :: clay.Color{76, 175, 80, 255}  // Grass green (base)
COLOR_BUTTON_HOVER :: clay.Color{92, 196, 96, 255}  // Slightly more saturated
COLOR_BUTTON_ACTIVE :: clay.Color{180, 255, 180, 255}  // Highly saturated for click

COLOR_BUTTON_DISABLED :: clay.Color{40, 40, 45, 255}
COLOR_TEXT_DISABLED :: clay.Color{80, 80, 90, 255}

COLOR_HARVEST_ZONE :: clay.Color{40, 60, 40, 255}  // Subtle green overlay

/////////////////////////////////////////////////////////////////////////////
// Button Widget
/////////////////////////////////////////////////////////////////////////////

Button_Border_Config :: struct {
	color: clay.Color,
	thickness: f32,
	enabled: bool,
}

Button_Animation_State :: enum {
	IDLE,
	RIPPLE,
}

Button_Animation :: struct {
	state: Button_Animation_State,
	progress: f32,  // 0.0 to 1.0
	start_time: f64,
	center_x: f32,  // Center of button for ripple
	center_y: f32,
	max_radius: f32,  // Maximum ripple radius
}

Button_Config :: struct {
	id: clay.ElementId,
	enabled: bool,
	on_click: proc(),
	user_data: rawptr,

	// Styling (applied as overrides)
	border: Button_Border_Config,
	backgroundColor: clay.Color,
	cornerRadius: f32,
}

// Default button config
button_config :: proc(id: clay.ElementId) -> Button_Config {
	return Button_Config {
		id = id,
		enabled = true,
		on_click = {},
		user_data = nil,

		border = Button_Border_Config {
			color = COLOR_PANEL_BORDER,
			thickness = 5.0,
			enabled = true,
		},
		backgroundColor = COLOR_BUTTON,
		cornerRadius = 6.0,
	}
}

// Store element bounds for hit testing
element_bounds: map[u32]clay.BoundingBox

// Store button animations
button_animations: map[u32]Button_Animation

// Store element bounds from render commands
store_element_bounds :: proc(id: u32, bounds: clay.BoundingBox) {
	element_bounds[id] = bounds
}

// Linear interpolation between two colors
lerp_color :: proc(c1: clay.Color, c2: clay.Color, t: f32) -> clay.Color {
	return clay.Color {
		f32(c1[0]) + (f32(c2[0]) - f32(c1[0])) * t,
		f32(c1[1]) + (f32(c2[1]) - f32(c1[1])) * t,
		f32(c1[2]) + (f32(c2[2]) - f32(c1[2])) * t,
		f32(c1[3]) + (f32(c2[3]) - f32(c1[3])) * t,
	}
}

// Get current time in seconds (using SDL for timing)
get_time :: proc() -> f64 {
	// For now, we'll use a simple counter
	// TODO: Integrate with SDL's time functions
	return 0.0
}

// Check if button was clicked - call within clay.UI block
button_click :: proc(config: Button_Config) -> bool {
	// Try to get stored bounds for this element
	bounds, found := element_bounds[config.id.id]

	is_hovered := false
	if found {
		// Check if mouse is within bounds
		is_hovered = (
			ui_state.mouse_pos.x >= bounds.x &&
			ui_state.mouse_pos.x < bounds.x + bounds.width &&
			ui_state.mouse_pos.y >= bounds.y &&
			ui_state.mouse_pos.y < bounds.y + bounds.height
		)
	}

	// Update hover state
	if is_hovered {
		ui_state.hovered_id = config.id.id
	} else if ui_state.hovered_id == config.id.id && !is_hovered {
		// Clear hover if we're no longer over this button
		ui_state.hovered_id = 0
	}

	is_active := ui_state.active_id == config.id.id

	clicked_this_frame := false

	// Track active state when clicking
	if is_hovered && ui_state.mouse_down {
		ui_state.active_id = config.id.id
	}

	// Track click: button was pressed and now released
	if config.enabled && is_hovered && ui_state.mouse_down == false && is_active {
		clicked_this_frame = true
		if config.on_click != nil {
			config.on_click()
		}

		// Trigger ripple animation
		bounds, _ := element_bounds[config.id.id]
		button_animations[config.id.id] = Button_Animation {
			state = .RIPPLE,
			progress = 0.0,
			start_time = get_time(),
			center_x = bounds.x + bounds.width * 0.5,
			center_y = bounds.y + bounds.height * 0.5,
			max_radius = max(bounds.width, bounds.height) * 0.6,
		}

		ui_state.active_id = 0  // Clear active state after successful click
	}

	// Clear active state if mouse is released but not over this button
	if !ui_state.mouse_down && !is_hovered && ui_state.active_id == config.id.id {
		ui_state.active_id = 0
	}

	return clicked_this_frame
}

// Apply button styling to a Clay UI config
button_style :: proc(config: Button_Config, base_color: clay.Color) -> clay.Color {
	bg_color := config.backgroundColor
	if bg_color == (clay.Color{}) {
		bg_color = base_color
	}

	is_hovered := ui_state.hovered_id == config.id.id
	is_active := ui_state.active_id == config.id.id
	is_pressed := is_hovered && ui_state.mouse_down

	// Determine target color based on state
	target_color: clay.Color
	if !config.enabled {
		target_color = COLOR_BUTTON_DISABLED
	} else if is_hovered {
		target_color = COLOR_BUTTON_HOVER
	} else {
		target_color = COLOR_BUTTON
	}

	// Get and update animation state
	anim, has_anim := button_animations[config.id.id]
	if has_anim && anim.state != .IDLE {
		// Update animation progress (1.0 seconds at 60 FPS = 60 frames)
		anim.progress += 1.0 / 60.0

		if anim.state == .RIPPLE {
			// Animate from saturated color back to target with ease-out
			t := anim.progress
			ease_t := t * (2.0 - t)  // Ease out curve

			bg_color = lerp_color(COLOR_BUTTON_ACTIVE, target_color, ease_t)

			// End animation
			if anim.progress >= 1.0 {
				anim.state = .IDLE
				anim.progress = 0.0
			}
		}

		// Update the animation in the map
		if anim.state != .IDLE {
			button_animations[config.id.id] = anim
		} else {
			// Remove completed animation - just set it to idle
			button_animations[config.id.id] = Button_Animation {
				state = .IDLE,
				progress = 0.0,
				start_time = 0.0,
				center_x = 0,
				center_y = 0,
				max_radius = 0,
			}
		}
	} else if is_active || is_pressed {
		bg_color = COLOR_BUTTON_ACTIVE
	} else {
		bg_color = target_color
	}

	return bg_color
}

// Get button border config
button_border :: proc(config: Button_Config) -> clay.BorderElementConfig {
	border_color := config.border.color
	if !config.enabled {
		border_color = {40, 40, 45, 255}
	}

	border_width := [4]u16{1, 1, 1, 1}
	if config.border.enabled {
		thick := u16(config.border.thickness)
		border_width = [4]u16{thick, thick, thick, thick}
	}

	return clay.BorderElementConfig {
		width = {border_width[0], border_width[1], border_width[2], border_width[3], 0},
		color = border_color,
	}
}

// Get button corner radius
button_corner_radius :: proc(config: Button_Config) -> clay.CornerRadius {
	return clay.CornerRadius {
		topLeft = config.cornerRadius,
		topRight = config.cornerRadius,
		bottomLeft = config.cornerRadius,
		bottomRight = config.cornerRadius,
	}
}

// Check if button has an active ripple animation
button_has_animation :: proc(config: Button_Config) -> bool {
	anim, has_anim := button_animations[config.id.id]
	return has_anim && anim.state == .RIPPLE
}

// Get button animation progress (0.0 to 1.0)
button_animation_progress :: proc(config: Button_Config) -> f32 {
	anim, has_anim := button_animations[config.id.id]
	if has_anim && anim.state == .RIPPLE {
		return anim.progress
	}
	return 1.0  // No animation means fully target color
}

// Get animation bounds for custom rendering
button_animation_bounds :: proc(config: Button_Config) -> (clay.BoundingBox, bool) {
	bounds, found := element_bounds[config.id.id]
	anim, has_anim := button_animations[config.id.id]

	if found && has_anim && anim.state == .RIPPLE {
		return bounds, true
	}
	return bounds, false
}

// Check if a specific element ID has an active animation
get_element_has_animation :: proc(element_id: u32) -> bool {
	anim, has_anim := button_animations[element_id]
	return has_anim && anim.state == .RIPPLE
}

// Get animation info for an element ID
get_element_animation_info :: proc(element_id: u32) -> (f32, f32, f32, f32, bool) {
	// Returns: progress, center_x, center_y, max_radius, has_animation
	anim, has_anim := button_animations[element_id]
	if !has_anim || anim.state != .RIPPLE {
		return 0, 0, 0, 0, false
	}
	return anim.progress, anim.center_x, anim.center_y, anim.max_radius, true
}

// Get bounds for an element ID
get_element_bounds_by_id :: proc(element_id: u32) -> (clay.BoundingBox, bool) {
	bounds, found := element_bounds[element_id]
	return bounds, found
}

/////////////////////////////////////////////////////////////////////////////
// Utility Helpers
/////////////////////////////////////////////////////////////////////////////

// CornerRadius helper
CornerRadius :: proc(radius: f32) -> clay.CornerRadius {
	return clay.CornerRadius {
		topLeft = radius,
		topRight = radius,
		bottomLeft = radius,
		bottomRight = radius,
	}
}
