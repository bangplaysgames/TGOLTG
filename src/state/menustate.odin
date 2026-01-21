package state

import clay "vendor:clay-odin"
import ui "../ui"
import "core:fmt"
import "core:os"
import "core:encoding/json" // For save/load

menustate_update :: proc(data: ^game.Play_Data) -> State_Type { // Now takes ^Play_Data for save/load
    if menustate_was_new_game_clicked() {
        return .PLAY
    }
    if menustate_was_continue_clicked() {
        menustate_load_game(data)
        return .PLAY
    }
    if menustate_was_options_clicked() {
        // Toggle options (e.g., data.mute_bgm = !data.mute_bgm) – add fields to Play_Data
    }
    if menustate_was_quit_clicked() {
        os.exit(0) // Or set data.quit_flag = true, handle in main
    }
    return .MENU
}

menustate_build_ui :: proc(data: ^game.Play_Data) { // Takes data for dynamic (e.g., continue disabled if no save)
    save_exists := os.exists("save.json")

    if clay.UI(clay.ID("MainContainer"))({
        layout = clay.LayoutConfig{
            size = {800, 600},
            position = {0, 0},
            alignment = .CENTER,
            padding = {20, 20, 20, 20},
            backgroundColor = ui.COLOR_BACKGROUND,
        },
    }) {
        // Title
        clay.UI(clay.ID("TitleText"))({
            layout = clay.LayoutConfig{
                size = {0, 50},
                margin = {0, 0, 0, 20},
                alignment = .CENTER,
            },
            text = "Cell Harvest",
            textSize = 32,
            textColor = ui.COLOR_TEXT_PRIMARY,
        })

        // Buttons column
        clay.UI(clay.ID("ButtonColumn"))({
            layout = clay.LayoutConfig{
                size = {200, 0},
                alignment = .CENTER,
                crossAlignment = .CENTER,
                childAlignment = .CENTER,
                direction = .COLUMN,
                spacing = 10,
            },
        }) {
            // New Game
            new_game_btn_id := clay.ID("NewGameButton")
            new_game_btn := ui.button_config(new_game_btn_id)
            clay.UI(new_game_btn_id)({
                layout = clay.LayoutConfig{size = {0, 40}},
                backgroundColor = ui.button_style(new_game_btn, ui.COLOR_BUTTON_PRIMARY),
                hoverColor = ui.COLOR_BUTTON_HOVER,
            })
            clay.Text(clay.ID("NewGameText"))({
                text = "New Game",
                textSize = 20,
                textColor = ui.COLOR_TEXT_PRIMARY,
            })

            // Continue (disabled if no save)
            continue_btn_id := clay.ID("ContinueButton")
            continue_btn := ui.button_config(continue_btn_id)
            clay.UI(continue_btn_id)({
                layout = clay.LayoutConfig{size = {0, 40}},
                backgroundColor = ui.button_style(continue_btn, save_exists ? ui.COLOR_BUTTON_PRIMARY : ui.COLOR_BUTTON_DISABLED),
                hoverColor = save_exists ? ui.COLOR_BUTTON_HOVER : ui.COLOR_BUTTON_DISABLED,
            })
            clay.Text(clay.ID("ContinueText"))({
                text = "Continue",
                textSize = 20,
                textColor = ui.COLOR_TEXT_PRIMARY,
            })

            // Options
            options_btn_id := clay.ID("OptionsButton")
            options_btn := ui.button_config(options_btn_id)
            clay.UI(options_btn_id)({
                layout = clay.LayoutConfig{size = {0, 40}},
                backgroundColor = ui.button_style(options_btn, ui.COLOR_BUTTON_PRIMARY),
                hoverColor = ui.COLOR_BUTTON_HOVER,
            })
            clay.Text(clay.ID("OptionsText"))({
                text = "Options",
                textSize = 20,
                textColor = ui.COLOR_TEXT_PRIMARY,
            })

            // Quit
            quit_btn_id := clay.ID("QuitButton")
            quit_btn := ui.button_config(quit_btn_id)
            clay.UI(quit_btn_id)({
                layout = clay.LayoutConfig{size = {0, 40}},
                backgroundColor = ui.button_style(quit_btn, ui.COLOR_BUTTON_PRIMARY),
                hoverColor = ui.COLOR_BUTTON_HOVER,
            })
            clay.Text(clay.ID("QuitText"))({
                text = "Quit",
                textSize = 20,
                textColor = ui.COLOR_TEXT_PRIMARY,
            })
        }

        // Credits/Version
        clay.UI(clay.ID("Footer"))({
            layout = clay.LayoutConfig{
                size = {0, 30},
                position = {0, 550},
                alignment = .CENTER,
            },
        }) {
            clay.Text(clay.ID("CreditsText"))({
                text = "By Luke v0.1 | Powered by Odin & xAI",
                textSize = 14,
                textColor = ui.COLOR_TEXT_SECONDARY,
            })
        }
    }
}

menustate_render_dynamic_text :: proc(data: ^game.Play_Data, renderer: ^render.Renderer) {
    // Optional: Draw version or loaded shards if continue
}

menustate_was_new_game_clicked :: proc() -> bool {
    btn_id := clay.ID("NewGameButton")
    btn := ui.button_config(btn_id)
    return ui.button_click(btn)
}

menustate_was_continue_clicked :: proc() -> bool {
    btn_id := clay.ID("ContinueButton")
    btn := ui.button_config(btn_id)
    return ui.button_click(btn)
}

menustate_was_options_clicked :: proc() -> bool {
    btn_id := clay.ID("OptionsButton")
    btn := ui.button_config(btn_id)
    return ui.button_click(btn)
}

menustate_was_quit_clicked :: proc() -> bool {
    btn_id := clay.ID("QuitButton")
    btn := ui.button_config(btn_id)
    return ui.button_click(btn)
}

menustate_load_game :: proc(data: ^game.Play_Data) {
    file_data, ok := os.read_entire_file("save.json")
    if !ok { return }
    defer delete(file_data)
    loaded, err := json.unmarshal(file_data, Play_Data) // Adjust for partial load
    if err == nil {
        // Copy relevant: data.shards = loaded.shards, data.upgrades = loaded.upgrades, etc.
        // Skip grid/round vars
    }
}

menustate_save_game :: proc(data: ^Play_Data) { // Call in crunch/shop or quit
    json_data, err := json.marshal(data) // Partial marshal if needed
    if err == nil {
        os.write_entire_file("save.json", json_data)
        delete(json_data)
    }
}