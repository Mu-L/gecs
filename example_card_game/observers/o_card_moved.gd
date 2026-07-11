## O_CardMoved — bridges logical state (C_AtSpot relationships) to visual
## motion (C_TweenTarget). Whenever a C_AtSpot relation is added to a card,
## stamp a tween from the card's current position to its resting slot in the
## destination pile. S_AnimateCards picks it up next frame.
##
## The resting slot is derived from the card's pile index (how many cards sit
## below it), which drives both the stack offset (piles get visible thickness;
## the war pot fans sideways) and the landing z_index (logical pile order ==
## render order). While the card is in flight it's boosted above every
## resting pile so it never slides underneath one.
##
## This is the only place in the example where logical and visual layers
## meet — there's no per-frame poll-the-spots loop anywhere.
class_name O_CardMoved
extends Observer

## z_index applied while a card is in flight. Far above any resting pile
## (piles top out at pile size), while preserving relative order between
## cards that are mid-flight at the same time.
const FLIGHT_Z_BOOST := 1000


func query() -> QueryBuilder:
	return q.with_all([C_Card]).on_relationship_added([C_AtSpot])


func each(_event: Variant, entity: Entity, payload: Variant = null) -> void:
	var rel := payload as Relationship
	if rel == null:
		return
	var spot := rel.target as Entity
	if spot == null:
		return
	var spot_c := spot.get_component(C_Spot) as C_Spot
	if spot_c == null:
		return
	var sprite := entity as Node as Sprite2D
	if sprite == null:
		return

	var rel_c := rel.relation as C_AtSpot
	var order: int = rel_c.order if rel_c else 0
	var pile_index := DeckOps.pile_index(_world, spot, order)

	var tween := C_TweenTarget.new()
	tween.from = sprite.global_position
	tween.to = spot_c.world_position + spot_c.stack_offset * float(pile_index)
	tween.final_z = 1 + pile_index
	tween.final_rotation = randf_range(-spot_c.rotation_jitter, spot_c.rotation_jitter)
	# Fly above all resting piles, keeping in-flight cards mutually ordered.
	sprite.z_index = FLIGHT_Z_BOOST + tween.final_z
	# If the card already has a tween, replace it (prevents jitter on
	# back-to-back moves like the WAR cascade).
	if entity.has_component(C_TweenTarget):
		cmd.remove_component(entity, C_TweenTarget)
	cmd.add_component(entity, tween)
