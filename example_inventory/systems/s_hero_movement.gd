## Moves heroes with WASD/arrows via [method CharacterBody2D.move_and_slide].
## Runs in the [code]physics[/code] group (driven from
## [code]_physics_process[/code]) because body physics belongs there.
##
## A present [C_SpeedBoost] multiplies [C_MoveSpeed]; this system never manages
## the buff's lifetime - [SpeedBoostSystem] owns expiry.
class_name HeroMovementSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_Hero, C_MoveSpeed])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	for entity in entities:
		var body := entity as Node as CharacterBody2D
		var c_speed := entity.get_component(C_MoveSpeed) as C_MoveSpeed
		var c_boost := entity.get_component(C_SpeedBoost) as C_SpeedBoost
		var multiplier := c_boost.multiplier if c_boost else 1.0
		body.velocity = direction * c_speed.speed * multiplier
		body.move_and_slide()
