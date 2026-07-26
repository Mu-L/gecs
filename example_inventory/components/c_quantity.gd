## Stack size of an item entity. Every entity built by [method ItemUtils.make_item]
## carries one. [method InventoryUtils.consolidate_inventory] merges same-type
## stacks by summing this value; [method InventoryUtils.remove_inventory_item]
## decrements it and removes the entity at zero.
class_name C_Quantity
extends Component

## How many units this stack holds. The setter emits
## [signal Component.property_changed] so observers using
## [code]on_changed([&"value"])[/code] can react to stack-size changes.
@export var value: int = 1:
	set = _set_value


func _init(quantity: int = 1) -> void:
	value = quantity


func _set_value(new_value: int) -> void:
	var old_value := value
	value = new_value
	property_changed.emit(self, "value", old_value, value)
