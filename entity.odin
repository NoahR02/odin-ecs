package ecs

import "core:container/queue"

Entity :: distinct uint

Entities :: struct {
  current_entity_id: uint,

  entities: [dynamic]Entity,
  available_slots: queue.Queue(uint),
}

create_entity :: proc(ctx: ^Context) -> Entity {
  using ctx.entities

  if queue.len(available_slots) <= 0 {
    append_elem(&entities, Entity(current_entity_id))
    current_entity_id += 1
    return Entity(current_entity_id - 1)
  } else {
    index := queue.pop_front(&available_slots)
    entities[index] = Entity(index)
    return Entity(index)
  }

  return Entity(current_entity_id)
}

destroy_entity :: proc(ctx: ^Context, entity: Entity) {
  using ctx.entities


  for _, component in &ctx.component_map {
   found := entity in component.entity_indices
   if !found do continue

   queue.push_back(&component.available_slots, component.entity_indices[entity])
   delete_key(&component.entity_indices, entity)
  }

  entities[uint(entity)] = {}
  queue.push_back(&available_slots, uint(entity))
}