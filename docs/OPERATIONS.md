# Operaciones

Guía para ejecutar, detener, probar y limpiar **Innsmouth Protocol** sin depender del editor de Godot.

Todos los comandos se ejecutan desde la raíz del proyecto:

```bash
cd /path/to/innsmouth-protocol
```

---

## 1. Requisitos

- **Godot 4.7.2-stable o superior**. La versión estable más reciente comprobada es **4.7.2**.
- `make` y `bash` para los atajos de operación.
- En Linux x86_64, `bash install.sh` reutiliza la versión estable compatible más alta disponible o descarga Godot 4.7.2 si no encuentra una. Para descargarlo hacen falta `curl` y `unzip`.
- Para exportar: plantillas oficiales de exportación de la misma versión que el editor (consulta `docs/BUILD.md`).
- Para ejecutar con ventana: un servidor gráfico (`DISPLAY` o `WAYLAND_DISPLAY`).

El Makefile busca Godot en este orden:

1. La variable `GODOT`.
2. `godot4` en `PATH`.
3. `godot` en `PATH`.
4. `.tools/godot/Godot_v4.7.2-stable_linux.x86_64`.
5. `.tools/godot/Godot_v4.7.2-stable_linux.x86_64` (si se instaló con `make install`).

Si tu binario está en otro sitio:

```bash
make run GODOT=/ruta/a/godot
# o bien
export GODOT=/ruta/a/godot
make run
```

### Instalación automática

Desde la raíz del proyecto:

```bash
make install
```

El instalador elige la versión estable compatible más alta encontrada en `PATH` o descarga la versión validada 4.7.2 en `.tools/godot/`. Después importa el proyecto y ejecuta la prueba de humo. Para instalar también las plantillas de exportación (descarga de aproximadamente 1,2 GB):

```bash
make install INSTALL_ARGS=--templates
```

En otros sistemas operativos, instala Godot 4.7.2-stable o superior manualmente y ejecuta `make import` seguido de `make test`.

### Instalar Godot manualmente

1. Descarga el binario estándar (no la versión .NET) desde:

```text
https://godotengine.org/download/linux/
```

2. Descomprime el archivo y dale permisos de ejecución:

```bash
chmod +x Godot_v4.7.2-stable_linux.x86_64
```

3. Comprueba la versión:

```bash
./Godot_v4.7.2-stable_linux.x86_64 --version
```

4. Usa ese binario con el proyecto:

```bash
make run GODOT="$PWD/Godot_v4.7.2-stable_linux.x86_64"
```

También puedes añadirlo a `PATH` como `godot` o `godot4`.

Para ver todos los atajos disponibles:

```bash
make help
```

---

## 2. Diagnóstico

```bash
make doctor
```

Comprueba:

- Que el ejecutable de Godot existe y su versión.
- Que `project.godot` y `export_presets.cfg` están presentes.
- La ruta esperada de las plantillas de exportación.
- Si hay entorno gráfico.
- La ruta aproximada del archivo de guardado.

`make doctor` no falla si faltan las plantillas; solo avisa. Para que falle una comprobación de exportación usa `make export-check`, que termina con error cuando faltan plantillas.

---

## 3. Ejecutar el juego

### Con ventana

```bash
make run
```

Equivale a:

```bash
godot --path .
```

Puedes pasar argumentos adicionales a Godot:

```bash
make run ARGS='--editor'
make run ARGS='--verbose'
```

El menú principal permite iniciar una partida, continuar desde el punto de control, cargar una ranura, abrir ajustes o salir. Durante la aventura, **Esc** abre el menú de pausa.

Para detener una ejecución en primer plano, pulsa **Ctrl+C** en la terminal. Para una ejecución en segundo plano usa `make stop` (ver más abajo).

### Sin ventana (headless)

Útil para servidores, CI o comprobar que el proyecto arranca:

```bash
make run-headless
```

El juego real no tiene una salida automática, así que este comando se queda ejecutándose. Para una comprobación corta usa la prueba automática:

```bash
make test
```

### En segundo plano

```bash
make run-bg
```

Crea:

- `.run/godot.pid`: PID del proceso.
- `.run/godot.log`: salida estándar y errores.

Puedes combinar con headless:

```bash
make run-bg ARGS='--headless'
```

---

## 4. Detener el juego

```bash
make stop
```

El script `tools/stop.sh`:

1. Lee `.run/godot.pid`.
2. Envía `SIGTERM`.
3. Espera hasta 5 segundos.
4. Si sigue vivo, envía `SIGKILL`.
5. Elimina el archivo de PID.

Si el PID ya no existe, limpia el archivo sin hacer nada más.

> `make stop` solo detiene procesos lanzados con `make run-bg`. No mata otras instancias de Godot abiertas manualmente.

---

## 5. Prueba automática

```bash
make test
```

Equivale a:

```bash
godot --headless --path . res://tests/SmokeTest.tscn
```

La suite comprueba:

- Parser y normalización de comandos.
- Las 14 salas, conexiones y NPC.
- Impactos de cordura y estados.
- Inventario, requisitos y consumo de la llave.
- Guardado, carga, borrado y restauración de objetos retirados.
- Punto de control automático, recuperación con `continuar` y borrado conjunto.
- Tres ranuras manuales, sus metadatos y su aislamiento del autoguardado.
- Menú inicial, pausa, nueva partida, reanudación y preferencias persistentes.
- Accesibilidad: escala de texto, contraste y reducción del efecto CRT.
- Controles de audio ambiental y persistencia de ajustes.
- Efecto opcional de escritura progresiva y modo de presentación instantánea.
- Reloj narrativo, coste temporal del descanso y persistencia del estado del hotel.
- Investigación de la aduana, la bodega de Zadok, la refinería y Devil Reef; requisitos, retornos y pruebas obtenidas.
- Las cinco rutas de victoria y el final trágico.
- Panel de objetivo y mensajes de la UI.

La prueba usa `user://smoketest_save.json` y lo borra al terminar, sin tocar la partida real.

Salida esperada:

```text
SMOKE TEST: OK
```

---

## 6. Guardado y carga

El juego guarda en JSON dentro de los datos de usuario de Godot:

```text
~/.local/share/godot/app_userdata/Innsmouth Protocol/innsmouth_save.json
```

En Windows suele estar en:

```text
%APPDATA%\Godot\app_userdata\Innsmouth Protocol\innsmouth_save.json
```

Comandos dentro del juego:

| Comando | Efecto |
|---|---|
| `guardar` | Guarda cordura, inventario, sala, diálogos, banderas y objetos retirados. |
| `cargar` | Restaura la partida de la ranura manual seleccionada. |
| `continuar` | Recupera el último punto de control automático. |
| `objetivo` | Muestra el objetivo actual y actualiza el panel lateral. |
| `borrar` | Elimina la ranura manual seleccionada y el punto de control automático. |

El guardado manual está en `user://innsmouth_save.json`; las ranuras 2 y 3 usan `user://innsmouth_save_2.json` y `user://innsmouth_save_3.json`. El punto de control, independiente, está en `user://innsmouth_autosave.json`. El menú permite seleccionar cualquier ranura manual y recuperar el autoguardado mediante **Continuar**.

El punto de control se actualiza tras cada acción mientras la partida sigue activa y conserva el último estado jugable ante una derrota. Las preferencias de audio y accesibilidad se almacenan aparte en `user://settings.cfg`.

El reloj de la historia parte de las 21:00. `esperar` añade una hora y descansar en la habitación 7 del Hotel Gillman añade seis horas y recupera cordura una única vez. El tiempo y la recuperación usan las banderas del jugador, por lo que se conservan en guardados sin cambiar su versión de formato. Actualmente el reloj añade contexto narrativo, no límites de tiempo.

El guardado incluye una versión (`version: 1`). Si cambias el formato de forma incompatible, sube `VERSION_GUARDADO` en `scripts/autoload/SaveManager.gd`.

---

## 7. Limpieza

### Limpieza normal

```bash
make clean
```

Borra:

- `.godot/`: caché de importación, clases globales y metadatos del editor.
- `.run/`: PID y logs de ejecución en segundo plano.
- Archivos `*.tmp` y restos de exportaciones interrumpidas.

Conserva `build/`.

### Limpieza completa

```bash
make clean-all
```

Además borra `build/`, donde van los ejecutables exportados.

Si el juego sigue ejecutándose, la limpieza se niega a borrar `.run/`. Detén primero con `make stop` o fuerza con:

```bash
bash tools/clean.sh --force
```

> Borrar `.godot/` es seguro: Godot lo reconstruye al volver a abrir o importar el proyecto. La primera ejecución después de limpiar puede tardar algo más.

---

## 8. Problemas frecuentes

### `Identifier "RoomManager" not declared in the current scope`

Falta la caché de clases globales de Godot. Fuerza un escaneo:

```bash
make import
# o:
godot --headless --editor --quit --path .
```

Después repite `make test` o `make run`.

### No hay servidor gráfico

```text
ERROR: no hay servidor gráfico.
```

Usa `make run-headless` o ejecuta desde una sesión de escritorio. Para comprobar el arranque sin ventana, `make test` es más rápido.

### Godot no encontrado

```bash
make doctor GODOT=/ruta/a/godot
make run GODOT=/ruta/a/godot
```

### El autobús no aparece / no hay victoria

La victoria principal requiere:

1. Coger la **llave oxidada** en la plaza.
2. Abrir el relicario de la **iglesia de Dagon** y coger la **tiara de Innsmouth**.
3. Volver a la **parada del autobús**.
4. Usar el **billete de autobús**.

También puedes escapar por cuatro rutas alternativas:

- Explora la cámara bajo el arrecife y usa la placa de cobre en la parada.
- Investiga la refinería de Marsh, coge el libro de cuentas de la oficina y enséñaselo a Joe.
- Visita a Zadok Allen en la bodega y lleva su cuaderno a la parada.
- Llega a la gruta de Devil Reef y usa el cuaderno de la expedición con Joe.

Las rutas opcionales son independientes; se puede terminar la aventura sin recorrerlas.

### El guardado no carga

Comprueba que existe el archivo y que su `version` es la esperada. Si el JSON está corrupto, el juego muestra un error y no modifica la partida actual. Puedes borrarlo con `borrar` o eliminar el archivo manualmente.

### La exportación falla por plantillas

Es el error esperado si no están instaladas:

```bash
make install-templates
make export-check
make build
```

Consulta `docs/BUILD.md` para la instalación manual y las rutas exactas.
