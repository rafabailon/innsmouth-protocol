#!/usr/bin/env bash
# Ejecuta el proyecto con ventana (o headless si HEADLESS=1).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"
GODOT_BIN="$(require_godot)"

if [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]]; then
	echo "Caché de clases ausente; importando recursos..."
	"$GODOT_BIN" --headless --editor --quit --path "$ROOT" >/dev/null
fi

if [[ "${HEADLESS:-0}" == "1" ]]; then
	exec "$GODOT_BIN" --headless --path "$ROOT" "$@"
fi

if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
	echo "ERROR: no hay servidor gráfico. Usa 'make run-headless' o ejecuta desde el escritorio." >&2
	exit 1
fi

exec "$GODOT_BIN" --path "$ROOT" "$@"
