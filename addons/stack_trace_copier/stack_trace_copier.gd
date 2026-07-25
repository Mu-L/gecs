@tool
extends EditorPlugin

const BUTTON_TEXT := "Copy Stack"
const BUTTON_TOOLTIP := "Copy the currently selected stack trace to the clipboard.\n\nWorks with:\n  • Stack Trace tab (when paused at a breakpoint)\n  • Errors tab (copies the selected error's full stack trace)"
const RETRY_INTERVAL := 2.0

var _copy_button: Button
var _debugger: Node
var _inject_attempts := 0


func _enter_tree() -> void:
	_copy_button = Button.new()
	_copy_button.text = BUTTON_TEXT
	_copy_button.tooltip_text = BUTTON_TOOLTIP
	_copy_button.flat = true
	_copy_button.focus_mode = Control.FOCUS_NONE
	var theme := EditorInterface.get_editor_theme()
	if theme and theme.has_icon("ActionCopy", "EditorIcons"):
		_copy_button.icon = theme.get_icon("ActionCopy", "EditorIcons")
	_copy_button.pressed.connect(_on_copy_pressed)

	_inject.call_deferred()


func _exit_tree() -> void:
	if is_instance_valid(_copy_button):
		var parent := _copy_button.get_parent()
		if parent:
			parent.remove_child(_copy_button)
		_copy_button.queue_free()
	_copy_button = null
	_debugger = null


func _inject() -> void:
	_inject_attempts += 1
	var base := EditorInterface.get_base_control()
	_debugger = _find_by_class(base, "ScriptEditorDebugger")
	if _debugger == null:
		# Fall back: some engine versions wrap the per-session debugger differently.
		_debugger = _find_by_class(base, "EditorDebuggerNode")
	if _debugger == null:
		if _inject_attempts < 30:
			get_tree().create_timer(RETRY_INTERVAL).timeout.connect(_inject)
		else:
			push_warning("StackTraceCopier: could not locate the script editor debugger; button not added.")
		return

	var toolbar := _find_first_child_of_type(_debugger, "HBoxContainer")
	if toolbar == null:
		toolbar = _debugger
	toolbar.add_child(_copy_button)


func _on_copy_pressed() -> void:
	if not is_instance_valid(_debugger):
		_notify("Debugger not available.")
		return

	var text := _build_stack_trace_text()
	if text.is_empty():
		_notify("No stack trace selected.")
		return

	DisplayServer.clipboard_set(text)
	_notify("Stack trace copied to clipboard.")


func _build_stack_trace_text() -> String:
	var trees: Array[Tree] = []
	_collect_trees(_debugger, trees)

	var best_text := ""
	var best_score := -1

	for tree in trees:
		var selected: TreeItem = tree.get_selected()
		if selected == null:
			continue
		var extracted := _extract_trace_from_item(tree, selected)
		if extracted.is_empty():
			continue
		var score := extracted.count("\n")
		if score > best_score:
			best_score = score
			best_text = extracted

	return best_text


func _extract_trace_from_item(tree: Tree, item: TreeItem) -> String:
	var tree_root := tree.get_root()

	var top := item
	while top.get_parent() != null and top.get_parent() != tree_root:
		top = top.get_parent()

	var lines := PackedStringArray()
	var top_line := _item_to_line(top, tree.columns)
	if not top_line.is_empty():
		lines.append(top_line)

	var child := top.get_first_child()
	while child != null:
		var line := _item_to_line(child, tree.columns)
		if not line.is_empty():
			lines.append("  " + line)
		child = child.get_next()

	if lines.size() <= 1 and top.get_parent() == tree_root:
		return top_line

	return "\n".join(lines)


func _item_to_line(item: TreeItem, column_count: int) -> String:
	var parts := PackedStringArray()
	for c in column_count:
		var t := item.get_text(c).strip_edges()
		if t.is_empty():
			continue
		parts.append(t)
	return " ".join(parts)


func _collect_trees(node: Node, out: Array[Tree]) -> void:
	if node is Tree:
		out.append(node)
	for child in node.get_children():
		_collect_trees(child, out)


func _find_by_class(node: Node, class_str: String) -> Node:
	if node.get_class() == class_str:
		return node
	for child in node.get_children():
		var r := _find_by_class(child, class_str)
		if r:
			return r
	return null


func _find_first_child_of_type(node: Node, class_str: String) -> Node:
	for child in node.get_children():
		if child.get_class() == class_str:
			return child
	for child in node.get_children():
		var r := _find_first_child_of_type(child, class_str)
		if r:
			return r
	return null


func _notify(msg: String, severity: int = EditorToaster.SEVERITY_INFO) -> void:
	var toaster := EditorInterface.get_editor_toaster()
	if toaster:
		toaster.push_toast("StackTraceCopier: " + msg, severity, "")
	else:
		print("StackTraceCopier: ", msg)
