## Timed movement buff granted by the speed-boots item. Its presence multiplies
## [C_MoveSpeed] in [HeroMovementSystem]; [SpeedBoostSystem] ticks
## [member time_remaining] down and removes the component at zero, which fires
## [O_HeroStatus]'s [code]on_removed[/code] to hide the UI badge.
##
## This add-tick-remove lifecycle is the standard GECS idiom for timed effects:
## the buff is data, expiry is a system, and the UI reacts to the removal event.
class_name C_SpeedBoost
extends Component

## Movement speed multiplier while active.
@export var multiplier: float = 2.0
## Seconds until the buff expires.
@export var time_remaining: float = 5.0


func _init(_multiplier: float = 2.0, _duration: float = 5.0) -> void:
	multiplier = _multiplier
	time_remaining = _duration
