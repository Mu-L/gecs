## The item core loop as three sub-systems: honor use requests, honor cycle
## requests, and turn use-key input into requests.
##
## Note the intentional one-frame latency: the input subsystem (tuple 3) adds
## [C_RequestUseItem] via [code]cmd[/code] AFTER tuple 1 already ran this frame,
## so the request is honored next frame. Requests-as-components make that
## pipeline visible and debuggable (the tag is inspectable in the GECS debugger).
class_name ItemsSystem
extends System


func sub_systems() -> Array[Array]:
	return [
		# 1. Honor use requests on items, wherever they came from.
		[q.with_all([C_Item, C_RequestUseItem]), request_use_item_subsystem],
		# 2. Honor cycle requests (on an item OR on an empty-handed hero).
		[q.with_all([C_CycleItem]), cycle_item_subsystem],
		# 3. Use-key input. The relationship filter IS the input gate: pressing
		#    use with empty hands matches zero entities and runs zero code.
		[
			q.with_all([C_Hero]).with_relationship([ItemRels.has_active_item_any]),
			item_usage_subsystem,
		],
	]


func request_use_item_subsystem(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		# Always consume the request, even when it can't be honored - a stuck
		# request tag would re-match this subsystem every frame.
		cmd.remove_component(entity, C_RequestUseItem)
		var rel := entity.get_relationship(ItemRels.owned_by_any)
		if not rel or not rel.target:
			continue
		InventoryUtils.use_inventory_item(entity, rel.target)


func cycle_item_subsystem(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		if entity.has_component(C_Item):
			_cycle_from_current_item(entity)
		else:
			_cycle_from_entity(entity)
		cmd.remove_component(entity, C_CycleItem)


func item_usage_subsystem(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if not Input.is_action_just_pressed("use_item"):
		return
	for entity in entities:
		var rel := entity.get_relationship(ItemRels.has_active_item_any)
		if rel and rel.target:
			cmd.add_component(rel.target, C_RequestUseItem.new())


## Cycle starting from the active item's position in the sorted quick bar.
## The +1 in the modulo arithmetic inserts an "empty hands" slot after the last
## item, so cycling goes A -> B -> C -> nothing -> A.
func _cycle_from_current_item(item_entity: Entity) -> void:
	var rel := item_entity.get_relationship(ItemRels.owned_by_any)
	if not rel or not rel.target:
		return
	var item_owner: Entity = rel.target
	var items := ItemQueries.sorted_quick_bar_items(item_owner)
	var index := items.find(item_entity)
	if index == -1:
		return
	var next_index := (index + 1) % (items.size() + 1)
	var next_item: Entity = null if next_index == items.size() else items[next_index]
	# Queued: set_active_item mutates relationships mid-iteration otherwise.
	cmd.add_custom(InventoryUtils.set_active_item.bind(next_item, item_owner))


## Cycle requested by an owner with nothing active: select the first item.
func _cycle_from_entity(entity: Entity) -> void:
	var items := ItemQueries.sorted_quick_bar_items(entity)
	if items.is_empty():
		cmd.add_custom(InventoryUtils.set_active_item.bind(null, entity))
		return
	var current_active := InventoryUtils.get_active_item(entity)
	if current_active == null:
		cmd.add_custom(InventoryUtils.set_active_item.bind(items[0], entity))
		return
	var index := items.find(current_active)
	if index == -1:
		cmd.add_custom(InventoryUtils.set_active_item.bind(items[0], entity))
		return
	var next_index := (index + 1) % (items.size() + 1)
	var next_item: Entity = null if next_index == items.size() else items[next_index]
	cmd.add_custom(InventoryUtils.set_active_item.bind(next_item, entity))
