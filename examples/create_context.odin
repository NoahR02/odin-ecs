package examples_ecs

import ecs "../"

// Context: Internal state that the ECS needs to manipulate.
ctx: ecs.Context

main :: proc() {
  // Allocate the structures that the ECS needs to run properly.
  ctx = ecs.init_ecs()

  // Free all of the allocated memory. This will cleanup everything.
  defer ecs.deinit_ecs(&ctx)
}

