## Identity component for a playing card.
## Suit is 0..3 (Hearts, Diamonds, Clubs, Spades) — matches the row order of the
## Kenney cardsLarge_tilemap atlas. Rank is 1..13 (Ace=1, J=11, Q=12, K=13).
## In WAR, Ace is high — see CardAtlas.compare_rank if you need that ordering.
class_name C_Card
extends Component

@export var suit: int = 0
@export var rank: int = 1
