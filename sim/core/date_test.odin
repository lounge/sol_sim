package sim_core

import "core:testing"

// Hinnant's days_from_civil, the exact inverse of date_from_days — test-only,
// because the round-trip needs a direction the sim itself never travels.
@(private = "file")
days_from_civil :: proc "contextless" (year, month, day: int) -> int {
	y := year
	if month <= 2 {
		y -= 1
	}

	era := y / 400
	if y < 0 && y % 400 != 0 {
		era -= 1
	}

	yoe := y - era * 400
	mp := month + 9
	if month > 2 {
		mp = month - 3
	}

	doy := (153 * mp + 2) / 5 + day - 1
	doe := yoe * 365 + yoe / 4 - yoe / 100 + doy

	return era * 146097 + doe - 719468
}

@(test)
date_anchors_test :: proc(t: ^testing.T) {
	testing.expect_value(t, date_from_jd(JD_UNIX_EPOCH), Date{1970, 1, 1, 0, 0})
	testing.expect_value(t, date_from_jd(JD_EPOCH), Date{2026, 1, 1, 0, 0})

	// astronomical year numbering: 4714 BC is year −4713, and JD days roll at noon
	testing.expect_value(t, date_from_jd(0), Date{-4713, 11, 24, 12, 0})

	// an integer JD is civil noon, not a day boundary
	testing.expect_value(t, date_from_jd(f64(JDN_UNIX_EPOCH)), Date{1970, 1, 1, 12, 0})

	// 2000 is a leap year, 1900 is not
	leap_jdn := days_from_civil(2000, 2, 29) + JDN_UNIX_EPOCH
	testing.expect_value(t, date_from_jd(f64(leap_jdn) - 0.5), Date{2000, 2, 29, 0, 0})
	nonleap_jdn := days_from_civil(1900, 2, 28) + 1 + JDN_UNIX_EPOCH
	testing.expect_value(t, date_from_jd(f64(nonleap_jdn) - 0.5), Date{1900, 3, 1, 0, 0})
}

@(test)
date_roundtrip_test :: proc(t: ^testing.T) {
	// the range reaches below JD 0 for the negative-era arithmetic and past
	// year 2262 — the core:time overflow that forced this hand-rolled conversion
	for z in -2_500_000 ..= 1_000_000 {
		jd := f64(z + JDN_UNIX_EPOCH) - 0.5 // civil midnight of day z
		date := date_from_jd(jd)
		back := days_from_civil(date.year, date.month, date.day)
		if back != z || date.hours != 0 || date.minutes != 0 {
			testing.expectf(t, false, "day %d -> %v -> %d", z, date, back)
			return
		}
	}
}

@(test)
date_minutes_midpoint_test :: proc(t: ^testing.T) {
	// pins floor semantics: a clock reads 19:59 until 20:00 arrives, so
	// round-to-nearest would fail here
	for k in 0 ..< 1440 {
		jd := f64(JDN_UNIX_EPOCH) - 0.5 + (f64(k) + 0.5) / 1440.0
		date := date_from_jd(jd)
		if date.hours != k / 60 || date.minutes != k % 60 {
			testing.expectf(t, false, "minute %d read as %02d:%02d", k, date.hours, date.minutes)
			return
		}
	}
}

@(test)
date_minutes_boundary_test :: proc(t: ^testing.T) {
	// 704 of these 1440 boundaries land ~20 µs low (half an ulp of a JD near
	// 2.4e6), so bare truncation reads a minute early on half the clock
	for k in 0 ..< 1440 {
		jd := f64(JDN_UNIX_EPOCH) - 0.5 + f64(k) / 1440.0
		date := date_from_jd(jd)
		if date.hours != k / 60 || date.minutes != k % 60 {
			testing.expectf(t, false, "minute %d read as %02d:%02d", k, date.hours, date.minutes)
			return
		}
	}
}
