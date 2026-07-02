## GECS performance summary generator.
##
## Aggregates reports/perf/*.jsonl into a markdown matrix (one row per test,
## one column per scale) with optional delta vs a baseline directory.
##
## Usage (from the project root):
##   "%GODOT_BIN%" --headless --path . -s res://tools/perf_summary.gd -- [current_dir] [baseline_dir]
##
## Defaults: current_dir = reports/perf, baseline_dir = (none).
## Writes <current_dir>/SUMMARY.md and prints it to stdout.
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var current_dir: String = args[0] if args.size() > 0 else "reports/perf"
	var baseline_dir: String = args[1] if args.size() > 1 else ""

	var current := _aggregate(current_dir)
	if current.is_empty():
		push_error("No perf results found in %s" % current_dir)
		quit(1)
		return

	var baseline := _aggregate(baseline_dir) if baseline_dir != "" else {}
	var md := _render(current, baseline, baseline_dir)

	var out_path := current_dir.path_join("SUMMARY.md")
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file:
		file.store_string(md)
		file.close()
		print(md)
		print("\nWritten to %s" % out_path)
		quit(0)
	else:
		push_error("Failed to write %s" % out_path)
		quit(1)


## Parse every JSONL file in dir. Returns { test_name: { scale: {ms, timestamp, sha} } }
## using the most recent line per (test, scale). Skips files with foreign schemas
## (e.g. stress_test_ramp.jsonl).
func _aggregate(dir_path: String) -> Dictionary:
	var results: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return results
	for fname in dir.get_files():
		if not fname.ends_with(".jsonl"):
			continue
		var file := FileAccess.open(dir_path.path_join(fname), FileAccess.READ)
		if file == null:
			continue
		while not file.eof_reached():
			var line := file.get_line().strip_edges()
			if line.is_empty():
				continue
			var entry: Variant = JSON.parse_string(line)
			if entry == null or not entry is Dictionary:
				continue
			if not entry.has("test") or not entry.has("scale"):
				continue
			var ms: float = entry.get("median_ms", entry.get("time_ms", -1.0))
			if ms < 0.0:
				continue
			var test_name: String = entry["test"]
			var scale: int = int(entry["scale"])
			if not results.has(test_name):
				results[test_name] = {}
			# Lines are appended chronologically — last one wins.
			results[test_name][scale] = {
				"ms": ms,
				"timestamp": entry.get("timestamp", ""),
				"sha": entry.get("git_sha", ""),
				"schema": int(entry.get("schema", 1)),
			}
		file.close()
	return results


func _render(current: Dictionary, baseline: Dictionary, baseline_dir: String) -> String:
	# Collect the union of scales for column headers
	var scales: Array = []
	for test_name in current:
		for scale in current[test_name]:
			if not scales.has(scale):
				scales.append(scale)
	scales.sort()

	var sha := ""
	for test_name in current:
		for scale in current[test_name]:
			if current[test_name][scale]["sha"] != "":
				sha = current[test_name][scale]["sha"]
				break
		if sha != "":
			break

	var lines: Array[String] = []
	lines.append("# GECS Performance Summary")
	lines.append("")
	lines.append(
		(
			"Generated: %s | Godot %s%s%s"
			% [
				Time.get_datetime_string_from_system(),
				Engine.get_version_info().string,
				(" | git " + sha) if sha != "" else "",
				(" | baseline: " + baseline_dir) if baseline_dir != "" else "",
			]
		)
	)
	lines.append("")
	lines.append("Cells: median ms (Δ% vs baseline; negative = faster). `*` = single-shot (schema v1).")
	lines.append("")

	var header := "| test |"
	var sep := "|---|"
	for scale in scales:
		header += " %s |" % _fmt_scale(scale)
		sep += "---:|"
	lines.append(header)
	lines.append(sep)

	var test_names := current.keys()
	test_names.sort()
	for test_name in test_names:
		var row := "| %s |" % test_name
		for scale in scales:
			if not current[test_name].has(scale):
				row += " — |"
				continue
			var cell_data: Dictionary = current[test_name][scale]
			var cell := "%.3f" % cell_data["ms"]
			if cell_data["schema"] == 1:
				cell += "*"
			if baseline.has(test_name) and baseline[test_name].has(scale):
				var base_ms: float = baseline[test_name][scale]["ms"]
				if base_ms > 0.0:
					var delta := (cell_data["ms"] - base_ms) / base_ms * 100.0
					cell += " (%+.0f%%)" % delta
			row += " %s |" % cell
		lines.append(row)

	lines.append("")
	return "\n".join(lines)


func _fmt_scale(scale: int) -> String:
	if scale >= 1000 and scale % 1000 == 0:
		return "%dk" % (scale / 1000)
	return str(scale)
