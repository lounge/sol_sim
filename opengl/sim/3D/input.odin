package main

import "core:math"
import "core:math/linalg"
import "vendor:glfw"

MASS_FACTOR :: 2
DRAG_TIME :: 0.4
SPAWN_MASS_SENS :: 0.5
SPAWN_BASE_MASS :: 3.69e-8 // Moon
SPAWN_BASE_RADIUS :: 1.161e-5 // Moon

ORBIT_SENS :: 0.005

Input :: struct {
	orbiting:       bool,
	press_anchor:   Pixel_Pos,
	pending_click:  Maybe(Pixel_Pos),
	pending_vel:    int,
	pending_mass:   int,
	pending_delete: bool,
}

callback_scroll :: proc "c" (window: glfw.WindowHandle, x_offset, y_offset: f64) {
	state := state_get(window)
	camera_dolly(&state.camera, y_offset)
}

callback_click :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	state := state_get(window)
	cursor_x, cursor_y := glfw.GetCursorPos(window)
	cursor: Pixel_Pos = {cursor_x, cursor_y}

	if button == glfw.MOUSE_BUTTON_LEFT {
		state.input.orbiting = action == glfw.PRESS
		state.input.press_anchor = Pixel_Pos(cursor)

		delta := ([2]f64)(cursor) - ([2]f64)(state.input.press_anchor)

		if action == glfw.RELEASE {
			if linalg.length2(delta) < MIN_MARKER_PX {
				state.input.pending_click = cursor
			}
		}
	}
}

callback_key :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	if action == glfw.PRESS || action == glfw.REPEAT {
		state := state_get(window)

		if key == glfw.KEY_ESCAPE {
			glfw.SetWindowShouldClose(window, true)
		}

		if key == glfw.KEY_LEFT {
			state.sim_speed = math.max(1, state.sim_speed / 2)
			state.title_stale = true
		}
		if key == glfw.KEY_RIGHT {
			state.sim_speed = math.min(MAX_SIM_SPEED, state.sim_speed * 2)
			state.title_stale = true
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
