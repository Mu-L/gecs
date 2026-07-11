## Shared helpers for the WAR systems and observers — finding the singleton
## entities, peeking piles, and moving cards between spots while keeping the
## C_AtSpot order counters monotonic.
##
## All mutations go through the caller's CommandBuffer so iteration in the
## caller stays safe. Order counters on C_Spot are consumed at QUEUE time
## (not at flush time) so every queued card gets a unique order even when a
## whole pot is awarded in one flush.
class_name DeckOps
extends RefCounted

## Sentinel returned by order_at for cards not present at the queried spot.
## Far below any real order (bottom-insert orders only reach -pile_size).
const ORDER_NONE := -0x7fff_ffff_ffff_ffff

## Default beat length for the shared step timer.
const STEP_SECONDS := 0.35
## Longer beat after a WAR is decided, so the revealed pot (and the slap
## window) stays on screen long enough to read.
const WAR_LINGER_SECONDS := 2.0


## Re-arm the shared step timer for one beat of [param seconds]. reset() also
## clears `ticked`, so systems later in the same group can't fire this frame.
static func arm_step(c_match: C_Match, seconds: float = STEP_SECONDS) -> void:
	if c_match.step_timer:
		c_match.step_timer.interval = seconds
		c_match.step_timer.reset()


## The singleton Match entity, or null before the world is populated.
static func find_match(world: World) -> Entity:
	var arr := world.query.with_all([C_Match]).execute()
	return arr[0] if not arr.is_empty() else null


## The player entity with C_Player.id == player_id, or null.
static func find_player(world: World, player_id: int) -> Entity:
	var arr := (
		world
		. query
		. with_all([{C_Player: {"id": {"_eq": player_id}}}])
		. execute()
	)
	return arr[0] if not arr.is_empty() else null


## Display name for a player id ("P1"/"P2" as authored in main.tscn).
static func player_name(world: World, player_id: int) -> String:
	var player := find_player(world, player_id)
	if player == null:
		return "P%d" % (player_id + 1)
	var c := player.get_component(C_Player) as C_Player
	return c.display_name if c else "P%d" % (player_id + 1)


## Find the spot of a given kind and owner_id. Returns null if not found.
static func find_spot(world: World, kind: int, owner_id: int) -> Entity:
	var arr := (
		world
		. query
		. with_all(
			[{C_Spot: {"kind": {"_eq": kind}, "owner_id": {"_eq": owner_id}}}]
		)
		. execute()
	)
	return arr[0] if not arr.is_empty() else null


## The spot `card` currently sits at (its C_AtSpot relationship target), or
## null for a card that hasn't been placed yet.
static func current_spot(card: Entity) -> Entity:
	var rel := card.get_relationship(Relationship.new(C_AtSpot.new(), null))
	if rel == null:
		return null
	return rel.target as Entity


## All cards currently at `spot`, sorted bottom→top by C_AtSpot.order.
static func cards_at(world: World, spot: Entity) -> Array:
	var arr := (
		world
		. query
		. with_relationship([Relationship.new(C_AtSpot.new(), spot)])
		. execute()
	)
	# arr is Array[Entity]; sort_custom needs a generic Array, so copy over.
	var result: Array = []
	for c in arr:
		result.append(c)
	result.sort_custom(
		func(a: Entity, b: Entity) -> bool:
			return order_at(a, spot) < order_at(b, spot)
	)
	return result


## The card with the largest C_AtSpot.order at `spot`, or null if empty.
static func top_card(world: World, spot: Entity) -> Entity:
	var arr := (
		world
		. query
		. with_relationship([Relationship.new(C_AtSpot.new(), spot)])
		. execute()
	)
	var best: Entity = null
	var best_order: int = ORDER_NONE
	for e in arr:
		var o := order_at(e, spot)
		if o > best_order:
			best_order = o
			best = e
	return best


## How many cards are at this spot. Cheaper than cards_at when only the count
## is needed.
static func count_at(world: World, spot: Entity) -> int:
	return (
		world
		. query
		. with_relationship([Relationship.new(C_AtSpot.new(), spot)])
		. execute()
		. size()
	)


## Cards a player owns = cards at any spot they own (deck + battlefield).
static func count_owned_by(world: World, player_id: int) -> int:
	var n := 0
	var spots := world.query.with_all([C_Spot]).execute()
	for s in spots:
		var sc := s.get_component(C_Spot) as C_Spot
		if sc and sc.owner_id == player_id:
			n += count_at(world, s)
	return n


## This card's C_AtSpot.order at `spot`, or a very small number if it isn't
## there (so it never wins a top_card scan).
static func order_at(card: Entity, spot: Entity) -> int:
	var rel := card.get_relationship(Relationship.new(C_AtSpot.new(), spot))
	if rel == null or rel.relation == null:
		return ORDER_NONE
	return (rel.relation as C_AtSpot).order


## How many cards currently at `spot` sit BELOW the given order. Used by
## O_CardMoved to derive a card's resting height (visual offset + z_index)
## inside its pile.
static func pile_index(world: World, spot: Entity, order: int) -> int:
	var arr := (
		world
		. query
		. with_relationship([Relationship.new(C_AtSpot.new(), spot)])
		. execute()
	)
	var below := 0
	for e in arr:
		if order_at(e, spot) < order:
			below += 1
	return below


## Move `card` onto the TOP of `to_spot`, consuming the destination's
## next_order counter. Pass null for `from_spot` when the card has never been
## placed (initial deal).
static func move_card(
	card: Entity, from_spot: Entity, to_spot: Entity, cmd: CommandBuffer
) -> void:
	if from_spot != null:
		cmd.remove_relationship(card, Relationship.new(C_AtSpot.new(), from_spot), 1)
	var to_c := to_spot.get_component(C_Spot) as C_Spot
	var rel_c := C_AtSpot.new()
	rel_c.order = to_c.next_order
	to_c.next_order += 1
	cmd.add_relationship(card, Relationship.new(rel_c, to_spot))


## Place `card` at the BOTTOM of `to_spot`, consuming the destination's
## next_bottom_order counter. Used when awarding pots: the winner takes the
## cards but they go to the bottom of their deck so they cycle through.
static func move_card_to_bottom(
	card: Entity, from_spot: Entity, to_spot: Entity, cmd: CommandBuffer
) -> void:
	if from_spot != null:
		cmd.remove_relationship(card, Relationship.new(C_AtSpot.new(), from_spot), 1)
	var to_c := to_spot.get_component(C_Spot) as C_Spot
	var rel_c := C_AtSpot.new()
	rel_c.order = to_c.next_bottom_order
	to_c.next_bottom_order -= 1
	cmd.add_relationship(card, Relationship.new(rel_c, to_spot))


## Award every card on the table (both battlefields + the war pot) to the
## bottom of `winner_deck`, flipping them face down. Returns how many cards
## were awarded. Shared by the normal RESOLVE payout and the "can't complete
## the war" forfeit so both paths leave the table clean.
static func award_table_to(
	world: World, winner_deck: Entity, cmd: CommandBuffer
) -> int:
	var table_spots := [
		find_spot(world, C_Spot.Kind.BATTLEFIELD, 0),
		find_spot(world, C_Spot.Kind.BATTLEFIELD, 1),
		find_spot(world, C_Spot.Kind.WAR_POT, -1),
	]
	var awarded := 0
	for spot in table_spots:
		if spot == null:
			continue
		for card in cards_at(world, spot):
			move_card_to_bottom(card, spot, winner_deck, cmd)
			if card.has_component(C_FaceUp):
				cmd.remove_component(card, C_FaceUp)
			awarded += 1
	return awarded
