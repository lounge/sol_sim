#!/bin/sh
# The define/lint matrix. Every build is app x defines, and a false `when`
# branch parses but is never type-checked — so every combination is its own
# compile and must be linted separately (the milestone-23 lesson).
#
# Cells are explicit lines, not loops over strings: word-splitting once glued
# two -define flags into one and manufactured a fake failure.
set -e

cells=0
check() {
	echo "== odin check $*"
	odin check "$@"
	cells=$((cells + 1))
}

# --- core, standalone (fast signal; -no-entry-point because it is a library)
check opengl/sim/core -no-entry-point -vet -strict-style
check opengl/sim/core -no-entry-point -vet -strict-style -define:MEASURE=true
check opengl/sim/core -no-entry-point -vet -strict-style -define:BH_DEBUG=true -define:BH_VALIDATE=true
check opengl/sim/core -no-entry-point -vet -strict-style -define:DETERMINISM_STEPS=10
check opengl/sim/core -no-entry-point -vet -strict-style -define:DIM=3
check opengl/sim/core -no-entry-point -vet -strict-style -define:DIM=3 -define:MEASURE=true
check opengl/sim/core -no-entry-point -vet -strict-style -define:DIM=3 -define:BH_DEBUG=true -define:BH_VALIDATE=true
check opengl/sim/core -no-entry-point -vet -strict-style -define:DIM=3 -define:DETERMINISM_STEPS=10

# --- 2D app (DIM defaults to 2)
check opengl/sim/2D -vet -strict-style
check opengl/sim/2D -vet -strict-style -define:MEASURE=true
check opengl/sim/2D -vet -strict-style -define:BH_DEBUG=true -define:BH_VALIDATE=true
check opengl/sim/2D -vet -strict-style -define:BH_DEBUG_DRAW=true
check opengl/sim/2D -vet -strict-style -define:DETERMINISM_STEPS=10

# --- 3D app
if [ -f opengl/sim/3D/main.odin ]; then
	check opengl/sim/3D -vet -strict-style -define:DIM=3
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:MEASURE=true
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:BH_DEBUG=true -define:BH_VALIDATE=true
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:BH_DEBUG_DRAW=true
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:DETERMINISM_STEPS=10
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:TOTAL_STEPS=10
	check opengl/sim/3D -vet -strict-style -define:DIM=3 -define:TOTAL_STEPS=10 -define:MEASURE=true
else
	echo "== SKIP opengl/sim/3D (no main.odin yet)"
fi

echo "matrix clean ($cells cells)"
