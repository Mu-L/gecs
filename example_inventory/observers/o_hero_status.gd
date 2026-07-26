## Hero status UI: health bar + speed-boost badge, driven entirely by component
## events - no polling, no signals wired in scenes.
##
## The health bar works because [C_HitPoints]' setter emits
## [signal Component.property_changed]; the [code]on_changed[/code] entry here
## would never fire on direct writes that bypass the setter. The
## [code]on_added[/code] entry doubles as the initial sync: scene-tree entities
## register AFTER observers, so their components arrive as ADDED events.
class_name O_HeroStatus
extends Observer

## Path to the health bar (wired in main.tscn).
@export var health_bar_path: NodePath
## Path to the "current / total" text next to the bar.
@export var health_label_path: NodePath
## Path to the badge shown while a [C_SpeedBoost] is active.
@export var boost_label_path: NodePath

var health_bar: ProgressBar
var health_label: Label
var boost_label: Label


func setup() -> void:
	health_bar = get_node(health_bar_path) as ProgressBar
	health_label = get_node(health_label_path) as Label
	boost_label = get_node(boost_label_path) as Label


func sub_observers() -> Array[Array]:
	return [
		# Initial sync: fires when the hero's components register at scene start.
		[q.with_all([C_Hero, C_HitPoints]).on_added(), _on_hp_event],
		# Live updates: fires on every setter write to C_HitPoints.current.
		[q.with_all([C_Hero, C_HitPoints]).on_changed([&"current"]), _on_hp_event],
		# Buff badge: presence/absence of the boost component IS the UI state.
		[q.with_all([C_Hero, C_SpeedBoost]).on_added().on_removed(), _on_boost_event],
	]


func _on_hp_event(_event: Variant, entity: Entity, _payload: Variant) -> void:
	var c_hp := entity.get_component(C_HitPoints) as C_HitPoints
	if not c_hp:
		return
	health_bar.max_value = c_hp.total
	health_bar.value = c_hp.current
	health_label.text = "%d / %d" % [c_hp.current, c_hp.total]


func _on_boost_event(event: Variant, _entity: Entity, _payload: Variant) -> void:
	match event:
		Observer.Event.ADDED:
			boost_label.visible = true
		Observer.Event.REMOVED:
			boost_label.visible = false
