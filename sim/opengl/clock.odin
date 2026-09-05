package main

import sim "../core"

import "core:math"
import "core:time"

MAX_SIM_SPEED :: #config(MAX_SIM_SPEED, int(50 * sim.SECONDS_IN_YEAR))
PHYSICS_BUDGET :: #config(PHYSICS_BUDGET, 0.010) // Seconds of wall clock per frame
GOVERNOR_FRAMES :: #config(GOVERNOR_FRAMES, 30) // Consecutive overloaded frames before halving
START_JD :: #config(START_JD, 0.0) // Start datetime for sim; 0 = wall clock (spec epoch in deterministic builds)

DETERMINISTIC_START :: sim.DETERMINISM_STEPS > 0 || TOTAL_STEPS > 0 || sim.MEASURE


Sim_Clock :: struct {
	sim_time:        f64,
	accumulator:     f64,
	start_jd:        f64,
	overload_frames: int,
}

start_jd_resolve :: proc() -> f64 {
	if START_JD != 0.0 do return START_JD
	if DETERMINISTIC_START do return sim.JD_EPOCH

	return(
		f64(time.to_unix_nanoseconds(time.now())) / sim.NANO_IN_SECONDS / sim.SECONDS_IN_DAY +
		sim.JD_UNIX_EPOCH \
	)
}

clock_delta_t :: proc(start_jd: f64) -> f64 {
	return (start_jd - sim.JD_EPOCH) * sim.SECONDS_IN_DAY / sim.T_UNIT_SECONDS
}

// launch catch-up if pinned JD
clock_start :: proc(
	start_jd: f64,
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	tree: ^sim.Gravity_Tree,
) -> Sim_Clock {
	delta_t := clock_delta_t(start_jd)
	if delta_t < 0 {
		return Sim_Clock{start_jd = start_jd}
	}

	n := int(math.floor(delta_t / sim.DT))
	tracked := -1

	for _ in 0 ..< n {
		step_once(bodies, trails, &tracked, tree, sim.DT)
	}

	return Sim_Clock {
		sim_time = f64(n) * sim.DT,
		accumulator = delta_t - f64(n) * sim.DT,
		start_jd = sim.JD_EPOCH,
	}
}

clock_advance :: proc(clock: ^Sim_Clock, frame_time: f64, sim_speed: int) {
	clock.accumulator += frame_time * f64(sim_speed) / sim.T_UNIT_SECONDS
}


clock_drain :: proc(
	clock: ^Sim_Clock,
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	tracked: ^int,
	tree: ^sim.Gravity_Tree,
	time_reversed: bool,
	measure: ^Measure,
) -> (
	steps: int,
	merged: bool,
) {
	t0 := time.tick_now()
	deadline := PHYSICS_BUDGET
	dt := time_reversed ? -sim.DT : sim.DT

	for clock.accumulator >= sim.DT {
		if step_once(bodies, trails, tracked, tree, dt, measure) do merged = true

		clock.sim_time += dt
		clock.accumulator -= sim.DT
		steps += 1

		if time.duration_seconds(time.tick_since(t0)) >= deadline do break
	}

	when sim.MEASURE {
		measure.physics_seconds += time.duration_seconds(time.tick_since(t0))
		measure.steps += steps
	}

	return steps, merged
}


clock_settle :: proc(clock: ^Sim_Clock) -> (throttle: bool) {
	if clock.accumulator >= sim.DT {
		clock.accumulator = math.mod(clock.accumulator, sim.DT)
		clock.overload_frames += 1
	} else {
		clock.overload_frames = 0
	}

	if clock.overload_frames >= GOVERNOR_FRAMES {
		clock.overload_frames = 0
		return true
	}

	return false
}

clock_alpha :: proc(clock: Sim_Clock) -> f64 {
	return clock.accumulator / sim.DT
}

clock_render_time :: proc(clock: Sim_Clock, time_reversed: bool) -> f64 {
	dt_signed := time_reversed ? -sim.DT : sim.DT
	return clock.sim_time - (1 - clock_alpha(clock)) * dt_signed
}

clock_jd :: proc(clock: Sim_Clock) -> f64 {
	return(
		clock.start_jd +
		(clock.sim_time + clock.accumulator) * sim.T_UNIT_SECONDS / sim.SECONDS_IN_DAY \
	)
}
