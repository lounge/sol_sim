# Plan: 2D + 3D binaries over a shared core (milestone 25)

Chosen approach: **compile-time dimension via `#config`**. One dimension-generic core
package; two thin app packages that build to separate binaries. The core declares

```odin
DIM :: #config(DIM, 2)
Vec :: [3]f64
```

and Odin's array programming does the rest: `a + b`, scalar broadcast (`accel = 0`),
`linalg.length`/`dot` are already dimension-blind, so the integrator, merge math, and
momentum zeroing port by type-alias alone. The 3D binary builds with `-define:DIM=3`.

## Target layout

```
opengl/sim/core/    package sim_core — physics, quadtree, collision, body, trail,
                    system, colors, measure  (imports only core:math, core:math/linalg)
opengl/sim/2d/      package main — main, render, camera, input, interaction, state,
                    shader, res/  (the current app, re-homed)
opengl/sim/3d/      package main — same file roles, 3D implementations, own res/
```

- Apps import core by relative path (`import sim "../core"`); every core call site
  gains the qualifier (`sim.body_add`). Odin exports everything by default — no
  annotation work. (Directory names starting with a digit are fine — the package
  *name* is what's declared in the file, and both apps declare `package main`.)
- Dependency is one-way and compiler-enforced: core never sees `State`, `Input`,
  `Camera`, `Pixel_Pos`, or GL.
- `World_Pos` stays app-side (each app declares its own, `[2]f64` vs `[3]f64`, beside
  its transforms). Core APIs take plain `Vec` — the unwrap-at-entry frontier moves to
  the app/core boundary but keeps its shape. `Pixel_Pos` is `[2]f64` in both apps.

## Phase 1 — Narrow the State seams (still one package, no behavior change) — DONE

What actually landed (slightly stronger than planned):

- `collision_merge` takes `tracked_body: ^int`; the caller sets `title_stale`. No
  core-candidate file sees `^State` anymore.
- `tracked_body` moved out of `Camera` into `State` entirely — it's selection state,
  not camera state. Payoff in Phase 5: the orbit-camera rewrite touches pure view
  state (`center`, `half_extent`) with nothing else riding along.
- `body_spawn` added to body.odin, owning the spawn invariants (teleport rule
  `prev_pos = pos`, `spawned = true`, `trail_make_default`, priming `accels_compute`).
  Both hand-rolled spawn sites (`pending_spawn_apply`, `measure_spawn`) now call it.
  Note: it primes per call, so batch spawns re-prime per body — fine for startup-only
  `measure_spawn`; a batch path can exist later if it ever matters.
- `PALETTE :: REALISTIC.body` moved main.odin → colors.odin (pre-does the Phase 2
  constant migration; core's `specs` needs it).
- The `BH_DEBUG` report moved main.odin → quadtree.odin as `quadtree_debug(tree,
  bodies, now)`: throttle state is a `debug_last` field on `Quadtree` (precedent:
  `validate_max_err`), the clock is passed in (core stays GLFW-free, same pattern as
  `measure_frame_report`), and the com diff prints as one `%v` vector — arity-proof
  at any DIM. App-side residue is one gated call.
- `interaction.odin` stays **app-side** (decided; it consumes `Input`,
  `world_pos_calc`, `DRAG_TIME` — all per-app; 3D spawn UX differs anyway).

Validation held: behavior-identical run; define-matrix lint clean (default, MEASURE,
BH_DEBUG+BH_VALIDATE, BH_DEBUG_DRAW); BH report verified at runtime under
MEASURE+BH_DEBUG+BH_VALIDATE (com diff ~1e-16, max err ~1e-4 at θ=0.5).

## Phase 2 — Package split, still 2D-only — DONE

What actually landed:

- As planned, with one naming deviation: the app dirs are uppercase `2D`/`3D`
  (fine on macOS's case-insensitive FS, but doc snippets below say `2d`/`3d`).
- Correction to "Known traps" below: core *can* be checked standalone —
  `odin check opengl/sim/core -no-entry-point -vet -strict-style` — and is the
  fast row of the check matrix.
- Gitignore gotcha: unanchored binary-name patterns (`2D`, `3D`) swallow the
  same-named source directories; the `!2D/`/`!3D/` negation lines (the file's
  existing convention) are load-bearing.
- The optional drain-loop extraction was deferred, per the note above.

Move the core files, change their `package` clause, add `sim.` qualifiers in the app.
No logic changes. Constants move with their concept per the existing convention:
`G`/`DT` (physics), `BH_*` (quadtree), `TRAIL_*` (trail), `PALETTE`/`Color` (colors —
`[3]f32` data, render-agnostic, and `specs` needs it; already homed in colors.odin,
moves with the file) all go to core; `MASS_FACTOR`, `DRAG_TIME`, `MAX_SIM_SPEED`,
budget/governor constants stay app-side.

Optional in this phase: extract the accumulator drain (merge-until-clean →
`physics_step` → `trail_record`) into a core proc taking `(bodies, trails, tree,
tracked: ^int, accumulator/budget)` and returning steps taken + alpha. It is pure sim
and would keep the two future `main.odin`s from duplicating the loop invariants
(budget break, debt drop, alpha). The governor and pending-edit application stay
app-side around it. Recommended, but it can wait until the 3D app exists and the
duplication is real.

Validation: identical behavior; determinism diff — print body positions after N
steps from a fixed start, before vs after the move; must match exactly.

## Phase 3 — Genericize core over DIM (default still 2) — DONE

What actually landed:

- The `.x/.y` and `[2]f64` audits played out as listed; collision's `pair.x`
  index pairs were the one false-positive cluster, left alone. As predicted,
  the DIM=3 *type-check* was the completeness oracle — at DIM=2 `Vec` is an
  alias and misses nothing.
- The rename option was taken, wider than planned: `Quadtree` →
  `Gravity_Tree` (type, procs, and quadtree.odin → gravity_tree.odin).
- Unplanned addition: `Trail.points` went from inline `[TRAIL_CAP]Vec` to a
  heap slice sized to the *logical* cap — the 3D struct (~307 KB) tripped
  Odin's large-stack-object warning. New rules that came with ownership:
  trails own their ring (`delete` in `body_remove` *before* `ordered_remove`,
  and before the orphan overwrite); a Trail value is a handle, one owner —
  slice assignment shares storage, only `make` mints independence (the
  root-trail cap fix-up shipped exactly that aliasing bug); `Trail{}`'s nil
  ring upgrades "never hand-build a Trail" from convention to memory safety.
  Spawn-trail memory dropped ~10× as a side effect.
- Validation held: DIM=2 determinism diff bitwise-identical, DIM=3 core check
  clean across the define combos.

The audit tool is `grep -n '\.x\|\.y' core/*.odin` — every hit is either spatial
(must become per-axis) or an index pair like collision's `pair.x` (`[2]int` of body
indices — dimension-blind, leave alone). Companion grep: `grep -n '\[2\]f64'
core/*.odin` — swizzle-free spatial code (e.g. `quadtree_debug`'s `weighted_pos`)
is invisible to the `.x/.y` grep, and since `Vec` is an alias, not distinct,
`[2]f64` sites only otherwise surface at the DIM=3 type-check. Known spatial sites:

- `quadtree.odin` — the bulk of the work, all mechanical:
  - `children: [4]i32` → `[1 << DIM]i32`; the `-1` fill loops.
  - Bounding box: per-axis min/max loop over `Vec` instead of `min_x/min_y` pairs.
  - `quadtree_push_down` child selection becomes the bit trick per axis:
    `for a in 0 ..< DIM do quad |= int(pos[a] > center[a]) << uint(a)`, and the
    child-center offset reads bit `a` of `quad`.
  - `outside` test in `quadtree_accel` and both overhang axes in `box_within_reach`:
    per-axis loops.
  - `return {0, 0}` / `sum: [2]f64 = {0, 0}` → `{}` / `Vec{}` (zero value and scalar
    broadcast are arity-safe; **element-count literals are not** — `{start_dist, 0}`
    won't compile at DIM=3, which is the compiler doing the audit for you).
- `body.odin` — `pos`/`vel` construction: switch to indexed writes
  (`pos[0] += start_dist; vel[1] += start_speed`), which at DIM=3 means "start in the
  z=0 ecliptic plane" — deliberately planar for now, see Phase 4. Plus `body_spawn`'s
  `pos, vel: [2]f64` parameters → `Vec` (mechanical rename).
- `collision.odin` — `bodies_overlap` drops the `.x*.x + .y*.y` for
  `linalg.length2(r_vec)`.
- `physics.odin` — only the `BH_VALIDATE` block's `brute: [2]f64` literal.

The name `Quadtree` becomes a lie at DIM=3 (it's a `2^DIM`-tree). Rename or keep as
history — owner's call; if renaming, do it in this phase while every site is already
being touched.

Validation: at DIM=2 this must be a **no-op** — same determinism diff as Phase 2.
Then a first `-define:DIM=3` *type-check* (`odin check`) of core via a scratch entry
point or the measure build; expect only arity errors already fixed above.

## Phase 4 — DIM=3 headless, before any pixel — DONE

What actually landed:

- `determinism_dump` (measure.odin, behind `DETERMINISM_STEPS`): steps the sim
  mirroring the drain-loop order, prints positions as raw f64 bit patterns —
  the cross-build oracle both apps call before window init.
- The planar-embedding oracle passed at full strength: 3D x/y bitwise-equal to
  the 2D binary's dump and z exactly zero on both the brute path and the
  forced-tree path (`BH_THRESHOLD=0`, 20k steps) — octant selection and MAC
  decisions reproduce the 2D run exactly. 200k-step soak with a per-step
  `planar_assert` stayed clean; thick disk under `BH_VALIDATE` too.
- The headless runner lives on in the 3D app (headless.odin, whole file behind
  `when TOTAL_STEPS > 0` — moving code *out* of a `when` re-exposes it to
  every build; the gate plus `_ :: sim`/`_ :: time` anchors keep windowed
  builds clean).
- `BH_THRESHOLD` re-measured via sweep.sh with `MEASURE_Z_THICKNESS` z-jitter
  (planar spawns would have measured the 4-octant degeneracy): crossover
  **~600 in 3D vs 300 in 2D**, insensitive to disk thickness (0.1 → 0.4 AU).
  Wired as the DIM-aware default. Sweep (brute/tree ms/step, -o:speed):
  115: 0.020/0.060 · 315: 0.164/0.253 · 600: 0.615/0.640 ·
  1015: 1.77/1.33 · 3015: 18.5/6.0.
- The matrix script exists (`check.sh`, 19 cells incl. the new
  `DETERMINISM_STEPS` and `TOTAL_STEPS` cells); `ols.json` profiles (`2d`/`3d`
  with per-profile defines) teach the editor the define matrix — the
  `#assert` guards stay for terminal builds.

The measure-build habit is the vehicle: run the 3D core with no window.

- **Planar-embedding oracle**: the solar system starts in z=0 with zero z-velocity;
  gravity from a planar mass distribution has no out-of-plane component, so z must
  stay exactly 0 (bitwise — every z-term is `0*something`) and x/y trajectories must
  match the DIM=2 run step for step. Any z-drift or x/y divergence is a genericization
  bug, caught with zero 3D-rendering ambiguity.
- The octree on planar data uses only 4 of 8 octants — that degeneracy is fine and
  expected; `BH_DEBUG` invariants and `BH_VALIDATE` (θ=0 structural oracle, then
  θ=0.5 aggregate check, per the milestone-23 method) should both run clean in 3D.
  `quadtree_debug` already lives in core with a `%v` vector print, so the 3D report
  needs zero prep — and its per-axis com diff is the z-drift detector for the oracle
  above.
- **Re-measure `BH_THRESHOLD`**: 8-way branching changes the constants; the 300-body
  crossover was measured for the 2D tree + collision pass and will not carry over.
  Same harness, 3D spawns (give the measurement disk some z-thickness or the tree
  never exercises the z-split). Thickness is now a one-line change: only the
  `pos`/`vel` expressions feeding `body_spawn` in `measure_spawn`.

## Phase 5 — 3D app: minimal render — DONE

What actually landed (well past "minimal" — picking/tracking/edits came too,
pulling most of Phase 6 forward; only spawn and inclinations remain there):

- Built in verified checkpoints: camera math proven numerically before any
  pixel (every spec body starts on +x, so an in-plane eye must see them all at
  view-space x=y=0 — a three-assert oracle); then billboarded bodies, camera
  input, trails, picking/tracking/title. The edge-on collapse to a line was
  the standing visual oracle throughout.
- Camera-relative rendering everywhere: eye-at-origin view matrix, `pos − eye`
  in f64 before the one f64→f32 narrowing. Billboards are free: model-view =
  view-space translate·scale, no rotation, so the 2D circle mesh faces the
  camera by construction. Near/far scale with `distance` (constant depth
  ratio at any zoom). Marker clamp generalized with per-body depth.
- Picking stayed screen-space (project + pixel hit-test against the clamped
  marker, `clip.w` = view depth) — the ray planned here is only needed when a
  click must produce a world *position*, i.e. spawn. Click vs orbit-drag
  disambiguated by release displacement.
- The measured perf story: 3D physics costs 1.42×/step (207→295 ns), which
  pushed the 50 yr/sec drain across the 5 ms budget; 3D's `PHYSICS_BUDGET`
  default is now 0.010 — a deliberate divergence from 2D, vsync headroom
  traded for the higher governor rung.

The original plan for this phase, kept for the record:

New app package; core is already trusted. The genuinely new ground, roughly in order:

- **Camera**: orbit camera (target + azimuth/elevation/distance) replacing pan/zoom;
  view matrix from it, `linalg.matrix4_perspective` for projection. Tracking and the
  `prev_pos + (pos − prev_pos) × alpha` render lerp carry over unchanged — alpha
  interpolation is dimension-blind; the lerped position just feeds a mat4 now.
  Uniforms become `matrix[4,4]f32` (f32 at the boundary, as ever).
- **Bodies**: camera-facing billboards reusing the circle shader first — spheres and
  lighting are milestone 26. The pixel-marker clamp needs rethinking (screen-space
  size now depends on perspective distance, not one zoom scalar).
- **Trails**: recording is already core; drawing 3D line strips works as-is, and the
  `gl_VertexID` fade shader is untouched — only the transform uniform changes.
- **Depth**: enable depth test + clear depth. Trails are alpha-blended — draw them
  after opaque bodies with depth *writes* off (test on), or they'll punch holes.
- Defer picking/spawn/edit: the 3D app can launch as a view-only sim. Input starts as
  camera control only.

Validation: it *looks* planar — the solar system edge-on is a line. That is the
visible proof the physics embedding is right, before any inclination exists.

## Phase 6 — 3D interaction + real inclinations — remainder → milestones 28/29

Picking and edit/delete activation landed early, with Phase 5 — screen-space
(project + pixel hit-test), not the ray sketched below; the ray is only needed
where a click must produce a world *position*. What stays: spawn (ray ×
ecliptic) with its drag preview, and the `Body_Spec` orbital-plane fields.
Tracked as milestones 28 (spawn) and 29 (inclinations) on the roadmap.

- **Picking**: the 2D inverse transform stops existing (a pixel is a ray). Unproject
  click → ray, ray–sphere test per body (against marker radius), nearest hit wins.
- **Spawn**: needs a surface to drag on — intersect the pick ray with the ecliptic
  (z=0) plane is the natural v1. The app computes 3D pos/vel and calls core's
  `body_spawn` — the lifecycle invariants come for free.
- **Inclination**: the one real spec-design change. In 2D, "perpendicular to the
  radius" is unique; in 3D it's a plane of choices, so `Body_Spec` grows orbital-plane
  fields (inclination, longitude of ascending node) and `body_add` rotates the start
  pos/vel accordingly — parent-relative, so moons inherit their parent's frame
  automatically via the existing inside-out composition. Payoff on screen: Pluto's
  17°, Mercury's 7°. Possibly its own milestone.

## The define/lint matrix

Every build is `app × defines`, and a false `when` branch is never type-checked — the
milestone-23 lesson now has twice the surface:

```sh
odin run   opengl/sim/2d                    # DIM defaults to 2
odin run   opengl/sim/3d -define:DIM=3
odin check opengl/sim/2d -vet -strict-style
odin check opengl/sim/3d -vet -strict-style -define:DIM=3
# plus the BH_VALIDATE / BH_DEBUG / measure combos, per app
```

- Put `#assert(sim.DIM == 3)` at the top of the 3D app (and `== 2` in the 2D app):
  forgetting the define then fails with one readable line instead of a wall of
  `[2]f64` vs `[3]f64` mismatches. (It fails loudly either way — this just makes it
  kind.)
- The matrix is now big enough to script: a `check.sh` (or make target) that runs
  every combination is part of this milestone, not an afterthought.

## Known traps, restated for this work

- ~~Checking core alone isn't possible as a main package~~ Disproven in Phase 2:
  `odin check opengl/sim/core -no-entry-point` checks core directly; the app
  checks still cover the app-side `when` branches, so the matrix script exists
  anyway (check.sh).
- `::` constants referencing `DIM` are fine (compile-time), but any table sized by it
  (`[1 << DIM]i32`) changes layout between builds — never serialize/share such data
  across binaries.
- The priming rule, merge-until-clean, consume-and-reset, and the teleport rule are
  all dimension-blind and move unchanged — but the *split* is exactly the kind of
  representation change CLAUDE.md warns about: migrate every site together, lean on
  the compiler by changing leaf signatures first.
- Spec-body names are literals, spawned names are `aprintf` — the ownership rule
  crosses the package boundary intact; keep `body_remove`'s conditional `delete` in
  core with the rest of body lifecycle.

## Done means

- Two binaries from three packages, check-matrix clean, 2D behavior identical to
  pre-split (determinism diff), 3D validated headless then visually.
- CLAUDE.md commands + architecture sections updated for the new layout; README
  milestone 25 marked DONE; JOURNAL entry per the usual discipline.
