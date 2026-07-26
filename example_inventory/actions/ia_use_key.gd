## Non-consumable demo: unlocks the nearest [C_Locked] door within range and
## stays in the inventory. The action's entire effect on the world is removing
## one tag component; [O_Door] owns the visual/collision reaction via
## [code]on_removed[/code]. Keys and doors never reference each other.
class_name UseKeyAction
extends ItemAction

## Maximum distance (pixels) between the user and a door for the key to work.
const UNLOCK_RANGE := 96.0


func _init() -> void:
	meta = {
		"name": "Use key",
		"description": "Unlocks the nearest locked door in range; not consumed.",
	}


func _execute_item(_item: Entity, user: Entity) -> void:
	var user_position := (user as Node as Node2D).global_position
	var nearest: Entity = null
	var nearest_distance := UNLOCK_RANGE
	for door in ECS.world.query.with_all([C_Locked]).execute():
		var distance := user_position.distance_to((door as Node as Node2D).global_position)
		if distance <= nearest_distance:
			nearest = door
			nearest_distance = distance

	if nearest == null:
		ECS.world.emit_event(&"toast", null, "The key doesn't reach any door from here")
		return

	nearest.remove_component(C_Locked)
	ECS.world.emit_event(&"toast", null, "Door unlocked!")
