## Full-screen flash request — S_Effects pulses the overlay ColorRect with
## `color` (its alpha is the peak intensity) and fades it out over
## `duration`, then removes the component. Red for WAR, gold for victory.
class_name C_Flash
extends Component

@export var color: Color = Color(1.0, 1.0, 1.0, 0.3)
@export var duration: float = 0.45
@export var elapsed: float = 0.0
