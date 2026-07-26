## Template component defining an item type. One [C_Item] .tres resource per item
## kind (see [code]example_inventory/items/[/code]); [method ItemUtils.make_item]
## composes it into a runtime entity together with a [C_Quantity].
##
## The template is deliberately SHARED (not duplicated) across every stack of the
## same type: it is read-only flyweight data, so all coin stacks point at the one
## [code]i_coin.tres[/code]. Anything mutable lives in sibling components.
class_name C_Item
extends Component

@export_group("Item Properties")
## Stacking identity. Stacks with matching [member type_id] merge into one entity.
@export var type_id: String = ""
## Name shown in the quick bar and toast messages.
@export var display_name: String = ""
## Flavor text (unused by the demo logic, shown here as authoring convention).
@export_multiline var description: String = ""
## Placeholder art: tint for pickup/quick-bar swatches (this example uses no textures).
@export var color: Color = Color.WHITE
## Placeholder art: 1-2 character label standing in for an icon.
@export var glyph: String = "?"

@export_group("Composition")
## Extra components attached to every entity spawned from this template.
## Each entry is deep-duplicated per entity so runtime mutation never leaks
## back into the template or sideways into other stacks.
@export var extra_components: Array[Component] = []

@export_group("Item Actions")
## Runs when the item is used from the inventory (E key). Null = unusable (coins).
@export var action: ItemAction
## Runs when a floor pickup of this item is collected. All items in this example
## share one [code]ia_default_pickup.tres[/code] instance.
@export var pickup_action: ItemAction
