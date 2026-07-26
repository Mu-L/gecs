## Opens doors when their [C_Locked] tag is removed - [code]on_removed[/code] as
## the logic-to-visuals bridge. [UseKeyAction] removes the tag knowing nothing
## about door scenes; this observer maps the data change to
## [method Door.open] and knows nothing about keys.
class_name O_Door
extends Observer


func query() -> QueryBuilder:
	return q.with_all([C_Locked]).on_removed()


func each(_event: Variant, entity: Entity, _payload: Variant = null) -> void:
	if entity is Door:
		(entity as Door).open()
