#!/usr/bin/env bash
# Hang-safe GdUnit4 runner with COMPACT output.
#
# Godot test runs hang when a script has a parse error (the debug runner drops
# into an interactive "Debugger Break" prompt and waits forever), and the raw
# runner output is enormous. This wrapper:
#   - enforces a hard timeout and kills ONLY the Godot processes it spawned
#     (pre-existing processes like the editor are never touched)
#   - prints ONLY: the overall summary line, failed test names, and capped
#     failure details (or the parse error on a hang)
#
# Usage (from the project root, Git Bash):
#   tools/run_tests.sh [-t seconds] <res://path> [<res://path> ...]
# Examples:
#   tools/run_tests.sh res://addons/gecs/tests/core
#   tools/run_tests.sh -t 600 res://addons/gecs/tests/core res://addons/gecs/tests/network
#
# Exit codes: 0 = all passed, 1 = failures, 124 = timeout/hang.
set -u

TIMEOUT=300
ARGS=()
while [[ $# -gt 0 ]]; do
	case "$1" in
	-t)
		TIMEOUT="$2"
		shift 2
		;;
	*)
		ARGS+=(-a "$1")
		shift
		;;
	esac
done

if [[ ${#ARGS[@]} -eq 0 ]]; then
	echo "usage: tools/run_tests.sh [-t seconds] <res://path> [...]" >&2
	exit 2
fi

export GODOT_BIN="${GODOT_BIN:-D:\\Godot\\4.7-dev5\\Godot_v4.7-dev5_win64_console.exe}"

LOG="$(mktemp -t gdunit_run_XXXX.log)"

godot_pids() {
	powershell -NoProfile -Command \
		'Get-Process | Where-Object ProcessName -like "*odot*" | ForEach-Object Id' \
		2>/dev/null | tr -d '\r'
}

# Snapshot pre-existing Godot PIDs (e.g. the user's open editor) — never kill these.
BEFORE_PIDS="$(godot_pids)"

timeout "$TIMEOUT" ./addons/gdUnit4/runtest.cmd "${ARGS[@]}" -c >"$LOG" 2>&1
STATUS=$?

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g' "$LOG"; }

if [[ $STATUS -eq 124 || $STATUS -eq 137 || $STATUS -eq 143 ]]; then
	# Kill only Godot processes that appeared after we started.
	for pid in $(godot_pids); do
		if ! grep -qx "$pid" <<<"$BEFORE_PIDS"; then
			powershell -NoProfile -Command "Stop-Process -Id $pid -Force" >/dev/null 2>&1
		fi
	done
	echo "RESULT: TIMEOUT after ${TIMEOUT}s (runner hung — usually a parse error; first hits below)"
	strip_ansi | grep -m 4 -E "Parser Error|Stray carriage|SCRIPT ERROR|Compile Error" | sed 's/^[[:space:]]*//' | sort -u
	strip_ansi | grep -m 2 -E "^\*Frame 0" | sed 's/^[[:space:]]*//'
	echo "Full log: $LOG"
	exit 124
fi

SUMMARY="$(strip_ansi | grep -E '^Overall Summary' | tail -1)"
FAILED_TESTS="$(strip_ansi | grep ' FAILED' | sed 's/^[[:space:]]*//' | sort -u | head -25)"

echo "${SUMMARY:-RESULT: no summary produced (exit=$STATUS) — log: $LOG}"
if [[ -n "$FAILED_TESTS" ]]; then
	echo "FAILED:"
	echo "$FAILED_TESTS"
	# Capped failure details (assertion lines only)
	strip_ansi | grep -A 8 ' FAILED' | grep -E 'line [0-9]+:|Expecting|but is|but was' |
		sed 's/^[[:space:]]*//' | head -30
	echo "Full log: $LOG"
	exit 1
fi

rm -f "$LOG"
echo "RESULT: PASSED"
exit 0
