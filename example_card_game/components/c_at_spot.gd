## Relation component used as the relation half of a Relationship(C_AtSpot, spot).
##
## Storing the order *in the relationship* — rather than as a property on the
## card itself — is the key idea this example demonstrates:
##
##   * "Where is this card?" is a single relationship lookup.
##   * "What's on top of this spot?" is one query + a max(order) scan.
##   * Moving a card is one remove_relationship + one add_relationship; no
##     parallel pile-index or array to keep in sync.
##   * Order is never decremented — popping the top doesn't rewrite siblings.
class_name C_AtSpot
extends Component

@export var order: int = 0
