## Canned [QueryBuilder] helpers for the inventory domain. Naming the queries
## keeps call sites readable ([code]ItemQueries.in_inventory_of(hero)[/code])
## and gives the relationship-based inventory model a single home.
class_name ItemQueries


## Entities that ARE items (carry a [C_Item]).
static func is_item() -> QueryBuilder:
	return ECS.world.query.with_all([C_Item])


## Items in anyone's inventory (owned by any entity).
static func in_inventory() -> QueryBuilder:
	return ECS.world.query.with_relationship([ItemRels.owned_by_any])


## Items in [param owner]'s inventory. THE inventory query: an instance-targeted
## relationship cannot be pre-allocated in [ItemRels], so it is built per call.
static func in_inventory_of(owner: Entity) -> QueryBuilder:
	return ECS.world.query.with_relationship([Relationship.new(C_OwnedBy.new(), owner)])


## Entities tagged as the currently held item.
static func is_active_item() -> QueryBuilder:
	return ECS.world.query.with_all([C_IsActiveItem])


## Items shown in [param owner]'s quick bar (this example shows every owned item).
static func quick_bar_items_of(owner: Entity) -> QueryBuilder:
	return in_inventory_of(owner).combine(is_item())


## [method quick_bar_items_of] executed and sorted by [member C_Item.type_id].
## The explicit sort matters in v9: [member World.entities] order is NOT stable
## across removals (O(1) swap-remove), so item cycling and the quick bar would
## otherwise reshuffle whenever a stack is consumed.
static func sorted_quick_bar_items(owner: Entity) -> Array:
	var items := quick_bar_items_of(owner).execute()
	items.sort_custom(
		func(a: Entity, b: Entity) -> bool:
			var item_a := a.get_component(C_Item) as C_Item
			var item_b := b.get_component(C_Item) as C_Item
			return item_a.type_id < item_b.type_id
	)
	return items
