## Tag set by [Pickup]'s Area2D overlap callback the moment a [Hero] touches it.
## Together with the [C_OwnedBy] relationship added at the same time, it makes the
## pickup match [PickupSystem]'s query on the next frame. This scene-signal to
## tag-component bridge is how Godot physics events enter the ECS.
class_name C_PickedUp
extends Component
