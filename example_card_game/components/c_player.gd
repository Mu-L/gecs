## Identity component for a player (id 0 = human, id 1 = AI).
## Spots reference players via owner_id rather than a relationship —
## relationships are reserved for the high-traffic card↔spot layer.
class_name C_Player
extends Component

@export var id: int = 0
@export var display_name: String = "Player"
