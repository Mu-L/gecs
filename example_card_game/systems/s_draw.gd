## DrawSystem — splits the two-beat draw into two sub_systems, each gated
## by a component-query on C_Phase.state. State transitions are deferred
## through cmd.add_custom so the second sub_query in the same frame still
## sees the old state and doesn't fire prematurely.
##
##   sub 0: state == P1_DRAW → move P1's top card to P1 battlefield, then
##                              schedule state := P2_DRAW (timer re-armed).
##   sub 1: state == P2_DRAW → move P2's top card to P2 battlefield, then
##                              schedule state := AWAIT_RESOLVE (no re-arm —
##                              the next beat waits for the player's click).
##
## Both sub_systems share the step_timer so they can never fire in the same
## frame — the timer ticks once, exactly one sub matches the current state.
class_name DrawSystem
extends System


func setup() -> void:
	var match_e := DeckOps.find_match(_world)
	if match_e:
		var c := match_e.get_component(C_Match) as C_Match
		if c and c.step_timer:
			tick_source = c.step_timer


func sub_systems() -> Array[Array]:
	return [
		[
			q.with_all([C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.P1_DRAW}}}]),
			_draw_for_p1,
		],
		[
			q.with_all([C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.P2_DRAW}}}]),
			_draw_for_p2,
		],
	]


func _draw_for_p1(entities: Array[Entity], _components: Array, _delta: float) -> void:
	_draw_for(entities, 0, C_Phase.State.P2_DRAW, true)


func _draw_for_p2(entities: Array[Entity], _components: Array, _delta: float) -> void:
	# After P2 draws, both cards are revealed on the battlefield. Stop here
	# and wait for the player's next click before resolving — see
	# InputSystem's AWAIT_RESOLVE branch.
	_draw_for(entities, 1, C_Phase.State.AWAIT_RESOLVE, false)


func _draw_for(
	entities: Array[Entity],
	player_id: int,
	next_state: C_Phase.State,
	rearm_timer: bool,
) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	var deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, player_id)
	var battlefield := DeckOps.find_spot(_world, C_Spot.Kind.BATTLEFIELD, player_id)
	if deck == null or battlefield == null:
		return

	# ResolveSystem never returns to IDLE with an empty deck, so the top card
	# always exists here; guarded anyway to keep the example crash-proof.
	var top_card := DeckOps.top_card(_world, deck)
	if top_card != null:
		DeckOps.move_card(top_card, deck, battlefield, cmd)
		cmd.add_component(top_card, C_FaceUp.new())

	# Defer phase transition until after the system flushes — keeps the
	# OTHER sub_query's gate from accidentally matching this same frame.
	cmd.add_custom(func(): c_phase.state = next_state)
	if rearm_timer:
		DeckOps.arm_step(c_match)
