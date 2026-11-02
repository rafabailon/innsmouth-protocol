class_name RoomDatabase
extends RefCounted
## Contenido de la aventura en Innsmouth.
## Separar los datos de la lógica permite añadir salas sin tocar Game.gd.

static func crear_habitaciones() -> Dictionary:
	var habitaciones: Dictionary = {}
	for habitacion in [
		_parada_autobus(),
		_camino_innsmouth(),
		_bodega_zadok(),
		_plaza_pueblo(),
		_refineria_marsh(),
		_oficina_refineria(),
		_muelle(),
		_iglesia_dagon(),
		_hotel_gillman(),
		_archivo_aduana(),
		_tunel_bajo_muelle(),
		_camara_arrecife(),
		_borde_devils_reef(),
		_gruta_devils_reef(),
	]:
		habitaciones[habitacion.id] = habitacion
	return habitaciones


static func crear_npcs() -> Dictionary:
	var npcs: Dictionary = {}
	for npc in [
		_joe_sargent(),
		_anciano_porche(),
		_hombre_banco(),
		_sacerdote_dagon(),
		_capataz_refineria(),
		_zadok_allen(),
		_vigia_marea(),
	]:
		npcs[npc.id] = npc
	return npcs


static func _examinable(nombre: String, descripcion: String, impacto: int = 0, alias: Array = []) -> Dictionary:
	var datos: Dictionary = {
		"nombre": nombre,
		"descripcion": descripcion,
		"impacto_cordura": impacto,
	}
	if not alias.is_empty():
		datos["alias"] = alias
	return datos


static func _parada_autobus() -> Room:
	var sala := Room.new()
	sala.id = "parada_autobus"
	sala.nombre = "Carretera de Innsmouth · Parada del autobús"
	sala.descripcion_larga = "El autobús de Newburyport se detiene con un traqueteo de hierro viejo y te deja en el arcén. El motor sigue en marcha, como si el vehículo no se atreviera a apagarse del todo. A tu espalda, la carretera se pierde entre marismas cubiertas de niebla. Delante, Innsmouth se pudre contra el cielo: tejados hundidos, campanarios torcidos y ventanas que parecen mirarte como ojos hundidos.\n\nEl aire huele a pescado podrido, a salitre y a algo dulzón que prefieres no identificar. Joe Sargent, el conductor, enciende un cigarrillo junto a la puerta abierta. Al este, un camino de tierra conduce hacia la plaza del pueblo."
	sala.descripcion_corta = "La parada del autobús, el arcén lodoso y, al este, el camino hacia Innsmouth."
	sala.ambiente = "El motor aún chisporrotea. En algún lugar, una gaviota grazna como si se estuviera ahogando."
	sala.conexiones = {
		"este": "camino_innsmouth",
	}
	sala.objetos_en_sala = []
	sala.npcs = ["joe_sargent"]
	sala.impacto_cordura = -2
	sala.examinables = {
		"autobus": _examinable(
			"El autobús de Joe Sargent",
			"Un autobús Ford destartalado, con el óxido comiéndose los costados. Los asientos de cuero están rajados y en el pasillo hay periódicos viejos. En el vaho del cristal trasero, alguien ha dibujado una espiral con el dedo. La espiral parece tener demasiadas vueltas.",
			-2,
			["bus", "vehiculo"]
		),
		"carretera": _examinable(
			"La carretera de Newburyport",
			"El asfalto está agrietado y cubierto de una película de sal. No pasa un solo coche. A lo lejos, la niebla borra el punto donde debería estar el mundo que conoces.",
			0,
			["camino", "arcen", "asfalto"]
		),
		"marismas": _examinable(
			"Las marismas",
			"Los juncos se mecen aunque el aire está quieto. El barro despide un olor dulzón. Entre las cañas hay huellas profundas, con dedos demasiado largos para ser de un pájaro.",
			-3,
			["juncos", "barro", "niebla"]
		),
		"casas_lejanas": _examinable(
			"Las casas al este",
			"Innsmouth se extiende más allá del camino. Las casas se apiñan como si quisieran ocultarse unas detrás de otras. Ninguna tiene la misma altura, pero todas parecen inclinarse en la misma dirección: hacia el mar.",
			-3,
			["pueblo", "casas", "tejados"]
		),
	}
	return sala


static func _camino_innsmouth() -> Room:
	var sala := Room.new()
	sala.id = "camino_innsmouth"
	sala.nombre = "El camino a Innsmouth"
	sala.descripcion_larga = "El camino serpentea entre casas de madera gris, tan inclinadas que parecen susurrarse unas a otras. Algunas tienen las ventanas tapiadas con tablones; en otras, las cortinas se mueven aunque no hay viento. Un anciano de abrigo aceitoso te observa desde un porche y no responde a tu saludo.\n\nA tu derecha, una casa con el tejado hundido se inclina sobre la calle como un animal herido. Al este se abre la plaza; al oeste queda la parada del autobús."
	sala.descripcion_corta = "Casas decrépitas a ambos lados. La plaza al este, la parada al oeste."
	sala.ambiente = "En algún tejado, algo arrastra escamas sobre la madera."
	sala.conexiones = {
		"oeste": "parada_autobus",
		"este": "plaza_pueblo",
		"norte": "bodega_zadok",
	}
	sala.objetos_en_sala = ["concha_ritual"]
	sala.npcs = ["anciano_porche"]
	sala.impacto_cordura = -2
	sala.examinables = {
		"casas": _examinable(
			"Las casas decrépitas",
			"Las casas no están vacías. Detrás de las cortinas hay siluetas inmóviles. Los ángulos de los tejados parecen imposibles, como si la madera hubiera crecido siguiendo una geometría que no es humana. Cuanto más miras, más seguro estás de que una de las ventanas acaba de cerrarse.",
			-7,
			["viviendas", "casas viejas", "decadentes"]
		),
		"ventanas": _examinable(
			"Las ventanas",
			"Ventanas como ojos hundidos. Algunas están tapiadas desde dentro, con los tablones clavados en ángulos absurdos. En una de ellas, una cortina se mueve. No hay viento.",
			-4,
			["ventana", "cortinas"]
		),
		"tejado": _examinable(
			"El tejado hundido",
			"Las tejas están negras de humedad. Bajo una de ellas algo se mueve, despacio, como si una mano intentara abrirse camino. Cuando te acercas, el sonido cesa.",
			-3,
			["tejados", "techo", "tejas"]
		),
		"porche": _examinable(
			"El porche del anciano",
			"La madera del porche está podrida y cubierta de sal. Hay una silla vacía junto a la puerta. En el suelo, alguien ha dibujado una espiral con tiza húmeda.",
			-2,
			["porche del anciano", "silla"]
		),
	}
	return sala


static func _bodega_zadok() -> Room:
	var sala := Room.new()
	sala.id = "bodega_zadok"
	sala.nombre = "Bodega de Zadok Allen"
	sala.descripcion_larga = "La puerta del sótano se abre bajo un rótulo casi borrado: «El Ancla». El lugar huele a cerveza agria, sal y madera mojada. Detrás de una mesa, un anciano de barba blanca protege una botella como si fuera lo único que queda de su vida anterior. Es Zadok Allen, uno de los pocos habitantes que todavía habla con los forasteros.\n\nEn una repisa hay un cuaderno envuelto en hule. La salida sube al camino."
	sala.descripcion_corta = "La bodega del Ancla, donde Zadok Allen guarda sus recuerdos y un cuaderno envuelto en hule. El camino queda arriba."
	sala.ambiente = "Una gota cae en un vaso vacío. El sonido llega desde el otro extremo de la habitación."
	sala.conexiones = {
		"arriba": "camino_innsmouth",
	}
	sala.objetos_en_sala = ["cuaderno_zadok"]
	sala.npcs = ["zadok_allen"]
	sala.impacto_cordura = -2
	sala.examinables = {
		"botellas": _examinable(
			"Las botellas de Zadok",
			"Las etiquetas tienen fechas de hace décadas. En varias aparece el nombre de Devil Reef, escrito con una letra infantil. Una botella está llena de agua de mar y contiene algo que parece un diente.",
			-3,
			["botella", "estantes", "bebida"]
		),
		"pared": _examinable(
			"La pared del sótano",
			"Alguien ha grabado nombres en la piedra. Muchos están tachados; junto a los últimos hay pequeñas marcas en forma de branquias. El nombre Allen aparece más de una vez.",
			-4,
			["piedra", "nombres"]
		),
	}
	return sala


static func _plaza_pueblo() -> Room:
	var sala := Room.new()
	sala.id = "plaza_pueblo"
	sala.nombre = "Plaza del pueblo"
	sala.descripcion_larga = "La plaza se abre entre edificios de ladrillo oscuro. Los adoquines están rotos y cubiertos de un musgo pálido que brilla bajo la luz gris. En el centro se alza un obelisco de piedra negra, cubierto de bajorrelieves que representan figuras mitad pez, mitad hombre, retorciéndose en una danza imposible.\n\nAl este, la iglesia de la Orden Esotérica de Dagon clava su aguja en el cielo y su puerta ha quedado entornada. Al norte, la fachada del hotel Gillman conserva un letrero de neón muerto. En un banco, un hombre con un abrigo demasiado grande te mira sin parpadear. Un callejón desciende hacia el puerto al sur; al nordeste, una chimenea ennegrece la niebla. Al oeste queda el camino de vuelta."
	sala.descripcion_corta = "La plaza vacía, el obelisco negro, la iglesia al este, el hotel al norte y una chimenea al nordeste."
	sala.ambiente = "El viento trae un olor a sal y a carne vieja. Ningún pájaro cruza el cielo."
	sala.conexiones = {
		"oeste": "camino_innsmouth",
		"sur": "muelle",
		"este": "iglesia_dagon",
		"norte": "hotel_gillman",
		"noreste": "refineria_marsh",
	}
	sala.objetos_en_sala = ["llave_oxidada"]
	sala.npcs = ["hombre_banco"]
	sala.impacto_cordura = -3
	sala.examinables = {
		"obelisco": _examinable(
			"El obelisco",
			"El obelisco está cubierto de musgo y de relieves que parecen moverse cuando no los miras de frente. En la base hay una inscripción gastada: «Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn». Las letras duelen detrás de los ojos.",
			-6,
			["monumento", "piedra negra", "inscripcion"]
		),
		"bajorrelieves": _examinable(
			"Los bajorrelieves",
			"Las figuras tienen demasiadas articulaciones. Algunas sostienen instrumentos que no reconoces; otras parecen estar bailando. En el centro de la procesión hay una figura con tu misma altura. Tiene tu rostro.",
			-8,
			["relieves", "figuras", "tallados"]
		),
		"iglesia": _examinable(
			"La iglesia de la Orden Esotérica de Dagon",
			"La iglesia tiene ventanas con vidrieras de colores enfermizos. La puerta está entornada; el candado nuevo cuelga abierto de la argolla. Dentro, alguien canta en una lengua que no tiene vocales.",
			-5,
			["orden", "dagon", "campanario", "iglesia de dagon"]
		),
		"hotel": _examinable(
			"El hotel Gillman",
			"Un edificio de tres plantas con el letrero de neón fundido. En la planta baja hay una recepción vacía; en las ventanas superiores, cortinas amarillas se mueven sin viento. La puerta principal no tiene cerradura.",
			-3,
			["hotel gillman", "posada", "alojamiento"]
		),
		"adoquines": _examinable(
			"Los adoquines",
			"El musgo pálido crece entre las piedras formando dibujos que casi reconoces. Hay huellas descalzas por todas partes. Los dedos son demasiado largos y las plantas parecen no haber tocado el suelo.",
			-2,
			["suelo", "musgo", "huellas"]
		),
	}
	return sala


static func _refineria_marsh() -> Room:
	var sala := Room.new()
	sala.id = "refineria_marsh"
	sala.nombre = "Refinería de Marsh"
	sala.descripcion_larga = "La chimenea de la refinería se alza sobre los tejados, aunque no hay humo en su boca. El edificio de ladrillo rojo está cubierto de sal y hollín; las ventanas altas dejan escapar una luz amarilla que no parpadea. A través de una puerta lateral se oye el golpeteo acompasado de una maquinaria que, según las placas oxidadas, lleva décadas desconectada.\n\nUn capataz vigila el patio desde una báscula. No lleva herramientas, solo guantes limpios. La plaza queda al suroeste; una puerta marcada «CONTABILIDAD» conduce a las oficinas."
	sala.descripcion_corta = "La refinería de Marsh y su chimenea apagada. La plaza queda al suroeste; las oficinas, dentro."
	sala.ambiente = "La chimenea no humea, pero una sombra asciende por su interior contra la gravedad."
	sala.conexiones = {
		"suroeste": "plaza_pueblo",
		"dentro": "oficina_refineria",
	}
	sala.objetos_en_sala = []
	sala.npcs = ["capataz_refineria"]
	sala.impacto_cordura = -2
	sala.examinables = {
		"chimenea": _examinable(
			"La chimenea de Marsh",
			"El ladrillo está vitrificado por un calor que no dejó ceniza. Desde la base se distingue una línea de pequeñas conchas incrustadas en el mortero, todas orientadas hacia el mar.",
			-4,
			["humo", "conducto"]
		),
		"báscula": _examinable(
			"La báscula del patio",
			"El indicador marca un peso negativo. Bajo el plato hay marcas recientes de arrastre que terminan en la puerta de las oficinas.",
			-3,
			["bascula", "plataforma", "peso"]
		),
		"maquinaria": _examinable(
			"La maquinaria detenida",
			"Los engranajes están inmóviles, pero el golpeteo continúa detrás de ellos. En una placa de latón apenas legible aparece el nombre de Obed Marsh y una fecha anterior a la construcción de la refinería.",
			-5,
			["engranajes", "maquinas", "placas"]
		),
	}
	return sala


static func _oficina_refineria() -> Room:
	var sala := Room.new()
	sala.id = "oficina_refineria"
	sala.nombre = "Oficina de cuentas de Marsh"
	sala.descripcion_larga = "La oficina conserva un escritorio, un archivador y una ventana que da al patio. Los libros de contabilidad están hinchados por la humedad, pero sus páginas no tienen una sola mancha. Las columnas registran oro recibido desde Devil Reef y pagos anotados con nombres de familias del pueblo. En el último libro, las entregas continúan décadas después de que la refinería cerrara.\n\nUn volumen encuadernado en piel está abierto por una página reciente. Junto a él, la puerta devuelve al patio."
	sala.descripcion_corta = "La oficina contable de Marsh y sus libros de oro procedente de Devil Reef. La refinería queda fuera."
	sala.ambiente = "Las páginas se levantan una a una, aunque la ventana está cerrada."
	sala.conexiones = {
		"fuera": "refineria_marsh",
	}
	sala.objetos_en_sala = ["libro_cuentas_marsh"]
	sala.npcs = []
	sala.impacto_cordura = -2
	sala.examinables = {
		"archivador": _examinable(
			"El archivador",
			"Las fichas más antiguas están firmadas por Obed Marsh. Las más recientes no tienen firma, solo una espiral estampada en cera negra. Todas registran oro y una cantidad de pescado que no aparece en ningún manifiesto del puerto.",
			-4,
			["fichas", "cajones"]
		),
		"ventana": _examinable(
			"La ventana del patio",
			"Desde aquí, la chimenea parece inclinarse hacia Devil Reef. Por un segundo, una hilera de figuras asciende por el ladrillo desde el lado del mar. Cuando parpadeas, solo queda la pared.",
			-5,
			["cristal", "patio"]
		),
	}
	return sala


static func _muelle() -> Room:
	var sala := Room.new()
	sala.id = "muelle"
	sala.nombre = "Muelle de Innsmouth"
	sala.descripcion_larga = "El callejón desemboca en un muelle de tablones podridos. Varias barcas de casco negro cabecean amarradas a los norays, y las redes cuelgan como piel muerta. El agua del puerto tiene un brillo aceitoso; bajo la superficie, formas pálidas se desplazan con demasiada lentitud para ser peces.\n\nEn el extremo del muelle, una figura encorvada arroja algo al mar. Unas escaleras de piedra descienden bajo el agua, cubiertas de algas. Al este, una puerta hinchada por la humedad conserva el rótulo de la vieja aduana. Al norte queda la plaza."
	sala.descripcion_corta = "El muelle desierto, las barcas negras y el agua aceitosa. La vieja aduana al este; la plaza al norte."
	sala.ambiente = "El agua golpea los pilotes. Entre dos golpes, jurarías oír una respiración."
	sala.conexiones = {
		"norte": "plaza_pueblo",
		"este": "archivo_aduana",
		"abajo": "tunel_bajo_muelle",
	}
	sala.requisitos_conexiones = {
		"abajo": {
			"objetos": ["libro_mareas"],
			"mensaje": "La marea cubre los escalones. El libro de mareas de la vieja aduana podría revelar cuándo bajar.",
		},
	}
	sala.objetos_en_sala = []
	sala.npcs = ["vigia_marea"]
	sala.impacto_cordura = -4
	sala.examinables = {
		"agua": _examinable(
			"El agua del puerto",
			"El agua refleja un cielo que no es el que hay sobre ti. Las formas pálidas se detienen cuando te acercas al borde. Una de ellas gira lentamente hacia arriba. Tiene ojos.",
			-6,
			["puerto", "mar", "superficie"]
		),
		"barcas": _examinable(
			"Las barcas",
			"Los nombres de las barcas han sido raspados de los cascos. En las redes hay dientes enredados entre el nailon. Algunos son humanos.",
			-3,
			["barcos", "botes", "cascos"]
		),
		"escaleras": _examinable(
			"Las escaleras de piedra",
			"Los escalones descienden bajo el agua y desaparecen en la oscuridad. Están cubiertos de algas, pero no de limo. Cada escalón tiene una forma ligeramente vertebral. No consigues ver el fondo.",
			-8,
			["escalones", "escalera", "escaleras de piedra"]
		),
		"figura": _examinable(
			"La figura encorvada",
			"La figura arroja algo brillante al agua. No tiene cuello: la cabeza se hunde directamente en los hombros. Antes de que puedas verle la cara, se gira y señala las escaleras con un dedo demasiado largo.",
			-5,
			["encorvado", "pescador", "silueta"]
		),
		"redes": _examinable(
			"Las redes",
			"Las redes huelen a pescado y a hierro. En sus mallas hay escamas del tamaño de monedas, y algo que parece una uña rota.",
			-2,
			["red"]
		),
	}
	return sala


static func _archivo_aduana() -> Room:
	var sala := Room.new()
	sala.id = "archivo_aduana"
	sala.nombre = "Archivo de la vieja aduana"
	sala.descripcion_larga = "La puerta del muelle cede con un gemido. La oficina de aduanas lleva décadas abandonada, pero el polvo termina en una línea recta frente al archivador del fondo. Una lámpara apagada cuelga sobre un escritorio cubierto de formularios; todos llevan el sello de Innsmouth y ninguno registra pescado.\n\nEn un cajón abierto descansa un libro de mareas sujeto por una concha negra. Una puerta interior conduce al depósito. Al oeste, la puerta devuelve al muelle."
	sala.descripcion_corta = "La vieja oficina de aduanas y un libro de mareas sujeto por una concha. El depósito queda dentro; el muelle, al oeste."
	sala.ambiente = "Una pluma rasca el papel en la habitación contigua. No hay habitación contigua."
	sala.conexiones = {
		"oeste": "muelle",
	}
	sala.objetos_en_sala = ["libro_mareas"]
	sala.impacto_cordura = -1
	sala.requisitos_objetos = {
		"libro_mareas": {
			"objetos": ["concha_ritual"],
			"mensaje": "La concha negra mantiene cerrado el cajón. Su espiral encaja en el cierre; necesitas haberla encontrado en el camino.",
		},
	}
	sala.examinables = {
		"archivador": _examinable(
			"El archivador",
			"Las fichas están ordenadas por fecha, pero las cajas de carga llevan nombres de vecinos desaparecidos. En cada ficha, el peso consignado es menor que el de un cuerpo y mayor que el de una caja vacía.",
			-4,
			["archivos", "fichero", "cajones"]
		),
		"formularios": _examinable(
			"Los formularios de aduanas",
			"Las columnas de mercancía están vacías. En la de destino se repiten tres palabras: «bajo el arrecife». La última página está firmada con una mano temblorosa: «No son cargamentos. Son retornos».",
			-3,
			["papeles", "documentos", "registros"]
		),
	}
	return sala


static func _tunel_bajo_muelle() -> Room:
	var sala := Room.new()
	sala.id = "tunel_bajo_muelle"
	sala.nombre = "Pasadizo bajo el muelle"
	sala.descripcion_larga = "Las escaleras terminan en un pasadizo excavado en la roca. El agua se retira con cada respiración de la marea y deja al descubierto marcas de manos en las paredes: cientos, todas orientadas hacia el interior. El libro de mareas te ha traído hasta aquí, pero no explica quién construyó el túnel.\n\nAl fondo, una abertura deja ver una luz verde bajo el agua. La abertura es lo bastante ancha para pasar; la concha negra vibra contra tu bolsillo. La escalera de vuelta sigue a tu espalda."
	sala.descripcion_corta = "Un pasadizo de roca cubierto de marcas de manos. La abertura queda al fondo; la escalera de vuelta, arriba."
	sala.ambiente = "Desde la abertura llega un golpe lento. La roca responde con otro, desde muy lejos."
	sala.conexiones = {
		"arriba": "muelle",
		"dentro": "camara_arrecife",
	}
	sala.requisitos_conexiones = {
		"dentro": {
			"objetos": ["concha_ritual", "libro_mareas"],
			"mensaje": "La abertura se estrecha bajo el agua. La concha vibra, pero necesitas el libro de mareas para cruzar durante la retirada.",
		},
	}
	sala.objetos_en_sala = []
	sala.impacto_cordura = -4
	sala.examinables = {
		"marcas": _examinable(
			"Las marcas de manos",
			"Las huellas se superponen en capas. Algunas son pequeñas y humanas; otras tienen membranas entre los dedos. En el centro, una marca reciente conserva el dibujo de un anillo con forma de espiral.",
			-5,
			["manos", "paredes", "huellas"]
		),
		"abertura": _examinable(
			"La abertura bajo el arrecife",
			"El agua al otro lado no se mueve como agua. Algo enorme pasa frente a la luz verde y la apaga durante varios segundos. Cuando vuelve, hay burbujas subiendo desde una profundidad que no debería existir.",
			-7,
			["grieta", "arrecife", "luz verde", "agua"]
		),
		"inscripcion": _examinable(
			"La inscripción de la roca",
			"Alguien grabó una frase en inglés: «La marea devuelve lo que la tierra no pudo conservar». Debajo, una fecha de hace casi un siglo y las iniciales E. M. La piedra está húmeda, pero las letras siguen secas.",
			-4,
			["frase", "letras", "grabado"]
		),
	}
	return sala


static func _camara_arrecife() -> Room:
	var sala := Room.new()
	sala.id = "camara_arrecife"
	sala.nombre = "Cámara bajo el arrecife"
	sala.descripcion_larga = "Al otro lado de la abertura, la roca forma una cámara seca bajo el mar. No hay algas ni sal: el suelo está cubierto de polvo gris y huellas que empiezan en la pared. En el centro, una mesa de piedra sostiene placas de cobre ordenadas por fecha. La más reciente lleva el sello de la aduana y una lista de pasajeros que aún no han llegado a Innsmouth.\n\nJunto a la mesa hay una placa suelta, marcada con el mismo sello. Detrás de ti, el pasadizo conserva una franja de aire hasta que cambie la marea."
	sala.descripcion_corta = "Una cámara seca bajo el arrecife, una mesa de registros y la placa de cobre de la aduana. El pasadizo queda atrás."
	sala.ambiente = "El mar presiona el techo. En lugar de gotear, la piedra exhala aire tibio."
	sala.conexiones = {
		"fuera": "tunel_bajo_muelle",
		"abajo": "borde_devils_reef",
	}
	sala.requisitos_conexiones = {
		"abajo": {
			"objetos": ["concha_ritual", "libro_mareas"],
			"mensaje": "La cámara desciende hacia Devil Reef, pero solo el libro de mareas y la concha negra permiten encontrar el paso entre las rocas.",
		},
	}
	sala.objetos_en_sala = ["placa_aduana"]
	sala.impacto_cordura = -3
	sala.examinables = {
		"registros": _examinable(
			"Los registros de cobre",
			"Las placas enumeran entradas y salidas desde hace más de cien años. No registran barcos, sino nombres. Junto a cada nombre aparece una fecha de regreso y la misma anotación: «adaptación completada». En la última placa, la fecha es mañana.",
			-6,
			["placas", "mesa", "registro"]
		),
		"lista": _examinable(
			"La lista de pasajeros",
			"Reconoces tu nombre entre los pasajeros previstos para mañana. La tinta es antigua, pero la última línea está recién grabada: «llegó por carretera; aún conserva la voz». No recuerdas haber estado aquí antes.",
			-8,
			["nombres", "pasajeros", "listado"]
		),
		"pared": _examinable(
			"La pared seca",
			"La pared no tiene grietas. Al apoyar la mano, notas un pulso lento detrás de la piedra. La concha negra responde con un temblor, como si ambas cosas compartieran un mismo latido.",
			-3,
			["roca", "techo"]
		),
	}
	return sala


static func _borde_devils_reef() -> Room:
	var sala := Room.new()
	sala.id = "borde_devils_reef"
	sala.nombre = "Cornisa de Devil Reef"
	sala.descripcion_larga = "El pasadizo desemboca en una cornisa estrecha bajo Devil Reef. El agua no cae sobre ti: se curva alrededor de la piedra como si una corriente invisible la apartara. Más allá, los restos de un embarcadero se hunden en la oscuridad. Una escalera tallada en el arrecife sube hacia la cámara; una grieta baja hasta una cavidad iluminada por un resplandor verdoso."
	sala.descripcion_corta = "Una cornisa bajo Devil Reef, entre el embarcadero hundido y una grieta verde. La cámara queda arriba."
	sala.ambiente = "Algo golpea tres veces desde el otro lado del arrecife. La piedra devuelve cuatro golpes."
	sala.conexiones = {
		"arriba": "camara_arrecife",
		"dentro": "gruta_devils_reef",
	}
	sala.impacto_cordura = -4
	sala.examinables = {
		"embarcadero": _examinable(
			"El embarcadero hundido",
			"Los pilotes están cortados desde dentro. Entre las tablas encajadas hay una campana de bronce con el nombre de un barco de Newburyport. El metal vibra aunque no hay corriente.",
			-5,
			["muelle", "pilotes", "barco"]
		),
		"grieta": _examinable(
			"La grieta del arrecife",
			"El resplandor viene de unas vetas minerales que parecen extenderse como venas por la roca. A través de ellas ves una sombra inmóvil, demasiado grande para caber en la cavidad.",
			-6,
			["luz", "vetas", "abertura"]
		),
	}
	return sala


static func _gruta_devils_reef() -> Room:
	var sala := Room.new()
	sala.id = "gruta_devils_reef"
	sala.nombre = "Gruta de Devil Reef"
	sala.descripcion_larga = "La grieta conduce a una gruta donde el oleaje apenas se oye. Hay restos de una expedición: una lámpara sellada, un cinturón de buceo y una caja de madera abierta desde dentro. Un cuaderno impermeable yace junto a la caja. Sus últimas páginas describen señales luminosas que respondían desde las profundidades y una ruta de regreso que no aparece en ninguna carta náutica.\n\nLa cornisa queda al otro lado de la grieta."
	sala.descripcion_corta = "Una gruta con restos de una expedición y un cuaderno de buceo. La cornisa queda fuera."
	sala.ambiente = "Las burbujas suben desde el suelo y se quedan suspendidas bajo el techo."
	sala.conexiones = {
		"fuera": "borde_devils_reef",
	}
	sala.objetos_en_sala = ["cuaderno_buzo"]
	sala.impacto_cordura = -5
	sala.examinables = {
		"caja": _examinable(
			"La caja de expedición",
			"Las bisagras están intactas; la tapa fue empujada hacia fuera. En el interior hay marcas de uñas y una fila de pequeñas conchas negras ordenadas por tamaño.",
			-5,
			["cajon", "madera"]
		),
		"lampara": _examinable(
			"La lámpara de buceo",
			"El cristal está sellado y no tiene agua dentro. La lámpara está apagada, pero una luz verde recorre el filamento cuando pronuncias el nombre de Innsmouth.",
			-4,
			["luz", "equipo", "buceo"]
		),
	}
	return sala


static func _iglesia_dagon() -> Room:
	var sala := Room.new()
	sala.id = "iglesia_dagon"
	sala.nombre = "Iglesia de la Orden Esotérica de Dagon"
	sala.descripcion_larga = "El interior huele a cera vieja, a incienso y a agua de mar estancada. Las bancas están alineadas con una precisión que parece antinatural; ninguna tiene polvo. Al fondo, un altar de piedra negra sostiene un relicario de latón cerrado con una cerradura en espiral. Sobre el altar, una figura encapuchada sigue cantando sin mover los labios.\n\nLas vidrieras no representan santos, sino cuerpos que se transforman en peces bajo una luna enorme. La puerta queda al oeste, de vuelta a la plaza."
	sala.descripcion_corta = "Bancas vacías, un altar de piedra negra y un relicario cerrado. La plaza queda al oeste."
	sala.ambiente = "El canto continúa aunque nadie respira. Las velas se inclinan hacia el altar."
	sala.conexiones = {
		"oeste": "plaza_pueblo",
	}
	sala.objetos_en_sala = ["tiara_innsmouth"]
	sala.npcs = ["sacerdote_dagon"]
	sala.impacto_cordura = -5
	sala.requisitos_objetos = {
		"tiara_innsmouth": {
			"objetos": ["llave_oxidada"],
			"consumir": ["llave_oxidada"],
			"mensaje": "El relicario está cerrado. La cerradura tiene forma de espiral y exige una llave de hierro oxidada.",
		},
	}
	sala.examinables = {
		"altar": _examinable(
			"El altar de piedra negra",
			"La piedra está fría y húmeda. En su borde hay marcas de uñas humanas, muchas, alineadas como si alguien hubiera intentado contener el altar. Bajo la losa se oye el eco de una marea que no existe.",
			-5,
			["altar de piedra", "losa"]
		),
		"relicario": _examinable(
			"El relicario de latón",
			"Un cofre pequeño con la tapa repujada en forma de ola. La cerradura es una espiral de hierro, demasiado grande para una llave corriente. A través de la ranura se distingue un brillo de oro pálido y coral negro.",
			-2,
			["cofre", "cerradura"]
		),
		"vidrieras": _examinable(
			"Las vidrieras",
			"Los cuerpos de las vidrieras tienen rostros humanos y extremidades de pez. En la más grande, una figura coronada señala el agua. Al mirarla de reojo, la corona parece estar hecha de dedos entrelazados.",
			-6,
			["vidriera", "ventanas", "cristal"]
		),
		"bancas": _examinable(
			"Las bancas",
			"La madera está pulida por el uso, pero no hay nadie sentado. En la última fila, alguien ha dejado un pañuelo mojado y una concha diminuta. La concha tiene la misma espiral que la cerradura del relicario.",
			-2,
			["banco", "asientos", "filas"]
		),
		"campana": _examinable(
			"La campana",
			"Una campana de bronce verdoso cuelga sobre el presbiterio. No tiene badajo. Aun así, cada vez que el sacerdote calla, se oye un golpe sordo dentro del metal.",
			-4,
			["campanario", "bronce"]
		),
	}
	return sala


static func _hotel_gillman() -> Room:
	var sala := Room.new()
	sala.id = "hotel_gillman"
	sala.nombre = "Hotel Gillman"
	sala.descripcion_larga = "La recepción del hotel Gillman está vacía. Un mostrador de caoba ocupa el centro, con un libro de registro abierto y una campanilla cubierta de sal. Detrás, las llaves de las habitaciones cuelgan de sus ganchos; solo falta la número 7. Las escaleras suben hacia un pasillo donde todas las puertas están entreabiertas.\n\nEl aire huele a ropa húmeda y a perfume rancio. En la pared hay un espejo ovalado que devuelve tu reflejo con un instante de retraso. La salida a la plaza queda al sur."
	sala.descripcion_corta = "Una recepción desierta, un libro de registro y escaleras hacia habitaciones vacías. La plaza al sur."
	sala.ambiente = "En algún piso superior, una cama cruje aunque nadie duerme en ella."
	sala.conexiones = {
		"sur": "plaza_pueblo",
	}
	sala.objetos_en_sala = []
	sala.npcs = []
	sala.impacto_cordura = -1
	sala.examinables = {
		"recepcion": _examinable(
			"La recepción",
			"El mostrador está limpio de polvo, como si alguien acabara de pasar un trapo. La campanilla no suena cuando la tocas; en su lugar, el sonido llega desde el piso de arriba, como una respuesta.",
			-2,
			["mostrador", "campanilla"]
		),
		"registro": _examinable(
			"El libro de registro",
			"Las últimas entradas están escritas con la misma letra. Todas dicen «huésped de la marea» y comparten la misma fecha: hoy. En la página siguiente, tu nombre ya está escrito, con la tinta aún húmeda.",
			-7,
			["libro", "libro de registro", "huespedes"]
		),
		"cama": _examinable(
			"La habitación número 7",
			"La puerta cedió sin resistencia. Dentro hay una cama hecha, un vaso de agua limpia y una silla junto a la ventana. Por primera vez desde que llegaste, el silencio de Innsmouth parece solo silencio. Puedes intentar dormir, aunque el rumor del puerto no se detiene.",
			0,
			["habitacion 7", "habitación 7", "cama de la habitacion 7", "descansar", "habitacion"]
		),
		"espejo": _examinable(
			"El espejo ovalado",
			"Tu reflejo tarda un instante en copiar tus movimientos. Cuando levantas la mano, él la levanta después. En el fondo del espejo, detrás de tu hombro, hay una puerta que no existe en la recepción.",
			-4,
			["reflejo", "espejo de la pared"]
		),
		"escaleras": _examinable(
			"Las escaleras",
			"Los escalones crujen con tu peso. En el pasillo superior, las puertas están numeradas del 1 al 8, pero no existe la 7. Al final, una ventana da al puerto. Desde aquí, las barcas parecen formar una espiral.",
			-3,
			["pasillo", "piso superior", "puertas"]
		),
	}
	return sala


static func _joe_sargent() -> NpcData:
	var npc := NpcData.new()
	npc.id = "joe_sargent"
	npc.nombre = "Joe Sargent"
	npc.alias = ["joe", "conductor", "sargent", "chofer"]
	npc.descripcion = "Joe Sargent tiene la cara curtida por el viento y las manos manchadas de grasa. No te mira a los ojos mientras fuma. Su autobús sigue ahí, pero no parece una vía de escape."
	npc.dialogos = [
		"«Innsmouth», dice Joe sin que preguntes. «Yo descargo aquí dos veces por semana y me voy antes de que anochezca. Usted debería hacer lo mismo.»",
		"«La gente del pueblo no es... hospitalaria. No les gustan los forasteros. Y no les gusta que miren las casas viejas.»",
		"«Si oye algo en el agua esta noche, no vaya a mirar. Y si le ofrecen algo en la Orden Esotérica de Dagon, diga que no. Diga que no y no pregunte por qué.»",
	]
	npc.despedida = "«El autobús vuelve al amanecer. Si es que vuelve. No se aleje demasiado.»"
	npc.impacto_cordura_inicial = -2
	return npc


static func _anciano_porche() -> NpcData:
	var npc := NpcData.new()
	npc.id = "anciano_porche"
	npc.nombre = "Anciano del porche"
	npc.alias = ["anciano", "viejo", "hombre del porche", "vecino"]
	npc.descripcion = "El anciano lleva un abrigo aceitoso y botas de agua agrietadas. Su piel tiene un brillo húmedo. No parpadea."
	npc.dialogos = [
		"El anciano no aparta la vista de tus botas. «Forastero», dice, y la palabra suena a acusación.",
		"«Los de fuera no entienden Innsmouth. No mire las casas. No escuche el agua. Y no pregunte por los que se fueron.»",
	]
	npc.despedida = "«Cuando el autobús vuelva, súbase. No mire atrás.»"
	npc.impacto_cordura_inicial = -3
	return npc


static func _hombre_banco() -> NpcData:
	var npc := NpcData.new()
	npc.id = "hombre_banco"
	npc.nombre = "El hombre del banco"
	npc.alias = ["hombre", "desconocido", "vigilante", "hombre del banco"]
	npc.descripcion = "El hombre tiene un abrigo demasiado grande para su cuerpo. Sonríe sin enseñar los dientes. Sus ojos no parpadean."
	npc.dialogos = [
		"El hombre no te ofrece la mano. «Usted no es de aquí», dice. Su voz suena como si hablara con la boca llena de agua.",
		"«Los que se van no vuelven. Los que se quedan... cambian. Esta noche hay marea alta. No vaya al muelle.»",
	]
	npc.despedida = "«Que Dagon le conceda una noche tranquila», murmura. No parece una bendición."
	npc.impacto_cordura_inicial = -3
	return npc


static func _sacerdote_dagon() -> NpcData:
	var npc := NpcData.new()
	npc.id = "sacerdote_dagon"
	npc.nombre = "Sacerdote de Dagon"
	npc.alias = ["sacerdote", "cura", "padre", "hombre encapuchado", "oficiante"]
	npc.descripcion = "La figura encapuchada tiene la piel gris y húmeda. Bajo la capucha se adivinan ojos demasiado grandes y una boca que se mueve un instante después de las palabras. Sostiene un incensario con forma de pez."
	npc.dialogos = [
		"El sacerdote no se gira. «Llegas tarde», dice. «La ceremonia empezó hace cien años y todavía no ha terminado.»",
		"«La tiara no es un adorno. Es una llave. Quien la lleva recuerda lo que el pueblo decidió olvidar. Por eso la guardamos bajo llave.»",
		"«Si de verdad quieres irte, llévala a la parada. El autobús solo reconoce a quien puede demostrar que ha visto lo que nosotros vemos. O quédate. Dagon siempre necesita manos nuevas.»",
	]
	npc.despedida = "«La marea sube», murmura. «Y tú ya hueles a ella.»"
	npc.impacto_cordura_inicial = -4
	return npc


static func _capataz_refineria() -> NpcData:
	var npc := NpcData.new()
	npc.id = "capataz_refineria"
	npc.nombre = "Capataz de la refinería"
	npc.alias = ["capataz", "encargado", "trabajador", "obrero"]
	npc.descripcion = "El capataz lleva guantes blancos sin una mota de hollín. Mira la báscula, no a ti. En el bolsillo del chaleco asoma una insignia con una espiral."
	npc.dialogos = [
		"«La refinería cerró hace años», dice. Detrás de él, los engranajes golpean una vez. «Lo que oye es el mar dentro de las tuberías.»",
		"«Obed Marsh sabía qué se podía sacar del arrecife. El oro era lo de menos. Si encuentra los libros, no lea en voz alta los nombres.»",
	]
	npc.despedida = "El capataz se quita un guante. La piel de su mano está húmeda y tiene una membrana fina entre dos dedos. «La marea paga sus deudas», dice."
	npc.impacto_cordura_inicial = -3
	return npc


static func _zadok_allen() -> NpcData:
	var npc := NpcData.new()
	npc.id = "zadok_allen"
	npc.nombre = "Zadok Allen"
	npc.alias = ["zadok", "allen", "anciano", "borracho", "viejo de la bodega"]
	npc.descripcion = "Zadok Allen es un anciano frágil, con barba blanca y ojos enrojecidos. Cuando mira hacia la puerta, deja de temblar; cuando mira hacia el mar, sus manos buscan una botella."
	npc.dialogos = [
		"«No soy de la Orden», murmura Zadok. «Pero he visto sus barcos volver de Devil Reef sin tripulación. No preguntes qué remolcan.»",
		"«Obed Marsh hizo un trato por oro. Luego el pueblo empezó a cambiar: primero los jóvenes, después todos. Yo era un crío y aun así recuerdo las caras de antes.»",
		"«Si consigues salir, no mires el agua al amanecer. Es cuando ellos suben a tierra para comprobar quién falta.»",
	]
	npc.despedida = "Zadok esconde la botella bajo la mesa. «No escribas mi nombre en ese cuaderno. Ya lo han escrito ellos.»"
	npc.impacto_cordura_inicial = -3
	return npc


static func _vigia_marea() -> NpcData:
	var npc := NpcData.new()
	npc.id = "vigia_marea"
	npc.nombre = "El vigía de la marea"
	npc.alias = ["vigia", "vigía", "vigilante", "hombre del noray"]
	npc.descripcion = "Un hombre con impermeable oscuro aguarda junto a un noray. El agua le llega a los tobillos, aunque el muelle está varios metros sobre el mar. Solo puedes distinguir su rostro cuando una ola se retira."
	npc.dialogos = [
		"«No mires el reloj de la aduana», dice. «Mira el agua. Cuando deje de golpear los pilotes, tienes cuatro horas para bajar.»",
		"«El libro no marca la marea. La recuerda. Alguien anotó cada descenso para saber cuándo abrir la puerta de abajo.»",
		"«Si oyes tres golpes bajo el tercer escalón, no respondas. La última persona que lo hizo todavía está aprendiendo a respirar.»",
	]
	npc.despedida = "El vigía se aparta del noray. Bajo el impermeable no hay cuerpo, solo agua que cae hacia arriba."
	npc.impacto_cordura_inicial = -2
	return npc
