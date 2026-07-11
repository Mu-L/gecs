## Bootstrap for the WAR card game example.
##
## All static state — the World node, the Match/Player/Spot entities, the
## Systems and Observers, the UI labels — is authored in `main.tscn`. The 52
## cards are spawned dynamically by DealSystem on the first DEALING tick (too
## many to reasonably hand-author in the scene tree) and reused for rematches.
##
## Setup order is driven by scene-tree order:
##   1. `World._ready()` calls `initialize()`, which adds Systems (deferred
##      setup), Observers, then Entities from the tree.
##   2. `Main._ready()` runs after, sets `ECS.world = world`, which triggers
##      `finalize_system_setup()`. Systems set up in scene-tree order:
##      DealSystem is first under the `logic` SystemGroup so its step_timer
##      exists by the time the other phase systems wire their `tick_source`.
##   3. Each frame, process the three groups in order: input → logic → visual.
extends Node

@onready var world: World = $World


func _ready() -> void:
	ECS.world = world


func _process(delta: float) -> void:
	world.process(delta, "input")
	world.process(delta, "logic")
	world.process(delta, "visual")
