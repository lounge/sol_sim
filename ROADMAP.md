# Roadmap

1. learnopengl.com ch. 1,2,3,4 - DONE
2. One circle you can draw at any position. - DONE
3. Two bodies with gravity and a naive integrator ( Explicit Euler) — watch it misbehave. - DONE
4. Fix the integrator. - DONE
5. Add the sun, make earth/moon orbit sun - DONE
6. Real masses and distances with proper scaling. - DONE
7. 2D Camera. Zoom / Tracking - DONE
8. Real sizes of objects (Clamp into minimum markers). - DONE
9. Add orbit paths. - DONE
10. Add Mercury, Venus, Mars - DONE
11. Correct orbits: real eccentricities (ellipses, perihelion/aphelion) instead of idealized circles. - DONE
12. Add Jupiter, Saturn, Uranus, Neptune, Pluto - DONE
13. Decouple sim time from render rate: fixed-timestep accumulator loop ("Fix Your Timestep"), so sim speed is identical on any display/frame rate. - DONE
14. Different shaders/colors for bodies/trails. - DONE
15. Add Jupiter's moons (Io, Europa, Ganymede, Callisto) and watch the fast ones artificially precess (~300 steps/orbit for Io under semi-implicit Euler). - DONE
16. Replace semi-implicit Euler with Velocity Verlet or leapfrog — measure the precession before/after, watch it collapse. - DONE
17. Mutate the tracked body (mass, prograde/retrograde burns) - DONE
18. Spawn a body with click-drag/scroll (position + velocity, mass) - DONE
19. Delete a body. - DONE
20. Perf improvements: trail drawing at spawn scale. - DONE
21. Frame-budgeted drain loop: cap physics time per frame, degrade sim speed gracefully instead of frame rate. - DONE
22. Handle close encounters: merge two bodies on contact. - DONE
23. Barnes–Hut: O(n log n) gravity via quadtree. - DONE
24. Collision detection served by the quadtree. - DONE
25. Make 3D. - DONE
27. Lighting (Sun). - DONE
28. 3D spawn: ecliptic-plane ray + drag preview. - DONE
29. Real inclinations: orbital-plane Body_Spec fields - DONE
30. Start at a real date (now, current datetime) (mean anomaly, Kepler's equation) - DONE
31. Binary-correct setup: G(M+m) gravitational parameters everywhere; heliocentric rows become system barycenters with reflex placement (Pluto's wobble around a point outside itself). - DONE
32. Launch-time catch-up: no-args launches integrate from the spec epoch to now, so the start state is the integrator's prediction, not a stale-element lookup. - DONE
33. Cast shadows: eclipses as an occlusion term on the lighting. - DONE
34. Reverse time: ← below sim_speed 1 flips the arrow of time, Verlet integrates backward. - DONE
35. z-spawning
36. Make bodies spheres.
37. Simple textures? Glowing sun/bloom?
38. Thread accels_compute across cores, runtime-scaled to the user's machine.
39. Per-body substepping for fast moons (Phobos-class orbits).
