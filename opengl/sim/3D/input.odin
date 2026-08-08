package main

import "vendor:glfw"


MASS_FACTOR :: 2
DRAG_TIME :: 0.4
SPAWN_MASS_SENS :: 0.5
SPAWN_BASE_MASS :: 3.69e-8 // Moon
SPAWN_BASE_RADIUS :: 1.161e-5 // Moon

Input :: struct {
	pending_click:  Maybe(Pixel_Pos),
	pending_vel:    int,
	pending_mass:   int,
	pending_spawn:  Maybe(Spawn_Request),
	pending_delete: bool,
	drag_start:     Maybe(Pixel_Pos),
	spawn_mass_exp: f64,
}

Spawn_Request :: struct {
	start_pos: Pixel_Pos,
	end_pos:   Pixel_Pos,
	mass:      f64,
	radius:    f64,
}

callback_click :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32) {
	// state := state_get(window)

	if button == glfw.MOUSE_BUTTON_LEFT && action == glfw.RELEASE {
		// TODO: Pan camera on left click hold / drag
	}
}
