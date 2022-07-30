package ecs

import "core:runtime"
import "core:container/queue"

ECS_Error :: enum {
  NO_ERROR,
  ENTITY_DOES_NOT_HAVE_THIS_COMPONENT,
  ENTITY_DOES_NOT_MAP_TO_ANY_INDEX,
  ENTITY_ALREADY_HAS_THIS_COMPONENT,
  COMPONENT_NOT_REGISTERED,
  COMPONENT_IS_ALREADY_REGISTERED,
}

Context :: struct {
  entities: Entities,
  component_map: map[typeid]Component_List,
}

init_ecs :: proc() -> (ctx: Context) {
  create_entities :: proc(ctx: ^Context) {
    ctx.entities.entities = make([dynamic]Entity_And_Some_Info)
    queue.init(&ctx.entities.available_slots)
  }
  create_entities(&ctx)

  create_component_map :: proc(ctx: ^Context) {
    ctx.component_map = make(map[typeid]Component_List)
  }

  create_component_map(&ctx)

  return ctx
}

deinit_ecs :: proc(ctx: ^Context) {

  destroy_entities :: proc(ctx: ^Context) {
    delete(ctx.entities.entities)
    ctx.entities.current_entity_id = 0
    queue.destroy(&ctx.entities.available_slots)
  }
  destroy_entities(ctx)

  destroy_component_map :: proc(ctx: ^Context) {
    for key, value in ctx.component_map {
      free(value.data^.data)
      free(value.data)
    }
  
    for key, value in ctx.component_map {
      delete(value.entity_indices)
    }
  
    delete(ctx.component_map)
  }
  destroy_component_map(ctx)
}

