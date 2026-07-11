## Atlas helper — slices the Kenney cardsLarge_tilemap.png into per-card
## AtlasTexture regions.
##
## Tilemap layout (909 × 259 px): 14 columns × 4 rows. Each row is a suit, in
## order Hearts(0), Diamonds(1), Clubs(2), Spades(3). The first 13 columns are
## ranks A..K (Ace=1 in column 0). The 14th column on rows 0/1 is a card back;
## on rows 2/3 it's a Joker — neither is used in WAR.
##
## Cell dimensions are computed from the texture's actual size to avoid hard-
## coding a magic number that would silently break if Kenney republishes the
## atlas at a different scale.
class_name CardAtlas
extends RefCounted

const TEXTURE_PATH := "res://example_card_game/assets/playing-card-pack-kenney/cardsLarge_tilemap.png"

const SUIT_HEARTS := 0
const SUIT_DIAMONDS := 1
const SUIT_CLUBS := 2
const SUIT_SPADES := 3

const COLS := 14
const ROWS := 4
const RANKS_PER_SUIT := 13   # Ace..King; column 13 holds back/joker

const SUIT_NAMES := ["H", "D", "C", "S"]
const RANK_NAMES := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

## Full words for UI messages ("King of Hearts"). Plain ASCII so the default
## Godot font renders them without suit-glyph fallbacks.
const SUIT_WORDS := ["Hearts", "Diamonds", "Clubs", "Spades"]
const RANK_WORDS := [
	"",
	"Ace",
	"Two",
	"Three",
	"Four",
	"Five",
	"Six",
	"Seven",
	"Eight",
	"Nine",
	"Ten",
	"Jack",
	"Queen",
	"King",
]

static var _texture: Texture2D = null


static func _get_texture() -> Texture2D:
	if _texture == null:
		_texture = load(TEXTURE_PATH) as Texture2D
	return _texture


## Returns an AtlasTexture pointing at the (suit, rank) face. rank is 1..13.
static func face_texture(suit: int, rank: int) -> AtlasTexture:
	var tex := _get_texture()
	if tex == null:
		push_error("CardAtlas: failed to load texture at %s" % TEXTURE_PATH)
		return null
	var cw := float(tex.get_width()) / float(COLS)
	var ch := float(tex.get_height()) / float(ROWS)
	var col: int = clamp(rank - 1, 0, RANKS_PER_SUIT - 1)
	var row: int = clamp(suit, 0, ROWS - 1)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(col * cw, row * ch, cw, ch)
	return atlas


## Returns an AtlasTexture pointing at one of the back-of-card cells (column 13,
## row 0). Same back is used for every face-down card.
static func back_texture() -> AtlasTexture:
	var tex := _get_texture()
	if tex == null:
		return null
	var cw := float(tex.get_width()) / float(COLS)
	var ch := float(tex.get_height()) / float(ROWS)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2((COLS - 1) * cw, 0, cw, ch)
	return atlas


## Compare two ranks under WAR rules — Ace high. Returns >0 if a beats b,
## <0 if b beats a, 0 on tie. Aces (rank=1) are treated as 14.
static func compare_rank(a: int, b: int) -> int:
	return _war_value(a) - _war_value(b)


static func _war_value(rank: int) -> int:
	return 14 if rank == 1 else rank


static func format_card(suit: int, rank: int) -> String:
	return "%s%s" % [RANK_NAMES[clamp(rank, 1, 13)], SUIT_NAMES[clamp(suit, 0, 3)]]


## Long form for UI messages — "King of Hearts".
static func describe(suit: int, rank: int) -> String:
	return "%s of %s" % [RANK_WORDS[clamp(rank, 1, 13)], SUIT_WORDS[clamp(suit, 0, 3)]]


## Just the rank word — "Queen" — for the WAR banner ("Both played a Queen").
static func rank_word(rank: int) -> String:
	return RANK_WORDS[clamp(rank, 1, 13)]
