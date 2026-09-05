package main

import sim "../core"

import "core:time"

_ :: sim
_ :: time

when TOTAL_STEPS > 0 {
	// Headless runner: steps the sim with no window through the shared
	// `step_once`. Plain build = the planar-embedding soak (planar_assert every
	// step); MEASURE build = sweep.sh's timing vehicle.
	run_headless_sim :: proc(
		bodies: ^[dynamic]sim.Body,
		trails: ^[dynamic]sim.Trail,
		gravity_tree: ^sim.Gravity_Tree,
	) {
		measure: Measure
		when sim.MEASURE {
			start := time.tick_now()
		}

		tracked := -1

		for _ in 0 ..< TOTAL_STEPS {
			when sim.MEASURE {
				step_t0 := time.tick_now()
			}

			step_once(bodies, trails, &tracked, gravity_tree, sim.DT, &measure)

			when !sim.MEASURE {
				planar_assert(bodies[:])
			}

			when sim.MEASURE {
				// physics includes collision, same nesting as the windowed
				// report; frames == report calls == steps, so the printed
				// per-frame ms reads as ms/step
				measure.physics_seconds += time.duration_seconds(time.tick_since(step_t0))
				measure.steps += 1
				sim.measure_frame_report(
					&measure,
					trails[:],
					time.duration_seconds(time.tick_since(start)),
				)
			}
		}

		return
	}

	// The planar-embedding oracle: from the all-planar spec start, gravity has
	// no out-of-plane component, so z must stay bitwise zero — any drift is a
	// genericization bug. Only meaningful without MEASURE's thick spawn disk.
	planar_assert :: proc(bodies: []sim.Body) {
		for body in bodies {
			assert(body.pos[2] == 0 && body.vel[2] == 0 && body.accel[2] == 0)
		}
	}
}
