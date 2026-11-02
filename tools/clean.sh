#!/usr/bin/env bash
# Limpia caché de Godot, temporales de ejecución y, opcionalmente, build/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALL=0
FORCE=0

while (($#)); do
	case "$1" in
		--all)
			ALL=1
			;;
		--force)
			FORCE=1
			;;
		*)
			echo "Uso: tools/clean.sh [--all] [--force]" >&2
			exit 1
			;;
	esac
	shift
done

PID_FILE="$ROOT/.run/godot.pid"
if [[ -f "$PID_FILE" && "$FORCE" != "1" ]]; then
	PID="$(cat "$PID_FILE" 2>/dev/null || true)"
	if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
		echo "ERROR: el juego sigue en ejecución (PID $PID). Usa 'make stop' o --force." >&2
		exit 1
	fi
fi

echo "Limpieza en $ROOT"

for target in .godot .run build; do
	path="$ROOT/$target"
	if [[ -e "$path" ]]; then
		if [[ "$target" == "build" && "$ALL" != "1" ]]; then
			echo "  Conservado: build/ (usa make clean-all para borrarlo)"
			continue
		fi
		echo "  Borrando: $target/ ($(du -sh "$path" 2>/dev/null | cut -f1))"
		rm -rf "$path"
	fi
done

while IFS= read -r -d '' tmp; do
	echo "  Borrando temporal: ${tmp#"$ROOT"/}"
	rm -f "$tmp"
done < <(find "$ROOT" -maxdepth 3 -type f -name '*.tmp' -print0 2>/dev/null)

# Restos habituales de exportaciones interrumpidas.
find "$ROOT" -maxdepth 3 -type f \( -name '*.pck.tmp' -o -name '*.zip.tmp' \) -delete 2>/dev/null || true

echo "Limpieza completada."
