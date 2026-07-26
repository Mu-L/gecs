## Tag on floor-pickup entities ([Pickup] scenes). Pickups are world objects
## holding an item template + quantity; they are NOT inventory items. When
## collected, [PickupSystem] destroys the pickup and spawns a proper item entity
## in the collector's inventory.
class_name C_IsPickup
extends Component
