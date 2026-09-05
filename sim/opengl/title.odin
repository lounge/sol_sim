package main

import sim "../core"

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "vendor:glfw"

TITLE :: "sol_sim 3D"

signed_speed :: proc(state: ^State) -> int {
	return state.sim_speed * (state.time_reversed ? -1 : 1)
}

window_title_update :: proc(
	window: glfw.WindowHandle,
	state: ^State,
	bodies: []sim.Body,
	date: sim.Date,
) {
	if !state.title_stale do return

	tracked := ""
	if state.tracked_body >= 0 {
		tracked = fmt.tprintf(" - %s", bodies[state.tracked_body].name)
	}

	speed := signed_speed(state)
	title := fmt.ctprintf(
		"%s%s - %f days/sec - %f years/sec - sim_speed %d - %04d-%02d-%02d %02d:%02d",
		TITLE,
		tracked,
		f64(speed) / sim.SECONDS_IN_DAY,
		f64(speed) / sim.SECONDS_IN_YEAR,
		speed,
		date.year,
		date.month,
		date.day,
		date.hours,
		date.minutes,
	)

	glfw.SetWindowTitle(window, title)
	state.title_stale = false
}

window_title_drag_update :: proc(
	window: glfw.WindowHandle,
	state: ^State,
	start_world, end_world: World_Pos,
) {
	speed := linalg.length(end_world - start_world) / DRAG_TIME
	mass, _ := mass_radius_get(state.input.spawn_mass_exp)

	title := fmt.ctprintf(
		"%s - Spawn %e sol (x%.0f Moon) - %.1f km/s",
		TITLE + " ",
		mass,
		math.pow(2, state.input.spawn_mass_exp),
		speed * sim.KM_PER_VEL_UNIT,
	)
	glfw.SetWindowTitle(window, title)

	state.title_stale = true
}
