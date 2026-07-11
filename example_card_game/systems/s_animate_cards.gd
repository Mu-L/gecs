## AnimateCardsSystem — the per-frame card-motion system. After an optional
## start delay, moves each card with a C_TweenTarget from `from` → `to` with
## an ease-out-back curve (a little overshoot, Balatro-style snap), scales it
## up mid-flight so it reads as "picked up off the table", and eases its
## rotation toward the pile's jitter angle. On completion the card settles at
## its pile z_index (`final_z`) and, if it actually traveled, stamps a
## card-place sound — unless the tween is marked quiet (bulk deal).
##
## No tick_source — runs every frame. Lives in the "visual" process group so
## it ticks after logic systems, and BEFORE S_FlipCards (which multiplies the
## x-scale this system sets absolutely). Cast on cards is via Sprite2D since
## the Card script is attached to a Sprite2D root.
class_name AnimateCardsSystem
extends System

## Tweens shorter than this (squared px) don't get a place sound — filters
## out reshuffle no-ops where a card is dealt back to the pile it was in.
const MIN_PLAY_AUDIO_DIST_SQ := 16.0
## How much the card grows at the midpoint of its flight.
const FLIGHT_LIFT_SCALE := 0.15
## Ease-out-back overshoot constant (the standard 1.70158).
const BACK_C1 := 1.70158
const BACK_C3 := BACK_C1 + 1.0


func query() -> QueryBuilder:
	return q.with_all([C_Card, C_TweenTarget]).iterate([C_TweenTarget])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var tweens: Array = components[0]
	for i in entities.size():
		var as_node: Node = entities[i]
		var sprite := as_node as Sprite2D
		var t := tweens[i] as C_TweenTarget
		if sprite == null or t == null:
			continue
		t.elapsed += delta
		var progress: float = clamp((t.elapsed - t.delay) / t.duration, 0.0, 1.0)
		var eased := _ease_out_back(progress)
		sprite.global_position = t.from.lerp(t.to, eased)
		# Lift: swell mid-flight, land at rest size (sin peaks at progress 0.5).
		sprite.scale = Vector2.ONE * (1.0 + sin(progress * PI) * FLIGHT_LIFT_SCALE)
		sprite.rotation = lerp_angle(sprite.rotation, t.final_rotation, progress)
		if progress >= 1.0:
			sprite.z_index = t.final_z
			sprite.scale = Vector2.ONE
			sprite.rotation = t.final_rotation
			cmd.remove_component(entities[i], C_TweenTarget)
			var traveled := t.from.distance_squared_to(t.to) >= MIN_PLAY_AUDIO_DIST_SQ
			if traveled and not t.quiet:
				cmd.add_component(entities[i], AudioLib.card_place())


func _ease_out_back(p: float) -> float:
	var u := p - 1.0
	return 1.0 + BACK_C3 * u * u * u + BACK_C1 * u * u
