## O_PlayAudio — fulfills C_PlayAudio "play this sound" requests.
##
## When C_PlayAudio is added to any entity, copy the stream / volume / pitch
## / bus settings onto the next AudioStreamPlayer in a small round-robin
## voice pool (created as children of this node at setup) and play it. With
## a pool, the win jingle, the loser tick and a fistful of card-place sounds
## can all ring out together during a pot award instead of clobbering one
## another. Finally, remove C_PlayAudio so the same request can be
## re-stamped to play the sound again.
class_name O_PlayAudio
extends Observer

## How many sounds can overlap before the oldest voice is stolen.
@export var voices: int = 8

var _pool: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func setup() -> void:
	for i in maxi(voices, 1):
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		add_child(voice)
		_pool.append(voice)


func query() -> QueryBuilder:
	return q.with_all([C_PlayAudio]).on_added()


func each(_event: Variant, entity: Entity, payload: Variant = null) -> void:
	var c := payload as C_PlayAudio
	if c == null or c.stream == null or _pool.is_empty():
		cmd.remove_component(entity, C_PlayAudio)
		return
	var voice := _pool[_next_voice]
	_next_voice = (_next_voice + 1) % _pool.size()
	voice.stream = c.stream
	voice.volume_db = c.volume_db
	voice.pitch_scale = c.pitch_scale
	voice.bus = c.bus
	voice.play()
	cmd.remove_component(entity, C_PlayAudio)
