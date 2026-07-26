## Drains [ActionQueue] once per frame. MUST be the last system in the gameplay
## group so every action dispatched anywhere this frame (input, pickups, item
## requests) executes at one coherent point before rendering.
##
## No [method System.query] override: the base implementation flags
## [member System.process_empty], so this system runs every update with no
## entities - it exists purely for its place in the schedule.
class_name ActionsSystem
extends System


func _init() -> void:
	# Action bodies perform immediate, ordered structural mutations - a later
	# action in the same drain must observe an earlier action's writes, so they
	# cannot be deferred through cmd.
	safe_iteration = true


func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	ActionQueue.drain()
