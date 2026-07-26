## Consumable demo: refills the user's [C_HitPoints] and removes one unit from
## the stack. Writing through the [member C_HitPoints.current] setter is what
## makes [O_HeroStatus]'s [code]on_changed[/code] observer repaint the health
## bar - no signal wiring here.
##
## Divergence from the source game: using a kit at full health refuses (and
## keeps the item) instead of silently wasting it.
class_name UseHealthKitAction
extends ItemAction


func _init() -> void:
	meta = {
		"name": "Use health kit",
		"description": "Heals the user to full and consumes one kit.",
	}


func _execute_item(item: Entity, user: Entity) -> void:
	var c_hp := user.get_component(C_HitPoints) as C_HitPoints
	if not c_hp:
		return
	if c_hp.current >= c_hp.total:
		ECS.world.emit_event(&"toast", null, "Already at full health")
		return
	c_hp.current = c_hp.total
	ECS.world.emit_event(&"toast", null, "Healed to full!")
	InventoryUtils.remove_inventory_item(item)
