## Paints the quick bar. This observer is the whole "autoload signals become
## GECS events" replacement: [InventoryUtils] emits
## [code]&"inventory_changed"[/code] / [code]&"active_item_changed"[/code] and
## nothing in gameplay code knows a UI exists.
##
## Both events trigger a full rebuild from a fresh query rather than diffing the
## payload - inventory sizes here are tiny, and rebuild-from-truth keeps the UI
## trivially correct no matter what sequence of stacks/merges/drops produced the
## event.
class_name O_QuickBar
extends Observer

## Path to the HBoxContainer the slots are built into (wired in main.tscn).
@export var quick_bar_path: NodePath

var quick_bar: HBoxContainer


func setup() -> void:
	quick_bar = get_node(quick_bar_path) as HBoxContainer


func sub_observers() -> Array[Array]:
	return [
		[q.on_event(&"inventory_changed"), _on_inventory_event],
		[q.on_event(&"active_item_changed"), _on_inventory_event],
	]


func _on_inventory_event(_event: Variant, owner_entity: Entity, _payload: Variant) -> void:
	if owner_entity:
		_rebuild(owner_entity)


func _rebuild(owner_entity: Entity) -> void:
	for child in quick_bar.get_children():
		child.queue_free()
	for item in ItemQueries.sorted_quick_bar_items(owner_entity):
		quick_bar.add_child(_build_slot(item))


## One slot: color swatch + glyph + stack count, gold border when active.
func _build_slot(item: Entity) -> Control:
	var c_item := item.get_component(C_Item) as C_Item
	var is_active := item.has_component(C_IsActiveItem)

	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(56, 56)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	style.border_color = Color(1.0, 0.85, 0.3) if is_active else Color(0.35, 0.35, 0.42)
	style.set_border_width_all(3 if is_active else 1)
	style.set_content_margin_all(6)
	slot.add_theme_stylebox_override("panel", style)

	var swatch := ColorRect.new()
	swatch.color = c_item.color
	slot.add_child(swatch)

	var glyph := Label.new()
	glyph.text = c_item.glyph
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override("font_color", Color(0.1, 0.1, 0.14))
	glyph.add_theme_font_size_override("font_size", 22)
	slot.add_child(glyph)

	var quantity := InventoryUtils.get_item_quantity(item)
	if quantity > 1:
		var qty_label := Label.new()
		qty_label.text = "x%d" % quantity
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.14))
		slot.add_child(qty_label)

	return slot
