package main

import "core:math"
import "vendor:glfw"


MASS_FACTOR :: 2
DRAG_TIME :: 0.4
SPAWN_MASS_SENS :: 0.5
SPAWN_BASE_MASS :: 3.69e-8 // Moon
SPAWN_BASE_RADIUS :: 1.161e-5 // Moon

Input :: struct {
	pending_click: Maybe(Pixel_Pos),
	pending_vel: int,
	pending_mass: int,
	pending_spawn: Maybe(Spawn_Request),
	pending_delete: bool,
	drag_start: Maybe(Pixel_Pos),
	spawn_mass_exp: f64,
}

Spawn_Request :: struct {
	start_pos: Pixel_Pos,
	end_pos: Pixel_Pos,
	mass: f64,
	radius: f64,
}

spawn_mass_radius :: proc "contextless" (mass_exp: f64) -> (mass: f64, radius: f64) {
	mass = SPAWN_BASE_MASS * math.pow(2, mass_exp)
	radius = SPAWN_BASE_RADIUS * math.pow(mass / SPAWN_BASE_MASS, 1.0/3.0)

	return mass, radius
}

scroll_callback :: proc "c" (window: glfw.WindowHandle, xOffset, yOffset: f64) {
	state := get_state(window)

	if _, ok := state.input.drag_start.?; ok {
		state.input.spawn_mass_exp += yOffset * SPAWN_MASS_SENS
	} else {
		camera_zoom(&state.camera, yOffset)
	}
}

click_callback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	state := get_state(window)

    if button == glfw.MOUSE_BUTTON_LEFT && action == glfw.RELEASE {
    	posX, posY := glfw.GetCursorPos(window)
     	state.input.pending_click = Pixel_Pos({posX, posY})
    }

    if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.PRESS {
	   	posX, posY := glfw.GetCursorPos(window)
		state.input.drag_start = Pixel_Pos({posX, posY})
    }

    if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.RELEASE {
	    if drag, ok := state.input.drag_start.?; ok {
			posX, posY := glfw.GetCursorPos(window)
			mass, radius := spawn_mass_radius(state.input.spawn_mass_exp)

			state.input.pending_spawn = Spawn_Request {
				start_pos = drag.xy,
				end_pos = {posX, posY},
				mass = mass,
				radius = radius,
	    	}
		}

		state.input.drag_start = nil
    }
}

key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if action == glfw.PRESS || action == glfw.REPEAT {
		state := get_state(window)

		if key == glfw.KEY_ESCAPE {
			glfw.SetWindowShouldClose(window, true)
		}

		if key ==  glfw.KEY_LEFT {
			state.sim_speed = math.max(1, state.sim_speed / 2)
		}
		if key == glfw.KEY_RIGHT {
			state.sim_speed = math.min(MAX_SIM_SPEED, state.sim_speed * 2)
		}

		if key == glfw.KEY_UP {
			state.input.pending_vel += 1
		}
		if key == glfw.KEY_DOWN {
			state.input.pending_vel = math.max(-99, state.input.pending_vel - 1)
		}

		if key == glfw.KEY_PERIOD {
			state.input.pending_mass += 1
		}
		if key == glfw.KEY_COMMA {
			state.input.pending_mass -= 1
		}
	}

	if action == glfw.PRESS {
		state := get_state(window)

		if key == glfw.KEY_BACKSPACE || key == glfw.KEY_DELETE {
			state.input.pending_delete = true
		}
	}
}
