## Curated audio palette for the card game. Each `static` factory returns a
## fresh C_PlayAudio component pre-loaded with a stream (and a small pitch
## jitter for the variants) — call sites just stamp the result onto an
## entity via `cmd.add_component(entity, AudioLib.card_place())` and let
## O_PlayAudio handle playback.
##
## Centralizing the file paths here keeps systems/observers free of res://
## strings and makes it easy to swap or randomize variants.
class_name AudioLib
extends RefCounted

const _CARD_PLACE := [
	"res://example_card_game/assets/Audio/card-place-1.ogg",
	"res://example_card_game/assets/Audio/card-place-2.ogg",
	"res://example_card_game/assets/Audio/card-place-3.ogg",
	"res://example_card_game/assets/Audio/card-place-4.ogg",
]
const _CARD_FLIP := [
	"res://example_card_game/assets/Audio/card-slide-1.ogg",
	"res://example_card_game/assets/Audio/card-slide-2.ogg",
	"res://example_card_game/assets/Audio/card-slide-3.ogg",
	"res://example_card_game/assets/Audio/card-slide-4.ogg",
]
const _CARD_SHUFFLE := "res://example_card_game/assets/Audio/card-shuffle.ogg"
const _ROUND_WON := [
	"res://example_card_game/assets/Audio/chips-collide-1.ogg",
	"res://example_card_game/assets/Audio/chips-collide-2.ogg",
	"res://example_card_game/assets/Audio/chips-collide-3.ogg",
	"res://example_card_game/assets/Audio/chips-collide-4.ogg",
]
const _ROUND_LOST := [
	"res://example_card_game/assets/Audio/card-shove-1.ogg",
	"res://example_card_game/assets/Audio/card-shove-2.ogg",
]
const _SLAP := [
	"res://example_card_game/assets/Audio/chips-handle-1.ogg",
	"res://example_card_game/assets/Audio/chips-handle-2.ogg",
	"res://example_card_game/assets/Audio/chips-handle-3.ogg",
]
const _GAME_OVER := "res://example_card_game/assets/Audio/question_001.ogg"
const _WAR := "res://example_card_game/assets/Audio/bong_001.ogg"


static func _make(path: String, pitch_jitter: float = 0.0, volume_db: float = -4.0) -> C_PlayAudio:
	var c := C_PlayAudio.new()
	c.stream = load(path) as AudioStream
	c.volume_db = volume_db
	if pitch_jitter > 0.0:
		c.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	return c


static func card_place() -> C_PlayAudio:
	return _make(_CARD_PLACE.pick_random(), 0.05)


static func card_flip() -> C_PlayAudio:
	return _make(_CARD_FLIP.pick_random(), 0.05, -8.0)


static func card_shuffle() -> C_PlayAudio:
	return _make(_CARD_SHUFFLE)


## Chip clatter — YOU (P1) won the round.
static func round_won() -> C_PlayAudio:
	return _make(_ROUND_WON.pick_random(), 0.04, 2.0)


## Dismissive card shove — you lost the round.
static func round_lost() -> C_PlayAudio:
	return _make(_ROUND_LOST.pick_random(), 0.04, -2.0)


## Chip grab — a successful slap on the war pot.
static func slap() -> C_PlayAudio:
	return _make(_SLAP.pick_random(), 0.06, 1.0)


static func war() -> C_PlayAudio:
	return _make(_WAR, 0.0, 0.0)


static func game_over() -> C_PlayAudio:
	return _make(_GAME_OVER, 0.0, 0.0)
