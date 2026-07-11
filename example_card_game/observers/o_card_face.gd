## O_CardFace — bridges face-up state (C_FaceUp tag) to the visible texture.
## Whenever C_FaceUp is added to or removed from a card, stamp a C_Flip so
## S_FlipCards animates the turn-over (the texture swap happens edge-on at
## the flip midpoint, reading the then-current C_FaceUp state).
##
## This is the C_FaceUp counterpart to O_CardMoved (which handles position).
## Both keep visuals out of the gameplay systems — a system just toggles the
## tag, the observers react.
class_name O_CardFace
extends Observer


func query() -> QueryBuilder:
	# Watch C_FaceUp on cards. ADDED fires when C_FaceUp is stamped on
	# (reveal); REMOVED fires when it's stripped off (winner takes the pot).
	return q.with_all([C_Card, C_FaceUp]).on_added().on_removed()


func each(event: Variant, entity: Entity, _payload: Variant = null) -> void:
	# Restart the flip if one is already in motion (rapid toggles).
	if entity.has_component(C_Flip):
		cmd.remove_component(entity, C_Flip)
	cmd.add_component(entity, C_Flip.new())
	# Flip-up gets a slide sound; flip-down (winner takes the pot) is silent
	# so the win/place sounds aren't drowned out by 4+ flip clicks at once.
	if event == Observer.Event.ADDED:
		cmd.add_component(entity, AudioLib.card_flip())
