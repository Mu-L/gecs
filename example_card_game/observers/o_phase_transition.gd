## O_PhaseTransition — uses a property-query monitor on C_Phase.state to
## react to GAME_OVER entry. Property-query monitors fire MATCH/UNMATCH when
## the underlying property crosses the threshold via a setter that emits
## `property_changed` — see C_Phase._set_state.
##
## Every path into GAME_OVER (resolve leaving the loser empty, WAR forfeit)
## first awards the table to the winner, so "the player who still owns
## cards" is always the winner here. Broadcasts `&"game_over"` with the
## result — O_Ui narrates it, and anything else can latch on.
class_name O_PhaseTransition
extends Observer


func query() -> QueryBuilder:
	return (
		q
		. with_all(
			[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.GAME_OVER}}}]
		)
		. on_match()
	)


func each(_event: Variant, entity: Entity, _payload: Variant = null) -> void:
	var winner := _winner_id()
	cmd.add_component(entity, AudioLib.game_over())
	cmd.add_component(entity, C_Shake.new())
	var flash := C_Flash.new()
	flash.duration = 0.7
	if winner == 0:
		flash.color = Color(1.0, 0.85, 0.4, 0.4)
		var burst := C_Burst.new()
		burst.position = Vector2(640, 380)
		cmd.add_component(entity, burst)
	else:
		flash.color = Color(0.5, 0.08, 0.08, 0.4)
	cmd.add_component(entity, flash)
	print("[card_game] GAME OVER — winner: %s" % DeckOps.player_name(_world, winner))
	_world.emit_event(
		&"game_over",
		null,
		{
			"winner_id": winner,
			"winner_name": DeckOps.player_name(_world, winner),
		},
	)


func _winner_id() -> int:
	var p1 := DeckOps.count_owned_by(_world, 0)
	var p2 := DeckOps.count_owned_by(_world, 1)
	if p1 == p2:
		return -1
	return 0 if p1 > p2 else 1
