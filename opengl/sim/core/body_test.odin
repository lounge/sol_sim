package sim_core

import "core:math"
import "core:math/linalg"
import "core:testing"

@(private = "file")
within :: proc "contextless" (got, want, tol: f64) -> bool {
	return abs(got - want) <= tol
}

@(test)
kepler_exact_cases_test :: proc(t: ^testing.T) {
	// both degenerate to an exact root, so these are bitwise, not toleranced
	ms := [?]f64{-5.5, -math.PI, -0.1, 0, 0.1, 1, math.PI, 5.5}
	for m in ms {
		testing.expect_value(t, kepler_solve(m, 0), m)
	}

	es := [?]f64{0, 0.1, 0.5, 0.9}
	for e in es {
		testing.expect_value(t, kepler_solve(0, e), 0)
	}
}

@(test)
kepler_roundtrip_test :: proc(t: ^testing.T) {
	// 0.95 is the measured limit of the E₀ = M Newton start under the
	// 12-iteration cap — 0.99 diverges (the hardening, if ever needed, is
	// E₀ = π). The spec table maxes at ~0.25, so the tail rows are margin.
	// Negative E covers negative M: pre-epoch START_JD pins feed the solver
	// negative anomalies, and math.mod is sign-preserving.
	es := [?]f64{0, 0.0167, 0.2056, 0.25, 0.5, 0.7, 0.9, 0.95}
	for e in es {
		for i in 0 ..= 96 {
			e_true := -2 * math.PI + f64(i) * (4 * math.PI / 96)
			m := e_true - e * math.sin(e_true)
			e_rt := kepler_solve(m, e)

			// the fixed point is ~ulp-exact in M-space; the round-trip error is
			// that times dE/dM = 1/(1 − e·cos E), worst near perihelion at high e
			amp := 1 / (1 - e * math.cos(e_true))
			tol := 1e-13 * amp * math.max(1.0, abs(e_true))
			testing.expectf(
				t,
				within(e_rt, e_true, tol),
				"e=%v M=%v: solved E=%v want %v (err %e, tol %e)",
				e,
				m,
				e_rt,
				e_true,
				e_rt - e_true,
				tol,
			)
		}
	}
}

// Vis-viva, energy, and |h| are rotation-blind — a scrambled p̂/q̂ basis passes
// all three — so the normal and eccentricity vectors are what witness the
// rotation. Expected angles mirror the INCL_SCALE factor, like the source.
@(private = "file")
rel_state_invariants_check :: proc(t: ^testing.T, spec: Body_Spec, mu, delta_t: f64) {
	pos, vel := spec_rel_state(spec, mu, delta_t)

	a := spec.semi_major_axis
	e := spec.eccentricity
	r := linalg.length(pos)
	v2 := linalg.dot(vel, vel)
	v2_ref := mu / a

	testing.expectf(
		t,
		within(v2, mu * (2 / r - 1 / a), 1e-12 * v2_ref),
		"%s dt=%v: vis-viva v²=%e want %e",
		spec.name,
		delta_t,
		v2,
		mu * (2 / r - 1 / a),
	)

	testing.expectf(
		t,
		within(v2 / 2 - mu / r, -mu / (2 * a), 1e-12 * v2_ref),
		"%s dt=%v: energy %e want %e",
		spec.name,
		delta_t,
		v2 / 2 - mu / r,
		-mu / (2 * a),
	)

	h := linalg.cross(pos, vel)
	h_len := linalg.length(h)
	h_want := math.sqrt(mu * a * (1 - e * e))
	testing.expectf(
		t,
		within(h_len, h_want, 1e-12 * h_want),
		"%s dt=%v: |h|=%e want %e",
		spec.name,
		delta_t,
		h_len,
		h_want,
	)

	// the orbit normal implied by (i, Ω)
	incl := math.to_radians(spec.inclination * INCL_SCALE)
	node := math.to_radians(spec.lon_asc_node * INCL_SCALE)
	n_want := Vec{math.sin(incl) * math.sin(node), -math.sin(incl) * math.cos(node), math.cos(incl)}
	h_hat := h / h_len
	testing.expectf(
		t,
		linalg.length(h_hat - n_want) <= 1e-12,
		"%s dt=%v: orbit normal %v want %v",
		spec.name,
		delta_t,
		h_hat,
		n_want,
	)

	// ē = (v × h)/μ − r̂ has magnitude e and points at perihelion
	e_vec := linalg.cross(vel, h) / mu - pos / r
	testing.expectf(
		t,
		within(linalg.length(e_vec), e, 1e-12),
		"%s dt=%v: |e_vec|=%e want %v",
		spec.name,
		delta_t,
		linalg.length(e_vec),
		e,
	)

	// ē's angle from the ascending node is ω — undefined on a circle
	if e > 1e-9 {
		peri := math.to_radians(spec.arg_perihelion * INCL_SCALE)
		n_line := Vec{math.cos(node), math.sin(node), 0}
		e_hat := e_vec / linalg.length(e_vec)
		w_got := math.atan2(linalg.dot(linalg.cross(n_line, e_hat), h_hat), linalg.dot(n_line, e_hat))
		dw := math.mod(w_got - peri + 3 * math.PI, 2 * math.PI) - math.PI
		testing.expectf(
			t,
			abs(dw) <= 1e-12,
			"%s dt=%v: arg of perihelion %v want %v",
			spec.name,
			delta_t,
			w_got,
			peri,
		)
	}
}

@(test)
spec_rel_state_invariants_test :: proc(t: ^testing.T) {
	dts := [?]f64{0, 0.5, 9.87, -3.21, 1234.5}

	synth := Body_Spec {
		eccentricity    = 0.3,
		mean_anomaly    = 123.4,
		semi_major_axis = 2.5,
		inclination     = 25,
		lon_asc_node    = 80,
		arg_perihelion  = 200,
		name            = "Synth",
	}
	for dt in dts {
		rel_state_invariants_check(t, synth, 1.0, dt)
	}

	// Triton-class: cos i < 0 exercises the flipped-normal paths
	retro := Body_Spec {
		eccentricity    = 0.05,
		mean_anomaly    = 42.0,
		semi_major_axis = 0.8,
		inclination     = 129.15,
		lon_asc_node    = 222.66,
		arg_perihelion  = 345.0,
		name            = "Retro",
	}
	for dt in dts {
		rel_state_invariants_check(t, retro, 0.5, dt)
	}

	circ := Body_Spec {
		mean_anomaly    = 271.0,
		semi_major_axis = 1.5,
		inclination     = 5.0,
		lon_asc_node    = 10.0,
		name            = "Circ",
	}
	for dt in dts {
		rel_state_invariants_check(t, circ, 1.0, dt)
	}

	// one real spec row, with its real pair μ
	for dt in dts {
		rel_state_invariants_check(t, MERCURY, G * (1.0 + MERCURY.mass), dt)
	}
}

@(test)
spec_rel_state_perihelion_test :: proc(t: ^testing.T) {
	// M₀ = 0 at Δt = 0 is perihelion, where r = a(1−e) and r·v = 0
	spec := Body_Spec {
		eccentricity    = 0.4,
		semi_major_axis = 3.0,
		inclination     = 15,
		lon_asc_node    = 30,
		arg_perihelion  = 60,
		name            = "Peri",
	}
	pos, vel := spec_rel_state(spec, 1.0, 0)
	r := linalg.length(pos)
	r_want := spec.semi_major_axis * (1 - spec.eccentricity)
	testing.expectf(t, within(r, r_want, 1e-14 * r_want), "perihelion r=%v want %v", r, r_want)

	rv := linalg.dot(pos, vel)
	rv_scale := r * linalg.length(vel)
	testing.expectf(t, abs(rv) <= 1e-13 * rv_scale, "apsis radial velocity r·v=%e", rv)
}

@(test)
spec_rel_state_planar_test :: proc(t: ^testing.T) {
	// exactly 0.0, not merely small: cos 0 is 1.0 and sin 0 is 0.0, so the
	// zero-angle path is bitwise planar — the milestone-29 oracle
	spec := Body_Spec {
		eccentricity    = 0.2,
		mean_anomaly    = 33.3,
		semi_major_axis = 1.2,
		name            = "Planar",
	}
	dts := [?]f64{0, 1.5, -7.25, 100.0}
	for dt in dts {
		pos, vel := spec_rel_state(spec, 1.0, dt)
		testing.expectf(t, pos.z == 0, "dt=%v: pos.z=%e", dt, pos.z)
		testing.expectf(t, vel.z == 0, "dt=%v: vel.z=%e", dt, vel.z)
	}
}

@(test)
spec_rel_state_periodicity_test :: proc(t: ^testing.T) {
	// catches the M mod 2π line and the mean-motion formula together
	mu := G * (1.0 + MERCURY.mass)
	a := MERCURY.semi_major_axis
	period := 2 * math.PI * math.sqrt(a * a * a / mu)
	v_ref := math.sqrt(mu / a)

	dts := [?]f64{0, 3.7, -12.9}
	for dt in dts {
		p1, v1 := spec_rel_state(MERCURY, mu, dt)
		p2, v2 := spec_rel_state(MERCURY, mu, dt + period)
		testing.expectf(t, linalg.length(p2 - p1) <= 1e-12 * a, "dt=%v: pos drift %e", dt, linalg.length(p2 - p1))
		testing.expectf(t, linalg.length(v2 - v1) <= 1e-12 * v_ref, "dt=%v: vel drift %e", dt, linalg.length(v2 - v1))
	}
}

@(test)
spec_rel_state_time_symmetry_test :: proc(t: ^testing.T) {
	// from M₀ = 0, ±t mirrors through the apsis line: |r| and |v| are even in
	// t, r·v is odd. This is the pre-epoch-pin path.
	spec := Body_Spec {
		eccentricity    = 0.35,
		semi_major_axis = 2.0,
		inclination     = 40,
		lon_asc_node    = 120,
		arg_perihelion  = 10,
		name            = "Mirror",
	}
	a := spec.semi_major_axis
	v_ref := math.sqrt(1.0 / a)

	dts := [?]f64{0.25, 2.0, 31.4}
	for dt in dts {
		pf, vf := spec_rel_state(spec, 1.0, dt)
		pb, vb := spec_rel_state(spec, 1.0, -dt)
		testing.expectf(t, within(linalg.length(pf), linalg.length(pb), 1e-12 * a), "dt=%v: |r| asymmetric", dt)
		testing.expectf(t, within(linalg.length(vf), linalg.length(vb), 1e-12 * v_ref), "dt=%v: |v| asymmetric", dt)
		testing.expectf(
			t,
			within(linalg.dot(pf, vf), -linalg.dot(pb, vb), 1e-12 * a * v_ref),
			"dt=%v: r·v not odd: %e vs %e",
			dt,
			linalg.dot(pf, vf),
			linalg.dot(pb, vb),
		)
	}
}
