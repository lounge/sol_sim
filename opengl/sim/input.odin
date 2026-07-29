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


mass_radius_get :: proc "contextless" (mass_exp: f64) -> (mass: f64, radius: f64) {
	mass = SPAWN_BASE_MASS * math.pow(2, mass_exp)
	radius = SPAWN_BASE_RADIUS * math.pow(mass / SPAWN_BASE_MASS, 1.0/3.0)

	return mass, radius
}

callback_scroll :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	state := state_get(window)

	if _, ok := state.input.drag_start.?; ok {
		state.input.spawn_mass_exp += y_offset * SPAWN_MASS_SENS
	} else {
		camera_zoom(&state.camera, y_offset)
	}
}

callback_click :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	state := state_get(window)

    if button == glfw.MOUSE_BUTTON_LEFT && action == glfw.RELEASE {
    	pos_x, pos_y := glfw.GetCursorPos(window)
     	state.input.pending_click = Pixel_Pos({pos_x, pos_y})
    }

    if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.PRESS {
	   	pos_x, pos_y := glfw.GetCursorPos(window)
		state.input.drag_start = Pixel_Pos({pos_x, pos_y})
    }

    if button == glfw.MOUSE_BUTTON_RIGHT && action == glfw.RELEASE {
	    if drag, ok := state.input.drag_start.?; ok {
			pos_x, pos_y := glfw.GetCursorPos(window)
			mass, radius := mass_radius_get(state.input.spawn_mass_exp)

			state.input.pending_spawn = Spawn_Request {
				start_pos = drag.xy,
				end_pos = {pos_x, pos_y},
				mass = mass,
				radius = radius,
	    	}
		}

		state.input.drag_start = nil
    }
}

callback_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if action == glfw.PRESS || action == glfw.REPEAT {
		state := state_get(window)

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
		state := state_get(window)

		if key == glfw.KEY_BACKSPACE || key == glfw.KEY_DELETE {
			state.input.pending_delete = true
		}
	}
}
