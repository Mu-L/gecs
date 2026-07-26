## A floor pickup: a world entity holding an item template + quantity, waiting
## to be collected. NOT an inventory item - when a [Hero] touches the Area2D,
## the overlap callback tags this entity ([C_PickedUp] + [C_OwnedBy]
## relationship) and [PickupSystem] converts it into a real inventory entity
## next frame. That scene-signal to tag-component bridge is how Godot physics
## events enter the ECS: the callback writes data, a system owns the logic.
@tool
class_name Pickup
extends Entity

## How long (seconds) the Area2D stays deaf after spawning, so a just-dropped
## item is not instantly re-collected by the hero standing next to it.
const PICKUP_GRACE_PERIOD := 0.4

## The item template this pickup grants.
@export var item_resource: C_Item
## How many units the collector receives (coins use this for pile sizes).
@export var quantity: int = 1


## Creates a pickup ready for [method World.add_entity]; the caller sets
## [member Node2D.position]. Uses [code]load[/code] rather than [code]preload[/code]
## because this script IS the scene's root script - preloading would create a
## script/scene load cycle.
static func make_pickup(c_item: C_Item, item_quantity: int) -> Pickup:
	var scene := load("res://example_inventory/entities/e_pickup.tscn") as PackedScene
	var e_pickup := scene.instantiate() as Pickup
	e_pickup.item_resource = c_item
	e_pickup.quantity = item_quantity
	return e_pickup


func _enter_tree() -> void:
	# Live preview of the authored item in the editor viewport.
	if Engine.is_editor_hint():
		_show_visuals()


func on_ready() -> void:
	_show_visuals()
	_start_grace_period()


## Tints the swatch and sets the glyph/quantity labels from the item template -
## the "no external art" stand-in for icons.
func _show_visuals() -> void:
	if not item_resource:
		return
	($Swatch as ColorRect).color = item_resource.color
	($Glyph as Label).text = item_resource.glyph
	($Qty as Label).text = "x%d" % quantity
	($Qty as Label).visible = quantity > 1


func _start_grace_period() -> void:
	var area := $Area2D as Area2D
	area.monitoring = false
	await get_tree().create_timer(PICKUP_GRACE_PERIOD).timeout
	if is_instance_valid(area):
		area.monitoring = true


func _on_area_2d_body_entered(body: Node) -> void:
	# Direct mutation is safe here: physics callbacks run outside system
	# iteration. The tags make this entity match PickupSystem's query next frame.
	if body is Hero and not has_component(C_PickedUp):
		add_component(C_PickedUp.new())
		add_relationship(Relationship.new(C_OwnedBy.new(), body))
