package ecs

import "core:runtime"
import "core:container/queue"

Entity :: distinct int

typeids: uint = 0
typeid_to_bit_location_map: map[typeid]uint
bit_to_typeid_map: map[uint]typeid

ECS_Error :: enum {
  NO_ERROR,
  ENTITY_DOES_NOT_HAVE_THIS_COMPONENT,
  ENTITY_DOES_NOT_MAP_TO_ANY_INDEX,
  ENTITY_ALREADY_HAS_THIS_COMPONENT,
  COMPONENT_NOT_REGISTERED,
  COMPONENT_IS_ALREADY_REGISTERED,
}

map_typeid_to_bit :: proc(id: typeid) -> uint {
  typeid_to_bit_location_map[id] = typeids
  bit_to_typeid_map[typeids] = id
  defer typeids += 1
  return typeids
}

Entity_And_Mask :: struct {
  entity: Entity,
  mask: u32,
}

entity_manager: struct {
  entity_id: int,

  entities: [dynamic]Entity_And_Mask,
  available_slots: queue.Queue(int),
}

init_ecs :: proc() {
  typeid_to_bit_location_map = make(map[typeid]uint)
  bit_to_typeid_map = make(map[uint]typeid)
  create_entity_manager()
}

deinit_ecs :: proc() {
  delete(typeid_to_bit_location_map)
  delete(bit_to_typeid_map)
  destroy_entity_manager()

  for key, value in Component_Map.component_map {
    queue.destroy(&(&Component_Map.component_map[key]).available_slots)
    free(value.data^.data)
    free(value.data)
  }

  for key, value in Component_Map.component_map {
    delete(value.entity_index)
  }

  delete(Component_Map.component_map)
}

create_entity_manager :: proc() {
  using entity_manager
  entity_manager.entities = make([dynamic]Entity_And_Mask)
  queue.init(&available_slots)
}

destroy_entity_manager :: proc() {
  using entity_manager
  delete(entity_manager.entities)
  entity_id = 0
  queue.destroy(&available_slots)
}

create_entity :: proc() -> Entity {
  using entity_manager

  if queue.len(available_slots) <= 0 {
    append_elem(&entities, Entity_And_Mask{Entity(entity_id), {}})
    entity_id += 1
    return Entity(entity_id - 1)
  } else {
    index := queue.pop_front(&available_slots)
    entities[index] = {Entity(index), {}}
    return Entity(index)
  }

  return Entity(entity_id)
}

destroy_entity :: proc(entity: Entity) {
  using entity_manager

  mask := entities[int(entity)].mask

  for _, component in &Component_Map.component_map {
   found := entity in component.entity_index
   if !found do continue

   queue.push_back(&component.available_slots, component.entity_index[entity])
   delete_key(&component.entity_index, entity)
  }

  entities[int(entity)] = {}
  queue.push_back(&available_slots, int(entity))
}

Component_List :: struct {
  type: typeid,
  data: ^runtime.Raw_Dynamic_Array,
  entity_index: map[Entity]int,
  available_slots: queue.Queue(int),
}

Component_Map: struct {
  component_map: map[typeid]Component_List,
}

@private
register_component :: proc($T: typeid) -> ECS_Error {
  is_type_a_key := T in typeid_to_bit_location_map
  if is_type_a_key {
    return .COMPONENT_IS_ALREADY_REGISTERED
  }

  array := new([dynamic]T)
  Component_Map.component_map[T] = {
    type = T,
    data = cast(^runtime.Raw_Dynamic_Array)array,
  }
  map_typeid_to_bit(T)
  queue.init(&(&Component_Map.component_map[T]).available_slots)

  return nil
}

add_component :: proc(entity: Entity, component: $T) -> (^T, ECS_Error) {
  register_component(T)

  if has_component(entity, T) {
    return nil, .ENTITY_ALREADY_HAS_THIS_COMPONENT
  } 
  array := cast(^[dynamic]T)Component_Map.component_map[T].data

  id: u32 = 1 << typeid_to_bit_location_map[T]  
  entity_manager.entities[int(entity)].mask ~= id
  
  if queue.len(Component_Map.component_map[T].available_slots) <= 0 {
    append_elem(array, component) 
    (&Component_Map.component_map[T]).entity_index[entity] = len(array) - 1
  } else {
    item := queue.pop_front(&(&Component_Map.component_map[T]).available_slots)
    (&Component_Map.component_map[T]).entity_index[entity] = item
    array[(&Component_Map.component_map[T]).entity_index[entity]] = component
  }
  return &array[(&Component_Map.component_map[T]).entity_index[entity]], nil
}

has_component :: proc(entity: Entity, $T: typeid) -> bool {
  bit, found := typeid_to_bit_location_map[T]
  if !found {
    return false
  }
  
  id: u32 = 1 << bit 

  mask := entity_manager.entities[entity].mask
  mask &= id

  return mask == id
}

remove_component :: proc(entity: Entity, $T: typeid) -> ECS_Error {

  if !has_component(entity, T) {
    return .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)Component_Map.component_map[T].data
  id: u32 = 0 << typeid_to_bit_location_map[T]  
  entity_manager.entities[int(entity)].mask ~= id

  queue.push_back(&(&Component_Map.component_map[T]).available_slots, int((&Component_Map.component_map[T]).entity_index[entity]))
  delete_key(&(&Component_Map.component_map[T]).entity_index, entity)

  return nil
}

get_component :: proc(entity: Entity, $T: typeid) -> (component: ^T, error: ECS_Error) {
  
  if !has_component(entity, T) {
    return nil, .ENTITY_DOES_NOT_HAVE_THIS_COMPONENT
  }

  array := cast(^[dynamic]T)Component_Map.component_map[T].data
  index, is_entity_a_key := Component_Map.component_map[T].entity_index[entity]
  
  if !is_entity_a_key {
    return nil, .ENTITY_DOES_NOT_MAP_TO_ANY_INDEX
  }

  return &array[index], nil
}

get_component_list :: proc($T: typeid) -> (component_list: [dynamic]^T, error: ECS_Error) {
  array := cast(^[dynamic]T)Component_Map.component_map[T].data
  component_list = make_dynamic_array([dynamic]^T)

  for _, index in Component_Map.component_map[T].entity_index {
    append_elem(&component_list, &array[index])
  }

  return component_list, {}
}