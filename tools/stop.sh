#!/usr/bin/env bash
# Detiene la instancia lanzada por tools/run-bg.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT/.run/godot.pid"

if [[ ! -f "$PID_FILE" ]]; then
	echo "No hay ningún proceso registrado en .run/godot.pid."
	exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [[ -z "$PID" ]] || ! kill -0 "$PID" 2>/dev/null; then
	echo "El PID registrado ya no está activo. Limpiando archivo."
	rm -f "$PID_FILE"
	exit 0
fi

kill -TERM "$PID" 2>/dev/null || true
for _ in $(seq 1 50); do
	if ! kill -0 "$PID" 2>/dev/null; then
		break
	fi
	sleep 0.1
done

if kill -0 "$PID" 2>/dev/null; then
	echo "El proceso no respondió; enviando SIGKILL."
	kill -KILL "$PID" 2>/dev/null || true
fi

rm -f "$PID_FILE"
echo "Proceso $PID detenido."
