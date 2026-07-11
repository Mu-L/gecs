# WAR — a GECS example card game

The classic children's card game, built end-to-end with GECS and presented
like a fighting game. One click plays a round; ties trigger a WAR (three
cards face down, one face up); the last player holding cards wins. Click at
game over to reshuffle and rematch.

**Controls:** Left click or SPACE.

**The slap:** when a WAR is decided, the pot flips face up and lingers on
the table for a couple of seconds — the slap window. Click fast (like
slapping the pile in real life) to snatch two cards off the CPU's deck.

## Why this example exists

It exercises most of the framework in ~15 small files:

| Pattern | Where |
|---|---|
| Enum FSM on a singleton entity, gated by property queries | `C_Phase` + every system's `sub_systems()` |
| Shared `SystemTimer` pacing multi-beat sequences | `C_Match.step_timer`, created in `DealSystem.setup()` |
| Relationships carrying data (`C_AtSpot.order` = pile position) | `DeckOps`, `O_CardMoved` |
| CommandBuffer for all structural changes + deferred state flips | every system (`cmd.add_custom` for phase transitions) |
| Property-query monitors (`on_match`) for phase entry | `O_PhaseTransition`, `O_Ui` |
| Relationship observers bridging logic → visuals | `O_CardMoved` (tweens), `O_Ui` (live card counts) |
| Component add/remove observers | `O_CardFace` (flips), `O_PlayAudio` (sound requests) |
| Custom events for gameplay → UI narration | `round_resolved`, `war_started`, `war_step`, `slapped`, `game_over` |
| Request components fulfilled by visual systems | `C_PlayAudio`, `C_Shake`, `C_Flip`, `C_Pop`, `C_Flash`, `C_Burst`, `C_TweenTarget` |
| Time-boxed input windows as tag components | `C_SlapWindow` (exists only during the war-resolve linger beat) |

## Flow

```
DEALING ──deal──▶ IDLE ──click──▶ P1_DRAW ─▶ P2_DRAW ─▶ AWAIT_RESOLVE
   ▲                                                        │ click
   │ click                                                  ▼
GAME_OVER ◀─loser owns nothing── AWARDING ◀── RESOLVE ──tie─▶ WAR
                                 (pot sweep)  (announce)       │
                                                   ▲──reveal──┘
```

The game is presented like a fighting game: each player's card count is
their health (`C_Health`, rendered by `S_HealthBars` with a trailing
damage-ghost bar), losing a round is "taking a hit" (`C_Hit` shakes and
flashes your bar), ties escalate to WAR with a camera shake, and running
out of cards is a K.O.

Every beat inside a round is paced by one shared single-shot `SystemTimer`
(`C_Match.step_timer`). A system that wants another beat calls
`step_timer.reset()`; a system that wants to wait for the player doesn't.
`reset()` also clears `ticked`, so downstream systems in the same group can
never double-fire on the frame that armed the timer.

Two rules keep the multi-beat WAR sequence honest:

1. **State transitions are deferred** (`cmd.add_custom`), so every sub-system
   gate in the same tick sees the *old* state.
2. **`war_cards_remaining` is decremented deferred too** — otherwise the
   reveal sub-system's `_eq 0` gate would match in the same tick as the final
   face-down commit, before the queued card moves applied, and would re-move
   the same top cards.

Game over is decided at the two places it can actually happen — awarding a
pot that empties the loser's deck (`ResolveSystem`), or a player unable to
complete a WAR (`WarCommitSystem` forfeits the table to the opponent). Both
paths first award all table cards to the winner, so "the player who still
owns cards" is always the winner by the time `O_PhaseTransition` broadcasts
`game_over`.

## Layers

- **logic** systems mutate only components/relationships — never sprites.
- **visual** systems (`S_AnimateCards`, `S_FlipCards`, `S_ShakeCamera`)
  consume animation-request components and touch the scene.
- **observers** are the only bridge between the two: a card *moved* because
  its `C_AtSpot` relationship changed, so `O_CardMoved` stamps a tween; a
  card *flipped* because `C_FaceUp` toggled, so `O_CardFace` stamps a
  `C_Flip`; the UI narrates custom events in `O_Ui`.

## Headless soak test

`autoplay.tscn` runs the game with a synthetic clicker and validates the
core invariants every frame (52 cards total, every card at exactly one spot,
counts add up). Useful after touching the phase systems:

```bash
"$GODOT_BIN" --headless --path . res://example_card_game/autoplay.tscn
```

It plays through at least two full matches (exercising the rematch/re-deal
path) and quits with exit code 0 on success, 1 on any invariant violation.

## Assets

- [Kenney playing-card pack](https://kenney.nl/assets/playing-cards-pack) (CC0)
- [Kenney audio packs](https://kenney.nl/assets?q=audio) (CC0)
