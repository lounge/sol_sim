package sim_core

import "core:math"

JD_EPOCH :: 2461041.5 // 2026-01-01 00:00 UTC
JD_UNIX_EPOCH :: 2440587.5 // JD of 1970-01-01 00:00 UTC (JD days start at noon)
JDN_UNIX_EPOCH :: int(JD_UNIX_EPOCH + 0.5) // = 2440588, the JDN jd_to_civil rounds to

Civil_Date :: struct {
	year:  int,
	month: int,
	day:   int,
}

// Howard Hinnant’s algo
date_civil_from_days :: proc "contextless" (z_in: int) -> Civil_Date {
	z := z_in
	z += 719468

	era := z / 146097
	if z < 0 && z % 146097 != 0 {
		era -= 1
	}

	doe := z - era * 146097
	yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	y := yoe + era * 400
	doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	mp := (5 * doy + 2) / 153
	d := doy - (153 * mp + 2) / 5 + 1

	m := mp + 3
	if mp >= 10 {
		m = mp - 9
	}

	if m <= 2 {
		y += 1
	}

	return {year = y, month = m, day = d}
}

//  Julian Date to Gregorian civil date
date_jd_to_civil :: proc "contextless" (jd: f64) -> Civil_Date {
	jdn := int(math.floor(jd + 0.5))

	// JDN of 1970-01-01 is 2440588
	days_since_unix_epoch := jdn - JDN_UNIX_EPOCH

	return date_civil_from_days(days_since_unix_epoch)
}
