## EffectsSystem — fulfills the two screen-effect request components:
##
##   * C_Flash — pulse the full-screen overlay ColorRect with the request's
##     color, fading its alpha to zero over the duration.
##   * C_Burst — teleport the shared one-shot confetti GPUParticles2D to the
##     requested position and restart it (consumed the same frame).
##
## Runs in the "visual" group. Overlay and particles are scene-wired exports.
class_name EffectsSystem
extends System

## Full-screen overlay pulsed by C_Flash requests. Wire in the inspector.
@export var flash_rect: ColorRect
## One-shot confetti emitter moved + restarted per C_Burst. Wire in the inspector.
@export var burst_particles: GPUParticles2D


func sub_systems() -> Array[Array]:
	return [
		[q.with_all([C_Flash]).iterate([C_Flash]), _process_flashes],
		[q.with_all([C_Burst]).iterate([C_Burst]), _process_bursts],
	]


func _process_flashes(entities: Array[Entity], components: Array, delta: float) -> void:
	if flash_rect == null:
		return
	var flashes: Array = components[0]
	for i in entities.size():
		var f := flashes[i] as C_Flash
		if f == null:
			continue
		f.elapsed += delta
		var fade: float = clamp(1.0 - f.elapsed / f.duration, 0.0, 1.0)
		flash_rect.color = Color(f.color.r, f.color.g, f.color.b, f.color.a * fade)
		if fade <= 0.0:
			cmd.remove_component(entities[i], C_Flash)


func _process_bursts(entities: Array[Entity], components: Array, _delta: float) -> void:
	var bursts: Array = components[0]
	for i in entities.size():
		var b := bursts[i] as C_Burst
		if b == null:
			continue
		if burst_particles:
			burst_particles.global_position = b.position
			burst_particles.restart()
		cmd.remove_component(entities[i], C_Burst)
