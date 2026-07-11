## PopCardsSystem — fulfills C_Pop scale-punch requests: the card swells by
## `strength` and settles back over `duration` (sin curve — up and down),
## then the component is removed.
##
## Runs last among the card visual systems, so a pop wins the scale for the
## frame if it ever overlaps a flight or flip (rare — pops are stamped on
## stationary, already-revealed cards).
class_name PopCardsSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_Card, C_Pop]).iterate([C_Pop])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var pops: Array = components[0]
	for i in entities.size():
		var as_node: Node = entities[i]
		var sprite := as_node as Sprite2D
		var p := pops[i] as C_Pop
		if sprite == null or p == null:
			continue
		p.elapsed += delta
		var progress: float = clamp(p.elapsed / p.duration, 0.0, 1.0)
		sprite.scale = Vector2.ONE * (1.0 + p.strength * sin(progress * PI))
		if progress >= 1.0:
			sprite.scale = Vector2.ONE
			cmd.remove_component(entities[i], C_Pop)
