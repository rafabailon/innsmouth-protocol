#!/usr/bin/env bash
# Diagnóstico del entorno de desarrollo y exportación.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"

echo "Innsmouth Protocol · diagnóstico"
echo "Proyecto: $ROOT"
echo

GODOT_BIN="$(require_godot)"

VERSION_RAW="$("$GODOT_BIN" --version 2>/dev/null | head -n 1 | tr -d '\r')"
echo "Godot: $GODOT_BIN"
echo "Versión: $VERSION_RAW"

if [[ ! -f "$ROOT/project.godot" ]]; then
	echo "ERROR: no existe project.godot en $ROOT." >&2
	exit 1
fi
echo "project.godot: OK"

if [[ -f "$ROOT/export_presets.cfg" ]]; then
	echo "export_presets.cfg: OK"
else
	echo "export_presets.cfg: FALTA (no se podrá exportar)"
fi

TEMPLATE_VERSION="$(printf '%s\n' "$VERSION_RAW" | sed -nE 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.(stable|rc[0-9]+|beta[0-9]+|dev[0-9]+)).*/\1/p')"
if [[ -z "$TEMPLATE_VERSION" ]]; then
	TEMPLATE_VERSION="$VERSION_RAW"
fi
TEMPLATES_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates"
TEMPLATES_DIR="$TEMPLATES_ROOT/$TEMPLATE_VERSION"

echo
echo "Plantillas de exportación"
echo "  Directorio esperado: $TEMPLATES_DIR"
if [[ -f "$TEMPLATES_DIR/linux_release.x86_64" ]]; then
	echo "  Linux: OK"
else
	echo "  Linux: FALTAN"
	echo "  Descarga oficial (~1,2 GB): make install-templates"
	echo "  O copia las plantillas en: $TEMPLATES_DIR"
fi
if [[ -d "$TEMPLATES_ROOT" ]]; then
	for dir in "$TEMPLATES_ROOT"/*; do
		[[ -d "$dir" ]] || continue
		echo "  Encontrada: $(basename "$dir")"
	done
fi

echo
echo "Entorno gráfico"
if [[ -n "${DISPLAY:-}" ]]; then
	echo "  DISPLAY=$DISPLAY"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
	echo "  WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
else
	echo "  Sin DISPLAY/WAYLAND_DISPLAY: usa make run-headless."
fi

PROJECT_NAME="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$ROOT/project.godot" | head -n 1)"
if [[ -n "$PROJECT_NAME" ]]; then
	echo
	echo "Guardado del juego"
	echo "  ~/.local/share/godot/app_userdata/$PROJECT_NAME/innsmouth_save.json"
	echo "  ~/.local/share/godot/app_userdata/$PROJECT_NAME/innsmouth_autosave.json"
fi

echo
echo "Comandos recomendados: make test · make run · make build · make clean"
