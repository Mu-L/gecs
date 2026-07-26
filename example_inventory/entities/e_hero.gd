## The player character. All gameplay state lives in components (returned from
## [method define_components]); this script is pure scene glue on a
## CharacterBody2D root so [HeroMovementSystem] can drive
## [method CharacterBody2D.move_and_slide].
##
## Starts wounded (35/100 HP) on purpose: the health-kit item has something to
## heal on first use.
@tool
class_name Hero
extends Entity


func define_components() -> Array:
	return [
		C_Hero.new(),
		C_HitPoints.new(100, 35),
		C_MoveSpeed.new(220.0),
	]
