## Consumable-with-buff demo: removes one unit and attaches a timed
## [C_SpeedBoost] to the user. Expiry belongs to [SpeedBoostSystem], the UI badge
## to [O_HeroStatus] - this action only plants the data. Using boots while
## boosted replaces the component, refreshing the duration.
##
## Direct [method Entity.add_component] is safe here because action bodies run at
## the [ActionQueue] drain point, outside all system iteration.
class_name UseSpeedBootsAction
extends ItemAction


func _init() -> void:
	meta = {
		"name": "Use speed boots",
		"description": "Grants a timed x2 movement boost and consumes the boots.",
	}


func _execute_item(item: Entity, user: Entity) -> void:
	InventoryUtils.remove_inventory_item(item)
	user.add_component(C_SpeedBoost.new(2.0, 5.0))
	ECS.world.emit_event(&"toast", null, "Speed boost! x2 for 5 seconds")
