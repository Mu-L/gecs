## The inventory API: static helpers for adding, removing, stacking, and
## activating items. Ported from the source game with its autoload signals
## replaced by GECS custom events ([code]&"inventory_changed"[/code],
## [code]&"active_item_changed"[/code]) that the UI observers consume.
##
## An inventory is nothing but [C_OwnedBy] relationships (see [C_OwnedBy]);
## every method here manipulates item entities and lets queries do the rest.
class_name InventoryUtils


## Returns the entity that owns [param e_item] via its [C_OwnedBy] relationship.
static func get_item_owner(e_item: Entity) -> Entity:
	var item_owner: Entity = e_item.get_relationship(ItemRels.owned_by_any).target
	assert(item_owner != null, "Item has no owner")
	return item_owner


## Returns [param owner]'s active item, or null when hands are empty.
static func get_active_item(owner: Entity) -> Entity:
	return ItemQueries.in_inventory_of(owner).combine(ItemQueries.is_active_item()).execute_one()


## Makes [param e_item] the held item for [param owner] (null = empty hands).
## Keeps the [C_IsActiveItem] tag and the [C_HasActiveItem] relationship in sync;
## this is the ONLY place either should be mutated. Emits
## [code]&"active_item_changed"[/code] so [O_QuickBar] can re-highlight.
static func set_active_item(e_item: Entity, owner: Entity) -> void:
	owner.remove_relationship(Relationship.new(C_HasActiveItem.new(), ECS.wildcard))
	var active_items := (
		ItemQueries.in_inventory_of(owner).combine(ItemQueries.is_active_item()).execute()
	)
	for e in active_items:
		e.remove_component(C_IsActiveItem)

	if e_item == null:
		ECS.world.emit_event(&"active_item_changed", owner, null)
		return

	e_item.add_component(C_IsActiveItem.new())
	owner.add_relationship(Relationship.new(C_HasActiveItem.new(), e_item))
	ECS.world.emit_event(&"active_item_changed", owner, e_item)


## Dispatches [param item]'s use action ([member C_Item.action]), if it has one.
## The action body runs later, at [ActionQueue]'s drain point.
static func use_inventory_item(item: Entity, owner: Entity) -> void:
	var action := get_item_action(item)
	if action:
		action.dispatch([item], owner)


## Spawns a stack of [param quantity] x [param c_item] straight into
## [param owner]'s inventory and consolidates duplicates. Returns the surviving
## stack entity.
##
## The re-fetch through [method get_item] is deliberate (a fix over the source
## game): consolidation may merge the entity just created into an existing stack
## and free it, so returning the original reference would hand back a dead
## entity.
static func add_to_inventory(owner: Entity, c_item: C_Item, quantity: int) -> Entity:
	var new_entity := ItemUtils.make_item(c_item, quantity)
	new_entity.add_relationship(Relationship.new(C_OwnedBy.new(), owner))
	ECS.world.add_entity(new_entity)
	if _should_stack(new_entity):
		consolidate_inventory(owner)

	ECS.world.emit_event(&"inventory_changed", owner, {"reason": &"added"})
	var survivor := get_item(owner, c_item)
	return survivor if survivor else new_entity


## Removes [param remove_quantity] units from [param item]'s stack. At zero the
## entity leaves the world entirely (clearing the active slot first if needed).
##
## No pending-delete tag is required here (the source game used one): every call
## path runs at the [ActionQueue] drain point or a command-buffer flush, both
## outside entity iteration, so direct removal is safe.
static func remove_inventory_item(item: Entity, remove_quantity: int = 1) -> void:
	var c_item := item.get_component(C_Item) as C_Item
	var c_qty := item.get_component(C_Quantity) as C_Quantity
	if not c_item or not c_qty or c_qty.value < remove_quantity:
		return
	var item_owner := get_item_owner(item)
	c_qty.value -= remove_quantity
	if c_qty.value == 0:
		if item.has_component(C_IsActiveItem):
			set_active_item(null, item_owner)
		ECS.world.remove_entity(item)

	ECS.world.emit_event(&"inventory_changed", item_owner, {"reason": &"removed"})


## Merges every stackable duplicate in [param owner]'s inventory: buckets by
## [member C_Item.type_id], sums quantities into the first entity of each
## bucket, and removes the rest. Re-adding [C_Quantity] replaces the existing
## instance (GECS same-type add semantics).
static func consolidate_inventory(owner: Entity) -> void:
	var inventory_entities := ItemQueries.in_inventory_of(owner).execute()
	var by_type_id: Dictionary = {}
	for entity in inventory_entities:
		if not _should_stack(entity):
			continue
		var c_item := entity.get_component(C_Item) as C_Item
		if not c_item or c_item.type_id == "":
			continue
		if not by_type_id.has(c_item.type_id):
			by_type_id[c_item.type_id] = []
		by_type_id[c_item.type_id].append(entity)

	for type_id in by_type_id:
		var bucket: Array = by_type_id[type_id]
		if bucket.size() <= 1:
			continue
		var total := 0
		for e in bucket:
			total += get_item_quantity(e)
		bucket[0].add_component(C_Quantity.new(total))
		# If a merged-away duplicate was the held item, promote the survivor:
		# query order is not stable in v9, so the active stack may not be first.
		var removed_active := false
		for i in range(1, bucket.size()):
			if bucket[i].has_component(C_IsActiveItem):
				removed_active = true
			ECS.world.remove_entity(bucket[i])
		if removed_active and not bucket[0].has_component(C_IsActiveItem):
			set_active_item(bucket[0], owner)


## Stack size of [param item] (1 when it has no [C_Quantity]).
static func get_item_quantity(item: Entity) -> int:
	if not item:
		return 0
	var c_qty := item.get_component(C_Quantity) as C_Quantity
	return c_qty.value if c_qty else 1


## The use action from [param item]'s [C_Item] template (may be null).
static func get_item_action(item: Entity) -> ItemAction:
	var c_item := item.get_component(C_Item) as C_Item
	assert(c_item, "Entity has no C_Item component")
	return c_item.action


## Finds the stack matching [param c_item]'s [member C_Item.type_id] in
## [param owner]'s inventory, or null.
static func get_item(owner: Entity, c_item: C_Item) -> Entity:
	if not c_item or c_item.type_id == "":
		return null
	var items := ItemQueries.quick_bar_items_of(owner).execute()
	for item in items:
		var item_component := item.get_component(C_Item) as C_Item
		if item_component and item_component.type_id == c_item.type_id:
			return item

	return null


## An entity stacks iff it is an item. The source game also excluded entities
## carrying procedural-roll components; this example has no unique items, so
## the marker check is gone but the extension point is documented here.
static func _should_stack(entity: Entity) -> bool:
	return entity.has_component(C_Item)
