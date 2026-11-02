#!/usr/bin/env bash
# Descarga e instala las plantillas oficiales de exportación de Godot.
# La descarga ronda 1,2 GB; no se ejecuta automáticamente desde make build.
set -euo pipefail

VERSION_INPUT="${GODOT_VERSION:-}"
FORCE=0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tools/godot-env.sh"

while (($#)); do
	case "$1" in
		--force)
			FORCE=1
			;;
		--version)
			shift
			VERSION_INPUT="${1:-}"
			;;
		*)
			echo "Uso: tools/install-templates.sh [--force] [--version 4.7.2]" >&2
			exit 1
			;;
	esac
	shift
done

if [[ -z "$VERSION_INPUT" ]]; then
	GODOT_BIN="$(require_godot)"
	VERSION_INPUT="$("$GODOT_BIN" --version 2>/dev/null | head -n 1 | tr -d '\r')"
fi

BASE_VERSION="$(printf '%s\n' "$VERSION_INPUT" | sed -nE 's/^([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p')"
if [[ -z "$BASE_VERSION" ]]; then
	echo "ERROR: no se pudo interpretar la versión '$VERSION_INPUT'." >&2
	exit 1
fi

TEMPLATE_VERSION="${BASE_VERSION}.stable"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$TEMPLATE_VERSION"
URL="https://github.com/godotengine/godot/releases/download/${BASE_VERSION}-stable/Godot_v${BASE_VERSION}-stable_export_templates.tpz"

echo "Plantillas de Godot $BASE_VERSION"
echo "Destino: $DEST"
echo "Origen:  $URL"

if [[ -f "$DEST/linux_release.x86_64" && "$FORCE" != "1" ]]; then
	echo "Las plantillas ya están instaladas. Usa --force para volver a descargarlas."
	exit 0
fi

command -v curl >/dev/null 2>&1 || { echo "ERROR: falta curl." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "ERROR: falta unzip." >&2; exit 1; }

TMP_DIR="$(mktemp -d)"
cleanup() {
	rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo
echo "Descargando (~1,2 GB). Esto puede tardar varios minutos..."
curl -fL --retry 3 --progress-bar -o "$TMP_DIR/templates.tpz" "$URL"

echo "Descomprimiendo..."
mkdir -p "$TMP_DIR/extract"
unzip -q "$TMP_DIR/templates.tpz" -d "$TMP_DIR/extract"

if [[ ! -d "$TMP_DIR/extract/templates" ]]; then
	echo "ERROR: el paquete no contiene la carpeta templates/." >&2
	exit 1
fi

mkdir -p "$DEST"
cp -a "$TMP_DIR/extract/templates/." "$DEST/"

if [[ ! -f "$DEST/linux_release.x86_64" ]]; then
	echo "ERROR: no se encontró linux_release.x86_64 tras la instalación." >&2
	exit 1
fi

echo
echo "Plantillas instaladas en: $DEST"
echo "Ya puedes ejecutar: make export-check && make build"
