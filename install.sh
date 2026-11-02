#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_VERSION="4.7.2"
INSTALL_DIR="$ROOT/.tools/godot"
INSTALL_PATH="$INSTALL_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
INSTALL_TEMPLATES=0

usage() {
	cat <<'EOF'
Uso: bash install.sh [--templates]

Prepara Innsmouth Protocol en Linux:
  - reutiliza Godot 4.7.2-stable o superior si ya está instalado;
  - si falta, instala Godot 4.7.2 en .tools/godot/;
  - importa el proyecto y ejecuta la prueba de humo.

Opciones:
  --templates  Instala también las plantillas oficiales de exportación
               (descarga grande; necesarias solo para exportar).
  --help       Muestra esta ayuda.
EOF
}

while (($#)); do
	case "$1" in
		--templates)
			INSTALL_TEMPLATES=1
			;;
		--help|-h)
			usage
			exit 0
			;;
		*)
			echo "Opción desconocida: $1" >&2
			usage >&2
			exit 2
			;;
	esac
	shift
done

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
	echo "ERROR: este instalador automatizado requiere Linux x86_64." >&2
	echo "En otras plataformas, instala Godot 4.7.2-stable o superior y ejecuta make import && make test." >&2
	exit 1
fi

command -v make >/dev/null 2>&1 || { echo "ERROR: falta make." >&2; exit 1; }

source "$ROOT/tools/godot-env.sh"
if GODOT_BIN="$(resolve_godot)"; then
	echo "Usando Godot existente: $GODOT_BIN"
else
	if [[ -n "${GODOT:-}" ]]; then
		echo "ERROR: no se pudo usar el ejecutable indicado en GODOT." >&2
		exit 1
	fi
	command -v curl >/dev/null 2>&1 || { echo "ERROR: falta curl para descargar Godot." >&2; exit 1; }
	command -v unzip >/dev/null 2>&1 || { echo "ERROR: falta unzip para instalar Godot." >&2; exit 1; }

	mkdir -p "$INSTALL_DIR"
	TMP_DIR="$(mktemp -d "$INSTALL_DIR/.install.XXXXXX")"
	cleanup() {
		rm -rf "$TMP_DIR"
	}
	trap cleanup EXIT

	BINARY="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
	ARCHIVE="${BINARY}.zip"
	URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${ARCHIVE}"
	echo "Descargando Godot ${GODOT_VERSION} desde la distribución oficial..."
	curl -fL --retry 3 --connect-timeout 20 -o "$TMP_DIR/$ARCHIVE" "$URL"
	unzip -q "$TMP_DIR/$ARCHIVE" -d "$TMP_DIR/extracted"
	DOWNLOADED="$TMP_DIR/extracted/$BINARY"
	if [[ ! -f "$DOWNLOADED" ]]; then
		echo "ERROR: el archivo descargado no contiene $ARCHIVE." >&2
		exit 1
	fi
	chmod +x "$DOWNLOADED"
	if ! "$DOWNLOADED" --version | grep -q "^${GODOT_VERSION}\."; then
		echo "ERROR: la versión del ejecutable descargado no coincide con ${GODOT_VERSION}." >&2
		exit 1
	fi
	mv -f "$DOWNLOADED" "$INSTALL_PATH"
	GODOT_BIN="$INSTALL_PATH"
	echo "Godot instalado en: $INSTALL_PATH"
fi

GODOT_VERSION_ACTUAL="$("$GODOT_BIN" --version | head -n 1 | tr -d '\r')"
echo "Preparando el proyecto con Godot $GODOT_VERSION_ACTUAL..."

if [[ "$INSTALL_TEMPLATES" == "1" ]]; then
	GODOT="$GODOT_BIN" bash "$ROOT/tools/install-templates.sh"
fi

make -C "$ROOT" import GODOT="$GODOT_BIN"
make -C "$ROOT" test GODOT="$GODOT_BIN"

echo
echo "Instalación y configuración completadas."
echo "Ejecuta 'make run' para abrir el juego."
if [[ "$INSTALL_TEMPLATES" != "1" ]]; then
	echo "Para exportar el juego: make install-templates"
fi
