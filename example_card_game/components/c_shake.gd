## Camera-shake request. Stamp on any entity (the Match, by convention) and
## S_ShakeCamera rattles the table camera with a decaying random offset, then
## removes the component. Re-stamping while a shake is live replaces it, so
## back-to-back wars just re-kick the shake.
class_name C_Shake
extends Component

## Peak offset in pixels at the start of the shake.
@export var amplitude: float = 10.0
@export var duration: float = 0.4
@export var elapsed: float = 0.0
