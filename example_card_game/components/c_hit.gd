## "You got hit" marker for a player — S_HealthBars shakes and flashes that
## player's health bar while this is present, then removes it. Stamped on the
## round loser at announce time, and on both players when a WAR breaks out.
class_name C_Hit
extends Component

@export var duration: float = 0.4
@export var elapsed: float = 0.0
