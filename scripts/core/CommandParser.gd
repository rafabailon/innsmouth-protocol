extends Node
class_name CommandParser
## Intérprete de comandos. Normaliza la entrada y la convierte en un diccionario
## estable: { verbo, objetivo, direccion, texto }. No conoce la UI ni las salas.

signal comando_invalido(texto_original: String, mensaje: String)

const DIRECCIONES := {
	"norte": "norte", "n": "norte",
	"sur": "sur", "s": "sur",
	"este": "este", "e": "este", "oriente": "este",
	"oeste": "oeste", "o": "oeste", "occidente": "oeste",
	"noreste": "noreste", "ne": "noreste",
	"noroeste": "noroeste", "noe": "noroeste",
	"sureste": "sureste", "se": "sureste",
	"suroeste": "suroeste", "so": "suroeste",
	"dentro": "dentro", "adentro": "dentro",
	"fuera": "fuera", "afuera": "fuera",
	"abajo": "abajo", "descender": "abajo", "desciende": "abajo",
	"arriba": "arriba", "subir": "arriba", "asciende": "arriba",
}

const VERBOS := {
	"mirar": "mirar", "mira": "mirar", "observar": "mirar", "ver": "mirar", "l": "mirar",
	"examinar": "examinar", "examina": "examinar", "inspeccionar": "examinar",
	"inspecciona": "examinar", "estudiar": "examinar", "x": "examinar",
	"inventario": "inventario", "inventarios": "inventario", "items": "inventario",
	"item": "inventario", "equipo": "inventario", "i": "inventario",
	"coger": "coger", "coge": "coger", "recoger": "coger", "recoge": "coger",
	"tomar": "coger", "toma": "coger", "agarrar": "coger", "agarra": "coger",
	"usar": "usar", "usa": "usar", "utilizar": "usar", "utiliza": "usar", "emplear": "usar",
	"hablar": "hablar", "habla": "hablar", "conversar": "hablar", "charlar": "hablar",
	"preguntar": "hablar", "saludar": "hablar",
	"ir": "ir", "anda": "ir", "andar": "ir", "caminar": "ir", "camina": "ir",
	"mover": "ir", "muevete": "ir", "avanzar": "ir", "avanza": "ir",
	"ayuda": "ayuda", "comandos": "ayuda", "ayudar": "ayuda",
	"reiniciar": "reiniciar", "reset": "reiniciar", "empezar": "reiniciar",
	"esperar": "esperar", "aguardar": "esperar", "descansar": "esperar",
	"guardar": "guardar", "salvar": "guardar", "save": "guardar",
	"cargar": "cargar", "load": "cargar", "recuperar": "cargar",
	"continuar": "continuar", "resume": "continuar", "reanudar": "continuar",
	"borrar": "borrar", "eliminar": "borrar", "borra": "borrar",
	"objetivo": "objetivo", "mision": "objetivo", "misión": "objetivo",
	"tarea": "objetivo", "proposito": "objetivo", "propósito": "objetivo",
}

const MENSAJES_INVALIDOS: Array[String] = [
	"No puedes hacer eso aquí... o tal vez las sombras te nublan el juicio.",
	"Las palabras se deshacen en tu boca, como sal arrastrada por la marea.",
	"Innsmouth no entiende esa orden. O tú ya no entiendes Innsmouth.",
	"Intentas recordar cómo se hacía, pero el pensamiento se escapa como un pez entre los dedos.",
	"El viento se lleva tu frase antes de que llegue a ninguna parte.",
	"No es una acción. No es una palabra. Aquí, las dos cosas pesan demasiado.",
	"La oscuridad no responde. Prueba con «ayuda» si aún confías en las palabras.",
]

var _ultimo_mensaje: int = -1


func parsear(entrada: String, emitir_invalidos: bool = true) -> Dictionary:
	var original := entrada.strip_edges()
	if original.is_empty():
		return {}

	# El signo de interrogación se trata antes de limpiar puntuación.
	if original == "?":
		return _crear("ayuda", "", "", original)

	var texto := TextUtils.normalizar(original)
	if texto.is_empty():
		return _no_reconocido(original, emitir_invalidos)

	var tokens := texto.split(" ", false)
	if tokens.is_empty():
		return _no_reconocido(original, emitir_invalidos)

	var primero := str(tokens[0])
	var resto := " ".join(tokens.slice(1))
	var verbo := str(VERBOS.get(primero, ""))

	# Movimiento directo: norte, sur, este, oeste, dentro...
	if DIRECCIONES.has(primero):
		return _crear("mover", "", str(DIRECCIONES[primero]), original)

	# Entrar/salir se resuelven como movimientos relativos.
	if primero in ["entrar", "entra", "pasar", "pasa"]:
		return _crear("mover", TextUtils.preparar_objetivo(resto), "dentro", original)
	if primero in ["salir", "sal", "abandonar"]:
		return _crear("mover", TextUtils.preparar_objetivo(resto), "fuera", original)

	if verbo.is_empty():
		return _no_reconocido(original, emitir_invalidos)

	match verbo:
		"ir":
			var destino := TextUtils.preparar_objetivo(resto)
			if destino.is_empty():
				return _crear("mover", "", "", original)
			if DIRECCIONES.has(destino):
				return _crear("mover", "", str(DIRECCIONES[destino]), original)
			return _crear("mover", destino, "", original)

		"mirar":
			if resto.is_empty():
				return _crear("mirar", "", "", original)
			var objetivo_mirado := TextUtils.preparar_objetivo(resto)
			if objetivo_mirado in ["alrededor", "habitacion", "sala", "lugar", "aqui"]:
				return _crear("mirar", "", "", original)
			return _crear("examinar", objetivo_mirado, "", original)

		"examinar":
			return _crear("examinar", TextUtils.preparar_objetivo(resto), "", original)

		"hablar":
			return _crear("hablar", TextUtils.preparar_objetivo(resto), "", original)

		"coger":
			return _crear("coger", TextUtils.preparar_objetivo(resto), "", original)

		"usar":
			return _crear("usar", TextUtils.preparar_objetivo(resto), "", original)

		"inventario":
			return _crear("inventario", "", "", original)

		"ayuda":
			return _crear("ayuda", "", "", original)

		"reiniciar":
			return _crear("reiniciar", "", "", original)

		"esperar":
			return _crear("esperar", "", "", original)

		"guardar":
			return _crear("guardar", "", "", original)

		"cargar":
			return _crear("cargar", "", "", original)

		"continuar":
			return _crear("continuar", "", "", original)

		"borrar":
			return _crear("borrar", TextUtils.preparar_objetivo(resto), "", original)

		"objetivo":
			return _crear("objetivo", "", "", original)

	return _no_reconocido(original, emitir_invalidos)


func _crear(verbo: String, objetivo: String, direccion: String, texto: String) -> Dictionary:
	return {
		"verbo": verbo,
		"objetivo": objetivo,
		"direccion": direccion,
		"texto": texto,
	}


func _no_reconocido(original: String, emitir_invalidos: bool = true) -> Dictionary:
	var indice := randi() % MENSAJES_INVALIDOS.size()
	if MENSAJES_INVALIDOS.size() > 1 and indice == _ultimo_mensaje:
		indice = (indice + 1) % MENSAJES_INVALIDOS.size()
	_ultimo_mensaje = indice

	if emitir_invalidos:
		comando_invalido.emit(original, MENSAJES_INVALIDOS[indice])
	return {}
