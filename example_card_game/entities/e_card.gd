## Card entity — one per playing card. The scene root is a Sprite2D (see
## e_card.tscn) so the card renders directly; the script extends Entity so
## the same node participates in ECS queries. `self` is dynamically a
## Sprite2D at runtime, so methods/props from Sprite2D are usable.
##
## All gameplay state (suit, rank, face-up tag, current spot relationship)
## lives on components. The only glue here is `refresh_face` which keeps
## the visible texture in sync with C_FaceUp toggles.
##
## The `Editor Preview` group exists so an authored Card scene can show any
## suit/rank face in the inspector — purely a development aid, ignored at
## runtime where the C_Card component drives the texture.
@tool
class_name Card
extends Entity

@export_group("Editor Preview")
## Suit displayed only inside the editor. 0=Hearts, 1=Diamonds, 2=Clubs, 3=Spades.
@export_enum("Hearts:0", "Diamonds:1", "Clubs:2", "Spades:3")
var preview_suit: int = 3:
	set(value):
		preview_suit = value
		_refresh_editor_preview()

## Rank displayed only inside the editor. 1=Ace, 11=J, 12=Q, 13=K.
@export_range(1, 13) var preview_rank: int = 1:
	set(value):
		preview_rank = value
		_refresh_editor_preview()

## When false, the editor preview shows the card back instead of the face.
@export var preview_face_up: bool = true:
	set(value):
		preview_face_up = value
		_refresh_editor_preview()


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview()
		return
	# Default to back so cards spawned mid-game don't flash their face for a
	# frame before they're flipped face-up.
	refresh_face()


## Apply the visual state implied by C_Card + C_FaceUp. Called from systems
## and observers whenever the face-up state changes. The runtime root node
## is a Sprite2D (see e_card.tscn) — we cast through Node to satisfy static
## analysis, which doesn't see the .tscn-level type.
func refresh_face() -> void:
	var as_node: Node = self
	var sprite := as_node as Sprite2D
	if sprite == null:
		return
	var c := get_component(C_Card) as C_Card
	if c == null:
		sprite.texture = CardAtlas.back_texture()
		return
	if has_component(C_FaceUp):
		sprite.texture = CardAtlas.face_texture(c.suit, c.rank)
	else:
		sprite.texture = CardAtlas.back_texture()


## Editor-only helper — mirrors `refresh_face()` but reads the preview_*
## exports instead of the C_Card component (which doesn't exist until the
## entity is registered with a World). Safe to call before _ready().
func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var as_node: Node = self
	var sprite := as_node as Sprite2D
	if sprite == null:
		return
	if preview_face_up:
		sprite.texture = CardAtlas.face_texture(preview_suit, preview_rank)
	else:
		sprite.texture = CardAtlas.back_texture()
