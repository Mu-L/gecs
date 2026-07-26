# GECS Example: Inventory & Item Actions

A tiny loot room that ports a real game's item/inventory/action architecture into
a self-contained GECS demo. Walk over pickups, watch coin piles stack, cycle and
use items, drop them back on the floor, and unlock a vault with a key that never
leaves your pocket.

The headline idea: **there is no inventory container**. An item is "in" the
hero's inventory because the item entity carries
`Relationship.new(C_OwnedBy.new(), hero)`, and "the inventory" is just the query
for that relationship. No arrays, no slots, no container component.

## Controls

| Input          | Action                                  |
| -------------- | --------------------------------------- |
| WASD / Arrows  | Move                                    |
| Tab            | Cycle active item (includes empty hands)|
| E / Enter      | Use active item                         |
| Q              | Drop one unit of the active item        |

## What to try

1. Grab the red health kit and press E: the health bar fills and the kit is
   consumed.
2. Grab all three coin piles (5, 10, and 1): they merge into a single x16 stack
   in the quick bar.
3. Press Q a few times: coins land back on the floor one at a time and can be
   re-collected.
4. Grab the key, walk to the brown door, press E: the door only unlocks in
   range, opens for good, and the key stays in your inventory. The vault holds
   25 more coins.
5. Use the cyan boots: x2 speed for 5 seconds with a badge, then everything
   reverts on its own.

## Why this example exists

| Pattern | Files |
| --- | --- |
| Template items + composer (one .tres per item type, composed into entities) | `components/c_item.gd`, `lib/item_utils.gd`, `items/*.tres` |
| Relationship-based inventory (no container, just `C_OwnedBy` edges) | `components/c_owned_by.gd`, `lib/item_queries.gd` |
| Pre-allocated Relationship singletons (query-time GC pressure) | `lib/item_rels.gd` |
| Scene-signal to tag-component bridge (Area2D overlap enters the ECS) | `entities/e_pickup.gd`, `systems/s_pickup.gd` |
| Request components (asking vs doing, one honoring system) | `components/c_request_use_item.gd`, `systems/s_items.gd` |
| Deferred action queue (Resources dispatch, one drain point per frame) | `actions/item_action.gd`, `lib/action_queue.gd`, `systems/s_actions.gd` |
| Stacking / consolidation | `lib/inventory_utils.gd` |
| Custom events to UI observers (gameplay never knows a UI exists) | `observers/o_quick_bar.gd`, `observers/o_toast.gd` |
| Property-change observer (setter-driven health bar) | `components/c_hit_points.gd`, `observers/o_hero_status.gd` |
| Timed component expiry (buff is data, expiry is a system) | `components/c_speed_boost.gd`, `systems/s_speed_boost.gd` |
| `on_removed` as logic-to-visuals bridge (key removes a tag, door reacts) | `actions/ia_use_key.gd`, `observers/o_door.gd` |

## The flow, end to end

```
key press ─▶ request tag (C_RequestUseItem)      HeroInputSystem / ItemsSystem
                 │
                 ▼
        ItemsSystem honors the request
                 │
                 ▼
        ItemAction.dispatch(...)                 queues, returns immediately
                 │
                 ▼
        ActionQueue (static FIFO)
                 │
                 ▼
        ActionsSystem.drain()                    LAST system in gameplay group
                 │
                 ▼
        InventoryUtils mutation + emit_event
                 │
                 ▼
        Observers repaint UI                     O_QuickBar / O_HeroStatus / O_Toast
```

## Key snippets

The whole inventory model in one query:

```gdscript
static func in_inventory_of(owner: Entity) -> QueryBuilder:
    return ECS.world.query.with_relationship([Relationship.new(C_OwnedBy.new(), owner)])
```

Actions queue now, run later, at one coherent point:

```gdscript
func dispatch(entities: Array, user: Entity) -> void:
    for entity in query().matches(entities):
        ActionQueue.push(_execute_item.bind(entity, user), self)
```

Why a static queue instead of `cmd.add_custom`: `dispatch` is called from
Resources (and could be called from UI or network code) that hold no command
buffer; everything dispatched during the frame executes at ONE known point; and
action bodies run synchronously in order, so a later action sees an earlier
action's structural writes. For a mutation queued from inside a single system,
`cmd.add_custom` remains the simpler tool.

Gameplay emits events, observers own the UI:

```gdscript
ECS.world.emit_event(&"active_item_changed", owner, e_item)   # InventoryUtils
[q.on_event(&"active_item_changed"), _on_inventory_event]     # O_QuickBar
```

## Differences from the source game

- The `ActionManager` autoload became the static `ActionQueue` class (examples
  add no autoloads).
- `GameState` signals became GECS custom events consumed by observers.
- Icons/localized text became a `color` + `glyph` on `C_Item` (no external art).
- A deferred pending-delete tag became direct removal at the drain point.
- `add_to_inventory` re-fetches the surviving stack after consolidation instead
  of returning a possibly-merged-away entity.

## How to run

Open the project in Godot, open `example_inventory/main.tscn`, and press
"Run Current Scene".
