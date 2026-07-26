## Narrates the demo: every action emits a [code]&"toast"[/code] event with a
## message String, and this observer fades it through a label.
##
## Toasts are broadcast events - emitted with a null entity, which delivers to
## every subscriber of the name regardless of entity filters.
class_name O_Toast
extends Observer

## Path to the label the message fades through (wired in main.tscn).
@export var toast_label_path: NodePath

var toast_label: Label
var _tween: Tween


func setup() -> void:
	toast_label = get_node(toast_label_path) as Label


func sub_observers() -> Array[Array]:
	return [
		[q.on_event(&"toast"), _on_toast],
	]


func _on_toast(_event: Variant, _entity: Entity, message: Variant) -> void:
	toast_label.text = str(message)
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(1.4)
	_tween.tween_property(toast_label, "modulate:a", 0.0, 0.8)
