## Pickup hook shared by every item: announces the collection via a toast.
## Receives the floor [Pickup] entity (not the inventory item entity - the item
## entity does not exist yet when this runs; [member C_Item.action] gets the
## inventory entity instead).
##
## One shared [code]ia_default_pickup.tres[/code] instance of this script is
## referenced by all item .tres files, mirroring the source game's shared
## default-pickup resource.
class_name DefaultPickupAction
extends ItemAction


func _init() -> void:
	meta = {
		"name": "Default pickup",
		"description": "Announces the collected item via toast.",
	}


func _execute_item(item: Entity, _user: Entity) -> void:
	# The PickupSystem queues the pickup's removal in the same frame this action
	# was dispatched; by drain time the node may already be exiting, so guard.
	if not is_instance_valid(item) or item is not Pickup:
		return
	var pickup := item as Pickup
	var message := "Picked up %s" % pickup.item_resource.display_name
	if pickup.quantity > 1:
		message += " x%d" % pickup.quantity
	ECS.world.emit_event(&"toast", null, message)
