package sim_core

TRAIL_CAP :: 12800
TRAIL_FRACTION :: 0.95

SPAWN_TRAIL_CAP :: #config(SPAWN_TRAIL_CAP, 1280)
#assert(SPAWN_TRAIL_CAP <= TRAIL_CAP)

SPAWN_TRAIL_STRIDE :: #config(SPAWN_TRAIL_STRIDE, 25)
#assert(SPAWN_TRAIL_STRIDE > 0)

Trail :: struct {
	points:      [TRAIL_CAP]Vec,
	head:        int,
	count:       int,
	parent:      int,
	cap:         int,
	stride:      int,
	frame_count: int,
}

trail_make_default :: proc() -> Trail {
	trail := Trail {
		points      = 0,
		parent      = -1,
		count       = 0,
		head        = 0,
		cap         = SPAWN_TRAIL_CAP,
		stride      = SPAWN_TRAIL_STRIDE,
		frame_count = SPAWN_TRAIL_STRIDE - 1, // Records on the next step, so a fresh trail anchors immediately
	}

	return trail
}

trail_make_orbital :: proc(parent: int, steps_per_orbit: f64, stride: int) -> Trail {
	trail := Trail {
		parent = parent,
		cap    = int(TRAIL_FRACTION * steps_per_orbit / f64(stride)),
		stride = stride,
	}

	return trail
}

trail_record :: proc(bodies: []Body, trails: []Trail) {
	for &body, i in bodies {
		trail := &trails[i]

		trail.frame_count += 1
		if trail.frame_count >= trail.stride {
			trail.points[trail.head] = body.prev_pos

			if trail.parent >= 0 {
				trail.points[trail.head] = body.prev_pos - bodies[trail.parent].prev_pos
			}

			trail.head = (trail.head + 1) % trail.cap
			trail.count = min(trail.count + 1, trail.cap)
		}

		trail.frame_count %= trail.stride
	}
}
