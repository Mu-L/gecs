## Base movement speed for [HeroMovementSystem], in pixels per second.
## Kept separate from [C_Hero] so buffs ([C_SpeedBoost]) multiply a stat
## component instead of poking at identity.
class_name C_MoveSpeed
extends Component

## Movement speed in pixels per second.
@export var speed: float = 220.0


func _init(_speed: float = 220.0) -> void:
	speed = _speed
