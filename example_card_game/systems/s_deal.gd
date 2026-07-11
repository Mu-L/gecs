## DealSystem — owns the DEALING phase (the boot deal AND every restart).
##
## setup() creates the shared step_timer and stashes it on the Match entity's
## C_Match so every other phase system can pick it up in their own setup()
## (this system is first under the `logic` SystemGroup, so its setup runs
## before theirs). The timer boots active, so the first tick after launch
## lands in DEALING and performs the initial deal; InputSystem re-enters
## DEALING from GAME_OVER for a rematch.
##
## The deal itself: spawn the 52 cards on first run (reuse them on restarts),
## shuffle, and deal them alternately to the two decks the way a human would.
## All placement goes through cmd, and a final queued custom op staggers the
## resulting tweens so the cards visibly fan out of the shuffle point one by
## one instead of teleporting.
class_name DealSystem
extends System

const CARD_SCENE: PackedScene = preload("res://example_card_game/entities/e_card.tscn")

## Where fresh cards spawn before flying to their deck (table center).
const DEAL_ORIGIN := Vector2(640, 360)
## Seconds between one card starting its deal flight and the next.
const DEAL_STAGGER: float = 0.025


func setup() -> void:
	var match_e := DeckOps.find_match(_world)
	if match_e == null:
		push_error("DealSystem: no Match entity found at setup")
		return
	var c_match := match_e.get_component(C_Match) as C_Match
	c_match.step_timer = SystemTimer.new()
	c_match.step_timer.interval = DeckOps.STEP_SECONDS
	c_match.step_timer.single_shot = true
	# Left active: the Match boots in DEALING, so the first tick deals.
	tick_source = c_match.step_timer


func sub_systems() -> Array[Array]:
	return [
		[
			q.with_all([C_Match, {C_Phase: {"state": {"_eq": C_Phase.State.DEALING}}}]),
			_deal,
		],
	]


func _deal(entities: Array[Entity], _components: Array, _delta: float) -> void:
	if entities.is_empty():
		return
	var match_e := entities[0]
	var c_match := match_e.get_component(C_Match) as C_Match
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_match == null or c_phase == null:
		return

	var p1_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 0)
	var p2_deck := DeckOps.find_spot(_world, C_Spot.Kind.DECK, 1)
	if p1_deck == null or p2_deck == null:
		push_error("DealSystem: could not locate both player decks")
		return

	# First deal spawns the 52 cards at the shuffle point; a rematch reuses
	# them wherever they ended up (they fly back into the decks).
	var cards: Array = []
	var existing := _world.query.with_all([C_Card]).execute()
	if existing.is_empty():
		for suit in 4:
			for rank in range(1, 14):
				cards.append(_make_card(suit, rank))
	else:
		cards.append_array(existing)
	cards.shuffle()

	for i in cards.size():
		var card: Entity = cards[i]
		var deck := p1_deck if i % 2 == 0 else p2_deck
		DeckOps.move_card(card, DeckOps.current_spot(card), deck, cmd)
		if card.has_component(C_FaceUp):
			cmd.remove_component(card, C_FaceUp)

	c_match.war_cards_remaining = 0
	c_match.round_number = 0
	cmd.add_component(match_e, AudioLib.card_shuffle())
	# Runs after every move above has applied and O_CardMoved has stamped the
	# tweens — spread their start times so the deal reads as one card at a
	# time, and silence the 52 individual place sounds (the shuffle covers it).
	cmd.add_custom(func(): _stagger_deal_tweens(cards))
	cmd.add_custom(func(): c_phase.state = C_Phase.State.IDLE)
	# No timer re-arm — IDLE waits for input.


func _make_card(suit: int, rank: int) -> Entity:
	var card: Entity = CARD_SCENE.instantiate()
	card.name = CardAtlas.format_card(suit, rank)
	var c := C_Card.new()
	c.suit = suit
	c.rank = rank
	card.component_resources = [c]
	# Snap to the shuffle point BEFORE registering so the deal tween starts
	# there instead of the card flashing in at (0, 0).
	var as_node: Node = card
	var sprite := as_node as Sprite2D
	if sprite:
		sprite.global_position = DEAL_ORIGIN
	cmd.add_entity(card)
	return card


func _stagger_deal_tweens(cards: Array) -> void:
	for i in cards.size():
		var card: Entity = cards[i]
		var t := card.get_component(C_TweenTarget) as C_TweenTarget
		if t == null:
			continue
		t.delay = DEAL_STAGGER * i
		t.quiet = true
