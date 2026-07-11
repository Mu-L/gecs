## Per-frame tween state stamped onto a card by O_CardMoved when its C_AtSpot
## relationship changes. S_AnimateCards lerps from→to over `duration` (after
## `delay` elapses), then removes the component. This is the one piece of
## frame-paced state in the whole example — everything else is event-driven.
class_name C_TweenTarget
extends Component

@export var from: Vector2 = Vector2.ZERO
@export var to: Vector2 = Vector2.ZERO
@export var elapsed: float = 0.0
@export var duration: float = 0.35
## Seconds to hold at `from` before the lerp starts. DealSystem staggers the
## 52 deal tweens through this so cards fan out one by one.
@export var delay: float = 0.0
## z_index the sprite lands on when the tween completes (its resting height
## inside the destination pile). While moving, the card is boosted above all
## resting piles so it never slides underneath one.
@export var final_z: int = 0
## Rotation (radians) the card settles at, sampled from the destination
## spot's rotation_jitter so piles look hand-placed rather than machined.
@export var final_rotation: float = 0.0
## Suppress the card-place sound on completion (used for the bulk deal, where
## 52 place sounds would drown the shuffle riff).
@export var quiet: bool = false
