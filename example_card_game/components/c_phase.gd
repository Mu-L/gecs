## Phase state of the Match. Single component with an enum, replacing what
## was originally six separate tag components (one per phase).
##
## For one-of-a-kind FSMs like the match controller, this is simpler than
## tag components and equally amenable to query-based gating:
## sub_systems gate on `{C_Phase: {"state": {"_eq": State.X}}}` — any phase
## branch that reads as a tag-like check on the original design becomes a
## property-query check on this design.
##
## Why a setter that emits `property_changed`: O_PhaseTransition and O_Ui use
## property-query monitors (`.on_match()` / `.on_unmatch()`) to detect
## phase entry/exit. Property-query monitors only fire transitions when
## the underlying property setter explicitly emits `property_changed` —
## direct field assignment doesn't trigger observers. See OBSERVERS.md.
class_name C_Phase
extends Component

enum State {
	## Shuffle + (re)deal in progress. DEALING is first so a freshly authored
	## C_Phase (state = 0) boots straight into the initial deal.
	DEALING,
	## Waiting for the player's click to start a round.
	IDLE,
	P1_DRAW,
	P2_DRAW,
	## Cards revealed on the battlefield — waiting for the player's second
	## click to apply the outcome.
	AWAIT_RESOLVE,
	## Compare the battle cards and announce the result (pop + sound + status).
	RESOLVE,
	## One beat after RESOLVE: the pot visibly sweeps to the round winner.
	AWARDING,
	WAR,
	## Match decided. Waiting for a click to re-enter DEALING.
	GAME_OVER,
}

@export var state: State = State.DEALING: set = _set_state


func _set_state(new_value: State) -> void:
	if state == new_value:
		return
	var old_value := state
	state = new_value
	property_changed.emit(self, &"state", old_value, new_value)
