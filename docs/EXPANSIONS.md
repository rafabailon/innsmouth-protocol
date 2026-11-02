# Ampliaciones implementadas

El proyecto contiene una aventura de terminal con cinco rutas de escape, persistencia y un panel de objetivo. Las investigaciones opcionales de Zadok Allen, Devil Reef y la refinería de Marsh amplían las pistas sobre el pueblo y la Orden Esotérica de Dagon.

---

## 1. Resumen de lo nuevo

| Ampliación | Dónde vive |
|---|---|
| Guardado/carga/borrado en JSON | `scripts/autoload/SaveManager.gd` + comandos en `Game.gd` |
| Puntos de control automáticos y comando `continuar` | `SaveManager.gd` + `Game.gd` |
| Serialización de la partida | `PlayerState.serializar()` / `deserializar()` |
| Serialización de objetos retirados | `RoomManager.serializar_objetos()` / `deserializar_objetos()` |
| Iglesia de Dagon | `RoomDatabase._iglesia_dagon()` |
| Hotel Gillman | `RoomDatabase._hotel_gillman()` |
| Aduana, pasadizo y cámara bajo el arrecife | `RoomDatabase._archivo_aduana()` / `_tunel_bajo_muelle()` / `_camara_arrecife()` |
| Libro de mareas y requisitos de conexiones | `ItemDB.OBJETOS["libro_mareas"]` + `Room.requisitos_conexiones` |
| Placa de cobre y ruta de escape alternativa | `ItemDB.OBJETOS["placa_aduana"]` + `Game._usar()` |
| Refinería de Marsh, oficina y cuentas de Devil Reef | `RoomDatabase._refineria_marsh()` / `_oficina_refineria()` + `ItemDB.OBJETOS["libro_cuentas_marsh"]` |
| Bodega de Zadok Allen y su testimonio | `RoomDatabase._bodega_zadok()` / `_zadok_allen()` + `ItemDB.OBJETOS["cuaderno_zadok"]` |
| Cornisa, gruta y expedición de Devil Reef | `RoomDatabase._borde_devils_reef()` / `_gruta_devils_reef()` + `ItemDB.OBJETOS["cuaderno_buzo"]` |
| Sacerdote de Dagon | `RoomDatabase._sacerdote_dagon()` |
| Tiara de Innsmouth | `ItemDB.OBJETOS["tiara_innsmouth"]` |
| Requisito de objeto | `Room.requisitos_objetos` + `Game._coger()` |
| Condición de victoria | `PlayerState.marcar_victoria()` + `Game._usar()` |
| Panel de objetivo | `Main.tscn` + `TerminalUI.actualizar_objetivo()` |
| Comandos nuevos | `guardar`, `cargar`, `continuar`, `borrar`, `objetivo` |
| Menú principal, pausa y tres ranuras | `scripts/ui/MainMenu.gd` + `SaveManager.gd` |
| Ajustes y accesibilidad persistentes | `scripts/autoload/SettingsManager.gd` + `TerminalUI.gd` |
| Audio ambiental sintetizado | `assets/audio/innsmouth_ambience.wav` + `tools/generate-ambience.py` |
| Tipografía redistribuible empaquetada | `assets/fonts/DejaVuSansMono.ttf` + aviso de licencia |
| Pruebas ampliadas | `tests/SmokeTest.gd` |

---

## 2. Recorrido de la ampliación (spoilers)

1. Llegas a la parada del autobús. El panel muestra el objetivo inicial: encontrar la llave oxidada.
2. En la plaza recoges la **llave oxidada**.
3. Al este de la plaza está la **iglesia de Dagon**. Si intentas coger la tiara sin la llave, el relicario se niega y muestra un mensaje.
4. Con la llave, el relicario se abre. La llave se consume y obtienes la **tiara de Innsmouth**.
5. Al norte de la plaza, el **hotel Gillman** ofrece un pequeño respiro: descansar en la habitación 7 hace avanzar seis horas y recupera 6 puntos de cordura una sola vez.
6. Con la tiara, vuelve a la parada y usa el **billete de autobús**. Se activa la victoria.
7. Si la cordura llega a 0 antes, se mantiene el final trágico original.

### Investigación opcional del puerto

Desde el muelle puedes entrar en la vieja aduana. El cajón del libro de mareas está cerrado con una concha negra, encontrada en el camino a Innsmouth. El libro permite calcular cuándo descender por las escaleras; bajo el muelle encontrarás registros de quienes volvieron con la marea.

En el pasadizo, `entrar` lleva a la cámara si conservas el libro y la concha. Allí, examinar la lista descubre que el protagonista figura entre los pasajeros previstos y permite coger una placa de cobre. Al mostrarla a Joe en la parada se activa un final alternativo sin la tiara. La ruta principal de la iglesia sigue disponible.

### Refinería de Marsh

Desde la plaza, `noreste` conduce a una refinería que oficialmente lleva décadas cerrada. El capataz habla de Obed Marsh y de una maquinaria que todavía golpea tras las paredes. Entra en la oficina para encontrar el libro de cuentas: sus registros enlazan el oro de Devil Reef con pagos a familias de Innsmouth. Mostrar el libro a Joe en la parada abre un final alternativo; esta ruta no requiere visitar el arrecife ni conseguir la tiara.

### El testimonio de Zadok Allen

Desde el camino a Innsmouth, `norte` baja a la bodega del Ancla. Zadok Allen recuerda los barcos que volvían de Devil Reef y el cambio que sufrió el pueblo tras el trato de Obed Marsh. Su cuaderno conserva nombres y fechas que coinciden con los recuerdos de Joe; mostrárselo en la parada abre un final propio.

### La expedición de Devil Reef

Después de llegar a la cámara bajo el arrecife, `abajo` conduce a una cornisa y `dentro` a una gruta. Ambas salidas tienen retorno. La entrada requiere el libro de mareas y la concha negra; en la gruta se encuentra el cuaderno de una expedición perdida. Sus observaciones permiten a Joe identificar el barco y aceptar la huida.

La victoria no exige un mínimo de cordura: es posible escapar al borde del abismo, pero el camino cuesta salud mental.

---

## 3. Guardado y carga

### Formato

`SaveManager.guardar()` envuelve los datos con metadatos:

```json
{
  "version": 1,
  "guardado_en": "2026-11-02T13:00:00",
  "jugador": {
    "salud_mental": 25,
    "inventario": ["billete_autobus", "revolver_viejo", "llave_oxidada"],
    "habitacion_actual": "muelle",
    "visitados": { "parada_autobus": true, "muelle": true },
    "objetos_examinados": { "item:llave_oxidada": true },
    "banderas": { "conocio:joe_sargent": true },
    "progreso_dialogos": { "joe_sargent": 2 },
    "partida_terminada": false,
    "partida_ganada": false
  },
  "mapa": {
    "camino_innsmouth": ["concha_ritual"],
    "plaza_pueblo": ["llave_oxidada"]
  }
}
```

### Garantías

- La ruta se puede cambiar con `SaveManager.usar_ruta(...)` para pruebas.
- La carga valida que el JSON sea un diccionario y que la versión coincida.
- Los tipos se normalizan: cordura entre 0 y 100, inventario solo con strings, progreso de diálogos con enteros no negativos.
- Si la cordura guardada es 0, la partida se restaura como derrota.
- La carga restaura también los objetos ya retirados de cada sala.

### Añadir campos nuevos

1. Añade el campo a `PlayerState.serializar()`.
2. Restáuralo con validación en `PlayerState.deserializar()`.
3. Si el cambio rompe guardados anteriores, incrementa `VERSION_GUARDADO` en `SaveManager.gd`.
4. Añade una comprobación en `tests/SmokeTest.gd`.

---

## 4. Requisitos de objetos

`Room` incorpora:

```gdscript
@export var requisitos_objetos: Dictionary = {}
```

Formato recomendado:

```gdscript
sala.requisitos_objetos = {
    "medallon": {
        "objetos": ["llave_oxidada"],
        "consumir": ["llave_oxidada"],
        "mensaje": "La vitrina está cerrada con una cerradura de hierro.",
    },
}
```

También se admite un array como atajo:

```gdscript
sala.requisitos_objetos = { "medallon": ["llave_oxidada"] }
```

`Game._coger()` comprueba los requisitos antes de retirar el objeto. Si falta algo, muestra `mensaje` o genera uno automático. Si se cumple, retira los objetos de `consumir` y añade el objeto al inventario.

Para requisitos más complejos (banderas, cordura, haber hablado con alguien), amplía `Game._coger()` o crea un método `cumple_requisito()` en `Room`/`Game`.

---

## 5. Requisitos de conexiones

Las salas pueden declarar objetos necesarios para usar una salida en `requisitos_conexiones`. `Game._mover()` comprueba el requisito antes de cambiar de habitación:

```gdscript
sala.requisitos_conexiones = {
    "dentro": {
        "objetos": ["concha_ritual", "libro_mareas"],
        "mensaje": "La abertura sigue cerrada.",
    },
}
```

También se admite un array de IDs como atajo. Este mecanismo gobierna tanto el acceso al pasadizo como el cruce a la cámara. Después se valida que el destino exista.

---

## 6. Rutas de victoria

En `Game._usar()`, el billete con la tiara activa la ruta principal. La placa, el libro de cuentas de Marsh, el cuaderno de Zadok o el cuaderno de Devil Reef activan rutas alternativas al usarlos en la parada. Todas llaman a `PlayerState.marcar_victoria(motivo)`, que marca la partida como terminada y ganada, emite la señal `victoria(motivo)` y permite a `Game._al_victorizar()` mostrar el epílogo correspondiente.

---

## 7. Salas y contenido nuevo

### Iglesia de Dagon

- Conexión: plaza → este.
- Primera visita: −5 de cordura.
- NPC: sacerdote de Dagon, con tres diálogos y despedida.
- Objeto: tiara de Innsmouth, protegida por el relicario.
- Examinables: altar, relicario, vidrieras, bancas, campana.

### Hotel Gillman

- Conexión: plaza → norte.
- Primera visita: −1 de cordura.
- Examinables: recepción, libro de registro, espejo, escaleras y la habitación 7.
- La habitación 7 recupera 6 puntos de cordura una sola vez y avanza seis horas. El tiempo se conserva al guardar; esperar en otras salas avanza una hora.

### Pasadizo y cámara bajo el arrecife

- Conexión: muelle → abajo; requiere el libro de mareas.
- Conexión: pasadizo → dentro; requiere el libro de mareas y la concha negra.
- En la cámara puedes examinar los registros y coger la placa de cobre.
- Mostrar la placa en la parada activa una ruta de victoria alternativa.

### Refinería de Marsh

- Conexión: plaza → noreste; regreso al suroeste.
- Los comandos diagonales se muestran en `ayuda`.
- Un capataz aporta contexto sobre Obed Marsh y la refinería oficialmente cerrada.
- Desde la refinería se entra en la oficina contable.
- El libro de cuentas recoge envíos de oro desde Devil Reef y permite una tercera ruta de escape.

### Bodega de Zadok Allen

- Conexión: camino a Innsmouth → norte; regreso por arriba.
- Zadok relata qué recuerda de los barcos y del trato de Obed Marsh.
- El cuaderno de Zadok abre una ruta de escape basada en su testimonio.

### Devil Reef

- Conexión: cámara bajo el arrecife → abajo; requiere libro de mareas y concha negra.
- La cornisa conecta con la gruta; ambas salas tienen salida de regreso.
- El cuaderno de la expedición documenta una ruta y permite otro final alternativo.

### Objetos

La tiara tiene textos propios de descripción y uso, y aplica −2 al examinarla y −3 al cogerla.

---

## 8. Panel de objetivo

`Main.tscn` añade un `Label` llamado `Objetivo` con `unique_name_in_owner = true`. `TerminalUI.actualizar_objetivo(texto)` lo actualiza.

`Game._objetivo_actual()` decide el texto según el estado:

1. Partida ganada → mensaje de escape.
2. Partida terminada → mensaje de derrota.
3. Tiene la tiara → volver a la parada y usar el billete.
4. Tiene una prueba del arrecife, las cuentas de Marsh o un cuaderno → puede mostrarlos en la parada o seguir investigando.
5. Tiene la llave → abrir el relicario.
6. En otro caso → encontrar la llave.

Se refresca al entrar en una sala, al cambiar el inventario y al terminar la partida. El comando `objetivo` muestra la misma información en el historial.

---

## 9. Pruebas

`make test` ejecuta la suite de humo. Las comprobaciones cubren:

- Existencia y conexiones de las catorce salas.
- Requisito de la tiara y consumo de la llave.
- Bloqueo de la tiara sin llave.
- Guardado, modificación, carga y restauración de sala, cordura, inventario, diálogos y objetos retirados.
- Borrado del guardado y aviso al cargar sin archivo.
- Victoria con la tiara y rutas alternativas con la placa, las cuentas de Marsh y los cuadernos.
- Derrota en una partida nueva.
- Objetivo inicial, intermedio y final.
- Acceso a la aduana, la bodega de Zadok, la refinería y Devil Reef; requisitos, retornos y finales alternativos.

La prueba aísla el guardado en `user://smoketest_save.json`.

---

## 10. Menú, guardados, accesibilidad y recursos

El menú inicial ofrece nueva partida, continuación desde el autoguardado, carga de una ranura, ajustes y salida. **Esc** abre la pausa durante el juego; desde allí se puede reanudar, guardar en tres ranuras, cargar, abrir ajustes o volver al inicio. La ranura 1 conserva la ruta de guardado anterior para no perder partidas existentes.

La pantalla de ajustes guarda el tamaño de texto, alto contraste, reducción de las líneas CRT, activación del audio y volumen en `user://settings.cfg`. El punto de control automático sigue usando su archivo independiente.

La escritura progresiva de la terminal es opcional, se activa desde Ajustes y se guarda como preferencia. Al desactivarla, el texto vuelve a mostrarse inmediatamente. La prueba automatizada comprueba el revelado gradual y el regreso al modo instantáneo.

El reloj comienza a las 21:00 y el descanso en el hotel hace avanzar hasta seis horas. Es un coste narrativo persistente, sin impedir rutas ni forzar un final.

El sonido es un WAV mono original de ocho segundos, generado de forma determinista con la biblioteca estándar de Python. Para regenerarlo:

```bash
make generate-ambience
```

La tipografía es DejaVu Sans Mono; su aviso de redistribución está en `assets/fonts/LICENSE-DejaVu.txt`. El tema la carga directamente desde `assets/fonts/DejaVuSansMono.ttf`.

Una posible ampliación futura es hacer que ciertas pistas o encuentros respondan al horario del reloj sin bloquear el avance principal.
