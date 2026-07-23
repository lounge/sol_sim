package main

import "core:math"

G :: 1.0

Body :: struct {
	name: string,
	pos: [2]f64,
	vel: [2]f64,
	mass: f64,
	radius: f64
}

physics_step :: proc(bodies: []Body, dt: f64) {
 for i := 0; i < len(bodies); i += 1 {
 	for j := i + 1; j < len(bodies); j += 1 {
  		bodyA := &bodies[i]
     	bodyB := &bodies[j]

     	// Integrator: Calculate motion
        // semi-implicit (symplectic) Euler
        r_vec := bodyA.pos - bodyB.pos
        distance := math.sqrt(r_vec.x * r_vec.x + r_vec.y * r_vec.y)

        force: f64 = G * bodyA.mass * bodyB.mass / (distance * distance)
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
