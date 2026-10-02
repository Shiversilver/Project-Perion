#!/usr/bin/env bash
# Headless combat smoke test. Fails on any script error or a FAIL result.
# Usage: GODOT=/path/to/godot tests/run_sim.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
out="$("$GODOT" --headless --path . --fixed-fps 60 res://tests/combat_sim.tscn 2>&1)"
echo "$out" | grep -E "^t=|^SIM" || true
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
	echo "$out" | grep -A1 -E "SCRIPT ERROR|Parse Error" | head -20
	echo "FAILED: script errors"
	exit 1
fi
echo "$out" | grep -q "SIM RESULT: PASS"
