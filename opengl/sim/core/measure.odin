package sim_core

import "core:fmt"
import "core:math"
import "core:math/rand"

_ :: fmt
_ :: math
_ :: rand

MEASURE :: #config(MEASURE, false)
MEASURE_SPAWN_COUNT :: #config(MEASURE_SPAWN_COUNT, 300)

when MEASURE {
	Measure :: struct {
		physics_seconds:   f64,
		collision_seconds: f64,
		trails_seconds:    f64,
		bodies_seconds:    f64,
		frames:            int,
		steps:             int,
		last_report:       f64,
	}

	// Seeded so before/after runs get the identical scene. Bodies go on
	// circular orbits around the root so rings fill without escapes.
	measure_spawn :: proc(bodies: ^[dynamic]Body, trails: ^[dynamic]Trail, tree: ^Gravity_Tree) {
		rand.reset(1)

		for i in 0 ..< MEASURE_SPAWN_COUNT {
			r := rand.float64_range(0.5, 5.0)
			theta := rand.float64_range(0, 2 * math.PI)
			speed := math.sqrt(bodies[0].mass / r)

			pos: Vec
			pos[0] = r * math.cos(theta)
			pos[1] = r * math.sin(theta)

			vel: Vec
			vel[0] = -math.sin(theta) * speed
			vel[1] = math.cos(theta) * speed

			body_spawn(
				bodies,
				trails,
				tree,
				fmt.aprintf("Measure %d", i),
				PALETTE[.Spawn],
				pos,
				vel,
				1e-9,
				1e-5,
			)
		}
	}

	measure_frame_report :: proc(m: ^Measure, trails: []Trail, now: f64) {
		m.frames += 1

		if now - m.last_report < 1.0 do return

		fill := trails[len(trails) - 1]

		fmt.printfln(
			"[measure] physics %.3f ms (collision %.3f ms) | bodies_draw %.3f ms | trails_draw %.3f ms | %d frames | %d steps | ring fill %d/%d",
			m.physics_seconds / f64(m.frames) * 1000,
			m.collision_seconds / f64(m.frames) * 1000,
			m.bodies_seconds / f64(m.frames) * 1000,
			m.trails_seconds / f64(m.frames) * 1000,
			m.frames,
			m.steps,
			fill.count,
			len(fill.points),
		)

		m.physics_seconds = 0
		m.collision_seconds = 0
		m.bodies_seconds = 0
		m.trails_seconds = 0
		m.frames = 0
		m.steps = 0
		m.last_report = now
	}
}
