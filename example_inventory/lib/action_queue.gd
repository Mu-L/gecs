## Static FIFO queue for deferred [ItemAction] execution, drained once per frame
## by [ActionsSystem] (the LAST system in the gameplay group).
##
## This replaces the source game's ActionManager autoload; examples cannot
## register autoloads, and a static class needs no global setup. Why a dedicated
## queue instead of routing actions through [member System.cmd]:
## [br]- [method ItemAction.dispatch] is called from Resources (and could be
##   called from UI or network code) that hold no reference to any system's
##   command buffer; a static queue is reachable from anywhere.
## [br]- Frame coherence: everything dispatched anywhere during the frame
##   executes at ONE known point, not scattered across per-system flushes.
## [br]- Action bodies run synchronously in queued order, so a later action in
##   the same drain observes an earlier action's structural writes. Routing the
##   writes through [code]cmd[/code] would defer them past the reads.
## [br]For a mutation queued from inside a single system, [method
## CommandBuffer.add_custom] remains the simpler tool; this queue earns its keep
## once many call sites feed one drain point.
class_name ActionQueue

## Queued [code][callback, action][/code] pairs. The action Resource is carried
## only for debugging/inspection; execution just calls the callback.
static var _queue: Array = []


## Queue [param callback] to run at the next [method drain]. [param action] is
## the dispatching [ItemAction], kept alongside for debuggability.
static func push(callback: Callable, action: Resource = null) -> void:
	_queue.push_back([callback, action])


## Execute every queued callback in FIFO order. Called by [ActionsSystem].
## Actions pushed WHILE draining (an action dispatching another action) run in
## the same drain, since the loop re-checks the live queue.
static func drain() -> void:
	while _queue.size() > 0:
		var entry: Array = _queue.pop_front()
		var callback: Callable = entry[0]
		if callback.is_valid():
			callback.call()


## Discard all queued actions. Called from [code]main.gd[/code] [code]_ready()[/code]
## because static state survives scene reloads (F6 restarts, scene switches).
static func clear() -> void:
	_queue.clear()
