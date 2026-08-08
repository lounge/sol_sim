package sim_core

import "core:fmt"
import "core:math"
import "core:math/rand"

_ :: fmt
_ :: math
_ :: rand

MEASURE :: #config(MEASURE, false)
MEASURE_SPAWN_COUNT :: #config(MEASURE_SPAWN_COUNT, 300)
MEASURE_Z_THICKNESS :: #config(MEASURE_Z_THICKNESS, 0.1)
DETERMINISM_STEPS :: #config(DETERMINISM_STEPS, 0)

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

			// A cold thin disk: z-jitter makes the tree exercise its z-split,
			// vel[2] = 0 keeps bodies oscillating through the plane instead of
			// escaping. Gated so the 2D measurement baselines stay untouched.
			when DIM == 3 {
				pos[2] = rand.float64_range(-MEASURE_Z_THICKNESS / 2, MEASURE_Z_THICKNESS / 2)
			}

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

when DETERMINISM_STEPS > 0 {
	// The cross-build trajectory oracle: step a fixed count, print every
	// position as raw bit patterns (hex of the f64 bits — no formatting
	// ambiguity). Two builds are equivalent iff their dumps are identical;
	// at DIM=3 from a planar start, x/y must match the DIM=2 dump and the
	// z column must be all zero bits. Mirrors the drain loop's step order
	// (merge-until-clean, step, record); the wall-clock machinery is
	// deliberately absent so output depends only on the build.
	determinism_dump :: proc(
		bodies: ^[dynamic]Body,
		trails: ^[dynamic]Trail,
		tree: ^Gravity_Tree,
	) {
		tracked := -1

		for _ in 0 ..< DETERMINISM_STEPS {
			for {
				pair, collision := collision_compute(bodies[:], tree)
				if !collision do break
				collision_merge(pair, bodies, trails, &tracked, tree)
			}

			physics_step(bodies[:], DT, tree)
			trail_record(bodies[:], trails[:])
		}

		for body in bodies {
			fmt.printf("%s", body.name)
			for axis in 0 ..< DIM {
				fmt.printf(" %016x", transmute(u64)body.pos[axis])
			}
			fmt.println()
		}
	}
}
