package ecs

/* import "core:fmt"
import "core:testing"

@(test)
test_ecs :: proc(test: ^testing.T) {
  
  init_ecs()
  defer deinit_ecs()

  Sprite :: struct {
    x, y: f32,
    width, height: f32,
  }

  entity := create_entity()
  defer destroy_entity(entity)
  
  comp, add_err := add_component(entity, Sprite{20, 10, 90, 80})
  testing.expect_value(test, comp^, Sprite{20, 10, 90, 80})
  testing.expect_value(test, add_err, ECS_Error.NO_ERROR)
  
  remove_err1 := remove_component(entity, Sprite)
  testing.expect_value(test, remove_err1, ECS_Error.NO_ERROR)

  remove_err2 := remove_component(entity, i32)
  testing.expect_value(test, remove_err2, ECS_Error.ENTITY_DOES_NOT_HAVE_THIS_COMPONENT)

  add_component(entity, Sprite{20, 20, 32, 32})
  defer remove_component(entity, Sprite)
  
} */