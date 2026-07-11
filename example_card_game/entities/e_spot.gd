## Spot entity — invisible logical pile. Position lives on C_Spot, not on the
## node, so we can stay pure-Entity (no Marker2D). Cards bind to spots via
## the C_AtSpot relationship; world coordinates are read off the component.
##
## Authored as `e_spot.tscn`. Each instance in `main.tscn` configures its own
## C_Spot sub-resource (kind / owner_id / world_position) in the inspector.
@tool
class_name Spot
extends Entity
