package test_ecs

import "core:testing"
import ecs "../"

@test
test_entity :: proc(test: ^testing.T) {
  using ecs
  ctx: Context
  ctx = init_ecs()
  defer deinit_ecs(&ctx)

  entities: [100]Entity
  for i in 0..< len(entities) {
    entities[i] = ecs.create_entity(&ctx)
    testing.expect_value(test, uint(entities[i]), uint(i)) 
  }

  // Delete the entities. The entities should be put on the available_slots queue, so we can reuse that index later.
  for i in 0..< len(entities) do destroy_entity(&ctx, entities[i])

  // The entity ids should be the same since we deleted all of the old entities.
  for i in 0..< len(entities) {
    entities[i] = ecs.create_entity(&ctx)
    testing.expect_value(test, uint(entities[i]), uint(i)) 
  }

}
