## Drops one unit of the item back onto the floor as a fresh [Pickup] and
## removes it from the stack. The inverse of the pickup flow: inventory entity
## out, world pickup in.
##
## The pickup lands offset below the user with a little jitter; [Pickup]'s
## spawn grace period (not this offset) is what prevents instant re-collection.
## Not referenced by any item .tres - [HeroInputSystem] holds an instance and
## dispatches it on the drop key, showing that actions work fine without being
## authored into a template.
class_name DropItemAction
extends ItemAction


func _init() -> void:
	meta = {
		"name": "Drop item",
		"description": "Drops one unit of the item as a floor pickup.",
	}


func _execute_item(item: Entity, user: Entity) -> void:
	var c_item := item.get_component(C_Item) as C_Item
	if not c_item:
		return
	var pickup := Pickup.make_pickup(c_item, 1)
	var user_position := (user as Node as Node2D).global_position
	pickup.position = user_position + Vector2(randf_range(-24.0, 24.0), 48.0)
	ECS.world.add_entity(pickup)
	InventoryUtils.remove_inventory_item(item, 1)
	ECS.world.emit_event(&"toast", null, "Dropped %s" % c_item.display_name)
