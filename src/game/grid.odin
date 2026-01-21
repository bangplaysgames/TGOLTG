package game

Cell_State :: enum u8 {
	DEAD     = 0,
	LIVE     = 1,
	CRYSTALLIZED = 2,
}

Grid :: struct {
	size: int,
	cells: []Cell_State,
}

// Create a new grid with specified size (e.g., 5 for 5x5)
grid_create :: proc(size: int) -> Grid {
	grid: Grid
	grid.size = size
	grid.cells = make([]Cell_State, size * size)

	// Initialize all cells to dead
	for i in 0 ..< len(grid.cells) {
		grid.cells[i] = .DEAD
	}

	return grid
}

// Get cell at position (x, y) - returns DEAD if out of bounds
grid_get_cell :: proc(grid: ^Grid, x, y: int) -> Cell_State {
	if x < 0 || x >= grid.size || y < 0 || y >= grid.size {
		return .DEAD
	}

	index := y * grid.size + x
	return grid.cells[index]
}

// Set cell at position (x, y)
grid_set_cell :: proc(grid: ^Grid, x, y: int, state: Cell_State) {
	if x < 0 || x >= grid.size || y < 0 || y >= grid.size {
		return
	}

	index := y * grid.size + x
	grid.cells[index] = state
}

// Count live neighbors for a cell at (x, y)
// Uses standard Moore neighborhood (8 neighbors)
grid_count_neighbors :: proc(grid: ^Grid, x, y: int) -> int {
	count := 0

	// Check all 8 neighbors
	for dy in -1 ..= 1 {
		for dx in -1 ..= 1 {
			if dx == 0 && dy == 0 {
				continue
			}

			nx := x + dx
			ny := y + dy

			// Grid is finite (no wraparound), edges pad with DEAD
			cell := grid_get_cell(grid, nx, ny)
			if cell == .LIVE || cell == .CRYSTALLIZED {
				count += 1
			}
		}
	}

	return count
}

// Check if position (x, y) is in harvest zone
// Harvest zone is central 3x3 for any grid size
grid_in_harvest_zone :: proc(grid: ^Grid, x, y: int) -> bool {
	harvest_zone_size := 3
	harvest_start := grid.size / 2 - harvest_zone_size / 2
	harvest_end := harvest_start + harvest_zone_size

	return x >= harvest_start && x < harvest_end &&
	       y >= harvest_start && y < harvest_end
}

// Check if cell at (x, y) forms a cross pattern
// Cross = center cell with all 4 orthogonal neighbors alive
grid_is_cross_center :: proc(grid: ^Grid, x, y: int) -> bool {
	center := grid_get_cell(grid, x, y)
	if center != .LIVE {
		return false
	}

	// Check all 4 orthogonal neighbors
	north := grid_get_cell(grid, x, y - 1)
	south := grid_get_cell(grid, x, y + 1)
	east  := grid_get_cell(grid, x + 1, y)
	west  := grid_get_cell(grid, x - 1, y)

	return north == .LIVE && south == .LIVE && east == .LIVE && west == .LIVE
}
