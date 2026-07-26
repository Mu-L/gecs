## Hero health, consumed by the health-kit action and displayed by [O_HeroStatus].
##
## The [member current] setter emits [signal Component.property_changed], which is
## what lets an observer query like
## [code]q.with_all([C_Hero, C_HitPoints]).on_changed([&"current"])[/code] drive
## the health bar with no polling. Direct property writes that skip the setter
## would be invisible to observers; this is intentional GECS behavior.
class_name C_HitPoints
extends Component

## Maximum hit points.
@export var total: int = 100
## Current hit points, clamped to [code][0, total][/code] by the setter.
@export var current: int = 100:
	set = _set_current


func _init(_total: int = 100, _current: int = 100) -> void:
	total = _total
	current = _current


func _set_current(new_value: int) -> void:
	var old_value := current
	current = clampi(new_value, 0, total)
	property_changed.emit(self, "current", old_value, current)
