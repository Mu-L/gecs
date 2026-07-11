## Stamp this on any entity to play a one-shot sound. O_PlayAudio sees the
## component, spawns an AudioStreamPlayer parented to the World (so the audio
## survives the entity being freed mid-playback), plays the stream, and then
## removes the component.
##
## Conceptually this is the "audio glue" version of C_TweenTarget — the
## entity does not own the player; the component is just a request that the
## reactive observer fulfills.
class_name C_PlayAudio
extends Component

@export var stream: AudioStream
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var bus: StringName = &"Master"
