## Ticks down every [C_SpeedBoost] and removes it at zero - the timed-component
## expiry idiom: the buff is data, expiry is a system, and the UI reacts to the
## removal event ([O_HeroStatus] hides its badge via [code]on_removed[/code]).
##
## Uses the v9 columnar [method QueryBuilder.iterate] API: [param components]
## arrives as one array per requested type, indexed in lockstep with
## [param entities] - no per-entity [method Entity.get_component] lookups.
class_name SpeedBoostSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_SpeedBoost]).iterate([C_SpeedBoost])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var boosts: Array = components[0]
	for i in entities.size():
		var c_boost := boosts[i] as C_SpeedBoost
		c_boost.time_remaining -= delta
		if c_boost.time_remaining <= 0.0:
			cmd.remove_component(entities[i], C_SpeedBoost)
