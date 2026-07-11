## O_Ui — the single bridge from ECS state to the fighting-game HUD. Nothing
## else in the example touches UI text; systems emit custom events / flip
## C_Phase.state, and this observer narrates.
##
## Three reactive axes, all declared as sub_observers:
##   * property-query MONITORS on C_Phase.state — phase entry updates the
##     hint line and the center round box.
##   * CUSTOM EVENTS from the gameplay systems (`round_resolved`,
##     `war_started`, `war_step`, `game_over`) — outcome narration on the
##     status line, phrased from the human player's (P1's) perspective.
##
## Card counts / health bars are NOT handled here: S_HealthBars derives them
## from the relationship layer once per frame, between command flushes —
## recounting inside a relationship event would read mid-flush index state.
class_name O_Ui
extends Observer

## Bottom center line — outcomes and banners ("You win the round! +6 cards").
@export var status_label: Label
## Smaller line under it — what the next click (or the game) is about to do.
@export var hint_label: Label
## Fighting-game center box between the health bars ("Round 3", "WAR!", "K.O.").
@export var round_label: Label


func setup() -> void:
	# The Match entity registers before this observer sees any transition at
	# boot, so seed the labels for the initial DEALING phase deterministically.
	_set_status("WAR — the card game")
	_set_hint("Shuffling...")
	_set_round("")


func sub_observers() -> Array[Array]:
	return [
		[
			(
				q
				. with_all(
					[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.DEALING}}}]
				)
				. on_match()
			),
			_on_dealing,
		],
		[
			(
				q
				. with_all(
					[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.IDLE}}}]
				)
				. on_match()
			),
			_on_idle,
		],
		[
			(
				q
				. with_all(
					[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.P1_DRAW}}}]
				)
				. on_match()
			),
			_on_drawing,
		],
		[
			(
				q
				. with_all(
					[
						C_Match,
						{C_Phase: {"state": {"_eq": C_Phase.State.AWAIT_RESOLVE}}},
					]
				)
				. on_match()
			),
			_on_await_resolve,
		],
		[q.on_event(&"round_resolved"), _on_round_resolved],
		[q.on_event(&"war_started"), _on_war_started],
		[q.on_event(&"war_step"), _on_war_step],
		[q.on_event(&"slapped"), _on_slapped],
		[q.on_event(&"game_over"), _on_game_over],
	]


func _on_dealing(_event: Variant, _entity: Entity, _payload: Variant = null) -> void:
	_set_status("Shuffling...")
	_set_hint("")
	_set_round("")


func _on_idle(_event: Variant, entity: Entity, _payload: Variant = null) -> void:
	var c_match := entity.get_component(C_Match) as C_Match
	var next_round: int = c_match.round_number + 1 if c_match else 1
	if next_round == 1:
		_set_status("WAR — the card game")
	_set_round("Round %d" % next_round)
	_set_hint("Click to draw")


func _on_drawing(_event: Variant, _entity: Entity, _payload: Variant = null) -> void:
	# Clear the click prompt so mid-animation clicks don't look actionable.
	_set_hint("")


func _on_await_resolve(
	_event: Variant, _entity: Entity, _payload: Variant = null
) -> void:
	var war_pot := DeckOps.find_spot(_world, C_Spot.Kind.WAR_POT, -1)
	var at_stake := DeckOps.count_at(_world, war_pot) if war_pot else 0
	if at_stake > 0:
		_set_hint("Click to fight — %d cards on the line!" % (at_stake + 2))
	else:
		_set_hint("Click to fight!")


func _on_round_resolved(_event: Variant, _entity: Entity, payload: Variant = null) -> void:
	var data := payload as Dictionary
	if data == null:
		return
	var prize := "the WAR" if data.get("was_war", false) else "the round"
	if data.get("winner_id", -1) == 0:
		_set_status("You win %s! +%d cards" % [prize, data.get("cards_won", 0)])
	else:
		_set_status(
			"You lose %s — %d cards to %s"
			% [prize, data.get("cards_won", 0), data.get("winner_name", "P2")]
		)
	if data.get("was_war", false):
		_set_hint("SLAP THE POT! Click fast to snatch cards!")
	else:
		_set_hint(
			"%s beats %s" % [data.get("winner_desc", "?"), data.get("loser_desc", "?")]
		)


func _on_slapped(_event: Variant, _entity: Entity, payload: Variant = null) -> void:
	var data := payload as Dictionary
	var stolen: int = data.get("stolen", 0) if data else 0
	if stolen > 0:
		_set_hint("SLAP! You snatch %d cards from the CPU!" % stolen)
	else:
		_set_hint("SLAP! ...but there was nothing left to grab")


func _on_war_started(_event: Variant, _entity: Entity, payload: Variant = null) -> void:
	var data := payload as Dictionary
	var rank: String = data.get("rank_word", "?") if data else "?"
	_set_status("WAR! Both played a %s" % rank)
	_set_hint("Each player commits 3 cards face down...")
	_set_round("WAR!")


func _on_war_step(_event: Variant, _entity: Entity, payload: Variant = null) -> void:
	var data := payload as Dictionary
	if data == null:
		return
	_set_hint(
		"Face-down card %d of %d..." % [data.get("step", 0), data.get("total", 3)]
	)


func _on_game_over(_event: Variant, _entity: Entity, payload: Variant = null) -> void:
	var data := payload as Dictionary
	var winner_id: int = data.get("winner_id", -1) if data else -1
	if winner_id == 0:
		_set_status("K.O. — YOU WIN THE MATCH!")
	else:
		var winner: String = data.get("winner_name", "P2") if data else "P2"
		_set_status("K.O. — %s wins the match" % winner)
	_set_hint("Click to play again")
	_set_round("K.O.")


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _set_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text


func _set_round(text: String) -> void:
	if round_label:
		round_label.text = text
