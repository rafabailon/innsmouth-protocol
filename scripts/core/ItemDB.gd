class_name ItemDB
extends RefCounted
## Catálogo de objetos. Los IDs son estables (se guardan en el inventario y en
## las salas); los nombres y textos viven aquí para poder localizarlos o
## reescribirlos sin tocar la lógica.

const OBJETOS := {
	"billete_autobus": {
		"nombre": "Billete de autobús",
		"descripcion": "Un billete de cartón arrugado. Newburyport-Innsmouth, ida y vuelta. La tinta de la fecha se ha corrido hasta formar una mancha oscura.",
		"uso": "Guardas el billete. El autobús no volverá hasta el amanecer... si es que vuelve.",
		"cordura_al_examinar": 0,
		"cordura_al_coger": 0,
	},
	"revolver_viejo": {
		"nombre": "Revólver viejo",
		"descripcion": "Un revólver de seis tiros con la culata envuelta en tela. El metal está frío y huele a aceite rancio. Te consuela menos de lo que esperabas.",
		"uso": "Aprietas la culata. El peso del arma es real; todo lo demás en Innsmouth parece discutible.",
		"cordura_al_examinar": 0,
		"cordura_al_coger": 0,
	},
	"concha_ritual": {
		"nombre": "Concha negra",
		"descripcion": "Una concha negra del tamaño de tu palma. Sus surcos forman una espiral demasiado regular, como si alguien la hubiera tallado. Despide un calor húmedo.",
		"uso": "Te la acercas al oído. No oyes el mar. Oyes una respiración húmeda que sigue el ritmo de la tuya.",
		"cordura_al_examinar": -3,
		"cordura_al_coger": -4,
	},
	"llave_oxidada": {
		"nombre": "Llave oxidada",
		"descripcion": "Una llave de hierro cubierta de óxido. Su cabeza tiene forma de espiral y los dientes parecen haber sido limados con paciencia.",
		"uso": "La llave no encaja en ninguna cerradura cercana. Aun así, al tocarla, tienes la certeza de que ya has abierto algo con ella.",
		"cordura_al_examinar": -1,
		"cordura_al_coger": 0,
	},
	"tiara_innsmouth": {
		"nombre": "Tiara de Innsmouth",
		"descripcion": "Una tiara de oro pálido coronada por una espiral de coral negro. En el interior, alguien ha grabado tres nombres. Dos están tachados; el tercero es el tuyo. La pieza está fría incluso a través del pañuelo.",
		"uso": "Sostienes la tiara contra la luz. El coral parece latir. Por un instante, el puerto entero guarda silencio, como si acabara de reconocerte.",
		"cordura_al_examinar": -2,
		"cordura_al_coger": -3,
	},
	"libro_mareas": {
		"nombre": "Libro de mareas",
		"descripcion": "Un registro de la vieja aduana, hinchado por la humedad. Entre las tablas de mareas hay anotaciones de una ruta bajo los pilotes: «seguir la espiral cuando el agua respire hacia fuera». En los márgenes, un funcionario escribió que los cargamentos no eran pescado, sino personas que regresaban distintas.",
		"uso": "La ruta anotada coincide con las escaleras del muelle. La marea se retira ahora; podrías bajar sin perder de vista el camino de vuelta.",
		"cordura_al_examinar": -2,
		"cordura_al_coger": 0,
	},
	"placa_aduana": {
		"nombre": "Placa de cobre de la aduana",
		"descripcion": "Una placa fina, oxidada en los bordes. El sello de la aduana rodea una lista de pasajeros y fechas de regreso. Tu nombre aparece en la última línea, grabado con una herramienta que aún conserva polvo de cobre.",
		"uso": "La placa no es una llave ni una reliquia. Es una prueba. Joe Sargent reconoce el sello de la aduana y deja de fingir que nunca ha visto la cámara bajo el arrecife.",
		"cordura_al_examinar": -2,
		"cordura_al_coger": -1,
	},
	"libro_cuentas_marsh": {
		"nombre": "Libro de cuentas de Marsh",
		"descripcion": "Un volumen de tapas oscuras con el nombre de Marsh grabado en el lomo. Sus páginas registran entregas de oro desde Devil Reef y pagos a familias de Innsmouth. Las fechas siguen avanzando después del cierre oficial de la refinería.",
		"uso": "El libro demuestra que la refinería siguió comerciando con Devil Reef mucho después de cerrar. Joe reconoce las cuentas y comprende que ya no puede fingir que Innsmouth es solo un pueblo pesquero.",
		"cordura_al_examinar": -3,
		"cordura_al_coger": -1,
	},
	"cuaderno_zadok": {
		"nombre": "Cuaderno de Zadok",
		"descripcion": "Un cuaderno pequeño envuelto en hule. Sus páginas reúnen fechas, nombres de barcos y recuerdos escritos con letra temblorosa. La última entrada describe una noche en que toda la flota de Innsmouth regresó sin luces.",
		"uso": "El cuaderno no acusa a Zadok de nada; registra décadas de regresos y desapariciones. Joe reconoce varios nombres de barcos que su padre mencionaba y decide que ya ha oído suficiente.",
		"cordura_al_examinar": -2,
		"cordura_al_coger": -1,
	},
	"cuaderno_buzo": {
		"nombre": "Cuaderno del buzo",
		"descripcion": "Un cuaderno impermeable con diagramas de Devil Reef. Las últimas notas describen campanas bajo el agua, luces que responden a la concha negra y una ruta entre las rocas que solo se abre cuando la marea retrocede.",
		"uso": "El cuaderno confirma que la expedición encontró una entrada bajo Devil Reef. Joe reconoce el nombre del barco en la cubierta y, por primera vez, acepta que la carretera es la única salida que queda.",
		"cordura_al_examinar": -3,
		"cordura_al_coger": -1,
	},
}


static func obtener(objeto_id: String) -> Dictionary:
	return OBJETOS.get(objeto_id, {})


static func nombre(objeto_id: String) -> String:
	var datos := obtener(objeto_id)
	return str(datos.get("nombre", objeto_id.capitalize()))


static func descripcion(objeto_id: String) -> String:
	return str(obtener(objeto_id).get("descripcion", "No encuentras nada digno de mención."))


static func uso(objeto_id: String) -> String:
	return str(obtener(objeto_id).get("uso", "No se te ocurre cómo usarlo aquí."))


static func cordura_al_examinar(objeto_id: String) -> int:
	return int(obtener(objeto_id).get("cordura_al_examinar", 0))


static func cordura_al_coger(objeto_id: String) -> int:
	return int(obtener(objeto_id).get("cordura_al_coger", 0))


## Resuelve "billete", "concha negra", etc. a un ID del catálogo.
static func buscar(texto: String) -> String:
	for objeto_id in OBJETOS:
		var datos: Dictionary = OBJETOS[objeto_id]
		if TextUtils.coincide(texto, [objeto_id, datos.get("nombre", "")]):
			return objeto_id
	return ""
