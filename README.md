# Innsmouth Protocol

Ficción interactiva de terminal inspirada en *La sombra sobre Innsmouth* de H. P. Lovecraft. Proyecto para **Godot 4.x** escrito íntegramente en GDScript, con una interfaz retro de fósforo verde, ámbar y rojo apagado.

La aventura ofrece cinco rutas de escape: la tiara de la iglesia, la placa de la aduana, las cuentas de Marsh, el testimonio de Zadok Allen o el cuaderno de una expedición a Devil Reef. La cordura sigue siendo el precio de mirar demasiado.

---

## Inicio rápido

```bash
make install  # prepara Godot, importa el proyecto y ejecuta las pruebas
make run      # abre el juego con ventana
make test     # prueba automática headless
```

El proyecto usa la versión estable actual verificada, **Godot 4.7.2**. El instalador reutiliza la versión estable compatible más alta instalada (4.7.2 o superior); si no encuentra ninguna, descarga 4.7.2 en `.tools/godot/`. Para preparar también la exportación (descarga grande):

```bash
make install INSTALL_ARGS=--templates
```

También puedes abrir `project.godot` en Godot 4.7.2 o superior y pulsar **F5**.

Si Godot no está en `PATH`:

```bash
make run GODOT=/ruta/a/godot
```

---

## Operaciones

| Comando | Qué hace |
|---|---|
| `make install` | Instala o detecta Godot, importa el proyecto y ejecuta las pruebas. |
| `make install INSTALL_ARGS=--templates` | Además descarga e instala las plantillas oficiales. |
| `make doctor` | Diagnóstico de Godot, proyecto, plantillas y entorno gráfico. |
| `make import` | Fuerza el escaneo/importación de recursos. |
| `make run` | Ejecuta el juego con ventana. |
| `make run-headless` | Ejecuta sin ventana. |
| `make run-bg` | Lanza en segundo plano con PID y log en `.run/`. |
| `make stop` | Detiene la instancia lanzada con `run-bg`. |
| `make test` | Ejecuta `tests/SmokeTest.tscn` en headless. |
| `make check` | Importa el proyecto y ejecuta la prueba de humo. |
| `make build` | Exporta Linux a `build/linux/`. |
| `make build-windows` | Exporta Windows a `build/windows/`. |
| `make export-check` | Valida preset y plantillas sin exportar. |
| `make install-templates` | Descarga las plantillas oficiales (~1,2 GB). |
| `make generate-ambience` | Regenera el audio ambiental original con Python 3. |
| `make clean` | Borra caché `.godot/` y temporales `.run/`. |
| `make clean-all` | Además borra `build/`. |

Guías detalladas:

- [`docs/OPERATIONS.md`](docs/OPERATIONS.md): ejecutar, detener, probar, guardar y limpiar.
- [`docs/BUILD.md`](docs/BUILD.md): plantillas de exportación, presets y artefactos.
- [`docs/EXPANSIONS.md`](docs/EXPANSIONS.md): ampliaciones implementadas y cómo extenderlas.

---

## Compilar y exportar

Godot no compila GDScript a código nativo: empaqueta el proyecto con una **plantilla de exportación**. La plantilla debe coincidir con la versión del editor.

```bash
make install-templates   # solo la primera vez; descarga ~1,2 GB
make export-check        # valida preset y plantillas
make build               # Linux -> build/linux/innsmouth-protocol.x86_64
make build-windows       # Windows -> build/windows/innsmouth-protocol.exe
```

`make install` no descarga las plantillas de exportación por defecto: ocupan alrededor de 1,2 GB y solo hacen falta para generar ejecutables distribuibles. El instalador comprueba que las pruebas terminen correctamente antes de finalizar.

La salida incluye el ejecutable y un `.pck` separado. Para probarla:

```bash
./build/linux/innsmouth-protocol.x86_64
```

Si `make export-check` falla, normalmente faltan las plantillas en:

```text
~/.local/share/godot/export_templates/4.7.2.stable/
```

Puedes indicar otra ruta de salida con `EXPORT_PATH=...`. Todos los detalles, incluida la instalación manual de plantillas y las notas de CI, están en [`docs/BUILD.md`](docs/BUILD.md).

---

## Controles

Escribe en la línea inferior y pulsa **Enter**. Las flechas **↑/↓** recuperan comandos anteriores.

| Comando | Ejemplo | Efecto |
|---|---|---|
| Movimiento | `norte`, `sur`, `este`, `oeste`, `noreste`, `suroeste` | Se mueve en esa dirección; las diagonales conectan con la refinería de Marsh. |
| Descenso | `abajo`, `descender`; regreso con `arriba` o `subir` | Explora el pasadizo desde el muelle después de encontrar el libro de mareas en la aduana. |
| Movimiento por nombre | `ir a la plaza`, `ir al muelle` | Busca una conexión cuyo destino coincida. |
| Entrar / salir | `entrar`, `salir` | Usa conexiones `dentro` / `fuera`; la cámara del arrecife requiere el libro y la concha negra. |
| Exploración | `mirar`, `examinar autobús`, `inspeccionar las casas` | Describe la sala o examina un objeto, zona o personaje. |
| Inventario | `inventario`, `items` | Lista los objetos y el estado mental. |
| Recoger | `coger concha`, `coger llave` | Añade un objeto visible al inventario si se cumplen sus requisitos. |
| Usar | `usar revólver`, `usar billete`, `usar placa` | Muestra el uso contextual; el billete con la tiara o la placa de cobre permiten escapar. |
| Hablar | `hablar con Joe Sargent`, `hablar con el sacerdote` | Avanza el diálogo del personaje. |
| Objetivo | `objetivo`, `misión` | Muestra el objetivo actual en el historial. |
| Guardado | `guardar`, `cargar`, `continuar`, `borrar` | Gestiona guardados manuales y el último punto de control automático. |
| Otros | `ayuda`, `esperar`, `descansar`, `reiniciar` | Esperar avanza una hora; descansar en la habitación 7 consume seis horas y recupera cordura una sola vez. |

El parser ignora mayúsculas, acentos, puntuación y artículos iniciales (`el`, `la`, `un`, `de`...). Por eso `MIRAR EL AUTOBÚS`, `mirar autobus` y `mirar el autobús` producen el mismo comando.

Pulsa **Esc** durante la partida para abrir el menú de pausa. Desde allí puedes guardar en una de las tres ranuras, cargar una partida, ajustar accesibilidad y audio o volver al menú principal. El menú inicial ofrece **Nueva partida**, **Continuar**, **Cargar partida**, **Ajustes** y **Salir**.

---

## Mapa

```text
                         [Hotel Gillman]
                                │
                              norte
                                │
[Parada] ──este──> [Camino] ──este──> [Plaza] ──este──> [Iglesia de Dagon]
                    │                   │
                  norte              noreste
                    ▼                   ▼
             [Bodega de Zadok]   [Refinería de Marsh]
                                        │
                                      dentro
                                        ▼
                                [Oficina de cuentas]
                                        │
                                      sur
                                        ▼
                                     [Muelle] ──este──> [Archivo de aduanas]
                                         │
                                    abajo (con el libro)
                                         ▼
                              [Pasadizo bajo el muelle]
                                         │
                              dentro (libro + concha)
                                         ▼
                              [Cámara bajo el arrecife]
                                         │
                                abajo (libro + concha)
                                         ▼
                             [Cornisa de Devil Reef]
                                         │
                                       dentro
                                         ▼
                              [Gruta de Devil Reef]

                          noreste
                 [Plaza] ───────────> [Refinería de Marsh]
                                          │
                                        dentro
                                          ▼
                                [Oficina de cuentas]
```

- **Parada del autobús:** Joe Sargent, el autobús, la carretera y las marismas. Punto de salida y de victoria.
- **Camino a Innsmouth:** casas decrépitas, ventanas, tejados, un anciano y una concha negra.
- **Bodega de Zadok Allen:** un testigo envejecido, sus recuerdos de Obed Marsh y un cuaderno con barcos desaparecidos.
- **Plaza del pueblo:** obelisco, bajorrelieves, un hombre inquietante y la llave oxidada.
- **Refinería de Marsh:** una instalación que oficialmente cerró hace años, un capataz y maquinaria que no debería funcionar.
- **Oficina de cuentas:** registros de oro procedente de Devil Reef que revelan el comercio secreto de la familia Marsh.
- **Muelle:** agua aceitosa, barcas, redes, una figura encorvada y escaleras que descienden bajo el agua.
- **Archivo de la vieja aduana:** manifiestos de cargamentos que no eran pescado y un libro que registra una ruta bajo el arrecife.
- **Pasadizo bajo el muelle:** marcas de quienes descendieron antes y una abertura hacia algo que sigue vivo bajo el arrecife. El libro de mareas permite encontrar el momento para bajar y regresar.
- **Cámara bajo el arrecife:** registros de pasajeros que aún no han llegado y una placa de cobre que puede servir como prueba para escapar.
- **Cornisa y gruta de Devil Reef:** restos de un embarcadero y de una expedición que encontró una ruta entre las rocas.
- **Iglesia de Dagon:** altar, vidrieras, bancas, campana, el sacerdote y el relicario de la tiara.
- **Hotel Gillman:** recepción desierta, libro de registro, espejo, escaleras y la habitación 7.

Los impactos de cordura se aplican **una sola vez** por sala al entrar y **una sola vez** por elemento al examinarlo. Los objetos examinados se registran en `PlayerState.objetos_examinados`; las salas visitadas, en `PlayerState.visitados`.

El reloj comienza a las 21:00. `esperar` avanza una hora; dormir en la habitación 7 del Hotel Gillman consume seis horas y recupera 6 puntos de cordura una sola vez. El tiempo y el descanso quedan guardados con la partida. El paso del tiempo es narrativo por ahora: no bloquea rutas ni provoca finales automáticos.

---

## Victoria, derrota y cordura

| Rango | Estado | Efecto |
|---|---|---|
| 100–61 | Lúcido | Sin distorsiones. |
| 60–31 | Inquieto | Barra ámbar, susurros ambientales ocasionales. |
| 30–1 | Al borde del abismo | Barra roja, pánico, textos con efecto `[shake]`, descripciones corrompidas y más alucinaciones. |
| 0 | Quebrado | Final trágico; solo se permite `reiniciar`, `cargar`, `continuar`, `objetivo` o `ayuda`. |

### Rutas de victoria

**Ruta de la tiara**

1. Coger la **llave oxidada** en la plaza.
2. Abrir el relicario de la **iglesia de Dagon** y coger la tiara. La llave se consume.
3. Volver a la parada y usar el **billete de autobús**.

**Ruta de la aduana**

1. Encontrar la concha negra en el camino y el libro de mareas en la aduana.
2. Bajar al pasadizo y cruzar la abertura con ambos objetos.
3. Examinar los registros, coger la placa de cobre y volver a la parada.
4. Usar la **placa de cobre** para convencer a Joe y escapar sin la tiara.

**Ruta de la refinería**

1. Desde la plaza, seguir al nordeste hasta la refinería de Marsh.
2. Hablar con el capataz, entrar en la oficina y coger el **libro de cuentas**.
3. Regresar a la parada y mostrar las cuentas a Joe.

**Ruta de Zadok**

1. Desde el camino, bajar a la bodega del Ancla y hablar con Zadok Allen.
2. Leer su cuaderno, que registra barcos que volvieron de Devil Reef sin tripulación.
3. Llevarlo a Joe en la parada.

**Ruta de Devil Reef**

1. Conseguir el libro de mareas y la concha negra para cruzar la cámara bajo el arrecife.
2. Desde la cámara, bajar a la cornisa y entrar en la gruta.
3. Recuperar el cuaderno de la expedición y mostrárselo a Joe.

La rama de Zadok introduce un testigo que recuerda el trato de Obed Marsh; la de Devil Reef añade una cornisa, una gruta y los restos de una expedición perdida. Ambas son opcionales, tienen un recorrido de regreso y permiten un final propio. Las cinco rutas no exigen un mínimo de cordura.

La victoria es narrativa y termina la partida. El panel lateral muestra el objetivo en cada momento y el comando `objetivo` lo repite en el historial.

---

## Guardado

La partida se guarda en JSON dentro de los datos de usuario de Godot:

```text
~/.local/share/godot/app_userdata/Innsmouth Protocol/innsmouth_save.json
```

El punto de control automático está junto al guardado manual, en `innsmouth_autosave.json`.

Incluye cordura, inventario, sala actual, salas visitadas, objetos examinados, banderas, progreso de diálogos, estado de victoria/derrota y objetos retirados de cada sala.

- `guardar` escribe el archivo.
- `cargar` restaura la partida de la ranura manual seleccionada.
- `continuar` recupera el último punto de control, que se actualiza al realizar acciones y conserva el último estado jugable si ocurre una derrota.
- `borrar` elimina la ranura manual seleccionada y el punto de control automático.
- El menú permite guardar y cargar cualquiera de las tres ranuras. La primera conserva el nombre histórico `innsmouth_save.json`; las otras son `innsmouth_save_2.json` y `innsmouth_save_3.json`.
- La versión del formato está en `SaveManager.VERSION_GUARDADO`.
- Las preferencias se guardan aparte en `user://settings.cfg`.

Las pruebas usan una ruta aislada (`user://smoketest_save.json`) para no tocar la partida real.

---

## Arquitectura

| Archivo | Responsabilidad |
|---|---|
| `scripts/autoload/PlayerState.gd` | Autoload. Cordura, inventario, flags, visitas, exámenes, diálogos, victoria/derrota y serialización. |
| `scripts/autoload/SaveManager.gd` | Autoload. Guardado/carga/borrado JSON, tres ranuras manuales y punto de control separado. |
| `scripts/autoload/SettingsManager.gd` | Autoload. Preferencias locales persistentes de accesibilidad y audio. |
| `scripts/core/Game.gd` | Orquestador. Coordina menú, partida, audio, comandos, mapa y narración. |
| `scripts/core/CommandParser.gd` | Normaliza la entrada y la convierte en `{verbo, objetivo, direccion, texto}`. No conoce la UI. |
| `scripts/core/Room.gd` | `Resource` con datos de sala, examinables y requisitos de objetos y conexiones. |
| `scripts/core/RoomManager.gd` | Carga el mapa y los paquetes, valida referencias, resuelve conexiones y serializa objetos retirados. |
| `scripts/data/ContentPackLoader.gd` | Lee y valida los paquetes JSON enumerados en el manifiesto. |
| `scripts/data/RoomDatabase.gd` | Contenido de las catorce salas base y los NPC. |
| `scripts/core/NpcData.gd` | `Resource` de personaje: nombre, alias, descripción y diálogos. |
| `scripts/core/ItemDB.gd` | Catálogo de objetos y sus textos/efectos de cordura. |
| `scripts/core/TextUtils.gd` | Normalización, artículos, coincidencia por alias y listas naturales. |
| `scripts/ui/TerminalUI.gd` | Presentación semántica: títulos, descripciones, diálogos, peligro, cordura, inventario y objetivo. |
| `scripts/ui/CRTOverlay.gd` | Capa decorativa de scanlines y viñeteado. |
| `scripts/ui/MainMenu.gd` | Menú inicial y de pausa, ranuras y ajustes. |
| `themes/terminal_theme.tres` | Tema que empaqueta DejaVu Sans Mono. |
| `assets/audio/innsmouth_ambience.wav` | Ambiente original de puerto sintetizado para este proyecto. |

### Flujo de un comando

```text
LineEdit
  → TerminalUI.comando_enviado
  → Game._al_recibir_comando
  → CommandParser.parsear
  → Game._ejecutar_comando
  → RoomManager / PlayerState / ItemDB / NpcData / SaveManager
  → TerminalUI (texto y panel lateral)
```

La UI no modifica el estado de la partida. El parser no muestra mensajes: emite `comando_invalido` y `Game` decide cómo presentarlo.

---

## Árbol de escenas

`scenes/Main.tscn`:

```text
Main (Control)                         ← Game.gd
├── Fondo (ColorRect)
├── CRT (Control)                      ← CRTOverlay.gd
├── UI (Control)                       ← TerminalUI.gd + terminal_theme.tres
│   └── Margen (MarginContainer)
│       └── Raiz (VBoxContainer)
│           ├── Cabecera (HBoxContainer)
│           ├── LineaSuperior (HSeparator)
│           ├── Cuerpo (HBoxContainer)
│           │   ├── Terminal (VBoxContainer)
│           │   │   ├── ScrollHistorial (ScrollContainer)
│           │   │   │   └── Historial (RichTextLabel, BBCode)
│           │   │   └── FilaEntrada (HBoxContainer)
│           │   │       ├── Prompt (Label ">")
│           │   │       └── Entrada (LineEdit)
│           │   └── Panel (PanelContainer)
│           │       └── MargenPanel (MarginContainer)
│           │           └── Info (VBoxContainer)
│           │               ├── Ubicacion (Label)
│           │               ├── EtiquetaObjetivo / Objetivo (Label)
│           │               ├── BarraCordura (ProgressBar)
│           │               ├── ValorCordura / EstadoCordura (Label)
│           │               ├── Inventario (RichTextLabel)
│           │               └── Advertencia (Label)
│           ├── LineaInferior (HSeparator)
│           └── Pie (Label de ayuda)
├── MainMenu (Control)                 ← MainMenu.gd
├── CommandParser (Node)               ← CommandParser.gd
└── RoomManager (Node)                 ← RoomManager.gd
```

`Game.gd` crea el reproductor de audio ambiental en tiempo de ejecución.

Autoloads:

```text
PlayerState (Node)                     ← scripts/autoload/PlayerState.gd
SaveManager (Node)                     ← scripts/autoload/SaveManager.gd
SettingsManager (Node)                 ← scripts/autoload/SettingsManager.gd
```

Los nodos con nombre único (`%Historial`, `%Entrada`, `%BarraCordura`, `%Inventario`, `%Objetivo`, etc.) se enlazan desde `TerminalUI.gd`. Si renombras alguno, actualiza su `unique_name_in_owner` o la referencia correspondiente.

---

## Pruebas

```bash
make test
```

La suite comprueba parser, las catorce salas base y el paquete de ejemplo, el encuentro condicionado por la marea, cordura, inventario, requisitos, guardado/carga/borrado, las ramas de Zadok, Marsh y Devil Reef, las cinco rutas de victoria y la derrota. Salida esperada:

```text
SMOKE TEST: OK
```

Si Godot no encuentra las clases globales tras limpiar la caché:

```bash
make import
make test
```

---

## Cómo ampliar el contenido

El proyecto carga paquetes JSON listados en [`content/expansions/manifest.json`](content/expansions/manifest.json). Puedes añadir salas, objetos, personajes, examinables y conexiones sin modificar la lógica del juego; [`docs/EXPANSIONS.md`](docs/EXPANSIONS.md) documenta el formato, la validación y cuándo hace falta código GDScript.

---

## Estado del proyecto y limitaciones

- El juego incluye ambiente de puerto original y un efecto de escritura progresiva opcional, activable desde Ajustes; todavía no tiene música.
- El menú ofrece tres ranuras manuales, un punto de control automático y controles de audio y accesibilidad.
- **La victoria y la derrota terminan la partida**; se reinicia con `reiniciar` o desde una nueva partida.
- **La exportación requiere plantillas oficiales** (~1,2 GB) que no se incluyen en el proyecto.

Los ajustes incluyen tamaño del texto, alto contraste, reducción de líneas CRT, audio ambiental y volumen. Se guardan independientemente de las partidas.

---

## Licencia y recursos

El código y el contenido original del proyecto se distribuyen bajo la licencia MIT, incluida en [`LICENSE`](LICENSE). La fuente DejaVu Sans Mono conserva su licencia Bitstream Vera, cuyo aviso está en [`assets/fonts/LICENSE-DejaVu.txt`](assets/fonts/LICENSE-DejaVu.txt). El WAV ambiental se genera localmente con el script estándar de Python [`tools/generate-ambience.py`](tools/generate-ambience.py).
