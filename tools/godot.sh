#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"
GODOT_BIN="$(require_godot)"
exec "$GODOT_BIN" "$@"
