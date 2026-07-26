## Relationship key: [i]owner HasActiveItem item[/i]. The inverse view of
## [C_IsActiveItem]: the owner side of "what am I holding?". [ItemsSystem]'s
## input subsystem filters heroes on this relationship, so pressing use with
## empty hands matches zero entities and runs zero code.
class_name C_HasActiveItem
extends Component
