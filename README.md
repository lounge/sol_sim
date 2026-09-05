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
odin run opengl/sim/3D            # debug build
odin run opengl/sim/3D -o:speed   # optimized build — needed for high sim speeds
```

Launches at the current date and time. Pin any start date with a Julian date define, e.g. the 2026-08-12 solar eclipse:

```sh
odin run opengl/sim/3D -o:speed -define:START_JD=2461265.24
```

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

## Documentation

- [ROADMAP.md](ROADMAP.md)
- [JOURNAL.md](JOURNAL.md)
- [Texture attribution](opengl/sim/3D/tex/ATTRIBUTION.md) — planet and moon maps are third-party (Solar System Scope CC BY 4.0, NASA, and others with non-commercial terms); sources and licences per file
