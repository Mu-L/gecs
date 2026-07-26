## Tag on the inventory item currently "in hand". Mirrored by the
## [C_HasActiveItem] relationship on the owner; [method InventoryUtils.set_active_item]
## keeps both in sync and is the only place either should be mutated.
class_name C_IsActiveItem
extends Component
