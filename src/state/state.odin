package state

/////////////////////////////////////////////////////////////////////////////
// Global State Controller - GLOBALLY CALLABLE
/////////////////////////////////////////////////////////////////////////////

State_Type :: enum {
	MENU,
	PLAY,
}

// Forward declare Play_Data as opaque type to avoid cyclic imports
Play_Data :: struct {}

// THE GLOBALLY CALLABLE FUNCTION - ANY FILE IN THE PROGRAM CAN CALL THIS
// Takes TWO arguments: target state and play_data
// Calls the init function in each state file
transition_to :: proc(target_state: State_Type, play_data: ^Play_Data) {
	switch target_state {
		case .MENU:
			// menustate_do_init is defined in menustate.odin
			transition_to_menu()

		case .PLAY:
			// playstate_do_init is defined in playstate.odin
			transition_to_play(play_data)
	}
}

// Forward declarations - implemented in menustate.odin and playstate.odin
transition_to_menu :: proc()
transition_to_play :: proc(play_data: ^Play_Data)
