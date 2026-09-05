# sol_sim

A from-scratch orbital simulation of the solar system. Trying to learn some new stuff...

## Learning

- **Odin** — lang
- **Graphics programming** — raw OpenGL, GLSL shaders, cameras & picking, f64→f32 precision at the GPU boundary, framebuffer objects & post-processing chains
- **Lighting & colour** — Lambert diffuse on UV-sphere meshes, analytic eclipse occlusion, sRGB textures & mipmaps, linear-light workflow & gamma 2.2, HDR and bloom, Narkowicz's ACES filmic tonemapping
- **Math** — numerical integration (explicit/semi-implicit Euler → velocity Verlet / leapfrog), vectors, floating-point behavior
- **Physics** — Newtonian gravity, orbital mechanics: Kepler's equation, osculating elements, barycenters & reflex motion
- **Algorithms** — Barnes–Hut octree, fixed-timestep loop, ring buffers
- **Real data** — JPL Horizons ephemerides, reference frames & epochs (J2000, TDB/UTC), Julian-date calendars
- **Texturing** — UV-sphere generation & seam handling, equirectangular maps, sRGB-vs-linear texture formats, mipmapping, PNG decoding in pure Odin
- **Planetary rotation** — sidereal periods, IAU pole & prime-meridian conventions, cartographic north vs. the right-hand rule
- **Engineering** — fixed-timestep accumulator, bitwise determinism dumps as a regression oracle, headless soak builds, a define/lint matrix

## Run

```sh
odin run sim/opengl            # debug build
odin run sim/opengl -o:speed   # optimized build — needed for high sim speeds
```

Launches at the current date and time. Pin any start date with a Julian date define, e.g. the 2026-08-12 solar eclipse:

```sh
odin run sim/opengl -o:speed -define:START_JD=2461265.24
```

## Seeing the octree

Gravity switches from brute force to a Barnes–Hut octree above `BH_THRESHOLD` bodies (600 by default), so the default system never builds one. Force the tree and draw its cells:

```sh
odin run sim/opengl -o:speed -define:BH_DEBUG_DRAW=true -define:BH_THRESHOLD=0
odin run sim/opengl -o:speed -define:BH_DEBUG_DRAW=true -define:BH_THRESHOLD=0 -define:MEASURE=true   # +300 spawned bodies, a much busier tree
```

Cells are drawn in red as wireframe boxes and rebuilt every physics step; zoom out to see the whole hierarchy, or right-drag to spawn bodies and watch the cells subdivide around them.

## Controls

| Input | Action |
|---|---|
| left-click a body | track it |
| left-drag | orbit the camera |
| scroll | zoom (during a spawn drag: spawn mass) |
| right-drag | spawn a body — position and velocity, relative to the tracked body |
| ← / → | slower / faster; ← below 1× flips time backward |
| ↑ / ↓ | prograde / retrograde burn on the tracked body |
| . / , | grow / shrink the tracked body's mass |
| Backspace / Delete | delete the tracked body |
| T | show / hide trails |
| W | wireframe on / off |
| Esc | quit |

## Scripts

```sh
scripts/check.sh    # the lint bar: odin check with -vet -strict-style across every define combination (17 cells), then the unit tests
scripts/sweep.sh    # BH_THRESHOLD crossover: headless MEASURE builds timing brute force vs. octree per body count, prints ms/step for each
```

`check.sh` exists because a false `when` branch is parsed but never type-checked, so each define combination is its own compile and must be linted on its own; keep it clean before committing. `sweep.sh` takes a few minutes and is only needed when the gravity or tree code changes; its crossover is what sets the shipped `BH_THRESHOLD`.

## Documentation

- [ROADMAP.md](ROADMAP.md)
- [JOURNAL.md](JOURNAL.md)
- [Texture attribution](sim/opengl/tex/ATTRIBUTION.md) — planet and moon maps are third-party (Solar System Scope CC BY 4.0, NASA, and others with non-commercial terms); sources and licences per file
