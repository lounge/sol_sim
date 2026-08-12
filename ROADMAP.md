# Roadmap

1. [x] learnopengl.com.
2. [x] One circle you can draw at any position.
3. [x] Two bodies with gravity and a naive integrator ( Explicit Euler) — watch it misbehave.
4. [x] Fix the integrator.
5. [x] Add the sun, make earth/moon orbit sun
6. [x] Real masses and distances with proper scaling.
7. [x] 2D Camera. Zoom / Tracking
8. [x] Real sizes of objects (Clamp into minimum markers).
9. [x] Add orbit paths.
10. [x] Add Mercury, Venus, Mars
11. [x] Correct orbits: real eccentricities (ellipses, perihelion/aphelion) instead of idealized circles.
12. [x] Add Jupiter, Saturn, Uranus, Neptune, Pluto
13. [x] Decouple sim time from render rate: fixed-timestep accumulator loop ("Fix Your Timestep"), so sim speed is identical on any display/frame rate.
14. [x] Different shaders/colors for bodies/trails.
15. [x] Add Jupiter's moons (Io, Europa, Ganymede, Callisto) and watch the fast ones artificially precess (~300 steps/orbit for Io under semi-implicit Euler).
16. [x] Replace semi-implicit Euler with Velocity Verlet or leapfrog — measure the precession before/after, watch it collapse.
17. [x] Mutate the tracked body (mass, prograde/retrograde burns)
18. [x] Spawn a body with click-drag/scroll (position + velocity, mass)
19. [x] Delete a body.
20. [x] Perf improvements: trail drawing at spawn scale.
21. [x] Frame-budgeted drain loop: cap physics time per frame, degrade sim speed gracefully instead of frame rate.
22. [x] Handle close encounters: merge two bodies on contact.
23. [x] Barnes–Hut: O(n log n) gravity via quadtree.
24. [x] Collision detection served by the quadtree.
25. [x] Convert the 2D app -> 3D.
26. [x] Remove 2D app
27. [x] Lighting (Sun).
28. [x] 3D spawn: ecliptic-plane ray + drag preview.
29. [x] Real inclinations: orbital-plane Body_Spec fields
30. [x] Start at a real date (now, current datetime) (mean anomaly, Kepler's equation)
31. [x] Binary-correct setup: G(M+m) gravitational parameters everywhere; heliocentric rows become system barycenters with reflex placement (Pluto's wobble around a point outside itself).
32. [x] Launch-time catch-up: no-args launches integrate from the spec epoch to now, so the start state is the integrator's prediction, not a stale-element lookup.
33. [x] Cast shadows: eclipses as an occlusion term on the lighting.
34. [x] Reverse time: ← below sim_speed 1 flips the arrow of time, Verlet integrates backward.
35. [ ] Debug/Confirm correctness against the real sky live. Solar Eclipse (Sweden: 2026-08-12 19:00-21:00) 
36. [ ] tests for the pure leaves (date conversions, kepler_solve round-trip, spec_rel_state)
37. [ ] Make bodies spheres.
38. [ ] Simple textures? Glowing sun/bloom?
39. [ ] Thread accels_compute across cores, runtime-scaled to the user's machine. Test improvment ganes
40. [ ] Per-body substepping for fast moons (Phobos-class orbits).
41. [ ] z-spawning
42. [ ] Port to Vulkan? :'(
