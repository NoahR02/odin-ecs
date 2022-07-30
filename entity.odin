package ecs

import "core:container/queue"

Entity :: distinct uint

Entity_And_Some_Info  :: struct {
  entity: Entity,
  is_valid: bool,
}

Entities :: struct {
  current_entity_id: uint,

  entities: [dynamic]Entity_And_Some_Info,
  available_slots: queue.Queue(uint),
}

create_entity :: proc(ctx: ^Context) -> Entity {
  using ctx.entities

  if queue.len(available_slots) <= 0 {
    append_elem(&entities, Entity_And_Some_Info{Entity(current_entity_id), true})
    current_entity_id += 1
    return Entity(current_entity_id - 1)
  } else {
    index := queue.pop_front(&available_slots)
    entities[index] = Entity_And_Some_Info{Entity(index), true}
    return Entity(index)
  }

  return Entity(current_entity_id)
}

is_entity_valid :: proc(ctx: ^Context, entity: Entity) -> bool {
  if uint(entity) >= len(ctx.entities.entities) {
    return false
  }
  return ctx.entities.entities[uint(entity)].is_valid
}

destroy_entity :: proc(ctx: ^Context, entity: Entity) {
  using ctx.entities
  
  for T, component in &ctx.component_map {
    remove_component_with_typeid(ctx, entity, T)
  }

  entities[uint(entity)] = {}
  queue.push_back(&available_slots, uint(entity))
}