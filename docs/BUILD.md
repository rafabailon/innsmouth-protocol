# Compilación y exportación

Godot no compila GDScript a un binario nativo: **empaqueta** el proyecto y los recursos dentro de un ejecutable usando una plantilla de exportación. Para generar el juego distribuible hacen falta las plantillas oficiales de la misma versión que el editor.

El proyecto usa la versión estable actual verificada, **Godot 4.7.2**.

---

## 1. Presets incluidos

`export_presets.cfg` define dos destinos:

| Preset | Plataforma | Salida por defecto |
|---|---|---|
| `Linux` | Linux x86_64 | `build/linux/innsmouth-protocol.x86_64` |
| `Windows Desktop` | Windows x86_64 | `build/windows/innsmouth-protocol.exe` |

Ambos exportan todos los recursos, con el PCK separado del ejecutable y arquitectura x86_64.

Puedes cambiar la ruta de salida:

```bash
make build EXPORT_PATH=/tmp/innsmouth/innsmouth-protocol.x86_64
```

O usar otro preset existente:

```bash
make build PRESET='Windows Desktop'
```

---

## 2. Instalar las plantillas

### Opción automática

```bash
make install-templates
```

También se pueden instalar junto con el motor y las pruebas:

```bash
make install INSTALL_ARGS=--templates
```

El script:

1. Detecta la versión de Godot.
2. Descarga `Godot_v<versión>-stable_export_templates.tpz` desde GitHub (~1,2 GB).
3. Lo descomprime.
4. Copia el contenido en:

```text
~/.local/share/godot/export_templates/<versión>.stable/
```

En Linux, para Godot 4.7.2 la ruta final es:

```text
~/.local/share/godot/export_templates/4.7.2.stable/
```

Para forzar una versión concreta:

```bash
bash tools/install-templates.sh --version 4.7.2
bash tools/install-templates.sh --version 4.7.2 --force
```

### Opción manual

1. Descarga el paquete oficial desde:

```text
https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
```

2. Descomprime el `.tpz` (es un ZIP).
3. Copia la carpeta `templates/` a:

```text
~/.local/share/godot/export_templates/4.7.2.stable/
```

Deben quedar archivos como:

```text
linux_debug.x86_64
linux_release.x86_64
windows_debug_x86_64.exe
windows_release_x86_64.exe
```

En Windows, la carpeta equivalente suele ser:

```text
%APPDATA%\Godot\export_templates\4.7.2.stable\
```

También puedes instalar plantillas desde el editor: **Editor → Gestionar plantillas de exportación**.

---

## 3. Comprobar el entorno

```bash
make doctor
make export-check
```

`make export-check` valida:

- Que Godot existe.
- Que `export_presets.cfg` existe.
- Que el preset solicitado está definido.
- Que la plantilla de liberación está en la ruta esperada.

Códigos de salida del script `tools/build.sh --check`:

| Código | Significado |
|---|---|
| `0` | Todo listo. |
| `2` | Error de configuración o preset inexistente. |
| `3` | Faltan las plantillas de exportación. |

`make export-check` propaga el fallo (verás `Error 3` en la salida de make) y termina con código distinto de cero. Es intencionado: sirve como puerta en CI.

---

## 4. Exportar

### Linux

```bash
make build
```

Salida:

```text
build/linux/innsmouth-protocol.x86_64
build/linux/innsmouth-protocol.pck
```

Ejecuta:

```bash
./build/linux/innsmouth-protocol.x86_64
```

### Windows

```bash
make build-windows
```

Salida:

```text
build/windows/innsmouth-protocol.exe
build/windows/innsmouth-protocol.pck
```

Copia ambos archivos al mismo directorio en la máquina Windows.

### Exportación directa con Godot

```bash
godot --headless --path . --export-release Linux build/linux/innsmouth-protocol.x86_64
godot --headless --path . --export-release "Windows Desktop" build/windows/innsmouth-protocol.exe
```

El script `tools/build.sh` añade comprobaciones, crea el directorio y verifica que el archivo exista al terminar.

---

## 5. PCK separado o embebido

La configuración actual deja el PCK separado:

```ini
binary_format/embed_pck=false
```

Ventajas:

- Actualizar solo el PCK es más pequeño que reexportar el ejecutable.
- Es fácil inspeccionar qué archivos se distribuyen.

Para un único archivo autocontenido, cambia en `export_presets.cfg`:

```ini
binary_format/embed_pck=true
```

Después vuelve a exportar. En ese caso el `.pck` no se genera aparte.

---

## 6. Probar la exportación

```bash
./build/linux/innsmouth-protocol.x86_64
```

Comprueba:

- Que abre la ventana y muestra la terminal.
- Que el panel lateral muestra ubicación, objetivo, cordura e inventario.
- Que `ayuda`, `objetivo`, `guardar` y `cargar` funcionan.
- Que `continuar` recupera el último punto de control automático.
- Que el guardado se crea en `app_userdata`, no dentro de `build/`.

También puedes ejecutar la versión exportada en modo headless para comprobar que arranca:

```bash
timeout 10 ./build/linux/innsmouth-protocol.x86_64 --headless
```

El código de salida `124` de `timeout` es normal: el juego se queda esperando comandos.

---

## 7. Limpiar artefactos

```bash
make clean       # caché .godot/ y temporales .run/
make clean-all   # además borra build/
```

Si una exportación se interrumpe, `make clean` elimina restos `*.tmp`. Después vuelve a importar con `make import` si Godot no encuentra clases globales.

---

## 8. Notas y limitaciones

- **No hay compilación nativa de GDScript**: el "build" es un empaquetado con plantillas.
- **Las plantillas deben coincidir con la versión del editor**. Una plantilla de 4.6 no sirve para exportar con 4.7.2.
- **No se firma el ejecutable**. Para distribuir en Windows/macOS harían falta pasos adicionales de firma y notarización.
- **Windows no modifica recursos del ejecutable** (`application/modify_resources=false`) para no depender de `rcedit`; el icono y la versión del `.exe` son los de la plantilla.
- **No hay iconos específicos de plataforma** en los presets; se usa el icono del proyecto.
- **El tamaño del paquete** depende sobre todo de la plantilla de Godot (decenas de MB); incluye además una fuente TTF y un WAV ambiental pequeño.
- Los recursos incluidos son DejaVu Sans Mono (aviso en `assets/fonts/LICENSE-DejaVu.txt`) y un ambiente WAV sintetizado en el proyecto.
- Si cambias `project.godot`, vuelve a ejecutar `make import` antes de exportar para refrescar la caché.

---

## 9. Integración continua

Ejemplo mínimo para una máquina Linux con Godot y plantillas instaladas:

```bash
#!/usr/bin/env bash
set -euo pipefail

make import
make test
make export-check
make build
```

Si las plantillas no caben en la caché de CI, guarda el directorio:

```text
~/.local/share/godot/export_templates/
```

como artefacto o caché entre ejecuciones. La descarga son ~1,2 GB.
