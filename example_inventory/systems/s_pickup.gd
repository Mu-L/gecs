## Converts touched floor pickups into inventory items. Matches pickups that
## [Pickup]'s Area2D callback tagged ([C_PickedUp] + OwnedBy relationship) and:
## dispatches the item's pickup action, queues the add-to-inventory work, and
## queues the pickup entity's removal.
##
## The add-to-inventory chain runs as ONE [method CommandBuffer.add_custom] op:
## [method InventoryUtils.add_to_inventory] returns the surviving stack that the
## auto-activate check consumes synchronously, so the chain must execute
## atomically at flush. The removal is queued AFTER the closure, so the pickup
## is still valid when the closure reads its exports.
class_name PickupSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_IsPickup, C_PickedUp]).with_relationship([ItemRels.owned_by_hero])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var pickup := entity as Pickup
		var hero: Entity = pickup.get_relationship(ItemRels.owned_by_hero).target
		assert(hero, "Picked-up pickup has no collecting hero")

		if pickup.item_resource.pickup_action:
			pickup.item_resource.pickup_action.dispatch([pickup], hero)

		cmd.add_custom(_add_pickup_to_inventory.bind(pickup, hero))
		cmd.remove_entity(pickup)


## Runs at command-buffer flush, outside system iteration. Fresh pickups
## auto-equip when the collector's hands are empty.
func _add_pickup_to_inventory(pickup: Pickup, hero: Entity) -> void:
	var new_item := InventoryUtils.add_to_inventory(hero, pickup.item_resource, pickup.quantity)
	assert(new_item, "Failed to add pickup to inventory")
	if InventoryUtils.get_active_item(hero) == null:
		InventoryUtils.set_active_item(new_item, hero)
