#!/usr/bin/env bash
# Exporta una versión de lanzamiento o valida el preset sin exportar.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"
GODOT_BIN="$(require_godot)"
PRESET="${PRESET:-Linux}"
CHECK_ONLY=0

while (($#)); do
	case "$1" in
		--check)
			CHECK_ONLY=1
			;;
		*)
			echo "Uso: tools/build.sh [--check]" >&2
			exit 1
			;;
	esac
	shift
done

if [[ ! -f "$ROOT/.godot/global_script_class_cache.cfg" ]]; then
	echo "Caché de clases ausente; importando recursos..."
	"$GODOT_BIN" --headless --editor --quit --path "$ROOT" >/dev/null
fi

case "$PRESET" in
	Linux)
		DEFAULT_OUTPUT="build/linux/innsmouth-protocol.x86_64"
		TEMPLATE_CHECK="linux_release.x86_64"
		;;
	"Windows Desktop")
		DEFAULT_OUTPUT="build/windows/innsmouth-protocol.exe"
		TEMPLATE_CHECK="windows_release_x86_64.exe"
		;;
	*)
		DEFAULT_OUTPUT="build/${PRESET// /_}/innsmouth-protocol"
		TEMPLATE_CHECK=""
		;;
esac

OUTPUT="${EXPORT_PATH:-$DEFAULT_OUTPUT}"
VERSION_RAW="$("$GODOT_BIN" --version 2>/dev/null | head -n 1 | tr -d '\r')"
TEMPLATE_VERSION="$(printf '%s\n' "$VERSION_RAW" | sed -nE 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.(stable|rc[0-9]+|beta[0-9]+|dev[0-9]+)).*/\1/p')"
if [[ -z "$TEMPLATE_VERSION" ]]; then
	TEMPLATE_VERSION="$VERSION_RAW"
fi
TEMPLATES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$TEMPLATE_VERSION"

echo "Godot: $VERSION_RAW"
echo "Preset: $PRESET"
echo "Salida: $OUTPUT"

if [[ ! -f "$ROOT/export_presets.cfg" ]]; then
	echo "ERROR: falta export_presets.cfg." >&2
	exit 1
fi

if ! grep -q "^name=\"$PRESET\"$" "$ROOT/export_presets.cfg"; then
	echo "ERROR: el preset '$PRESET' no existe en export_presets.cfg." >&2
	exit 1
fi

TEMPLATES_OK=0
if [[ -n "$TEMPLATE_CHECK" && -f "$TEMPLATES_DIR/$TEMPLATE_CHECK" ]]; then
	TEMPLATES_OK=1
elif [[ -z "$TEMPLATE_CHECK" ]]; then
	TEMPLATES_OK=1
fi

if [[ "$TEMPLATES_OK" != "1" ]]; then
	echo
	echo "Faltan las plantillas de exportación para $TEMPLATE_VERSION." >&2
	echo "  Esperadas en: $TEMPLATES_DIR/$TEMPLATE_CHECK" >&2
	echo "  Instálalas con: make install-templates" >&2
	echo "  Descarga oficial: ~1,2 GB" >&2
	if [[ "$CHECK_ONLY" == "1" ]]; then
		exit 3
	fi
	exit 2
fi

if [[ "$CHECK_ONLY" == "1" ]]; then
	echo "export-check: preset y plantillas OK (no se ha exportado nada)."
	exit 0
fi

if [[ "$OUTPUT" = /* ]]; then
	OUTPUT_ABS="$OUTPUT"
else
	OUTPUT_ABS="$ROOT/$OUTPUT"
fi

mkdir -p "$(dirname "$OUTPUT_ABS")"
cd "$ROOT"
"$GODOT_BIN" --headless --path "$ROOT" --export-release "$PRESET" "$OUTPUT_ABS"

if [[ ! -f "$OUTPUT_ABS" ]]; then
	echo "ERROR: Godot terminó sin generar el archivo esperado: $OUTPUT" >&2
	exit 1
fi
if [[ "$PRESET" == "Linux" || "$PRESET" == "Windows Desktop" ]]; then
	PCK_OUTPUT="$(dirname "$OUTPUT_ABS")/$(basename "${OUTPUT_ABS%.*}").pck"
	if [[ ! -s "$PCK_OUTPUT" ]]; then
		echo "ERROR: falta el paquete de recursos esperado: $PCK_OUTPUT" >&2
		exit 1
	fi
	echo "Paquete de recursos:"
	ls -lh "$PCK_OUTPUT"
fi

echo
echo "Exportación completada:"
ls -lh "$OUTPUT_ABS"
