package main

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
		physics_seconds: f64,
		trails_seconds:  f64,
		frames:          int,
		last_report:     f64,
	}

	// Seeded so before/after runs get the identical scene. Bodies go on
	// circular orbits around the root so rings fill without escapes.
	measure_spawn :: proc(bodies: ^[dynamic]Body, trails: ^[dynamic]Trail) {
		rand.reset(1)

		for i in 0 ..< MEASURE_SPAWN_COUNT {
			r := rand.float64_range(0.5, 5.0)
			theta := rand.float64_range(0, 2 * math.PI)
			speed := math.sqrt(bodies[0].mass / r)
			pos := [2]f64{r * math.cos(theta), r * math.sin(theta)}

			body := Body {
				name     = fmt.aprintf("Measure %d", i),
				color    = PALETTE[.Spawn],
				pos      = pos,
				prev_pos = pos,
				vel      = [2]f64{-math.sin(theta), math.cos(theta)} * speed,
				mass     = 1e-9,
				radius   = 1e-5,
				spawned  = true,
			}

			append(bodies, body)
			append(trails, trail_make_default())
		}

		accels_compute(bodies[:])
	}

	measure_frame_report :: proc(m: ^Measure, trails: []Trail, now: f64) {
		m.frames += 1

		if now - m.last_report < 1.0 do return

		fill := trails[len(trails) - 1]

		fmt.printfln(
			"[measure] physics %.3f ms | trails_draw %.3f ms | %d frames | ring fill %d/%d",
			m.physics_seconds / f64(m.frames) * 1000,
			m.trails_seconds / f64(m.frames) * 1000,
			m.frames,
			fill.count,
			fill.cap,
		)

		m.physics_seconds = 0
		m.trails_seconds = 0
		m.frames = 0
		m.last_report = now
	}
}
