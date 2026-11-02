#!/usr/bin/env bash
# Lanza el juego en segundo plano y guarda PID y log en .run/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"
GODOT_BIN="$(require_godot)"
RUN_DIR="$ROOT/.run"
PID_FILE="$RUN_DIR/godot.pid"
LOG_FILE="$RUN_DIR/godot.log"

if [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]]; then
	echo "Caché de clases ausente; importando recursos..."
	"$GODOT_BIN" --headless --editor --quit --path "$ROOT" >/dev/null
fi

mkdir -p "$RUN_DIR"

if [[ -f "$PID_FILE" ]]; then
	PID="$(cat "$PID_FILE" 2>/dev/null || true)"
	if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
		echo "Ya hay una instancia en ejecución (PID $PID). Usa 'make stop' primero."
		exit 0
	fi
	rm -f "$PID_FILE"
fi

CMD=("$GODOT_BIN")
if [[ "${HEADLESS:-0}" == "1" ]]; then
	CMD+=(--headless)
elif [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
	echo "ERROR: no hay servidor gráfico. Usa HEADLESS=1 o 'make run-headless'." >&2
	exit 1
fi
CMD+=(--path "$ROOT")

nohup "${CMD[@]}" "$@" >"$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" >"$PID_FILE"
sleep 1

if kill -0 "$PID" 2>/dev/null; then
	echo "Juego lanzado en segundo plano."
	echo "  PID: $PID"
	echo "  Log: $LOG_FILE"
	echo "  Detener: make stop"
	[[ -s "$LOG_FILE" ]] && tail -n 5 "$LOG_FILE"
else
	echo "ERROR: el proceso terminó al arrancar. Revisa $LOG_FILE." >&2
	tail -n 20 "$LOG_FILE" >&2 || true
	rm -f "$PID_FILE"
	exit 1
fi
