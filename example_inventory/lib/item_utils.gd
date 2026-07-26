## Static composer turning a [C_Item] template into a runtime item entity.
## Keeps [C_Item] pure data: all "how does a template become an entity" logic
## lives here, mirroring the [InventoryUtils]/[ItemQueries] split.
class_name ItemUtils


## Composes a runtime item entity from a [C_Item] template: the SHARED template
## resource itself, a fresh [C_Quantity] of [param qty], and a deep-duplicated
## copy of every [member C_Item.extra_components] entry (so runtime mutation of
## an attached component cannot leak back to the .tres or sideways to other
## stacks spawned from the same template).
##
## The returned entity is NOT yet in the world; the caller decides where it goes
## (usually [method InventoryUtils.add_to_inventory]).
static func make_item(c_item: C_Item, qty: int) -> Entity:
	assert(c_item, "ItemUtils.make_item: c_item is required")
	var entity := Entity.new()
	entity.name = "%s-%d" % [c_item.display_name, entity.get_instance_id()]

	var comps: Array = [c_item, C_Quantity.new(qty)]
	for extra in c_item.extra_components:
		if extra:
			comps.append(extra.duplicate(true))
	entity.add_components(comps)

	return entity
