extends Node
## Estado persistente de la partida. Al ser un Autoload sobrevive a los cambios
## de escena y centraliza cordura, inventario, flags narrativos y progreso.

signal cordura_cambiada(valor_actual: int, delta: int)
signal inventario_cambiado(inventario: Array[String])
signal alucinacion(texto: String)
signal umbral_panico(activo: bool)
signal derrota(motivo: String)
signal victoria(motivo: String)

const CORDURA_MAXIMA := 100
const UMBRAL_INQUIETUD := 60
const UMBRAL_PANICO := 30

const INVENTARIO_INICIAL: Array[String] = [
	"billete_autobus",
	"revolver_viejo",
]

const ALUCINACIONES: Array[String] = [
	"Alguien pronuncia tu nombre desde el otro lado del camino. Cuando giras la cabeza, solo hay juncos.",
	"Durante un instante, todas las ventanas de la calle tienen la misma cortina. Luego vuelven a ser distintas.",
	"El olor a pescado se vuelve tan intenso que puedes saborearlo. No has comido nada desde Newburyport.",
	"Bajo tus pies, el suelo parece húmedo y blando, como si caminaras sobre el lomo de algo enorme.",
	"Una voz con demasiadas vocales te pregunta si ya has encontrado la llave. No hay nadie a tu lado.",
	"Las sombras se inclinan hacia ti, con la paciencia de quien lleva siglos esperando.",
	"Parpadeas y, por un momento, tus manos tienen membranas entre los dedos.",
]

var salud_mental: int = CORDURA_MAXIMA
var inventario: Array[String] = []
var habitacion_actual: String = ""
var visitados: Dictionary = {}
var objetos_examinados: Dictionary = {}
var banderas: Dictionary = {}
var progreso_dialogos: Dictionary = {}
var partida_terminada: bool = false
var partida_ganada: bool = false


func _ready() -> void:
	reset()


## Devuelve la partida a su estado inicial. Se llama al arrancar y al reiniciar.
func reset() -> void:
	salud_mental = CORDURA_MAXIMA
	inventario.clear()
	for objeto in INVENTARIO_INICIAL:
		inventario.append(objeto)
	habitacion_actual = ""
	visitados.clear()
	objetos_examinados.clear()
	banderas.clear()
	progreso_dialogos.clear()
	partida_terminada = false
	partida_ganada = false

	cordura_cambiada.emit(salud_mental, 0)
	_emitir_inventario()


## Aplica un cambio de cordura, actualiza umbrales y decide si aparece una
## alucinación. Devuelve el valor resultante para facilitar composición.
func modificar_cordura(cantidad: int) -> int:
	if partida_terminada:
		return salud_mental

	var anterior := salud_mental
	salud_mental = clampi(salud_mental + cantidad, 0, CORDURA_MAXIMA)
	var delta := salud_mental - anterior

	if delta == 0:
		return salud_mental

	cordura_cambiada.emit(salud_mental, delta)
	_comprobar_umbrales(anterior)

	if salud_mental <= 0:
		partida_terminada = true
		derrota.emit(
			"Tu mente se quiebra como un espejo bajo el agua. Las casas de Innsmouth se inclinan para mirarte y, por fin, comprendes lo que hay detrás de sus ventanas."
		)
		return salud_mental

	_comprobar_alucinacion(delta)
	return salud_mental


func _comprobar_umbrales(anterior: int) -> void:
	if anterior > UMBRAL_PANICO and salud_mental <= UMBRAL_PANICO:
		umbral_panico.emit(true)
	elif anterior <= UMBRAL_PANICO and salud_mental > UMBRAL_PANICO:
		umbral_panico.emit(false)


func _comprobar_alucinacion(delta: int) -> void:
	if salud_mental > UMBRAL_INQUIETUD:
		return

	var probabilidad := 0.12
	if salud_mental <= UMBRAL_PANICO:
		probabilidad = 0.60
	elif salud_mental <= 45:
		probabilidad = 0.32

	# Recuperar cordura calma temporalmente las voces.
	if delta > 0:
		probabilidad *= 0.30

	if randf() < probabilidad:
		alucinacion.emit(ALUCINACIONES.pick_random())


func _emitir_inventario() -> void:
	var copia: Array[String] = []
	copia.append_array(inventario)
	inventario_cambiado.emit(copia)


func estado_texto() -> String:
	if partida_ganada:
		return "Superviviente"
	if salud_mental > UMBRAL_INQUIETUD:
		return "Lúcido"
	if salud_mental > UMBRAL_PANICO:
		return "Inquieto"
	if salud_mental > 10:
		return "Al borde del abismo"
	return "Quebrado"


func en_panico() -> bool:
	return salud_mental <= UMBRAL_PANICO


func agregar_objeto(objeto_id: String) -> bool:
	if objeto_id.is_empty() or inventario.has(objeto_id):
		return false
	inventario.append(objeto_id)
	_emitir_inventario()
	return true


func quitar_objeto(objeto_id: String) -> bool:
	var indice := inventario.find(objeto_id)
	if indice == -1:
		return false
	inventario.remove_at(indice)
	_emitir_inventario()
	return true


func tiene_objeto(objeto_id: String) -> bool:
	return inventario.has(objeto_id)


func marcar_visitado(habitacion_id: String) -> void:
	visitados[habitacion_id] = true


func ha_visitado(habitacion_id: String) -> bool:
	return visitados.has(habitacion_id)


func marcar_examinado(clave: String) -> void:
	objetos_examinados[clave] = true


func ya_examinado(clave: String) -> bool:
	return objetos_examinados.has(clave)


func poner_bandera(clave: String, valor: Variant = true) -> void:
	banderas[clave] = valor


func bandera(clave: String, valor_por_defecto: Variant = false) -> Variant:
	return banderas.get(clave, valor_por_defecto)


func marcar_victoria(motivo: String) -> void:
	if partida_terminada:
		return
	partida_terminada = true
	partida_ganada = true
	victoria.emit(motivo)


## Serialización estable para guardados. Solo datos primitivos y diccionarios.
func serializar() -> Dictionary:
	var copia_inventario: Array[String] = []
	copia_inventario.append_array(inventario)
	return {
		"salud_mental": salud_mental,
		"inventario": copia_inventario,
		"habitacion_actual": habitacion_actual,
		"visitados": visitados.duplicate(true),
		"objetos_examinados": objetos_examinados.duplicate(true),
		"banderas": banderas.duplicate(true),
		"progreso_dialogos": progreso_dialogos.duplicate(true),
		"partida_terminada": partida_terminada,
		"partida_ganada": partida_ganada,
	}


## Restaura el estado desde un guardado. Valida tipos para no confiar en el JSON.
func deserializar(datos: Dictionary) -> void:
	salud_mental = clampi(int(datos.get("salud_mental", CORDURA_MAXIMA)), 0, CORDURA_MAXIMA)
	habitacion_actual = str(datos.get("habitacion_actual", ""))

	inventario.clear()
	var inventario_bruto: Variant = datos.get("inventario", [])
	if inventario_bruto is Array:
		for objeto in inventario_bruto:
			if objeto is String and not inventario.has(objeto):
				inventario.append(objeto)

	visitados = _diccionario_seguro(datos.get("visitados", {})).duplicate(true)
	objetos_examinados = _diccionario_seguro(datos.get("objetos_examinados", {})).duplicate(true)
	banderas = _diccionario_seguro(datos.get("banderas", {})).duplicate(true)
	progreso_dialogos = _progreso_seguro(datos.get("progreso_dialogos", {}))

	partida_ganada = bool(datos.get("partida_ganada", false))
	partida_terminada = bool(datos.get("partida_terminada", false)) or partida_ganada
	if salud_mental <= 0:
		partida_terminada = true
		partida_ganada = false

	cordura_cambiada.emit(salud_mental, 0)
	_emitir_inventario()


func _diccionario_seguro(valor: Variant) -> Dictionary:
	if valor is Dictionary:
		return valor
	return {}


func _progreso_seguro(valor: Variant) -> Dictionary:
	var resultado: Dictionary = {}
	if not valor is Dictionary:
		return resultado

	for clave in valor:
		if clave is String:
			resultado[str(clave)] = maxi(0, int(valor[clave]))
	return resultado
