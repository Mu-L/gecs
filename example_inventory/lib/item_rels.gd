## Pre-allocated [Relationship] singletons for the hot query paths.
##
## [code]Relationship.new(...)[/code] at query time allocates a Relationship AND
## a key component per call; queries that run every frame (systems, input gates)
## turn that into steady garbage. Hoisting the common wildcard-target probes into
## statics is a real-world GECS optimization ported from the source game.
##
## Only wildcard/archetype targets can be hoisted; relationships targeting a
## specific entity instance (see [method ItemQueries.in_inventory_of]) must be
## built per call.
class_name ItemRels

## item OwnedBy [i]anyone[/i] - "is in some inventory".
static var owned_by_any := Relationship.new(C_OwnedBy.new())
## item OwnedBy [i]any Hero[/i] - the target is the [Hero] Script archetype, not
## an instance: it matches items owned by whichever hero entity exists.
static var owned_by_hero := Relationship.new(C_OwnedBy.new(), Hero)
## owner HasActiveItem [i]anything[/i] - "is holding an item".
static var has_active_item_any := Relationship.new(C_HasActiveItem.new())
