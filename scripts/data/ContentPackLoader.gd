class_name ContentPackLoader
extends RefCounted
## Carga contenido declarativo listado explícitamente en un manifiesto.

const MANIFEST_PATH := "res://content/expansions/manifest.json"

var ultimo_error := ""


func cargar() -> Dictionary:
	ultimo_error = ""
	var manifiesto := _leer_json(MANIFEST_PATH)
	if not ultimo_error.is_empty():
		return {}
	if not _version_compatible(manifiesto.get("version", null)):
		_fallar("%s: versión de manifiesto no compatible." % MANIFEST_PATH)
		return {}

	var paquetes: Variant = manifiesto.get("paquetes", null)
	if not paquetes is Array:
		_fallar("%s: «paquetes» debe ser una lista." % MANIFEST_PATH)
		return {}

	var contenido := {
		"habitaciones": [],
		"objetos": {},
		"npcs": [],
		"conexiones": [],
	}
	var rutas_cargadas: Dictionary = {}
	var ids: Dictionary = {"habitaciones": {}, "objetos": {}, "npcs": {}}

	for ruta_bruta in paquetes:
		if not ruta_bruta is String or str(ruta_bruta).is_empty():
			_fallar("%s: cada paquete debe tener una ruta de texto." % MANIFEST_PATH)
			return {}
		var ruta := str(ruta_bruta)
		if not ruta.begins_with("res://") or not ruta.ends_with(".json"):
			_fallar("%s: ruta de paquete no válida: %s" % [MANIFEST_PATH, ruta])
			return {}
		if rutas_cargadas.has(ruta):
			_fallar("%s: paquete listado más de una vez: %s" % [MANIFEST_PATH, ruta])
			return {}
		rutas_cargadas[ruta] = true

		var paquete := _leer_json(ruta)
		if not ultimo_error.is_empty():
			return {}
		if not _version_compatible(paquete.get("version", null)):
			_fallar("%s: versión de paquete no compatible." % ruta)
			return {}

		if not _cargar_objetos(paquete.get("objetos", []), ruta, contenido, ids):
			return {}
		if not _cargar_npcs(paquete.get("npcs", []), ruta, contenido, ids):
			return {}
		if not _cargar_habitaciones(paquete.get("habitaciones", []), ruta, contenido, ids):
			return {}
		if not _cargar_conexiones(paquete.get("conexiones", []), ruta, contenido):
			return {}

	return contenido


func _leer_json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		_fallar("No existe el archivo de contenido: %s" % ruta)
		return {}
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_fallar("No se pudo abrir %s: %s" % [ruta, error_string(FileAccess.get_open_error())])
		return {}

	var parser := JSON.new()
	var error := parser.parse(archivo.get_as_text())
	if error != OK:
		_fallar("%s:%d: %s" % [ruta, parser.get_error_line(), parser.get_error_message()])
		return {}
	if not parser.data is Dictionary:
		_fallar("%s: la raíz JSON debe ser un objeto." % ruta)
		return {}
	return parser.data


func _cargar_objetos(valor: Variant, ruta: String, contenido: Dictionary, ids: Dictionary) -> bool:
	if not valor is Array:
		return _fallar("%s: «objetos» debe ser una lista." % ruta)
	for datos in valor:
		if not datos is Dictionary:
			return _fallar("%s: cada objeto debe ser un objeto JSON." % ruta)
		var objeto_id := _id_requerido(datos, "id", ruta, "objeto")
		if objeto_id.is_empty() or not _registrar_id("objetos", objeto_id, ruta, ids):
			return false
		for campo in ["nombre", "descripcion", "uso"]:
			if not datos.get(campo, null) is String:
				return _fallar("%s: el objeto «%s» requiere el campo de texto «%s»." % [ruta, objeto_id, campo])
		for campo in ["cordura_al_examinar", "cordura_al_coger"]:
			var impacto: Variant = datos.get(campo, 0)
			if not _es_numero(impacto):
				return _fallar("%s: «%s.%s» debe ser numérico." % [ruta, objeto_id, campo])

		contenido["objetos"][objeto_id] = {
			"nombre": str(datos["nombre"]),
			"descripcion": str(datos["descripcion"]),
			"uso": str(datos["uso"]),
			"cordura_al_examinar": int(datos.get("cordura_al_examinar", 0)),
			"cordura_al_coger": int(datos.get("cordura_al_coger", 0)),
		}
	return true


func _cargar_npcs(valor: Variant, ruta: String, contenido: Dictionary, ids: Dictionary) -> bool:
	if not valor is Array:
		return _fallar("%s: «npcs» debe ser una lista." % ruta)
	for datos in valor:
		if not datos is Dictionary:
			return _fallar("%s: cada NPC debe ser un objeto JSON." % ruta)
		var npc_id := _id_requerido(datos, "id", ruta, "NPC")
		if npc_id.is_empty() or not _registrar_id("npcs", npc_id, ruta, ids):
			return false
		for campo in ["nombre", "descripcion"]:
			if not datos.get(campo, null) is String:
				return _fallar("%s: el NPC «%s» requiere el campo de texto «%s»." % [ruta, npc_id, campo])
		var alias := _lista_texto(datos.get("alias", []), ruta, "%s.alias" % npc_id)
		if not ultimo_error.is_empty():
			return false
		var dialogos := _lista_texto(datos.get("dialogos", []), ruta, "%s.dialogos" % npc_id)
		if not ultimo_error.is_empty():
			return false
		var impacto: Variant = datos.get("impacto_cordura_inicial", 0)
		if not _es_numero(impacto):
			return _fallar("%s: «%s.impacto_cordura_inicial» debe ser numérico." % [ruta, npc_id])
		var despedida: Variant = datos.get("despedida", "")
		if not despedida is String:
			return _fallar("%s: «%s.despedida» debe ser texto." % [ruta, npc_id])

		var npc := NpcData.new()
		npc.id = npc_id
		npc.nombre = str(datos["nombre"])
		npc.descripcion = str(datos["descripcion"])
		npc.alias = alias
		npc.dialogos = dialogos
		npc.despedida = str(despedida)
		npc.impacto_cordura_inicial = int(impacto)
		contenido["npcs"].append(npc)
	return true


func _cargar_habitaciones(valor: Variant, ruta: String, contenido: Dictionary, ids: Dictionary) -> bool:
	if not valor is Array:
		return _fallar("%s: «habitaciones» debe ser una lista." % ruta)
	for datos in valor:
		if not datos is Dictionary:
			return _fallar("%s: cada habitación debe ser un objeto JSON." % ruta)
		var sala_id := _id_requerido(datos, "id", ruta, "habitación")
		if sala_id.is_empty() or not _registrar_id("habitaciones", sala_id, ruta, ids):
			return false
		for campo in ["nombre", "descripcion_larga", "descripcion_corta"]:
			if not datos.get(campo, null) is String:
				return _fallar("%s: la habitación «%s» requiere el campo de texto «%s»." % [ruta, sala_id, campo])
		var conexiones: Variant = datos.get("conexiones", {})
		if not conexiones is Dictionary:
			return _fallar("%s: «%s.conexiones» debe ser un objeto." % [ruta, sala_id])
		var impacto: Variant = datos.get("impacto_cordura", 0)
		if not _es_numero(impacto):
			return _fallar("%s: «%s.impacto_cordura» debe ser numérico." % [ruta, sala_id])
		var ambiente: Variant = datos.get("ambiente", "")
		if not ambiente is String:
			return _fallar("%s: «%s.ambiente» debe ser texto." % [ruta, sala_id])
		var objetos := _lista_texto(datos.get("objetos_en_sala", []), ruta, "%s.objetos_en_sala" % sala_id)
		if not ultimo_error.is_empty():
			return false
		var npcs := _lista_texto(datos.get("npcs", []), ruta, "%s.npcs" % sala_id)
		if not ultimo_error.is_empty():
			return false
		if not _validar_conexiones(conexiones, ruta, sala_id):
			return false
		var examinables: Variant = datos.get("examinables", {})
		if not _validar_examinables(examinables, ruta, sala_id):
			return false
		for campo in ["requisitos_conexiones", "requisitos_objetos"]:
			if not _validar_requisitos(datos.get(campo, {}), ruta, sala_id, campo):
				return false

		var sala := Room.new()
		sala.id = sala_id
		sala.nombre = str(datos["nombre"])
		sala.descripcion_larga = str(datos["descripcion_larga"])
		sala.descripcion_corta = str(datos["descripcion_corta"])
		sala.conexiones = conexiones.duplicate(true)
		sala.objetos_en_sala = objetos
		sala.npcs = npcs
		sala.impacto_cordura = int(impacto)
		sala.ambiente = str(ambiente)
		sala.examinables = examinables.duplicate(true)
		sala.requisitos_conexiones = datos.get("requisitos_conexiones", {}).duplicate(true)
		sala.requisitos_objetos = datos.get("requisitos_objetos", {}).duplicate(true)
		contenido["habitaciones"].append(sala)
	return true


func _cargar_conexiones(valor: Variant, ruta: String, contenido: Dictionary) -> bool:
	if not valor is Array:
		return _fallar("%s: «conexiones» debe ser una lista." % ruta)
	for extension in valor:
		if not extension is Dictionary:
			return _fallar("%s: cada extensión de conexiones debe ser un objeto JSON." % ruta)
		var sala_id := _id_requerido(extension, "sala", ruta, "conexión")
		if sala_id.is_empty():
			return false
		var conexiones: Variant = extension.get("conexiones", null)
		if not conexiones is Dictionary or conexiones.is_empty():
			return _fallar("%s: «conexiones» de «%s» debe ser un objeto no vacío." % [ruta, sala_id])
		if not _validar_conexiones(conexiones, ruta, sala_id):
			return false
		contenido["conexiones"].append({
			"sala": sala_id,
			"conexiones": conexiones.duplicate(true),
		})
	return true


func _validar_conexiones(conexiones: Dictionary, ruta: String, sala_id: String) -> bool:
	for direccion in conexiones:
		if not direccion is String or str(direccion).is_empty():
			return _fallar("%s: dirección de salida no válida en «%s»." % [ruta, sala_id])
		if not conexiones[direccion] is String or str(conexiones[direccion]).is_empty():
			return _fallar("%s: destino no válido para «%s» en «%s»." % [ruta, direccion, sala_id])
	return true


func _validar_examinables(valor: Variant, ruta: String, sala_id: String) -> bool:
	if not valor is Dictionary:
		return _fallar("%s: «%s.examinables» debe ser un objeto." % [ruta, sala_id])
	for clave in valor:
		var examinable: Variant = valor[clave]
		if not clave is String or not examinable is Dictionary:
			return _fallar("%s: examinable no válido en «%s»." % [ruta, sala_id])
		for campo in ["nombre", "descripcion"]:
			if not examinable.get(campo, null) is String:
				return _fallar("%s: «%s.%s» requiere «%s» de texto." % [ruta, sala_id, clave, campo])
		var impacto: Variant = examinable.get("impacto_cordura", 0)
		if not _es_numero(impacto):
			return _fallar("%s: «%s.%s.impacto_cordura» debe ser numérico." % [ruta, sala_id, clave])
		var alias := _lista_texto(examinable.get("alias", []), ruta, "%s.%s.alias" % [sala_id, clave])
		if not ultimo_error.is_empty():
			return false
		examinable["alias"] = alias
	return true


func _validar_requisitos(valor: Variant, ruta: String, sala_id: String, campo: String) -> bool:
	if not valor is Dictionary:
		return _fallar("%s: «%s.%s» debe ser un objeto." % [ruta, sala_id, campo])
	for clave in valor:
		var requisito: Variant = valor[clave]
		if requisito is Array:
			var lista := _lista_texto(requisito, ruta, "%s.%s.%s" % [sala_id, campo, clave])
			if not ultimo_error.is_empty():
				return false
			valor[clave] = lista
			continue
		if not requisito is Dictionary:
			return _fallar("%s: requisito no válido para «%s» en «%s»." % [clave, sala_id, campo])
		for propiedad in ["objetos", "consumir"]:
			if requisito.has(propiedad):
				var lista := _lista_texto(requisito[propiedad], ruta, "%s.%s.%s.%s" % [sala_id, campo, clave, propiedad])
				if not ultimo_error.is_empty():
					return false
				requisito[propiedad] = lista
		if requisito.has("mensaje") and not requisito["mensaje"] is String:
			return _fallar("%s: mensaje no válido para el requisito «%s»." % [ruta, clave])
	return true


func _lista_texto(valor: Variant, ruta: String, campo: String) -> Array[String]:
	var resultado: Array[String] = []
	if not valor is Array:
		_fallar("%s: «%s» debe ser una lista de textos." % [ruta, campo])
		return resultado
	for elemento in valor:
		if not elemento is String or str(elemento).is_empty():
			_fallar("%s: «%s» contiene un valor que no es texto no vacío." % [ruta, campo])
			return []
		resultado.append(str(elemento))
	return resultado


func _id_requerido(datos: Dictionary, campo: String, ruta: String, tipo: String) -> String:
	var valor: Variant = datos.get(campo, null)
	if not valor is String or str(valor).is_empty():
		_fallar("%s: cada %s requiere un «%s» de texto no vacío." % [ruta, tipo, campo])
		return ""
	return str(valor)


func _registrar_id(tipo: String, id: String, ruta: String, ids: Dictionary) -> bool:
	if ids[tipo].has(id):
		return _fallar("%s: ID duplicado para %s: %s" % [ruta, tipo, id])
	ids[tipo][id] = true
	return true


func _es_numero(valor: Variant) -> bool:
	return typeof(valor) == TYPE_INT or typeof(valor) == TYPE_FLOAT


func _version_compatible(valor: Variant) -> bool:
	return _es_numero(valor) and float(valor) == 1.0


func _fallar(mensaje: String) -> bool:
	ultimo_error = mensaje
	return false
