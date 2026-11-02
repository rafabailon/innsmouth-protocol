class_name Room
extends Resource
## Datos inmutables de una habitación. El estado variable (objetos recogidos,
## visitas...) vive en PlayerState/RoomManager para no contaminar los recursos.

@export var id: String = ""
@export var nombre: String = ""
@export_multiline var descripcion_larga: String = ""
@export_multiline var descripcion_corta: String = ""
@export var conexiones: Dictionary = {}
@export var objetos_en_sala: Array[String] = []
@export var impacto_cordura: int = 0
@export var examinables: Dictionary = {}
@export var npcs: Array[String] = []
@export_multiline var ambiente: String = ""
## Requisitos para usar una salida: dirección -> IDs de objeto o diccionario con "objetos" y "mensaje".
@export var requisitos_conexiones: Dictionary = {}
## Requisitos para retirar ciertos objetos de la sala. El formato recomendado es:
## { "objeto_id": { "objetos": ["llave_oxidada"], "consumir": ["llave_oxidada"], "mensaje": "..." } }
## También se admite directamente un Array de IDs como atajo.
@export var requisitos_objetos: Dictionary = {}


func conexion(direccion: String) -> String:
	return str(conexiones.get(direccion, ""))


func requisito_para_conexion(direccion: String) -> Dictionary:
	var datos: Variant = requisitos_conexiones.get(direccion, {})
	if datos is Array:
		return {"objetos": datos}
	if datos is Dictionary:
		return datos
	return {}


func objetos_requeridos_conexion(direccion: String) -> Array[String]:
	return _normalizar_objetos_requeridos(requisito_para_conexion(direccion))


## Devuelve los datos de requisito de un objeto, normalizados a diccionario.
func requisito_para(objeto_id: String) -> Dictionary:
	var datos: Variant = requisitos_objetos.get(objeto_id, {})
	if datos is Array:
		return {"objetos": datos}
	if datos is Dictionary:
		return datos
	return {}


func objetos_requeridos(objeto_id: String) -> Array[String]:
	return _normalizar_objetos_requeridos(requisito_para(objeto_id))


func _normalizar_objetos_requeridos(datos: Dictionary) -> Array[String]:
	var requeridos: Array[String] = []
	var lista: Variant = datos.get("objetos", [])
	if lista is Array:
		for objeto in lista:
			var texto := str(objeto)
			if not texto.is_empty() and not requeridos.has(texto):
				requeridos.append(texto)
	return requeridos


## Busca una zona/objeto inspeccionable por clave, nombre o alias.
## Devuelve una copia con la clave incluida para poder registrar el examen.
func buscar_examinable(texto: String) -> Dictionary:
	for clave in examinables:
		var datos: Dictionary = examinables[clave]
		var candidatos: Array = [clave, datos.get("nombre", "")]
		if datos.has("alias"):
			candidatos.append_array(datos["alias"])
		if TextUtils.coincide(texto, candidatos):
			var encontrado: Dictionary = datos.duplicate(true)
			encontrado["clave"] = clave
			return encontrado
	return {}
