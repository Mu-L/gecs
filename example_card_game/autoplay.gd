## Headless soak test for the WAR example. Instantiates the real game scene,
## blind-clicks the "advance" action on a cadence (the phase gates drop the
## irrelevant presses, which exercises the input gating too), and validates
## the core invariants that the WAR sequence must never break:
##
##   * exactly 52 cards exist once dealt,
##   * every card sits at exactly ONE spot (one C_AtSpot relationship),
##   * the per-spot counts sum back to 52.
##
## Runs at a high Engine.time_scale so full matches take seconds. Quits 0
## after two complete matches (which proves the rematch/re-deal path), or 1
## on any invariant violation or timeout.
##
## Usage:  "$GODOT_BIN" --headless --path . res://example_card_game/autoplay.tscn
extends Node

const MAIN_SCENE: PackedScene = preload("res://example_card_game/main.tscn")

const TIME_SCALE := 30.0
const TIMEOUT_MSEC := 240 * 1000
const MATCHES_TO_PLAY := 2

var _frame := 0
var _dealt := false
var _violations := 0
var _wars := 0
var _game_overs := 0
var _last_state: int = -1
var _start_msec := 0


func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	_start_msec = Time.get_ticks_msec()
	add_child(MAIN_SCENE.instantiate())


func _process(_delta: float) -> void:
	_frame += 1
	# Blind click cadence: press for 5 frames, release for 5. Phases that
	# aren't waiting for input drop the press via their sub-system gates.
	if _frame % 10 == 0:
		Input.action_press("advance")
	elif _frame % 10 == 5:
		Input.action_release("advance")

	_track_phase()
	if _frame % 30 == 0:
		_check_invariants()

	if _game_overs >= MATCHES_TO_PLAY and _last_state == C_Phase.State.GAME_OVER:
		_finish()
	elif Time.get_ticks_msec() - _start_msec > TIMEOUT_MSEC:
		push_error("[autoplay] TIMEOUT after %d wars / %d matches" % [_wars, _game_overs])
		_violations += 1
		_finish()


func _track_phase() -> void:
	var world := ECS.world
	if world == null:
		return
	var match_e := DeckOps.find_match(world)
	if match_e == null:
		return
	var c_phase := match_e.get_component(C_Phase) as C_Phase
	if c_phase == null or c_phase.state == _last_state:
		return
	_last_state = c_phase.state
	match c_phase.state:
		C_Phase.State.WAR:
			_wars += 1
		C_Phase.State.GAME_OVER:
			_game_overs += 1
			print("[autoplay] match %d over (%d wars so far)" % [_game_overs, _wars])
		C_Phase.State.IDLE:
			_dealt = true


func _check_invariants() -> void:
	var world := ECS.world
	if world == null or not _dealt:
		return
	var cards := world.query.with_all([C_Card]).execute()
	if cards.size() != 52:
		_fail("expected 52 cards, found %d" % cards.size())
	var wildcard := Relationship.new(C_AtSpot.new(), null)
	for card: Entity in cards:
		var rels := card.get_relationships(wildcard)
		if rels.size() != 1:
			_fail("%s has %d C_AtSpot relationships (want 1)" % [card.name, rels.size()])
	var total := 0
	for spot in world.query.with_all([C_Spot]).execute():
		total += DeckOps.count_at(world, spot)
	if total != 52:
		_fail("spot counts sum to %d (want 52)" % total)
	# HUD health must mirror actual ownership (O_Ui keeps C_Health in sync).
	for player_id in 2:
		var player := DeckOps.find_player(world, player_id)
		if player == null:
			_fail("player %d not found" % player_id)
			continue
		var health := player.get_component(C_Health) as C_Health
		var owned := DeckOps.count_owned_by(world, player_id)
		if health == null:
			_fail("player %d missing C_Health" % player_id)
		elif health.current != owned:
			_fail("P%d health %d != owned %d" % [player_id + 1, health.current, owned])


func _fail(message: String) -> void:
	_violations += 1
	push_error("[autoplay] INVARIANT VIOLATION: %s" % message)


func _finish() -> void:
	var verdict := "PASS" if _violations == 0 else "FAIL (%d violations)" % _violations
	print(
		"[autoplay] %s — %d matches, %d wars, %.1fs real time"
		% [verdict, _game_overs, _wars, (Time.get_ticks_msec() - _start_msec) / 1000.0]
	)
	get_tree().quit(0 if _violations == 0 else 1)
