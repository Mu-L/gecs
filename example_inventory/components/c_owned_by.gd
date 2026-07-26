## Relationship key: [i]item OwnedBy owner[/i]. This IS the inventory.
##
## There is no container component and no slot array anywhere in this example:
## "the hero's inventory" is purely the query
## [code]q.with_relationship([Relationship.new(C_OwnedBy.new(), hero)])[/code]
## (see [method ItemQueries.in_inventory_of]). Adding the relationship puts an
## item in an inventory; removing the entity takes it out.
class_name C_OwnedBy
extends Component
