# Handoff: GECS Debugger Performance Overhaul

You are planning a rework of the GECS editor debugger's runtime instrumentation.
The goal: **`gecs/settings/debug_mode = true` should cost near-zero when the GECS
debugger tab isn't listening, and a bounded, predictable amount when it is.**
Today it costs ~20 ms per `world.process()` call — more than an entire 60 fps
frame budget — even when nothing is listening.

## Context

The framework just shipped a major performance overhaul (v9, branch
`perf-overhaul-v9` — see `addons/gecs/docs/PERFORMANCE.md` and the commit log
P0–P8). During that work we measured, via a controlled micro-benchmark, that
`ECS.debug = true` adds a **flat ~20 ms to every `world.process()` call** (1000
entities, one system matching nothing, Godot 4.7-dev5, headless). Identical on
v8 and v9 — this is pre-existing instrumentation cost, untouched by the
overhaul. The v9 work made the simulation fast; the debugger now needs the same
treatment.

## Measured facts

- Micro-benchmark: `addons/gecs/tests/performance/test_process_overhead.gd`
  (records `process_call_overhead_x100` to `reports/perf/`). With
  `--no-gecs-debug`: ~0.1–0.5 ms per call. With debug on: ~20 ms per call.
- The overhead exists in headless runs where **no debugger session is
  attached** — the cost is not the editor tab consuming data.
- Test logs from debug-on runs show repeated engine errors:
  `ERROR: Capture not registered: 'gecs'.` — i.e. messages are being *sent*
  (and failing, with an error print each) despite no listener.

## Root-cause hypotheses (ranked; verify with profiling before designing)

1. **`GECSEditorDebuggerMessages.can_send_message()` doesn't check for a live
   debugger.** It is `not Engine.is_editor_hint() and OS.has_feature("editor")`
   (`addons/gecs/debug/gecs_editor_debugger_messages.gd:28`). It never checks
   `EngineDebugger.is_active()` nor whether the `gecs` capture has a session.
   With debug_mode on and no debugger attached, every helper still builds its
   args and calls `EngineDebugger.send_message`, which **prints an engine
   ERROR per call** ("Capture not registered") — error logging I/O is
   expensive and happens several times per frame (`PROCESS_WORLD` +
   `SYSTEM_METRIC` + `SYSTEM_LAST_RUN_DATA` per system per frame), plus once
   per structural op during churn.
2. **Per-frame allocation/formatting regardless of need**:
   `System._handle` builds `lastRunData` every frame including
   `get_script().resource_path.get_file().get_basename()`
   (`addons/gecs/ecs/system.gd`, debug block near the top of `_handle`), and
   `system_last_run_data` does `last_run_data.duplicate()` per system per frame
   (`gecs_editor_debugger_messages.gd:63`).
3. **`world.perf_mark` aggregation** runs on every `_query` and other hot paths
   when `ECS.debug` (`addons/gecs/ecs/world.gd`, `perf_mark` + `_perf_metrics`).
4. **Per-op messages during entity churn**: `entity_added` calls
   `ent.get_path()` per spawn, `component_property_changed` fires per emitting
   write, etc. — all inside `if ECS.debug: assert(GECSEditorDebuggerMessages...)`
   wrappers throughout `world.gd`.

## Design goals

1. **Zero-ish cost when unattached**: debug_mode on + no debugger session (or
   tab closed) should cost < 0.5 ms per 100 `process()` calls vs debug off.
   At minimum, never build message args or hit error prints when nobody
   listens.
2. **Bounded cost when attached**: the tab being open shouldn't halve the
   game's frame rate. Consider: per-frame metrics sampled/throttled (e.g.
   10 Hz), batching one message per frame instead of N, sending deltas.
3. **Subscription model preferred**: the tab already has a two-way channel
   (the `gecs` capture; the tab sends `gecs:poll_entity` etc. — see
   `addons/gecs/debug/gecs_editor_debugger_tab.gd` and
   `gecs_editor_debugger.gd`). Let the tab explicitly enable/disable capture
   categories (metrics vs entity lifecycle vs property changes) so the game
   only produces what's being viewed.
4. **Keep the release-strip pattern**: the `if ECS.debug: assert(Messages.x())`
   idiom compiles out in release exports. Whatever replaces it must not add
   cost to release builds.
5. **No feature regressions**: live entity/component/relationship inspection,
   per-system min/max/avg metrics, Reset Metrics, pinning, poll/select — all
   must keep working (guard tests in `addons/gecs/tests/debug/`).

## Key files

- `addons/gecs/debug/gecs_editor_debugger_messages.gd` — all message senders +
  `can_send_message()` (the primary fix site).
- `addons/gecs/debug/gecs_editor_debugger.gd` — `EditorDebuggerPlugin`
  (editor side), registers the `gecs` capture.
- `addons/gecs/debug/gecs_editor_debugger_tab.gd` — the tab UI; sends
  `gecs:poll_entity`, toggles system active state, etc.
- `addons/gecs/ecs/system.gd` — `_handle`: `measure_time`, `lastRunData`
  construction, metric aggregation, per-frame message sends.
- `addons/gecs/ecs/world.gd` — `perf_mark`/`_perf_metrics`, and the
  `if ECS.debug: assert(GECSEditorDebuggerMessages.*)` call sites (grep for
  `GECSEditorDebuggerMessages`).
- `addons/gecs/ecs/ecs.gd` — `ECS.debug` resolution (project setting
  `gecs/settings/debug_mode`, CLI overrides `--gecs-debug`/`--no-gecs-debug`).

## How to measure (IMPORTANT — read this)

- Run tests ONLY via `tools/run_tests.sh` (hang-safe, compact output). NEVER
  `addons/gdUnit4/runtest.cmd` directly — its `-d` flag turns any script error
  into an interactive debugger prompt that hangs forever, and raw output is
  enormous. Example:
  `tools/run_tests.sh -t 200 res://addons/gecs/tests/performance/test_process_overhead.gd`
- Toggle instrumentation per run with `EXTRA_GODOT_ARGS="--no-gecs-debug"` (or
  `--gecs-debug`).
- Benchmark results append to `reports/perf/*.jsonl`; compare directories with
  `"%GODOT_BIN%" --headless --path . -s res://tools/perf_summary.gd -- <current> <baseline>`.
- The attached-debugger scenario can't be measured headless — verify manually
  from the editor (F5 with the GECS tab open/closed) using the
  `performance_monitor` export on a system or the debug_menu FPS overlay.

## Constraints

- Do not regress the v9 hot paths (regression gates listed in
  `addons/gecs/docs/PERFORMANCE.md`); correctness suites must stay green:
  `tools/run_tests.sh -t 400 res://addons/gecs/tests/core res://addons/gecs/tests/_bug_repros res://addons/gecs/tests/network res://addons/gecs/tests/debug`
  (currently 565/565).
- GDScript style: tabs, `##` doc comments, snake_case. Some files are CRLF —
  don't introduce stray carriage returns (parse errors).
- Godot 4.5+ (project currently runs 4.7-dev5:
  `D:\Godot\4.7-dev5\Godot_v4.7-dev5_win64_console.exe`).
- `EngineDebugger.is_active()` and `EngineDebugger.has_capture()` are the
  cheap runtime checks available on the game side; the editor side can send a
  handshake message when the tab opens/closes.

## Suggested deliverable

A phased plan (gate each phase on the micro-benchmark + debug test suite):
likely (1) attach/subscription gating so unattached cost ≈ 0, (2) per-frame
message batching + metric sampling when attached, (3) lazy/cached arg
construction (system name, lastRunData), (4) category toggles in the tab UI.
