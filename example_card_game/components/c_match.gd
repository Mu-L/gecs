## State carried by the single Match controller entity.
##
## Holds the shared step_timer that all phase systems use as their tick_source,
## plus per-WAR scratch state. Phase identity lives on the sibling C_Phase
## component (single component, enum-valued) — sub_systems gate via
## component-query, e.g. `{C_Phase: {"state": {"_eq": C_Phase.State.WAR}}}`.
class_name C_Match
extends Component

## Shared SystemTimer driving the round's internal beats. Created by S_Deal at
## init time; null until then. RefCounted, so safe to hold here and on each
## phase system's tick_source.
var step_timer: SystemTimer = null

## Set when entering C_Phase.State.WAR. Decremented (deferred via cmd, so the
## reveal sub-system never fires in the same tick as the final face-down
## commit) as each WAR commit lands. When it reaches 0 the next tick is the
## face-up reveal. Read via the component-query gates in WarCommitSystem
## (`{C_Match: {"war_cards_remaining": {"_gt": 0}}}`).
@export var war_cards_remaining: int = 0

## Completed battles this match (wars extend a round, they don't start one).
## Incremented by ResolveSystem when it announces a result; reset by DealSystem.
@export var round_number: int = 0

## Winner of the round just announced, carried from the RESOLVE beat to the
## AWARDING beat (the pot sweep happens one beat after the announcement so
## the result has a moment to land). -1 outside that window.
@export var round_winner: int = -1
