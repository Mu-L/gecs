## FlipCardsSystem — animates card flips. While a card carries C_Flip, its
## x-scale squashes to zero and back over the flip duration; at the midpoint
## the texture is refreshed from the (already final) C_FaceUp state, so the
## new side appears exactly when the card is edge-on.
##
## Runs in the "visual" group AFTER S_AnimateCards: that system writes
## scale absolutely each frame, this one multiplies x afterward, so a card
## can fly (lift) and flip at the same time without fighting over the sprite.
class_name FlipCardsSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_Card, C_Flip]).iterate([C_Flip])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var flips: Array = components[0]
	for i in entities.size():
		var as_node: Node = entities[i]
		var sprite := as_node as Sprite2D
		var f := flips[i] as C_Flip
		if sprite == null or f == null:
			continue
		f.elapsed += delta
		var progress: float = clamp(f.elapsed / f.duration, 0.0, 1.0)
		if progress >= 0.5 and not f.swapped:
			f.swapped = true
			if entities[i] is Card:
				(entities[i] as Card).refresh_face()
		# y holds the card's base scale each frame (1.0, or the flight lift
		# S_AnimateCards just wrote) — deriving x from it keeps the squash
		# deterministic instead of compounding frame over frame.
		sprite.scale.x = sprite.scale.y * absf(cos(progress * PI))
		if progress >= 1.0:
			sprite.scale.x = sprite.scale.y
			cmd.remove_component(entities[i], C_Flip)
