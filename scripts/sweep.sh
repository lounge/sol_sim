#!/bin/sh
# BH_THRESHOLD crossover sweep for the 3D build (milestone 25, phase 4).
# For each spawn count, times the forced-brute path (threshold above any n)
# against the forced-tree path (threshold 0) and prints ms/step from each
# run's last measure report. The crossover is where the tree column drops
# below the brute column; wire the result as the shipped default.
#
# A blank cell means the run finished under the report's 1-second throttle —
# raise that row's step count.
set -e
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

measure_case() { # spawn_count total_steps bh_threshold -> physics ms/step
	odin build opengl/sim/3D -o:speed -define:MEASURE=true \
		-define:MEASURE_SPAWN_COUNT="$1" -define:TOTAL_STEPS="$2" \
		-define:BH_THRESHOLD="$3" -out:"$tmp/sweep"
	"$tmp/sweep" | grep '^\[measure\]' | tail -1 | awk '{print $3}'
}

echo "bodies | brute ms/step | tree ms/step"
while read -r n steps; do
	brute=$(measure_case "$n" "$steps" 99999)
	tree=$(measure_case "$n" "$steps" 0)
	echo "$((n + 15)) | $brute | $tree"
done <<EOF
100 100000
300 20000
1000 2500
3000 500
EOF
