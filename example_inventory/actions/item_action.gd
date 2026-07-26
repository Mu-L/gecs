## Abstract base for item behaviors, authored as [Resource]s and referenced from
## [member C_Item.action] / [member C_Item.pickup_action] in item .tres files.
##
## Two-phase design: [method dispatch] may be called from ANY context at ANY time
## (systems, scene signals, UI) because it only queues work; the actual
## [method _execute_item] bodies run later at [ActionQueue]'s drain point, inside
## [ActionsSystem], outside all entity iteration. That is what makes it safe for
## action bodies to mutate structure directly (remove entities, add components)
## without a command buffer.
@abstract
class_name ItemAction
extends Resource

## Authoring metadata carried alongside the queued callable for debugging.
@export var meta: Dictionary = {
	"name": "Unnamed item action",
	"description": "No description set.",
}


## The ECS query entities must match to be processed by this action.
## Override to restrict; the default matches any entity.
func query() -> QueryBuilder:
	return ECS.world.query


## Per-item behavior, implemented by each concrete action.
## [param user] is the entity using the item (the hero in this example).
@abstract func _execute_item(item: Entity, user: Entity) -> void


## Queues [method _execute_item] on [ActionQueue] for every entity in
## [param entities] that matches [method query].
func dispatch(entities: Array, user: Entity) -> void:
	assert(user, "ItemAction.dispatch: a user entity is required")
	assert(entities.size(), "ItemAction.dispatch: entities are required")
	for entity in query().matches(entities):
		ActionQueue.push(_execute_item.bind(entity, user), self)
