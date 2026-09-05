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
# (no -debug cell: core has no `when ODIN_DEBUG` code, and the 3D -debug cell
# compiles core anyway — a core -debug cell would re-check the default surface)
check sim/core -no-entry-point -vet -strict-style
check sim/core -no-entry-point -vet -strict-style -define:MEASURE=true
check sim/core -no-entry-point -vet -strict-style -define:BH_DEBUG=true -define:BH_VALIDATE=true
check sim/core -no-entry-point -vet -strict-style -define:DETERMINISM_STEPS=10
# `when` EXPRESSIONS skip their untaken arm too (verified empirically), so the
# non-default palette arms are unchecked without their own cells
check sim/core -no-entry-point -vet -strict-style -define:PALETTE_SET=realistic
check sim/core -no-entry-point -vet -strict-style -define:PALETTE_SET=vibrant

# --- the app
check sim/opengl -vet -strict-style
check sim/opengl -vet -strict-style -debug
check sim/opengl -vet -strict-style -define:MEASURE=true
check sim/opengl -vet -strict-style -define:BH_DEBUG=true -define:BH_VALIDATE=true
# VALIDATE solo is the documented workflow (paired with -define:BH_THRESHOLD=0);
# the combined cell above never checks VALIDATE-without-DEBUG
check sim/opengl -vet -strict-style -define:BH_VALIDATE=true
check sim/opengl -vet -strict-style -define:BH_DEBUG_DRAW=true
check sim/opengl -vet -strict-style -define:DETERMINISM_STEPS=10
check sim/opengl -vet -strict-style -define:TOTAL_STEPS=10
check sim/opengl -vet -strict-style -define:TOTAL_STEPS=10 -define:MEASURE=true
# used compositions (same rationale as TOTAL_STEPS+MEASURE above): the
# benchmark-scene determinism oracle, and debug-draw over the measure disk
check sim/opengl -vet -strict-style -define:DETERMINISM_STEPS=10 -define:MEASURE=true
check sim/opengl -vet -strict-style -define:MEASURE=true -define:BH_DEBUG_DRAW=true

echo "matrix clean ($cells cells)"

# --- unit tests (milestone 36): the pure leaves — run, not just type-check.
# The *_test.odin files are package members, so the core cells above already
# lint them in every define combination; this step executes the assertions.
echo "== odin test sim/core"
odin test sim/core -out:/tmp/sim_core_test

echo "unit tests pass"
