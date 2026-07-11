## Card-flip animation state, stamped by O_CardFace whenever a card's face-up
## state changes. S_FlipCards squashes the sprite's x-scale to zero, swaps the
## texture at the midpoint (the logical C_FaceUp state is already final by
## then, so refresh_face() shows the new side), and un-squashes — a real flip
## instead of an instant texture swap.
class_name C_Flip
extends Component

@export var duration: float = 0.18
@export var elapsed: float = 0.0

## Set once the midpoint texture swap has happened (internal).
var swapped: bool = false
