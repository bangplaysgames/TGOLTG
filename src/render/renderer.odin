package render

import SDL "vendor:sdl3"
import clay "vendor:clay-odin"
import SDL_ttf "vendor:sdl3/ttf"
import ui "../ui"
import "core:c"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:math"

/////////////////////////////////////////////////////////////////////////////
// Renderer State
/////////////////////////////////////////////////////////////////////////////

Renderer :: struct {
	window:       ^SDL.Window,
	sdl_renderer: ^SDL.Renderer,
	text_engine:  ^SDL_ttf.TextEngine,
	fonts:        []^SDL_ttf.Font,
	arena:        clay.Arena,
	screen_width: f32,
	screen_height: f32,
	stored_borders: map[u32]clay.BorderRenderData,  // Store border configs by element ID
}

/////////////////////////////////////////////////////////////////////////////
// Initialization
/////////////////////////////////////////////////////////////////////////////

@(private="file")
clay_measure_text_c :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, user_data: rawptr) -> clay.Dimensions {
	fonts_ptr := (^[]^SDL_ttf.Font)(user_data)

	// Safety check
	fonts := fonts_ptr^
	if int(config.fontId) >= len(fonts) {
		return {0, 0}
	}

	font := fonts_ptr^[config.fontId]
	if font == nil {
		return {0, 0}
	}

	SDL_ttf.SetFontSize(font, f32(config.fontSize))

	width: c.int
	height: c.int
	str := cstring(text.chars)
	if !SDL_ttf.GetStringSize(font, str, c.size_t(text.length), &width, &height) {
		// Silent fail on text measurement error
	}

	return {f32(width), f32(height)}
}

renderer_create :: proc(title: cstring, width: i32, height: i32) -> ^Renderer {
	renderer := new(Renderer)

	// Initialize SDL TTF
	if !SDL_ttf.Init() {
		fmt.println("Failed to initialize SDL_ttf")
		return nil
	}

	// Create window and renderer
	if !SDL.CreateWindowAndRenderer(
		title,
		width,
		height,
		{},
		&renderer.window,
		&renderer.sdl_renderer,
	) {
		fmt.println("Failed to create window and renderer")
		return nil
	}

	SDL.SetWindowResizable(renderer.window, true)

	// Create text engine
	renderer.text_engine = SDL_ttf.CreateRendererTextEngine(renderer.sdl_renderer)
	if renderer.text_engine == nil {
		fmt.println("Failed to create text engine")
		return nil
	}

	// Allocate font array (start with 1 slot)
	renderer.fonts = make([]^SDL_ttf.Font, 1)

	// Load default system font
	// Try common system fonts
	font_paths := []string{
		"C:\\Windows\\Fonts\\arial.ttf",
		"C:\\Windows\\Fonts\\segoeui.ttf",
		"C:\\Windows\\Fonts\\tahoma.ttf",
		"C:\\Windows\\Fonts\\verdana.ttf",
	}

	font_loaded := false
	for path in font_paths {
		if load_font(renderer, 0, path, 16) {
			fmt.printf("Loaded font: %s\n", path)
			font_loaded = true
			break
		}
	}

	if !font_loaded {
		fmt.println("Warning: Could not load any system font")
	}

	// Initialize Clay arena
	total_memory_size := clay.MinMemorySize()
	data, _ := mem.alloc(int(total_memory_size))
	renderer.arena.memory = ([^]u8)(data)
	renderer.arena.capacity = uint(total_memory_size)

	// Store screen dimensions
	renderer.screen_width = f32(width)
	renderer.screen_height = f32(height)

	// Initialize Clay
	clay.Initialize(
		renderer.arena,
		{renderer.screen_width, renderer.screen_height},
		clay.ErrorHandler {},
	)

	// Set up text measurement
	clay.SetMeasureTextFunction(clay_measure_text_c, rawptr(&renderer.fonts))

	return renderer
}

renderer_destroy :: proc(renderer: ^Renderer) {
	if renderer == nil {
		return
	}

	// Free fonts
	for font in renderer.fonts {
		if font != nil {
			SDL_ttf.CloseFont(font)
		}
	}
	delete(renderer.fonts)

	// Destroy text engine
	if renderer.text_engine != nil {
		SDL_ttf.DestroyRendererTextEngine(renderer.text_engine)
	}

	// Destroy renderer and window
	if renderer.sdl_renderer != nil {
		SDL.DestroyRenderer(renderer.sdl_renderer)
	}
	if renderer.window != nil {
		SDL.DestroyWindow(renderer.window)
	}

	// Free Clay arena
	if renderer.arena.memory != nil {
		mem.free(renderer.arena.memory)
	}

	// Quit SDL_ttf
	SDL_ttf.Quit()

	free(renderer)
}

/////////////////////////////////////////////////////////////////////////////
// Font Loading
/////////////////////////////////////////////////////////////////////////////

load_font :: proc(renderer: ^Renderer, font_id: int, path: string, size: int) -> bool {
	if font_id >= len(renderer.fonts) {
		// Expand font array if needed
		new_fonts := make([]^SDL_ttf.Font, font_id + 1)
		for i in 0 ..< len(renderer.fonts) {
			new_fonts[i] = renderer.fonts[i]
		}
		delete(renderer.fonts)
		renderer.fonts = new_fonts
	}

	font := SDL_ttf.OpenFont(strings.clone_to_cstring(path), f32(size))
	if font == nil {
		fmt.printf("Failed to load font: %s\n", path)
		return false
	}

	renderer.fonts[font_id] = font
	return true
}

/////////////////////////////////////////////////////////////////////////////
// Clay Integration
/////////////////////////////////////////////////////////////////////////////

renderer_begin_frame :: proc(renderer: ^Renderer) {
	// Clear screen with background color
	SDL.SetRenderDrawColor(renderer.sdl_renderer, 20, 20, 25, 255)
	SDL.RenderClear(renderer.sdl_renderer)

	// Begin Clay layout
	clay.BeginLayout()
}

renderer_end_frame :: proc(renderer: ^Renderer) {
	// End Clay layout and get render commands
	commands := clay.EndLayout()

	// Render Clay commands
	render_clay_commands(renderer, &commands)

	// Present frame
	SDL.RenderPresent(renderer.sdl_renderer)
}

handle_clay_events :: proc(renderer: ^Renderer, event: ^SDL.Event) {
	if event.type == .WINDOW_RESIZED {
		window_event := (^SDL.WindowEvent)(event)
		renderer.screen_width = f32(window_event.data1)
		renderer.screen_height = f32(window_event.data2)
		clay.SetLayoutDimensions({renderer.screen_width, renderer.screen_height})
	}

	if event.type == .MOUSE_MOTION {
		motion := (^SDL.MouseMotionEvent)(event)
		mouse_down := (motion.state & SDL.BUTTON_LMASK) == SDL.BUTTON_LMASK

		// Update Clay pointer state
		clay.SetPointerState(
			{motion.x, motion.y},
			mouse_down,
		)

		// Update UI state for button interactions
		ui.update_ui_state_mouse({motion.x, motion.y}, mouse_down)
	}

	if event.type == .MOUSE_BUTTON_DOWN {
		button := (^SDL.MouseButtonEvent)(event)
		if button.button == SDL.BUTTON_LEFT {
			// Update Clay pointer state
			clay.SetPointerState(
				{button.x, button.y},
				true,
			)

			// Update UI state
			ui.update_ui_state_mouse_down({button.x, button.y}, true)
		}
	}

	if event.type == .MOUSE_BUTTON_UP {
		button := (^SDL.MouseButtonEvent)(event)
		if button.button == SDL.BUTTON_LEFT {
			// Update Clay pointer state
			clay.SetPointerState(
				{button.x, button.y},
				false,
			)

			// Update UI state
			ui.update_ui_state_mouse_down({button.x, button.y}, false)
		}
	}

	if event.type == .MOUSE_WHEEL {
		wheel := (^SDL.MouseWheelEvent)(event)
		clay.UpdateScrollContainers(
			true,
			{wheel.x, wheel.y},
			0.01,
		)
	}
}

/////////////////////////////////////////////////////////////////////////////
// Clay Rendering
/////////////////////////////////////////////////////////////////////////////

render_rounded_rectangle :: proc(renderer: ^Renderer, rect: SDL.FRect, corner: clay.CornerRadius, color: clay.Color, border_color: clay.Color = {}, border_width: f32 = 0.0) {
	// Render rounded rectangle using filled circles and rectangles
	r := min(corner.topLeft, corner.topRight, corner.bottomLeft, corner.bottomRight)
	radius := min(f32(r), min(rect.w, rect.h) * 0.5)

	has_border := border_width > 0 && border_color != (clay.Color{})

	if radius <= 0 {
		// No rounding, use simple rectangle
		rect_copy := rect
		SDL.RenderFillRect(renderer.sdl_renderer, &rect_copy)

		// Draw border if present
		if has_border {
			SDL.SetRenderDrawColor(renderer.sdl_renderer, u8(border_color.r), u8(border_color.g), u8(border_color.b), u8(border_color.a))
			// Draw border as 4 rectangles - INSIDE the rectangle bounds
			thick := i32(border_width)
			for t in 0 ..< thick {
				offset := f32(t)
				// Top
				top_b: SDL.FRect = {rect.x + offset, rect.y + offset, rect.w - offset * 2.0, 1.0}
				SDL.RenderFillRect(renderer.sdl_renderer, &top_b)
				// Bottom
				bottom_b: SDL.FRect = {rect.x + offset, rect.y + rect.h - 1.0 - offset, rect.w - offset * 2.0, 1.0}
				SDL.RenderFillRect(renderer.sdl_renderer, &bottom_b)
				// Left
				left_b: SDL.FRect = {rect.x + offset, rect.y + offset, 1.0, rect.h - offset * 2.0}
				SDL.RenderFillRect(renderer.sdl_renderer, &left_b)
				// Right
				right_b: SDL.FRect = {rect.x + rect.w - 1.0 - offset, rect.y + offset, 1.0, rect.h - offset * 2.0}
				SDL.RenderFillRect(renderer.sdl_renderer, &right_b)
			}
		}
		return
	}

	SDL.SetRenderDrawColor(renderer.sdl_renderer, u8(color.r), u8(color.g), u8(color.b), u8(color.a))

	// Draw center rectangle (middle part without corners)
	center_rect: SDL.FRect = {
		rect.x + radius,
		rect.y + radius,
		rect.w - radius * 2.0,
		rect.h - radius * 2.0,
	}
	SDL.RenderFillRect(renderer.sdl_renderer, &center_rect)

	// Draw top and bottom rectangles
	top_rect: SDL.FRect = {
		rect.x + radius,
		rect.y,
		rect.w - radius * 2.0,
		radius,
	}
	bottom_rect: SDL.FRect = {
		rect.x + radius,
		rect.y + rect.h - radius,
		rect.w - radius * 2.0,
		radius,
	}
	SDL.RenderFillRect(renderer.sdl_renderer, &top_rect)
	SDL.RenderFillRect(renderer.sdl_renderer, &bottom_rect)

	// Draw left and right rectangles
	left_rect: SDL.FRect = {
		rect.x,
		rect.y + radius,
		radius,
		rect.h - radius * 2.0,
	}
	right_rect: SDL.FRect = {
		rect.x + rect.w - radius,
		rect.y + radius,
		radius,
		rect.h - radius * 2.0,
	}
	SDL.RenderFillRect(renderer.sdl_renderer, &left_rect)
	SDL.RenderFillRect(renderer.sdl_renderer, &right_rect)

	// Draw corner circles using triangle wedges from corner center
	// This fills the corner properly by drawing triangles from the center to each arc segment
	num_segments := i32(max(radius * 2.0, 12))  // More segments for smoother corners
	angle_step := f32(math.PI) * 0.5 / f32(num_segments)

	// Top-left corner - center at (rect.x + radius, rect.y + radius)
	corner_center_x := rect.x + radius
	corner_center_y := rect.y + radius
	for i in 0 ..< num_segments {
		angle1 := f32(math.PI) + f32(i) * angle_step
		angle2 := f32(math.PI) + f32(i + 1) * angle_step

		// Points on the arc
		x1 := corner_center_x + math.cos_f32(angle1) * radius
		y1 := corner_center_y + math.sin_f32(angle1) * radius
		x2 := corner_center_x + math.cos_f32(angle2) * radius
		y2 := corner_center_y + math.sin_f32(angle2) * radius

		// Draw triangle from corner center to the two arc points
		// We approximate this with multiple small rectangles
		tri_steps := 5
		for step in 0 ..< tri_steps {
			t := f32(step) / f32(tri_steps)

			// Interpolate between corner center and first arc point
			px1 := corner_center_x + (x1 - corner_center_x) * t
			py1 := corner_center_y + (y1 - corner_center_y) * t

			// Interpolate between corner center and second arc point
			px2 := corner_center_x + (x2 - corner_center_x) * t
			py2 := corner_center_y + (y2 - corner_center_y) * t

			// Rectangle between the two interpolated points
			tri_rect: SDL.FRect = {
				min(px1, px2),
				min(py1, py2),
				max(abs(px2 - px1), 2.0),
				max(abs(py2 - py1), 2.0),
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &tri_rect)
		}
	}

	// Top-right corner - center at (rect.x + rect.w - radius, rect.y + radius)
	corner_center_x = rect.x + rect.w - radius
	corner_center_y = rect.y + radius
	for i in 0 ..< num_segments {
		angle1 := f32(math.PI) * 1.5 + f32(i) * angle_step
		angle2 := f32(math.PI) * 1.5 + f32(i + 1) * angle_step

		x1 := corner_center_x + math.cos_f32(angle1) * radius
		y1 := corner_center_y + math.sin_f32(angle1) * radius
		x2 := corner_center_x + math.cos_f32(angle2) * radius
		y2 := corner_center_y + math.sin_f32(angle2) * radius

		tri_steps := 5
		for step in 0 ..< tri_steps {
			t := f32(step) / f32(tri_steps)

			px1 := corner_center_x + (x1 - corner_center_x) * t
			py1 := corner_center_y + (y1 - corner_center_y) * t
			px2 := corner_center_x + (x2 - corner_center_x) * t
			py2 := corner_center_y + (y2 - corner_center_y) * t

			tri_rect: SDL.FRect = {
				min(px1, px2),
				min(py1, py2),
				max(abs(px2 - px1), 2.0),
				max(abs(py2 - py1), 2.0),
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &tri_rect)
		}
	}

	// Bottom-left corner - center at (rect.x + radius, rect.y + rect.h - radius)
	corner_center_x = rect.x + radius
	corner_center_y = rect.y + rect.h - radius
	for i in 0 ..< num_segments {
		angle1 := f32(math.PI) * 0.5 + f32(i) * angle_step
		angle2 := f32(math.PI) * 0.5 + f32(i + 1) * angle_step

		x1 := corner_center_x + math.cos_f32(angle1) * radius
		y1 := corner_center_y + math.sin_f32(angle1) * radius
		x2 := corner_center_x + math.cos_f32(angle2) * radius
		y2 := corner_center_y + math.sin_f32(angle2) * radius

		tri_steps := 5
		for step in 0 ..< tri_steps {
			t := f32(step) / f32(tri_steps)

			px1 := corner_center_x + (x1 - corner_center_x) * t
			py1 := corner_center_y + (y1 - corner_center_y) * t
			px2 := corner_center_x + (x2 - corner_center_x) * t
			py2 := corner_center_y + (y2 - corner_center_y) * t

			tri_rect: SDL.FRect = {
				min(px1, px2),
				min(py1, py2),
				max(abs(px2 - px1), 2.0),
				max(abs(py2 - py1), 2.0),
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &tri_rect)
		}
	}

	// Bottom-right corner - center at (rect.x + rect.w - radius, rect.y + rect.h - radius)
	corner_center_x = rect.x + rect.w - radius
	corner_center_y = rect.y + rect.h - radius
	for i in 0 ..< num_segments {
		angle1 := f32(i) * angle_step
		angle2 := f32(i + 1) * angle_step

		x1 := corner_center_x + math.cos_f32(angle1) * radius
		y1 := corner_center_y + math.sin_f32(angle1) * radius
		x2 := corner_center_x + math.cos_f32(angle2) * radius
		y2 := corner_center_y + math.sin_f32(angle2) * radius

		tri_steps := 5
		for step in 0 ..< tri_steps {
			t := f32(step) / f32(tri_steps)

			px1 := corner_center_x + (x1 - corner_center_x) * t
			py1 := corner_center_y + (y1 - corner_center_y) * t
			px2 := corner_center_x + (x2 - corner_center_x) * t
			py2 := corner_center_y + (y2 - corner_center_y) * t

			tri_rect: SDL.FRect = {
				min(px1, px2),
				min(py1, py2),
				max(abs(px2 - px1), 2.0),
				max(abs(py2 - py1), 2.0),
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &tri_rect)
		}
	}

	// Draw border with rounded corners if present
	if has_border {
		SDL.SetRenderDrawColor(renderer.sdl_renderer, u8(border_color.r), u8(border_color.g), u8(border_color.b), u8(border_color.a))

		// Use multiple small rectangles to trace the border following the rounded corners
		border_segments := i32(max(radius * 2.0, 12))  // Match background segments
		border_angle_step := f32(math.PI) * 0.5 / f32(border_segments)
		border_thickness_int := i32(max(border_width, 1.0))

		// Top edge (with rounded corners) - draw INSIDE the button
		for t in 0 ..< border_thickness_int {
			offset := f32(t)
			// Top-left corner arc - angles from PI to 1.5*PI
			for i in 0 ..< border_segments {
				angle1 := f32(math.PI) + f32(i) * border_angle_step
				angle2 := f32(math.PI) + f32(i + 1) * border_angle_step

				// For top-left, we want the border inside the corner
				// The corner center is at (rect.x + radius, rect.y + radius)
				// We draw the border along the inner edge
				x1 := rect.x + radius + math.cos_f32(angle1) * (radius - offset)
				y1 := rect.y + radius + math.sin_f32(angle1) * (radius - offset)
				x2 := rect.x + radius + math.cos_f32(angle2) * (radius - offset)
				y2 := rect.y + radius + math.sin_f32(angle2) * (radius - offset)

				border_seg: SDL.FRect = {
					min(x1, x2),
					min(y1, y2),
					max(abs(x2 - x1), 1.0),
					max(abs(y2 - y1), 1.0),
				}
				SDL.RenderFillRect(renderer.sdl_renderer, &border_seg)
			}

			// Top edge
			top_border: SDL.FRect = {
				rect.x + radius,
				rect.y + offset,
				rect.w - radius * 2.0,
				1.0,
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &top_border)

			// Top-right corner arc - angles from 1.5*PI to 2*PI
			for i in 0 ..< border_segments {
				angle1 := f32(math.PI) * 1.5 + f32(i) * border_angle_step
				angle2 := f32(math.PI) * 1.5 + f32(i + 1) * border_angle_step

				// Corner center is at (rect.x + rect.w - radius, rect.y + radius)
				x1 := rect.x + rect.w - radius + math.cos_f32(angle1) * (radius - offset)
				y1 := rect.y + radius + math.sin_f32(angle1) * (radius - offset)
				x2 := rect.x + rect.w - radius + math.cos_f32(angle2) * (radius - offset)
				y2 := rect.y + radius + math.sin_f32(angle2) * (radius - offset)

				border_seg: SDL.FRect = {
					min(x1, x2),
					min(y1, y2),
					max(abs(x2 - x1), 1.0),
					max(abs(y2 - y1), 1.0),
				}
				SDL.RenderFillRect(renderer.sdl_renderer, &border_seg)
			}
		}

		// Bottom edge (with rounded corners) - draw INSIDE the button
		for t in 0 ..< border_thickness_int {
			offset := f32(t)
			// Bottom-left corner arc - angles from 0.5*PI to PI
			for i in 0 ..< border_segments {
				angle1 := f32(math.PI) * 0.5 + f32(i) * border_angle_step
				angle2 := f32(math.PI) * 0.5 + f32(i + 1) * border_angle_step

				// Corner center is at (rect.x + radius, rect.y + rect.h - radius)
				x1 := rect.x + radius + math.cos_f32(angle1) * (radius - offset)
				y1 := rect.y + rect.h - radius + math.sin_f32(angle1) * (radius - offset)
				x2 := rect.x + radius + math.cos_f32(angle2) * (radius - offset)
				y2 := rect.y + rect.h - radius + math.sin_f32(angle2) * (radius - offset)

				border_seg: SDL.FRect = {
					min(x1, x2),
					min(y1, y2),
					max(abs(x2 - x1), 1.0),
					max(abs(y2 - y1), 1.0),
				}
				SDL.RenderFillRect(renderer.sdl_renderer, &border_seg)
			}

			// Bottom edge
			bottom_border: SDL.FRect = {
				rect.x + radius,
				rect.y + rect.h - offset - 1.0,
				rect.w - radius * 2.0,
				1.0,
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &bottom_border)

			// Bottom-right corner arc - angles from 0 to 0.5*PI
			for i in 0 ..< border_segments {
				angle1 := f32(i) * border_angle_step
				angle2 := f32(i + 1) * border_angle_step

				// Corner center is at (rect.x + rect.w - radius, rect.y + rect.h - radius)
				x1 := rect.x + rect.w - radius + math.cos_f32(angle1) * (radius - offset)
				y1 := rect.y + rect.h - radius + math.sin_f32(angle1) * (radius - offset)
				x2 := rect.x + rect.w - radius + math.cos_f32(angle2) * (radius - offset)
				y2 := rect.y + rect.h - radius + math.sin_f32(angle2) * (radius - offset)

				border_seg: SDL.FRect = {
					min(x1, x2),
					min(y1, y2),
					max(abs(x2 - x1), 1.0),
					max(abs(y2 - y1), 1.0),
				}
				SDL.RenderFillRect(renderer.sdl_renderer, &border_seg)
			}
		}

		// Left edge - draw INSIDE the button
		for t in 0 ..< border_thickness_int {
			offset := f32(t)
			left_border: SDL.FRect = {
				rect.x + offset,
				rect.y + radius,
				1.0,
				rect.h - radius * 2.0,
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &left_border)
		}

		// Right edge - draw INSIDE the button
		for t in 0 ..< border_thickness_int {
			offset := f32(t)
			right_border: SDL.FRect = {
				rect.x + rect.w - offset - 1.0,
				rect.y + radius,
				1.0,
				rect.h - radius * 2.0,
			}
			SDL.RenderFillRect(renderer.sdl_renderer, &right_border)
		}
	}
}

// Render expanding circle ripple effect on button
render_button_ripple :: proc(renderer: ^Renderer, element_id: u32) {
	// Check if this element has an active animation
	has_anim := ui.get_element_has_animation(element_id)
	if !has_anim {
		return
	}

	// Get animation info
	progress, center_x, center_y, max_radius, _ := ui.get_element_animation_info(element_id)
	if !has_anim {
		return
	}

	// Get element bounds for clipping
	bounds, has_bounds := ui.get_element_bounds_by_id(element_id)
	if !has_bounds {
		return
	}

	// Calculate current ripple radius
	current_radius := max_radius * progress

	if current_radius <= 0 {
		return
	}

	// Set up scissor rect to clip to button bounds
	clip_rect := SDL.Rect {
		i32(bounds.x),
		i32(bounds.y),
		i32(bounds.width),
		i32(bounds.height),
	}
	SDL.SetRenderClipRect(renderer.sdl_renderer, &clip_rect)

	// Set color to hover color (the ripple color)
	SDL.SetRenderDrawColor(
		renderer.sdl_renderer,
		u8(ui.COLOR_BUTTON_HOVER.r),
		u8(ui.COLOR_BUTTON_HOVER.g),
		u8(ui.COLOR_BUTTON_HOVER.b),
		u8(ui.COLOR_BUTTON_HOVER.a),
	)

	// Draw filled circle using multiple triangles
	num_segments := i32(max(current_radius * 0.5, 8))
	angle_step := f32(math.PI) * 2.0 / f32(num_segments)

	for i in 0 ..< num_segments {
		angle1 := f32(i) * angle_step
		angle2 := f32(i + 1) * angle_step

		x1 := center_x + math.cos_f32(angle1) * current_radius
		y1 := center_y + math.sin_f32(angle1) * current_radius
		x2 := center_x + math.cos_f32(angle2) * current_radius
		y2 := center_y + math.sin_f32(angle2) * current_radius

		// Draw triangle using filled polygon approach
		// For simplicity, we'll draw it as 3 small rectangles forming a triangle approximation
		// Center to first edge point
		mid_x1 := (center_x + x1) * 0.5
		mid_y1 := (center_y + y1) * 0.5
		dx1 := x1 - center_x
		dy1 := y1 - center_y

		// Draw multiple rectangles along each triangle edge
		steps := 5
		for step in 0 ..< steps {
			t1 := f32(step) / f32(steps)
			t2 := f32(step + 1) / f32(steps)

			// Point on edge 1
			px1_a := center_x + dx1 * t1
			py1_a := center_y + dy1 * t1
			px1_b := center_x + dx1 * t2
			py1_b := center_y + dy1 * t2

			// Point on edge 2
			dx2 := x2 - center_x
			dy2 := y2 - center_y
			px2_a := center_x + dx2 * t1
			py2_a := center_y + dy2 * t1
			px2_b := center_x + dx2 * t2
			py2_b := center_y + dy2 * t2

			// Rectangle between the two edges
			rect_x := min(px1_a, px2_a)
			rect_y := min(py1_a, py2_a)
			rect_w := max(abs(px2_a - px1_a), abs(px2_b - px1_b), 2.0)
			rect_h := max(abs(py2_a - py1_a), abs(py2_b - py1_b), 2.0)

			tri_rect: SDL.FRect = {rect_x, rect_y, rect_w, rect_h}
			SDL.RenderFillRect(renderer.sdl_renderer, &tri_rect)
		}
	}

	// CRITICAL: Disable clipping entirely by setting clip rect to null bounds
	// This ensures clipping doesn't persist to affect subsequent rendering
	SDL.SetRenderClipRect(renderer.sdl_renderer, nil)
}

render_clay_commands :: proc(renderer: ^Renderer, commands: ^clay.ClayArray(clay.RenderCommand)) {
	// First pass: collect all borders by their bounds
	border_map: map[clay.BoundingBox]clay.BorderRenderData

	for i: u32 = 0; i < u32(commands.length); i += 1 {
		cmd := commands.internalArray[i]
		if cmd.commandType == clay.RenderCommandType.Border {
			border_map[cmd.boundingBox] = cmd.renderData.border
		}
	}

	// Second pass: render everything, looking up borders by bounds
	for i: u32 = 0; i < u32(commands.length); i += 1 {
		cmd := commands.internalArray[i]
		bounds := cmd.boundingBox

		// Store element bounds for hit testing
		ui.store_element_bounds(cmd.id, bounds)

		rect: SDL.FRect = {
			bounds.x,
			bounds.y,
			bounds.width,
			bounds.height,
		}

		#partial switch cmd.commandType {
			case clay.RenderCommandType.Border:
				// Skip - borders are handled in rectangle rendering

			case clay.RenderCommandType.Rectangle:
				// Look up border by matching bounds
				border_config, has_border := border_map[cmd.boundingBox]
				if has_border {
					renderer.stored_borders[cmd.id] = border_config
				}
				render_rectangle(renderer, rect, cmd)
				// Render ripple overlay if this button has an active animation
				render_button_ripple(renderer, cmd.id)

			case clay.RenderCommandType.Text:
				render_text(renderer, rect, cmd)

			case clay.RenderCommandType.ScissorStart:
				render_scissor_start(renderer, bounds)

			case clay.RenderCommandType.ScissorEnd:
				render_scissor_end(renderer)

			case:
				// Ignore other commands
		}
	}
}

render_rectangle :: proc(renderer: ^Renderer, rect: SDL.FRect, cmd: clay.RenderCommand) {
	config := cmd.renderData.rectangle

	// Look up border config for this element
	border_config, has_border := renderer.stored_borders[cmd.id]
	border_color: clay.Color
	border_width: f32 = 0.0
	if has_border && (border_config.width.left > 0 || border_config.width.top > 0 || border_config.width.right > 0 || border_config.width.bottom > 0) {
		border_color = border_config.color
		// Use the first non-zero width as the border thickness
		border_width = f32(max(max(border_config.width.left, border_config.width.top), max(border_config.width.right, border_config.width.bottom)))
	}

	SDL.SetRenderDrawBlendMode(renderer.sdl_renderer, SDL.BLENDMODE_BLEND)

	// Check if we have rounded corners
	corner := config.cornerRadius

	if corner.topLeft == 0 && corner.topRight == 0 && corner.bottomLeft == 0 && corner.bottomRight == 0 {
		// No rounded corners, use simple rectangle
		SDL.SetRenderDrawColor(
			renderer.sdl_renderer,
			u8(config.backgroundColor.r),
			u8(config.backgroundColor.g),
			u8(config.backgroundColor.b),
			u8(config.backgroundColor.a),
		)
		rect_copy := rect
		SDL.RenderFillRect(renderer.sdl_renderer, &rect_copy)
	} else {
		// Render rounded rectangle with border (function sets its own colors)
		render_rounded_rectangle(renderer, rect, corner, config.backgroundColor, border_color, border_width)
	}
}

render_text :: proc(renderer: ^Renderer, rect: SDL.FRect, cmd: clay.RenderCommand) {
	config := cmd.renderData.text

	font := renderer.fonts[config.fontId]
	if font == nil {
		return
	}

	SDL_ttf.SetFontSize(font, f32(config.fontSize))

	cstr := cstring(config.stringContents.chars)

	text := SDL_ttf.CreateText(
		renderer.text_engine,
		font,
		cstr,
		c.size_t(config.stringContents.length),
	)
	defer SDL_ttf.DestroyText(text)

	SDL_ttf.SetTextColor(
		text,
		u8(config.textColor.r),
		u8(config.textColor.g),
		u8(config.textColor.b),
		u8(config.textColor.a),
	)

	SDL_ttf.DrawRendererText(text, rect.x, rect.y)
}

// Direct text rendering for dynamic text values
render_text_direct :: proc(renderer: ^Renderer, text_str: string, x, y: f32, font_size: f32, color: clay.Color) {
	font := renderer.fonts[0]  // Use default font
	if font == nil {
		return
	}

	SDL_ttf.SetFontSize(font, font_size)

	// Convert string to cstring (create temporary null-terminated copy)
	temp_cstr := make([]u8, len(text_str) + 1)
	copy(temp_cstr, text_str)
	temp_cstr[len(text_str)] = 0
	cstr := cstring(&temp_cstr[0])

	text := SDL_ttf.CreateText(
		renderer.text_engine,
		font,
		cstr,
		len(text_str),
	)

	delete(temp_cstr)

	if text != nil {
		SDL.SetRenderDrawColor(renderer.sdl_renderer, u8(color.r), u8(color.g), u8(color.b), u8(color.a))
		SDL_ttf.DrawRendererText(text, x, y)
		SDL_ttf.DestroyText(text)
	}
}

render_border :: proc(renderer: ^Renderer, rect: SDL.FRect, cmd: clay.RenderCommand) {
	config := cmd.renderData.border

	SDL.SetRenderDrawColor(
		renderer.sdl_renderer,
		u8(config.color.r),
		u8(config.color.g),
		u8(config.color.b),
		u8(config.color.a),
	)

	// Left edge
	if config.width.left > 0 {
		border_rect: SDL.FRect = {
			rect.x - 1,
			rect.y,
			f32(config.width.left),
			rect.h,
		}
		SDL.RenderFillRect(renderer.sdl_renderer, &border_rect)
	}

	// Right edge
	if config.width.right > 0 {
		border_rect: SDL.FRect = {
			rect.x + rect.w - f32(config.width.right) + 1,
			rect.y,
			f32(config.width.right),
			rect.h,
		}
		SDL.RenderFillRect(renderer.sdl_renderer, &border_rect)
	}

	// Top edge
	if config.width.top > 0 {
		border_rect: SDL.FRect = {
			rect.x,
			rect.y - 1,
			rect.w,
			f32(config.width.top),
		}
		SDL.RenderFillRect(renderer.sdl_renderer, &border_rect)
	}

	// Bottom edge
	if config.width.bottom > 0 {
		border_rect: SDL.FRect = {
			rect.x,
			rect.y + rect.h - f32(config.width.bottom) + 1,
			rect.w,
			f32(config.width.bottom),
		}
		SDL.RenderFillRect(renderer.sdl_renderer, &border_rect)
	}

	// TODO: Implement rounded corners for borders
}

current_clip_rect: SDL.Rect

render_scissor_start :: proc(renderer: ^Renderer, bounds: clay.BoundingBox) {
	current_clip_rect = SDL.Rect {
		i32(bounds.x),
		i32(bounds.y),
		i32(bounds.width),
		i32(bounds.height),
	}
	SDL.SetRenderClipRect(renderer.sdl_renderer, &current_clip_rect)
}

render_scissor_end :: proc(renderer: ^Renderer) {
	SDL.SetRenderClipRect(renderer.sdl_renderer, nil)
}
