class_name RoomManager
extends Node
## Gestor del mapa. Mantiene las habitaciones, los NPC y el estado mutable de
## los objetos retirados de cada sala.

var habitaciones: Dictionary = {}
var npcs: Dictionary = {}
var _objetos_retirados: Dictionary = {}
var ultimo_error := ""


func cargar_mapa() -> bool:
	ultimo_error = ""
	var cargador := ContentPackLoader.new()
	var contenido := cargador.cargar()
	if contenido.is_empty():
		return _fallar(cargador.ultimo_error)

	var nuevas_habitaciones := RoomDatabase.crear_habitaciones()
	var nuevos_npcs := RoomDatabase.crear_npcs()
	var nuevos_objetos: Dictionary = contenido.get("objetos", {})

	for objeto_id in nuevos_objetos:
		if ItemDB.OBJETOS.has(objeto_id):
			return _fallar("El paquete intenta reemplazar un objeto existente: %s" % objeto_id)

	for sala_bruta in contenido.get("habitaciones", []):
		var sala := sala_bruta as Room
		if sala == null or nuevas_habitaciones.has(sala.id):
			return _fallar("ID de habitación duplicado o no válido: %s" % (sala.id if sala != null else ""))
		nuevas_habitaciones[sala.id] = sala

	for npc_bruto in contenido.get("npcs", []):
		var npc := npc_bruto as NpcData
		if npc == null or nuevos_npcs.has(npc.id):
			return _fallar("ID de personaje duplicado o no válido: %s" % (npc.id if npc != null else ""))
		nuevos_npcs[npc.id] = npc

	for extension in contenido.get("conexiones", []):
		var sala_id := str(extension.get("sala", ""))
		var sala := nuevas_habitaciones.get(sala_id) as Room
		if sala == null:
			return _fallar("La conexión ampliada referencia una sala inexistente: %s" % sala_id)
		var conexiones: Dictionary = extension.get("conexiones", {})
		for direccion in conexiones:
			if sala.conexiones.has(direccion):
				return _fallar("La sala «%s» ya tiene una salida «%s»." % [sala_id, direccion])
			sala.conexiones[direccion] = conexiones[direccion]

	if not _validar_contenido(nuevas_habitaciones, nuevos_npcs, nuevos_objetos):
		return false

	habitaciones = nuevas_habitaciones
	npcs = nuevos_npcs
	ItemDB.establecer_extensiones(nuevos_objetos)
	_objetos_retirados.clear()
	return true


func reiniciar_estado() -> void:
	_objetos_retirados.clear()


func _validar_contenido(
	nuevas_habitaciones: Dictionary,
	nuevos_npcs: Dictionary,
	nuevos_objetos: Dictionary
) -> bool:
	for sala_bruta in nuevas_habitaciones.values():
		var sala := sala_bruta as Room
		for destino_bruto in sala.conexiones.values():
			var destino := str(destino_bruto)
			if not nuevas_habitaciones.has(destino):
				return _fallar("La salida de «%s» apunta a una sala inexistente: %s" % [sala.id, destino])
		for objeto_bruto in sala.objetos_en_sala:
			var objeto_id := str(objeto_bruto)
			if not ItemDB.contiene(objeto_id, nuevos_objetos):
				return _fallar("La sala «%s» referencia un objeto inexistente: %s" % [sala.id, objeto_id])
		for npc_bruto in sala.npcs:
			var npc_id := str(npc_bruto)
			if not nuevos_npcs.has(npc_id):
				return _fallar("La sala «%s» referencia un personaje inexistente: %s" % [sala.id, npc_id])

		for direccion in sala.requisitos_conexiones:
			if not sala.conexiones.has(direccion):
				return _fallar("El requisito de salida «%s» no tiene conexión en «%s»." % [direccion, sala.id])
			for objeto_id in sala.objetos_requeridos_conexion(str(direccion)):
				if not ItemDB.contiene(objeto_id, nuevos_objetos):
					return _fallar("El requisito de «%s» referencia un objeto inexistente: %s" % [sala.id, objeto_id])

		for objeto_id in sala.requisitos_objetos:
			if not ItemDB.contiene(str(objeto_id), nuevos_objetos):
				return _fallar("El requisito de «%s» referencia un objeto inexistente: %s" % [sala.id, objeto_id])
			var requisito := sala.requisito_para(str(objeto_id))
			for requerido in sala.objetos_requeridos(str(objeto_id)):
				if not ItemDB.contiene(requerido, nuevos_objetos):
					return _fallar("El requisito de «%s» referencia un objeto inexistente: %s" % [sala.id, requerido])
			var consumidos: Variant = requisito.get("consumir", [])
			if consumidos is Array:
				for consumido in consumidos:
					if not ItemDB.contiene(str(consumido), nuevos_objetos):
						return _fallar("El requisito de «%s» consume un objeto inexistente: %s" % [sala.id, consumido])
	return true


func _fallar(mensaje: String) -> bool:
	ultimo_error = mensaje
	push_error("RoomManager: " + mensaje)
	return false


func obtener(habitacion_id: String) -> Room:
	return habitaciones.get(habitacion_id) as Room


func existe(habitacion_id: String) -> bool:
	return habitaciones.has(habitacion_id)


func obtener_npc(npc_id: String) -> NpcData:
	return npcs.get(npc_id) as NpcData


## Busca un NPC por nombre o alias. La pertenencia a la sala se comprueba en Game.
func buscar_npc(texto: String) -> NpcData:
	for npc in npcs.values():
		var datos := npc as NpcData
		if datos != null and datos.coincide(texto):
			return datos
	return null


func objetos_visibles(habitacion_id: String) -> Array[String]:
	var sala := obtener(habitacion_id)
	var visibles: Array[String] = []
	if sala == null:
		return visibles

	var retirados: Array = _objetos_retirados.get(habitacion_id, [])
	for objeto_id in sala.objetos_en_sala:
		if not retirados.has(objeto_id):
			visibles.append(objeto_id)
	return visibles


func objeto_visible(habitacion_id: String, objeto_id: String) -> bool:
	return objetos_visibles(habitacion_id).has(objeto_id)


func retirar_objeto(habitacion_id: String, objeto_id: String) -> void:
	if not _objetos_retirados.has(habitacion_id):
		_objetos_retirados[habitacion_id] = []
	_objetos_retirados[habitacion_id].append(objeto_id)


## Estado mínimo del mapa que debe persistir en un guardado. Las salas y los
## NPC son datos inmutables, así que solo hacen falta los objetos ya retirados.
func serializar_objetos() -> Dictionary:
	return _objetos_retirados.duplicate(true)


func deserializar_objetos(datos: Dictionary) -> void:
	_objetos_retirados.clear()
	for habitacion_id in datos:
		var lista: Variant = datos[habitacion_id]
		if not lista is Array:
			continue

		var limpia: Array[String] = []
		for objeto in lista:
			if objeto is String:
				var objeto_id := str(objeto)
				if not limpia.has(objeto_id):
					limpia.append(objeto_id)
		if not limpia.is_empty():
			_objetos_retirados[str(habitacion_id)] = limpia


## Resuelve "ir a la plaza", "ir al muelle", "sur", etc. a una clave de
## conexión. Devuelve "" si no hay salida coincidente.
func resolver_conexion(sala: Room, objetivo: String) -> String:
	if sala == null:
		return ""

	var clave := TextUtils.normalizar(objetivo)
	if clave.is_empty():
		return ""

	for direccion in sala.conexiones:
		if TextUtils.normalizar(str(direccion)) == clave:
			return str(direccion)

	for direccion in sala.conexiones:
		var destino_id := str(sala.conexiones[direccion])
		var destino := obtener(destino_id)
		if destino == null:
			continue
		if TextUtils.coincide(clave, [destino.id, destino.nombre, direccion]):
			return str(direccion)
	return ""
