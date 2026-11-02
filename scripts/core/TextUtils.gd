class_name TextUtils
extends RefCounted
## Utilidades de normalización compartidas por el parser, las salas y la UI.
## Mantenerlas en un único lugar evita que cada sistema interprete el texto
## de forma distinta (acentos, artículos, mayúsculas...).

const ACENTOS := {
	"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u",
	"ü": "u", "ñ": "n", "à": "a", "è": "e", "ì": "i",
	"ò": "o", "ù": "u", "â": "a", "ê": "e", "î": "i",
	"ô": "o", "û": "u", "ä": "a", "ë": "e", "ï": "i",
	"ö": "o", "ç": "c",
}

const ARTICULOS := [
	"el ", "la ", "los ", "las ",
	"un ", "una ", "unos ", "unas ",
	"del ", "de la ", "de los ", "de las ", "de ",
]

const PREFIJOS := [
	"hacia la ", "hacia el ", "hacia los ", "hacia las ", "hacia ",
	"a la ", "al ", "a los ", "a las ", "a ",
	"en la ", "en el ", "en los ", "en las ", "en ",
	"con la ", "con el ", "con los ", "con las ", "con ",
	"de la ", "del ", "de los ", "de las ", "de ",
]


## Convierte una entrada libre en una clave comparable.
static func normalizar(texto: String) -> String:
	var limpio := texto.strip_edges().to_lower()
	for original in ACENTOS:
		limpio = limpio.replace(original, ACENTOS[original])

	# La puntuación no aporta nada al parser y rompe la coincidencia exacta.
	for signo in [".", ",", ";", ":", "!", "?", "¿", "¡", "\"", "'", "(", ")", "“", "”", "‘", "’"]:
		limpio = limpio.replace(signo, " ")

	limpio = limpio.replace("\t", " ").replace("\n", " ")
	while limpio.contains("  "):
		limpio = limpio.replace("  ", " ")
	return limpio.strip_edges()


## Elimina artículos iniciales. Se repite para casos como "la de la casa".
static func limpiar_articulos(texto: String) -> String:
	var limpio := texto.strip_edges()
	var cambio := true
	while cambio:
		cambio = false
		for articulo in ARTICULOS:
			if limpio.begins_with(articulo):
				limpio = limpio.substr(articulo.length()).strip_edges()
				cambio = true
				break
	return limpio


## Limpia un objetivo de comando: "a la plaza" -> "plaza".
static func preparar_objetivo(texto: String) -> String:
	var limpio := texto.strip_edges()
	for prefijo in PREFIJOS:
		if limpio.begins_with(prefijo):
			limpio = limpio.substr(prefijo.length()).strip_edges()
			break
	return limpiar_articulos(limpio)


## Compara un texto del jugador con una lista de nombres/alias.
## La coincidencia parcial solo se usa a partir de tres caracteres para evitar
## que palabras cortas ("a", "el") activen cualquier objeto.
static func coincide(buscado: String, candidatos: Array) -> bool:
	var clave := normalizar(buscado)
	if clave.is_empty():
		return false

	for candidato in candidatos:
		var nombre := normalizar(str(candidato))
		if nombre.is_empty():
			continue
		if nombre == clave:
			return true
		if clave.length() >= 3 and nombre.contains(clave):
			return true
		if nombre.length() >= 3 and clave.contains(nombre):
			return true
	return false


## "a, b y c" para mensajes naturales.
static func formatear_lista(elementos: Array[String]) -> String:
	if elementos.is_empty():
		return ""
	if elementos.size() == 1:
		return elementos[0]

	var resultado := ""
	for i in elementos.size():
		if i > 0:
			if i == elementos.size() - 1:
				resultado += " y "
			else:
				resultado += ", "
		resultado += elementos[i]
	return resultado
