## InputSystem — runs every frame, four click-paced sub-systems gated
## entirely by component-queries:
##
##   * IDLE          → "advance" pressed → P1_DRAW (timer arms; cards animate
##                                          out P1 → P2 automatically).
##   * AWAIT_RESOLVE → "advance" pressed → RESOLVE (timer arms; ResolveSystem
##                                          fires once and awards the pot).
##   * GAME_OVER     → "advance" pressed → DEALING (timer arms; DealSystem
##                                          reshuffles for a rematch).
##   * C_SlapWindow present → "advance" pressed → SLAP! Snatch cards off the
##     CPU's deck. The window exists only during the war-resolve linger beat,
##     when no state gate matches, so the click is unambiguous.
##
## The click cadence: click to play, click to apply the outcome, click to
## rematch. Mid-step presses are dropped because no sub_query matches the
## in-flight phase — no imperative `if phase == X` gate inside the body.
class_name InputSystem
extends System

## Cards snatched from the CPU's deck by a successful slap.
const SLAP_STEAL_COUNT := 2


func sub_systems() -> Array[Array]:
	return [
		[q.with_all([C_Match, C_SlapWindow]), _on_slap],
		[
			(
				q
				. with_all(
					[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.IDLE}}}]
				)
			),
			_on_idle,
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
			),
			_on_await_resolve,
		],
		[
			(
				q
				. with_all(
					[C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.GAME_OVER}}}]
				)
			),
			_on_game_over,
		],
	]


func _on_idle(entities: Array[Entity], _components: Array, _delta: float) -> void:
	_advance_to(entities, C_Phase.State.P1_DRAW)


func _on_await_resolve(
	entities: Array[Entity], _components: Array, _delta: float
) -> void:
	_advance_to(entities, C_Phase.State.RESOLVE)


func _on_game_over(
	entities: Array[Entity], _components: Array, _delta: float
) -> void:
	_advance_to(entities, C_Phase.State.DEALING)


## Real-life WAR: everyone slaps the pile. A click while the slap window is
## open snatches the top cards of the CPU's deck to the bottom of yours.
func _on_slap(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if entities.is_empty():
		return
	if not Input.is_action_just_pressed("advance"):
		return
	var match_e := entities[0]
	cmd.remove_component(match_e, C_SlapWindow)

	var your_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 0)
	var cpu_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 1)
	var cpu_pile := DeckOps.cards_at(_world, cpu_deck)
	var stolen: int = mini(SLAP_STEAL_COUNT, cpu_pile.size())
	# Top of the pile is the END of cards_at; take distinct cards (successive
	# top_card calls would return the same card while the moves are queued).
	for i in stolen:
		var card: Entity = cpu_pile[cpu_pile.size() - 1 - i]
		DeckOps.move_card_to_bottom(card, cpu_deck, your_deck, cmd)

	cmd.add_component(match_e, AudioLib.slap())
	if stolen > 0 and cpu_deck:
		var spot_c := cpu_deck.get_component(C_Spot) as C_Spot
		var burst := C_Burst.new()
		burst.position = spot_c.world_position
		cmd.add_component(match_e, burst)
	_world.emit_event(&"slapped", match_e, {"stolen": stolen})


func _advance_to(entities: Array[Entity], next_state: C_Phase.State) -> void:
	if entities.is_empty():
		return
	if not Input.is_action_just_pressed("advance"):
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_match.step_timer == null or c_phase == null:
		return
	# Defer the state mutation so any observer cascade and any same-frame
	# sub_systems gating see the OLD state until the system completes.
	cmd.add_custom(func(): c_phase.state = next_state)
	DeckOps.arm_step(c_match)
