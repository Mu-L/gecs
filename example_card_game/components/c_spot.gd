## A spot is a logical pile/zone where cards live (deck, battlefield, war pot).
## Cards are linked to spots via the C_AtSpot relationship; the spot itself
## just identifies kind + owner + the monotonic order counters used to stamp
## cards that arrive here.
##
## Position is stored here rather than on a Marker2D so spots don't need a
## .tscn; cards read this directly when O_CardMoved schedules a tween.
class_name C_Spot
extends Component

enum Kind { DECK, BATTLEFIELD, WAR_POT }

@export var kind: Kind = Kind.DECK
## -1 = unowned (the war pot). 0 / 1 for the two players.
@export var owner_id: int = -1
## Monotonically increasing. Top of pile = card with the largest C_AtSpot.order
## targeting this spot; bottom = smallest. Never decremented; cards that arrive
## on top consume next_order, then it's incremented.
@export var next_order: int = 0
## Monotonically decreasing mirror of next_order for bottom inserts. Cards
## awarded to the bottom of a deck consume next_bottom_order, then it's
## decremented — each gets a unique order even when many are queued in one
## CommandBuffer flush (a live min() scan would hand them all the same order).
@export var next_bottom_order: int = -1
## World-space position cards tween to when they arrive at this spot.
@export var world_position: Vector2 = Vector2.ZERO
## Offset per stacked card so piles have visible thickness. The war pot
## overrides this in main.tscn to fan sideways so the stakes stay readable.
@export var stack_offset: Vector2 = Vector2(0, -1.0)
## Max random tilt (radians) a card settles at when it lands here. Decks keep
## it small (squared-up piles); battlefields and the war pot go looser so
## played cards look tossed rather than machined.
@export var rotation_jitter: float = 0.02
