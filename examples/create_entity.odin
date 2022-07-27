package examples_ecs

import ecs "../"

// Entity: ID(number) that we use as a index internally to relate data to the entity(ID).

main :: proc() {
  ctx: ecs.Context
  ctx = ecs.init_ecs()
  defer ecs.deinit_ecs(&ctx)

  // This will return a id(number) that we use internally.
  entity := ecs.create_entity(&ctx)
  // Optional, depending on your usage.
  defer ecs.destroy_entity(&ctx, entity)
}

