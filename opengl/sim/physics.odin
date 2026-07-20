package main

import "core:math"

Body :: struct {
	pos: [2]f32,
	vel: [2]f32,
	mass: f32,
	size: f32
}

G :: 1.0

physics_step :: proc(bodies: []Body, dt: f32) {
 for i := 0; i < len(bodies); i += 1 {
 	for j := i + 1; j < len(bodies); j += 1 {
  		bodyA := &bodies[i]
     	bodyB := &bodies[j]

     	// Integrator: Calculate motion
        // semi-implicit (symplectic) Euler
        r_vec := bodyA.pos - bodyB.pos
        distance := math.sqrt(r_vec.x * r_vec.x + r_vec.y * r_vec.y)
        force := G * bodyA.mass * bodyB.mass / (distance * distance)
        direction := r_vec / distance

        bodyA_accel := force / bodyA.mass
        bodyB_accel := force / bodyB.mass

        bodyA.vel -= direction * (bodyA_accel * dt)
        bodyB.vel += direction * (bodyB_accel * dt)
  	}
 }

 for &body in bodies {
	body.pos += body.vel * dt
 }
}
