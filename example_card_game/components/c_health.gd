## Fighting-game health for a player: current == cards owned. Kept in sync by
## O_Ui whenever any card changes spots, and read every frame by
## S_HealthBars. 0 cards = K.O.
class_name C_Health
extends Component

## Bar capacity. Both players start at 26; owning more than max still shows a
## full bar (the number label carries the real count).
@export var max_health: int = 26
@export var current: int = 26
