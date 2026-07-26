## Translates cycle/drop key presses into ECS terms for each hero.
## Cycling becomes a [C_CycleItem] request tag; dropping dispatches a
## [DropItemAction] directly (an action needs no .tres authoring to be used).
##
## The cycle tag goes on the active item when one exists, else on the hero
## itself, so cycling can bootstrap from empty hands - [ItemsSystem]'s cycle
## subsystem handles both shapes.
##
## Deliberately absent: the USE key. Use input lives in [ItemsSystem]'s
## input subsystem, where a relationship filter makes empty-handed presses
## match zero entities.
class_name HeroInputSystem
extends System

var _drop_action: ItemAction = DropItemAction.new()


func query() -> QueryBuilder:
	return q.with_all([C_Hero])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var cycle_pressed := Input.is_action_just_pressed("cycle_item")
	var drop_pressed := Input.is_action_just_pressed("drop_item")
	if not cycle_pressed and not drop_pressed:
		return

	for hero in entities:
		var active_item := InventoryUtils.get_active_item(hero)
		if cycle_pressed:
			cmd.add_component(active_item if active_item else hero, C_CycleItem.new())
		if drop_pressed and active_item:
			_drop_action.dispatch([active_item], hero)
