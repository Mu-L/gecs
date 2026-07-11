## HealthBarsSystem — drives the fighting-game HUD from player C_Health.
##
## Per frame, for each player entity: refresh C_Health.current from the
## relationship layer (card count IS health — recomputing here, between
## flushes, avoids the stale-index reads a mid-flush observer recount would
## see), snap the bar to it, trail a slower "damage ghost" bar behind it
## (the classic fighting-game after-image that shows how big the hit was),
## tint the fill by remaining health, and — while the player carries a
## C_Hit — shake the bar and flash the fill.
##
## The bars/labels are scene UI wired via exports; health itself lives on the
## entities, so this system is pure ECS-to-HUD glue in the visual group.
class_name HealthBarsSystem
extends System

## How fast the damage ghost drains, in health points per second.
const GHOST_DRAIN_PER_SEC := 14.0
const HIT_SHAKE_PX := 5.0
const COLOR_HEALTHY := Color(0.36, 0.75, 0.36)
const COLOR_WOUNDED := Color(0.85, 0.72, 0.25)
const COLOR_CRITICAL := Color(0.85, 0.3, 0.25)
const COLOR_FLASH := Color(1.0, 1.0, 1.0)

@export var p1_bar: ProgressBar
@export var p1_ghost: ProgressBar
@export var p1_label: Label
@export var p2_bar: ProgressBar
@export var p2_ghost: ProgressBar
@export var p2_label: Label

var _base_positions: Dictionary = {}


func query() -> QueryBuilder:
	return q.with_all([C_Player, C_Health])


func setup() -> void:
	for bar in [p1_bar, p2_bar]:
		if bar:
			_base_positions[bar] = bar.position


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var c_player := entity.get_component(C_Player) as C_Player
		var health := entity.get_component(C_Health) as C_Health
		if c_player == null or health == null:
			continue
		var bar := p1_bar if c_player.id == 0 else p2_bar
		var ghost := p1_ghost if c_player.id == 0 else p2_ghost
		var label := p1_label if c_player.id == 0 else p2_label
		if bar == null or ghost == null:
			continue

		health.current = DeckOps.count_owned_by(_world, c_player.id)
		bar.max_value = health.max_health
		ghost.max_value = health.max_health
		bar.value = health.current
		# Ghost: jump up instantly on heals, drain slowly after hits.
		if ghost.value < health.current:
			ghost.value = health.current
		else:
			ghost.value = move_toward(
				ghost.value, health.current, GHOST_DRAIN_PER_SEC * delta
			)
		if label:
			label.text = "%s — %d" % [c_player.display_name, health.current]

		var fill := bar.get("theme_override_styles/fill") as StyleBoxFlat
		if fill:
			fill.bg_color = _health_color(health)

		var hit := entity.get_component(C_Hit) as C_Hit
		var base: Vector2 = _base_positions.get(bar, bar.position)
		if hit:
			hit.elapsed += delta
			if hit.elapsed >= hit.duration:
				bar.position = base
				cmd.remove_component(entity, C_Hit)
			else:
				bar.position = base + Vector2(
					randf_range(-HIT_SHAKE_PX, HIT_SHAKE_PX),
					randf_range(-HIT_SHAKE_PX, HIT_SHAKE_PX)
				)
				if fill and fmod(hit.elapsed, 0.1) < 0.05:
					fill.bg_color = COLOR_FLASH
		else:
			bar.position = base


func _health_color(health: C_Health) -> Color:
	var pct := float(health.current) / float(maxi(health.max_health, 1))
	if pct > 0.5:
		return COLOR_HEALTHY
	if pct > 0.25:
		return COLOR_WOUNDED
	return COLOR_CRITICAL
