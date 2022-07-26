package ecs

import "core:runtime"
import "core:container/queue"

Component_List :: struct {
  type: typeid,
  data: ^runtime.Raw_Dynamic_Array,
  entity_indices: map[Entity]int,
  available_slots: queue.Queue(int),
}

@private
register_component :: proc(ctx: ^Context, $T: typeid) -> ECS_Error {
  is_type_a_key := T in ctx.component_map
  if is_type_a_key {
    return .COMPONENT_IS_ALREADY_REGISTERED
  }

  array := new([dynamic]T)
  ctx.component_map[T] = {
    type = T,
    data = cast(^runtime.Raw_Dynamic_Array)array,
  }
  queue.init(&(&ctx.component_map[T]).available_slots)

  return .NO_ERROR
}

add_component :: proc(ctx: ^Context, entity: Entity, component: $T) -> (^T, ECS_Error) {
  register_component(ctx, T)

  if has_component(ctx, entity, T) {
    return nil, .ENTITY_ALREADY_HAS_THIS_COMPONENT
  } 
  array := cast(^[dynamic]T)ctx.component_map[T].data
  comp_map := &ctx.component_map[T]
  
  if queue.len(ctx.component_map[T].available_slots) <= 0 {
    // Add a new component to the component array.
    append_elem(array, component) 
    // Map the entity to the new index, so we can lookup the component index later,
    comp_map.entity_indices[entity] = len(array) - 1
  } else {
    // Use a unused slot in the array to save memory.
    item := queue.pop_front(&comp_map.available_slots)
    // Map the entity to the unusued index, so we can lookup the component index later.
    comp_map.entity_indices[entity] = item
    array[comp_map.entity_indices[entity]] = component
  }

  return &array[comp_map.entity_indices[entity]], .NO_ERROR
}

has_component :: proc(ctx: ^Context, entity: Entity, $T: typeid) -> bool {
  return entity in (&ctx.component_map[T]).entity_indices
}

remove_component :: proc(ctx: ^Context, entity: Entity, $T: typeid) -> ECS_Error {

  if !has_component(ctx, entity, T) {
    return .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)ctx.component_map[T].data
  comp_map := &ctx.component_map[T]
  
  // Push the component index onto the slot queue, so the next component dosen't use more memory.
  queue.push_back(&comp_map.available_slots, int(comp_map.entity_indices[entity]))
  // Remove the old entity key.
  delete_key(&comp_map.entity_indices, entity)

  return .NO_ERROR
}

get_component :: proc(ctx: ^Context, entity: Entity, $T: typeid) -> (component: ^T, error: ECS_Error) {
  
  if !has_component(ctx, entity, T) {
    return nil, .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)ctx.component_map[T].data
  index, is_entity_a_key := ctx.component_map[T].entity_indices[entity]
  
  if !is_entity_a_key {
    return nil, .ENTITY_DOES_NOT_MAP_TO_ANY_INDEX
  }

  return &array[index], .NO_ERROR
}

get_component_list :: proc(ctx: ^Context, $T: typeid) -> (component_list: [dynamic]^T, error: ECS_Error) {
  array := cast(^[dynamic]T)ctx.component_map[T].data
  component_list = make_dynamic_array([dynamic]^T)

  for _, index in ctx.component_map[T].entity_indices {
    append_elem(&component_list, &array[index])
  }

  return component_list, .NO_ERROR
}