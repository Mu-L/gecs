## ShakeCameraSystem — fulfills C_Shake requests with a decaying random
## offset on the table camera. Stamped by ResolveSystem when a WAR breaks
## out and by O_PhaseTransition at game over.
##
## Runs in the "visual" group. The camera is scene-wired in main.tscn.
class_name ShakeCameraSystem
extends System

## The camera to rattle. Wire in the inspector.
@export var camera: Camera2D


func query() -> QueryBuilder:
	return q.with_all([C_Shake]).iterate([C_Shake])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	if camera == null:
		return
	var shakes: Array = components[0]
	for i in entities.size():
		var s := shakes[i] as C_Shake
		if s == null:
			continue
		s.elapsed += delta
		var decay: float = clamp(1.0 - s.elapsed / s.duration, 0.0, 1.0)
		if decay <= 0.0:
			camera.offset = Vector2.ZERO
			cmd.remove_component(entities[i], C_Shake)
			continue
		var strength := s.amplitude * decay * decay
		camera.offset = Vector2(
			randf_range(-strength, strength), randf_range(-strength, strength)
		)
