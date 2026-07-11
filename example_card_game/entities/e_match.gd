## Match entity — invisible singleton controller. Holds C_Match (with the
## shared step_timer) plus C_Phase (the current phase enum). No visual —
## the script extends Entity directly. Authored as `e_match.tscn` with
## both component_resources pre-wired in the inspector.
@tool
class_name MatchEntity
extends Entity
