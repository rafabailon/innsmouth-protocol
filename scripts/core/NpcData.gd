class_name NpcData
extends Resource
## Personaje no jugador. Los diálogos se consumen en orden; al terminarlos se
## repite la despedida.

@export var id: String = ""
@export var nombre: String = ""
@export var alias: Array[String] = []
@export_multiline var descripcion: String = ""
@export var dialogos: Array[String] = []
@export_multiline var despedida: String = ""
@export var impacto_cordura_inicial: int = 0


func coincide(texto: String) -> bool:
	var candidatos: Array = [id, nombre]
	candidatos.append_array(alias)
	return TextUtils.coincide(texto, candidatos)
