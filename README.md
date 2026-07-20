# Sol Sim

A from-scratch orbital simulation whose real purpose is the learning along the way: graphics programming with raw OpenGL, the Odin language, orbital mechanics, and the physics and math underneath it all — numerical integration, vectors, floating-point behavior. The simulation is the vehicle, not the destination.

The physics of an Earth–Moon system is identical in 2D and 3D (two bodies orbiting each other always stay in a single plane anyway), so you lose nothing physically. What you avoid is cameras, projection matrices, depth buffers, and lighting — all of which are worth learning, but they'd be noise while you're also learning Odin, OpenGL, and orbital mechanics at the same time. Once the 2D version works, "upgrading" to 3D is mostly a rendering exercise and a great second milestone.

## The three skill tracks (you can interleave them)

### 1. Odin itself

- The official Odin overview at [odin-lang.org/docs/overview](https://odin-lang.org/docs/overview) — read it once, then keep it open as a reference.
- Karl Zylinski's "Understanding the Odin Programming Language" material and his YouTube content — he's the most active Odin educator and does exactly this kind of gamedev-adjacent work.
- Key thing to internalize early: Odin ships with `vendor:` packages — `vendor:glfw`, `vendor:OpenGL`, and also `vendor:raylib`. Go look at what's in your Odin installation's `vendor/` folder.

### 2. Getting pixels on screen

- The canonical OpenGL resource is [learnopengl.com](https://learnopengl.com). It's C++, but the OpenGL calls translate almost 1:1 to Odin's bindings — translating it yourself is genuinely good practice. You need roughly the chapters through "Hello Triangle," shaders, and transformations; that's enough for circles orbiting on a black background.
- Concepts to learn, in order: window + GL context (GLFW), the render loop, vertex buffers (VBO/VAO), a minimal vertex + fragment shader, and uniforms (how you'll pass each planet's position to the shader).
- A question to sit with: raw OpenGL vs raylib. Raylib gets you a circle on screen in ~10 lines and lets you focus on physics first; raw OpenGL teaches you what's actually happening. Neither is wrong — decide what you want to learn first.

### 3. The physics

- Newton's law of universal gravitation — that's the whole force model.
- Numerical integration is where the real learning is. Look up: explicit Euler, semi-implicit (symplectic) Euler, velocity Verlet, and RK4. Understand why plain Euler makes orbits spiral outward and why "symplectic" matters for orbits specifically. This is the single most important concept for your project.
- Look up what initial velocity a circular orbit requires — that's how you'll place the Moon so it actually orbits instead of falling straight in.

## One trap to know about in advance

(Not the solution, just the trap.) The real Earth–Moon distance is ~384,000 km and G is ~6.67×10⁻¹¹. Think about what happens when you feed numbers of wildly different magnitudes into 32-bit floats, and how "real physics" and "units drawn on screen" need to relate. Search terms: *simulation units / scaling*, *float precision in space games*.

## Suggested first milestones

1. learnopengl.com ch. 1,2,3,4 - DONE
2. One circle you can draw at any position. - DONE
3. Two bodies with gravity and a naive integrator — watch it misbehave. - DONE
4. Fix the integrator. - DONE (semi-implicit Euler)
5. Add the sun, make earth/moon orbit sun - DONE
6. Real masses and distances with proper scaling. - DONE
7. 2D Camera. Zoom / Tracking
8. Real sizes of objects (Clamp into minimum markers).
9. Make 3D.
10. Lighting (Sun).
10. Make interactive.

Each one is small, and step 3 failing is a feature — you'll understand why the better integrators exist.
