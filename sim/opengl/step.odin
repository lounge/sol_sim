package main

import sim "../core"

import "core:time"

_ :: time

when sim.MEASURE {
	Measure :: sim.Measure
} else {
	Measure :: struct {}
}

// One physics step: collision drain, integrate, record.
step_once :: proc(
	bodies: ^[dynamic]sim.Body,
	trails: ^[dynamic]sim.Trail,
	tracked: ^int,
	tree: ^sim.Gravity_Tree,
	dt: f64,
	measure: ^Measure = nil,
) -> (
	merged: bool,
) {
	when sim.MEASURE {
		t0 := time.tick_now()
	}

	merged = sim.collision_drain(bodies, trails, tracked, tree)

	when sim.MEASURE {
		if measure != nil {
			measure.collision_seconds += time.duration_seconds(time.tick_since(t0))
		}
	}

	sim.physics_step(bodies[:], dt, tree)
	sim.trail_record(bodies[:], trails[:])

	return merged
}
