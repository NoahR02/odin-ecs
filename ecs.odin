package ecs

import "core:runtime"
import "core:container/queue"

Entity_And_Mask :: struct {
  entity: Entity,
}

Entity_Manager :: struct {
  current_entity_id: int,

  entities: [dynamic]Entity_And_Mask,
  available_slots: queue.Queue(int),
}

  entity_manager: Entity_Manager

ECS :: struct {
  
}

init_ecs :: proc() {
  create_entity_manager()
}

deinit_ecs :: proc() {
  destroy_entity_manager()

  for key, value in component_map {
    queue.destroy(&(&component_map[key]).available_slots)
    free(value.data^.data)
    free(value.data)
  }

  for key, value in component_map {
    delete(value.entity_indices)
  }

  delete(component_map)
}

create_entity_manager :: proc() {
  using entity_manager
  entity_manager.entities = make([dynamic]Entity_And_Mask)
  queue.init(&available_slots)
}

destroy_entity_manager :: proc() {
  using entity_manager
  delete(entity_manager.entities)
  current_entity_id = 0
  queue.destroy(&available_slots)
}

create_entity :: proc() -> Entity {
  using entity_manager

  if queue.len(available_slots) <= 0 {
    append_elem(&entities, Entity_And_Mask{Entity(current_entity_id)})
    current_entity_id += 1
    return Entity(current_entity_id - 1)
  } else {
    index := queue.pop_front(&available_slots)
    entities[index] = {Entity(index)}
    return Entity(index)
  }

  return Entity(current_entity_id)
}

destroy_entity :: proc(entity: Entity) {
  using entity_manager

  for _, component in &component_map {
   found := entity in component.entity_indices
   if !found do continue

   queue.push_back(&component.available_slots, component.entity_indices[entity])
   delete_key(&component.entity_indices, entity)
  }

  entities[int(entity)] = {}
  queue.push_back(&available_slots, int(entity))
}

Component_List :: struct {
  type: typeid,
  data: ^runtime.Raw_Dynamic_Array,
  entity_indices: map[Entity]int,
  available_slots: queue.Queue(int),
}

component_map: map[typeid]Component_List

@private
register_component :: proc($T: typeid) -> ECS_Error {
  is_type_a_key := T in component_map
  if is_type_a_key {
    return .COMPONENT_IS_ALREADY_REGISTERED
  }

  array := new([dynamic]T)
  component_map[T] = {
    type = T,
    data = cast(^runtime.Raw_Dynamic_Array)array,
  }
  queue.init(&(&component_map[T]).available_slots)

  return .NO_ERROR
}

add_component :: proc(entity: Entity, component: $T) -> (^T, ECS_Error) {
  register_component(T)

  if has_component(entity, T) {
    return nil, .ENTITY_ALREADY_HAS_THIS_COMPONENT
  } 
  array := cast(^[dynamic]T)component_map[T].data
  comp_map := &component_map[T]

  //add_component_to_entity_mask(entity, T)
  
  if queue.len(component_map[T].available_slots) <= 0 {
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

has_component :: proc(entity: Entity, $T: typeid) -> bool {
  return entity in (&component_map[T]).entity_indices
}

remove_component :: proc(entity: Entity, $T: typeid) -> ECS_Error {

  if !has_component(entity, T) {
    return .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)component_map[T].data
  comp_map := &component_map[T]

  //remove_component_from_entity_mask(entity, T)
  
  // Push the component index onto the slot queue, so the next component dosen't use more memory.
  queue.push_back(&comp_map.available_slots, int(comp_map.entity_indices[entity]))
  // Remove the old entity key.
  delete_key(&comp_map.entity_indices, entity)

  return .NO_ERROR
}

get_component :: proc(entity: Entity, $T: typeid) -> (component: ^T, error: ECS_Error) {
  
  if !has_component(entity, T) {
    return nil, .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)component_map[T].data
  index, is_entity_a_key := component_map[T].entity_indices[entity]
  
  if !is_entity_a_key {
    return nil, .ENTITY_DOES_NOT_MAP_TO_ANY_INDEX
  }

  return &array[index], .NO_ERROR
}

get_component_list :: proc($T: typeid) -> (component_list: [dynamic]^T, error: ECS_Error) {
  array := cast(^[dynamic]T)component_map[T].data
  component_list = make_dynamic_array([dynamic]^T)

  for _, index in component_map[T].entity_indices {
    append_elem(&component_list, &array[index])
  }

  return component_list, .NO_ERROR
}

