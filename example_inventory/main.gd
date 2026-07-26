## Bootstrap for the inventory example: hands the [World] node to the ECS
## singleton and pumps the system groups.
##
## Group order per render frame: input first so a key press is consumed by item
## logic in the same frame, then gameplay (whose LAST system drains the
## [ActionQueue]). Movement runs from [method Node._physics_process] because
## [method CharacterBody2D.move_and_slide] belongs there.
extends Node2D

@onready var world: World = $World


func _ready() -> void:
	# ActionQueue is static state and survives scene reloads; start clean.
	ActionQueue.clear()
	ECS.world = world


func _process(delta: float) -> void:
	world.process(delta, "input")
	world.process(delta, "gameplay")


func _physics_process(delta: float) -> void:
	world.process(delta, "physics")
