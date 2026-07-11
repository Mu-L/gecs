## Editor utility — lays out the entire 52-card deck plus the back as Sprite2D
## children of this node so you can visually verify the Kenney atlas slicing
## (see CardAtlas). Open `card_atlas_preview.tscn` in the editor and the grid
## populates automatically; toggle `rebuild` in the inspector to regenerate
## after editing the atlas helper.
##
## Each row is one suit (Hearts / Diamonds / Clubs / Spades), each column is
## one rank (Ace .. King). The card back sits to the right of row 1 (Diamonds)
## for a quick face-vs-back comparison.
##
## Children are rebuilt on every load and never owned by the scene, so they
## are not serialized — the .tscn stays a single Node2D root.
@tool
extends Node2D

const CELL_W := 68.0
const CELL_H := 88.0
const COLS := 13
const ROWS := 4


@export_tool_button("Rebuild") var _rebuild_button: Callable = _rebuild


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for suit in ROWS:
		for rank_idx in COLS:
			var rank := rank_idx + 1
			var s := Sprite2D.new()
			s.texture = CardAtlas.face_texture(suit, rank)
			s.position = Vector2(rank_idx * CELL_W, suit * CELL_H)
			s.name = CardAtlas.format_card(suit, rank)
			add_child(s)
	var back := Sprite2D.new()
	back.texture = CardAtlas.back_texture()
	back.position = Vector2(COLS * CELL_W + CELL_W * 0.5, 1.5 * CELL_H)
	back.name = "Back"
	add_child(back)
