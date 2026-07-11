## Scale-punch request — stamp on a card and S_PopCards swells it up and back
## over `duration`, then removes the component. Used to celebrate the winning
## battle card the moment the round result is announced.
class_name C_Pop
extends Component

## How much the card swells at the peak (0.35 = +35%).
@export var strength: float = 0.35
@export var duration: float = 0.3
@export var elapsed: float = 0.0
