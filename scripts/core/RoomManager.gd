class_name RoomManager
extends Node
## Gestor del mapa. Mantiene las habitaciones, los NPC y el estado mutable de
## los objetos retirados de cada sala.

var habitaciones: Dictionary = {}
var npcs: Dictionary = {}
var _objetos_retirados: Dictionary = {}


func cargar_mapa() -> void:
	habitaciones = RoomDatabase.crear_habitaciones()
	npcs = RoomDatabase.crear_npcs()
	_objetos_retirados.clear()


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
