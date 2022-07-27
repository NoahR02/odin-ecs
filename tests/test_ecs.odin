package test_ecs

import "core:fmt"
import "core:testing"
import "core:container/queue"

import ecs "../"

@test
test_entity :: proc(test: ^testing.T) {
  using ecs
  ctx: Context
  ctx = init_ecs()
  defer deinit_ecs(&ctx)

  entity := create_entity(&ctx)
  testing.expect(test, entity == 0, "Error: The first entity id should be zero!")  
  testing.expect(test, ctx.entities.available_slots.len == 0, "Error: The queue should be empty upon creation of the first entity!")  
  testing.expect(test, ctx.entities.current_entity_id == 1, "Error: The current entity id should have been incremented!")

  destroy_entity(&ctx, entity)
  testing.expect(test, ctx.entities.available_slots.len == 1, "Error: The deleted entity id should be placed on the queue!")
  testing.expect(test, queue.front(&ctx.entities.available_slots) == 0, "Error: The new entity slot should be 0!")
}

@test
test_component :: proc(test: ^testing.T) {
  using ecs
  ctx: Context
  Sprite :: struct {
    x, y: f32,
    width, height: f32,
  }

  Name :: distinct string

  ctx = init_ecs()
  defer deinit_ecs(&ctx)

  entity := create_entity(&ctx)

  test_comp_value := Sprite {
    x = 20, y = 20,
    width = 64, height = 64,
  }
  
  is_component_added_properly :: proc(ctx: ^ecs.Context, test: ^testing.T, entity: ecs.Entity, component: $A) -> (^A) {
    
    comp, comp_err := add_component(ctx, entity, component)
    is_returned_comp_equal := comp^ == component
    testing.expect(test, is_returned_comp_equal == true, "Error: The returned component is not equal to the original component passed in.")
    testing.expect_value(test, comp_err, ECS_Error.NO_ERROR)

    is_type_in_map := A in ctx.component_map
    testing.expect(test, is_type_in_map == true, "Failed to register the component type!")
    return comp
  }

  sprite_comp := is_component_added_properly(&ctx, test, entity, test_comp_value)
  name_comp := is_component_added_properly(&ctx, test, entity, Name("Test Name"))

  is_component_removed_properly :: proc(ctx: ^ecs.Context, test: ^testing.T, entity: ecs.Entity, $T: typeid) {
    old_entity_index := ctx.component_map[T].entity_indices[entity]
    
    comp_err := remove_component(ctx, entity, T)
    testing.expect_value(test, comp_err, ECS_Error.NO_ERROR)

    is_entity_index_valid := entity in ctx.component_map[T].entity_indices
    testing.expect(test, is_entity_index_valid == false, "Error: The key should be deleted after the entity removes the component.")
    testing.expect(test, old_entity_index == queue.front(&(&ctx.component_map[T]).available_slots), "Error: The old component slot should be put on the queue!")
  }

  is_component_removed_properly(&ctx, test, entity, Sprite)
  is_component_removed_properly(&ctx, test, entity, Name)
}