# Sol Sim

A from-scratch orbital simulation whose real purpose is the learning along the way: graphics programming with raw OpenGL, the Odin language, orbital mechanics, and the physics and math underneath it all — numerical integration, vectors, floating-point behavior. The simulation is the vehicle, not the destination.

## Milestones

1. learnopengl.com ch. 1,2,3,4 - DONE
2. One circle you can draw at any position. - DONE
3. Two bodies with gravity and a naive integrator — watch it misbehave. - DONE
4. Fix the integrator. - DONE (semi-implicit Euler)
5. Add the sun, make earth/moon orbit sun - DONE
6. Real masses and distances with proper scaling. - DONE
7. 2D Camera. Zoom / Tracking - DONE
8. Real sizes of objects (Clamp into minimum markers). - DONE
9. Add orbit paths. - DONE
10. Add Mercury, Venus, Mars - DONE
11. Correct orbits: real eccentricities (ellipses, perihelion/aphelion) instead of idealized circles. - DONE
12. Add Jupiter, Saturn, Uranus, Neptune, Pluto (plus per-body trail strides, click-to-track, adjustable sim speed) - DONE
13. Decouple sim time from render rate: fixed-timestep accumulator loop ("Fix Your Timestep"), so sim speed is identical on any display/frame rate. - DONE
14. Different shaders/colors for bodies/trails. - DONE (per-body palette, trail fade via gl_VertexID, sim speed clamp)
15. Add Jupiter's moons (Io, Europa, Ganymede, Callisto) and watch the fast ones artificially precess (~300 steps/orbit for Io under semi-implicit Euler).
16. Replace semi-implicit Euler with Velocity Verlet or leapfrog — measure the precession before/after, watch it collapse.
17. Make 3D.
18. Lighting (Sun).
19. Make interactive.
