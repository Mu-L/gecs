## WarCommitSystem — splits the WAR commit beats into two sub_systems
## using compound component-query gates:
##
##   sub 0: state == WAR  AND  war_cards_remaining > 0
##           → commit one face-down card from each player into the war pot.
##           → decrement counter — DEFERRED via cmd (see below).
##   sub 1: state == WAR  AND  war_cards_remaining == 0
##           → reveal one face-up card from each player onto their
##             battlefield, then transition to AWAIT_RESOLVE.
##
## The decrement MUST be deferred: both sub-queries are evaluated inside one
## _handle() pass and the shared CommandBuffer only flushes after the whole
## system. If sub 0 decremented directly, the 1→0 transition would satisfy
## sub 1's gate in the SAME tick — and because sub 0's moves are still queued,
## top_card() would return the very cards just committed to the pot, queuing
## them into the battlefield too (one card, two C_AtSpot relationships).
## Deferring keeps each beat on its own timer tick.
##
## If a player can't produce the next card mid-WAR they forfeit: the opponent
## is awarded everything on the table and the match ends.
class_name WarCommitSystem
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
			(
				q
				. with_all(
					[
						{C_Phase: {"state": {"_eq": C_Phase.State.WAR}}},
						{C_Match: {"war_cards_remaining": {"_gt": 0}}},
					]
				)
			),
			_commit_face_down,
		],
		[
			(
				q
				. with_all(
					[
						{C_Phase: {"state": {"_eq": C_Phase.State.WAR}}},
						{C_Match: {"war_cards_remaining": {"_eq": 0}}},
					]
				)
			),
			_commit_face_up,
		],
	]


func _commit_face_down(
	entities: Array[Entity], _components: Array, _delta: float
) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	var p1_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 0)
	var p2_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 1)
	var war_pot := DeckOps.find_spot(_world, C_Spot.Kind.WAR_POT, -1)
	if _forfeit_if_bankrupt(c_phase, p1_deck, p2_deck):
		return

	var p1_card := DeckOps.top_card(_world, p1_deck)
	var p2_card := DeckOps.top_card(_world, p2_deck)
	DeckOps.move_card(p1_card, p1_deck, war_pot, cmd)
	DeckOps.move_card(p2_card, p2_deck, war_pot, cmd)

	# Deferred — sub 1's gate must keep seeing the OLD value this tick.
	cmd.add_custom(func(): c_match.war_cards_remaining -= 1)
	var step: int = 4 - c_match.war_cards_remaining
	_world.emit_event(&"war_step", match_e, {"step": step, "total": 3})

	DeckOps.arm_step(c_match)


func _commit_face_up(
	entities: Array[Entity], _components: Array, _delta: float
) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	var p1_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 0)
	var p2_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 1)
	if _forfeit_if_bankrupt(c_phase, p1_deck, p2_deck):
		return

	var p1_bf := DeckOps.find_spot(_world, C_Spot.Kind.BATTLEFIELD, 0)
	var p2_bf := DeckOps.find_spot(_world, C_Spot.Kind.BATTLEFIELD, 1)
	var p1_reveal := DeckOps.top_card(_world, p1_deck)
	var p2_reveal := DeckOps.top_card(_world, p2_deck)
	DeckOps.move_card(p1_reveal, p1_deck, p1_bf, cmd)
	cmd.add_component(p1_reveal, C_FaceUp.new())
	DeckOps.move_card(p2_reveal, p2_deck, p2_bf, cmd)
	cmd.add_component(p2_reveal, C_FaceUp.new())

	# After WAR's reveal, mirror the normal draw flow: stop and wait for the
	# player's click before resolving — see InputSystem's AWAIT_RESOLVE branch.
	cmd.add_custom(func(): c_phase.state = C_Phase.State.AWAIT_RESOLVE)


## When either deck is empty mid-WAR that player can't complete the war and
## forfeits: everything on the table goes to the opponent and the match ends
## (GAME_OVER leaves the loser owning zero cards, which is the invariant
## O_PhaseTransition uses to name the winner). Returns true if it fired.
## If both decks are empty at once, the player with more table presence has
## no claim either way — P1 takes it by convention (classic WAR has no rule).
func _forfeit_if_bankrupt(
	c_phase: C_Phase, p1_deck: Entity, p2_deck: Entity
) -> bool:
	var p1_broke := DeckOps.count_at(_world, p1_deck) == 0
	var p2_broke := DeckOps.count_at(_world, p2_deck) == 0
	if not p1_broke and not p2_broke:
		return false
	var winner_deck := p1_deck if p2_broke else p2_deck
	DeckOps.award_table_to(_world, winner_deck, cmd)
	var loser_player := DeckOps.find_player(_world, 1 if p2_broke else 0)
	if loser_player:
		cmd.add_component(loser_player, C_Hit.new())
	cmd.add_custom(func(): c_phase.state = C_Phase.State.GAME_OVER)
	return true
