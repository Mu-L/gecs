## A lockable door. Game state is one tag: [C_Locked] (from
## [method define_components]). [UseKeyAction] removes the tag; [O_Door] reacts
## to the removal by calling [method open], which is scene glue - the observer
## never reaches into this scene's children itself.
@tool
class_name Door
extends Entity


func define_components() -> Array:
	return [C_Locked.new()]


## Visually opens the door and stops it blocking movement. Collision is disabled
## via [code]set_deferred[/code] because the unlock can land during physics.
func open() -> void:
	var tween := create_tween()
	tween.tween_property($Panel, "color", Color(0.35, 0.75, 0.4, 0.35), 0.3)
	($CollisionShape2D as CollisionShape2D).set_deferred("disabled", true)
	($DoorLabel as Label).visible = false
