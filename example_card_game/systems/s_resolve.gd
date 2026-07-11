## ResolveSystem — two beats, two sub_systems:
##
##   RESOLVE  → compare the top battle cards and ANNOUNCE: pop the winning
##              card, stamp C_Hit on the loser (their health bar shakes),
##              play the win/lose sting, emit `&"round_resolved"` for the UI,
##              then re-arm the timer into AWARDING. Ties instead reset the
##              WAR counter, shake the camera and emit `&"war_started"`.
##   AWARDING → one beat later, sweep everything on the table to the bottom
##              of the winner's deck. If that leaves the loser's deck empty
##              they own nothing, so the match ends right here — no ghost
##              round where an empty deck pretends to draw.
##
## Splitting announce from award is pure feel: the result gets a beat to
## land before the pot visibly flies home.
##
## State transitions are deferred via cmd so property-query monitors fire
## cleanly after the system flushes.
class_name ResolveSystem
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
			q.with_all([C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.RESOLVE}}}]),
			_announce,
		],
		[
			q.with_all([C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.AWARDING}}}]),
			_award,
		],
	]


func _announce(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	var p1_bf := DeckOps.find_spot(_world, C_Spot.Kind.BATTLEFIELD, 0)
	var p2_bf := DeckOps.find_spot(_world, C_Spot.Kind.BATTLEFIELD, 1)
	var p1_top := DeckOps.top_card(_world, p1_bf)
	var p2_top := DeckOps.top_card(_world, p2_bf)
	if p1_top == null or p2_top == null:
		# Defensive — shouldn't happen mid-resolve. Drop back to idle.
		cmd.add_custom(func(): c_phase.state = C_Phase.State.IDLE)
		return

	var p1_c := p1_top.get_component(C_Card) as C_Card
	var p2_c := p2_top.get_component(C_Card) as C_Card
	var cmp := CardAtlas.compare_rank(p1_c.rank, p2_c.rank)

	if cmp == 0:
		# Tie → WAR: red screen flash, camera shake, both fighters brace.
		c_match.war_cards_remaining = 3
		cmd.add_custom(func(): c_phase.state = C_Phase.State.WAR)
		cmd.add_component(match_e, AudioLib.war())
		var shake := C_Shake.new()
		shake.amplitude = 14.0
		shake.duration = 0.5
		cmd.add_component(match_e, shake)
		var flash := C_Flash.new()
		flash.color = Color(0.75, 0.1, 0.1, 0.35)
		cmd.add_component(match_e, flash)
		for player_id in 2:
			var player := DeckOps.find_player(_world, player_id)
			if player:
				cmd.add_component(player, C_Hit.new())
		_world.emit_event(
			&"war_started", match_e, {"rank_word": CardAtlas.rank_word(p1_c.rank)}
		)
		DeckOps.arm_step(c_match)
		return

	var winner_id := 0 if cmp > 0 else 1
	var winner_card := p1_c if cmp > 0 else p2_c
	var loser_card := p2_c if cmp > 0 else p1_c
	c_match.round_winner = winner_id
	c_match.round_number += 1

	# Feedback burst: the winning card pops, the loser takes a visible hit,
	# and ONE outcome sting plays from the human player's perspective.
	cmd.add_component(p1_top if cmp > 0 else p2_top, C_Pop.new())
	var loser_player := DeckOps.find_player(_world, 1 - winner_id)
	if loser_player:
		cmd.add_component(loser_player, C_Hit.new())
	var sting := AudioLib.round_won() if winner_id == 0 else AudioLib.round_lost()
	cmd.add_component(match_e, sting)

	# If this resolve settles a WAR, flip the face-down pot face up so the
	# player sees exactly what was won or lost before the sweep beat.
	var war_pot := DeckOps.find_spot(_world, C_Spot.Kind.WAR_POT, -1)
	var pot_cards := DeckOps.cards_at(_world, war_pot)
	for pot_card: Entity in pot_cards:
		if not pot_card.has_component(C_FaceUp):
			cmd.add_component(pot_card, C_FaceUp.new())

	var at_stake := (
		DeckOps.count_at(_world, p1_bf)
		+ DeckOps.count_at(_world, p2_bf)
		+ pot_cards.size()
	)
	_world.emit_event(
		&"round_resolved",
		match_e,
		{
			"round": c_match.round_number,
			"winner_id": winner_id,
			"winner_name": DeckOps.player_name(_world, winner_id),
			"winner_desc": CardAtlas.describe(winner_card.suit, winner_card.rank),
			"loser_desc": CardAtlas.describe(loser_card.suit, loser_card.rank),
			"cards_won": at_stake,
			"was_war": not pot_cards.is_empty(),
		},
	)

	cmd.add_custom(func(): c_phase.state = C_Phase.State.AWARDING)
	if pot_cards.is_empty():
		DeckOps.arm_step(c_match)
	else:
		# WAR decided: hold the revealed pot on the table long enough to
		# read, and open the slap window for exactly that beat.
		cmd.add_component(match_e, C_SlapWindow.new())
		DeckOps.arm_step(c_match, DeckOps.WAR_LINGER_SECONDS)


func _award(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	# The slap window (if any) closes when the sweep starts.
	if match_e.has_component(C_SlapWindow):
		cmd.remove_component(match_e, C_SlapWindow)

	var winner_id := c_match.round_winner
	c_match.round_winner = -1
	if winner_id < 0:
		cmd.add_custom(func(): c_phase.state = C_Phase.State.IDLE)
		return

	var winner_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, winner_id)
	var cards_won := DeckOps.award_table_to(_world, winner_deck, cmd)
	if cards_won >= 8:
		# Big pot — worth a table rumble.
		var shake := C_Shake.new()
		shake.amplitude = 8.0
		cmd.add_component(match_e, shake)
	if winner_id == 0:
		# Confetti where the spoils land.
		var deck_c := winner_deck.get_component(C_Spot) as C_Spot
		var burst := C_Burst.new()
		burst.position = deck_c.world_position
		cmd.add_component(match_e, burst)

	# The pot moves are still queued, so the loser's live deck count IS their
	# post-award total (their table cards all went to the winner). Empty deck
	# → they own nothing once the buffer flushes → match over.
	var loser_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 1 - winner_id)
	if DeckOps.count_at(_world, loser_deck) == 0:
		cmd.add_custom(func(): c_phase.state = C_Phase.State.GAME_OVER)
	else:
		# IDLE → don't re-arm the timer. Wait for input.
		cmd.add_custom(func(): c_phase.state = C_Phase.State.IDLE)
