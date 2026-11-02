extends Node
## Persistencia de partidas en JSON dentro de user://.
## No conoce el formato interno de PlayerState/RoomManager: recibe un
## diccionario, le añade metadatos y lo escribe de forma atómica mediante
## un archivo temporal y un respaldo.

const VERSION_GUARDADO := 1
const CANTIDAD_RANURAS := 3
const RUTA_PREDETERMINADA := "user://innsmouth_save.json"
const RUTA_AUTOGUARDADO := "user://innsmouth_autosave.json"
const PREFIJO_RANURAS_PREDETERMINADO := "user://innsmouth_save"
const SUFIJO_TEMPORAL := ".tmp"
const SUFIJO_RESPALDO := ".bak"

var ruta_guardado: String = RUTA_PREDETERMINADA
var ruta_autoguardado: String = RUTA_AUTOGUARDADO
var prefijo_ranuras := PREFIJO_RANURAS_PREDETERMINADO
var ranura_actual := 1
var ultimo_error: String = ""


func guardar(datos: Dictionary) -> bool:
	ultimo_error = ""
	if datos.is_empty():
		ultimo_error = "No hay datos que guardar."
		return false

	var payload: Dictionary = datos.duplicate(true)
	payload["version"] = VERSION_GUARDADO
	payload["guardado_en"] = Time.get_datetime_string_from_system()

	var contenido := JSON.stringify(payload, "\t")
	if contenido.is_empty():
		ultimo_error = "No se pudo serializar la partida."
		return false

	if not _asegurar_directorio():
		return false

	var ruta_temporal := ruta_guardado + SUFIJO_TEMPORAL
	var archivo := FileAccess.open(ruta_temporal, FileAccess.WRITE)
	if archivo == null:
		ultimo_error = "No se pudo abrir el archivo temporal de guardado (%s)." % FileAccess.get_open_error()
		return false

	archivo.store_string(contenido)
	archivo.close()

	# Verificar que el contenido llegó completo antes de sustituir el guardado.
	if FileAccess.get_file_as_string(ruta_temporal) != contenido:
		_borrar_si_existe(ruta_temporal)
		ultimo_error = "La escritura del guardado quedó incompleta."
		return false

	var ruta_respaldo := ruta_guardado + SUFIJO_RESPALDO
	if not _borrar_si_existe(ruta_respaldo):
		_borrar_si_existe(ruta_temporal)
		ultimo_error = "No se pudo preparar el respaldo del guardado."
		return false

	if FileAccess.file_exists(ruta_guardado) and not _renombrar(ruta_guardado, ruta_respaldo):
		_borrar_si_existe(ruta_temporal)
		ultimo_error = "No se pudo apartar el guardado anterior."
		return false

	if not _renombrar(ruta_temporal, ruta_guardado):
		if FileAccess.file_exists(ruta_respaldo) and not FileAccess.file_exists(ruta_guardado):
			_renombrar(ruta_respaldo, ruta_guardado)
		_borrar_si_existe(ruta_temporal)
		ultimo_error = "No se pudo reemplazar el archivo de guardado."
		return false

	_borrar_si_existe(ruta_respaldo)
	return true


func cargar() -> Dictionary:
	ultimo_error = ""
	_recuperar_respaldo()
	if not FileAccess.file_exists(ruta_guardado):
		ultimo_error = "No hay ninguna partida guardada."
		return {}

	var archivo := FileAccess.open(ruta_guardado, FileAccess.READ)
	if archivo == null:
		ultimo_error = "No se pudo leer el archivo de guardado."
		return {}

	var contenido := archivo.get_as_text()
	archivo.close()
	if contenido.strip_edges().is_empty():
		ultimo_error = "El archivo de guardado está vacío."
		return {}

	var parsed: Variant = JSON.parse_string(contenido)
	if typeof(parsed) != TYPE_DICTIONARY:
		ultimo_error = "El archivo de guardado está corrupto."
		return {}

	var datos: Dictionary = parsed
	if not datos.has("version") or int(datos.get("version", 0)) != VERSION_GUARDADO:
		ultimo_error = "La versión del guardado no es compatible."
		return {}

	return datos


func existe() -> bool:
	_recuperar_respaldo()
	return FileAccess.file_exists(ruta_guardado)


func borrar() -> bool:
	ultimo_error = ""
	_recuperar_respaldo()

	var existia := FileAccess.file_exists(ruta_guardado)
	var codigo := OK
	if existia:
		codigo = DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_guardado))

	# Limpiar restos de una escritura interrumpida.
	_borrar_si_existe(ruta_guardado + SUFIJO_TEMPORAL)
	_borrar_si_existe(ruta_guardado + SUFIJO_RESPALDO)

	if not existia:
		return false
	if codigo != OK:
		ultimo_error = "No se pudo borrar el archivo de guardado."
		return false
	return true


func ruta_legible() -> String:
	return ProjectSettings.globalize_path(ruta_guardado)


## Para pruebas automatizadas o para futuras ranuras de guardado.
func usar_ruta(ruta: String) -> void:
	if not ruta.is_empty():
		ruta_guardado = ruta


func restaurar_ruta() -> void:
	ruta_guardado = RUTA_PREDETERMINADA


func guardar_autoguardado(datos: Dictionary) -> bool:
	var ruta_anterior := ruta_guardado
	ruta_guardado = ruta_autoguardado
	var resultado := guardar(datos)
	ruta_guardado = ruta_anterior
	return resultado


func cargar_autoguardado() -> Dictionary:
	var ruta_anterior := ruta_guardado
	ruta_guardado = ruta_autoguardado
	var datos := cargar()
	ruta_guardado = ruta_anterior
	return datos


func existe_autoguardado() -> bool:
	var ruta_anterior := ruta_guardado
	ruta_guardado = ruta_autoguardado
	var resultado := existe()
	ruta_guardado = ruta_anterior
	return resultado


func borrar_autoguardado() -> bool:
	var ruta_anterior := ruta_guardado
	ruta_guardado = ruta_autoguardado
	var resultado := borrar()
	ruta_guardado = ruta_anterior
	return resultado


func ruta_autoguardado_legible() -> String:
	return ProjectSettings.globalize_path(ruta_autoguardado)


func usar_ruta_autoguardado(ruta: String) -> void:
	if not ruta.is_empty():
		ruta_autoguardado = ruta


func restaurar_rutas() -> void:
	ruta_guardado = RUTA_PREDETERMINADA
	ruta_autoguardado = RUTA_AUTOGUARDADO
	prefijo_ranuras = PREFIJO_RANURAS_PREDETERMINADO
	ranura_actual = 1


func usar_ranura(ranura: int) -> bool:
	if ranura < 1 or ranura > CANTIDAD_RANURAS:
		ultimo_error = "La ranura debe estar entre 1 y %d." % CANTIDAD_RANURAS
		return false
	ranura_actual = ranura
	ruta_guardado = ruta_de_ranura(ranura)
	ultimo_error = ""
	return true


func ruta_de_ranura(ranura: int) -> String:
	if ranura < 1 or ranura > CANTIDAD_RANURAS:
		return ""
	if ranura == 1:
		return prefijo_ranuras + ".json"
	return "%s_%d.json" % [prefijo_ranuras, ranura]


func informacion_ranura(ranura: int) -> Dictionary:
	var ruta := ruta_de_ranura(ranura)
	if ruta.is_empty():
		return {"ocupada": false, "valida": false}

	var ruta_anterior := ruta_guardado
	var error_anterior := ultimo_error
	ruta_guardado = ruta
	var datos := cargar()
	var ocupada := FileAccess.file_exists(ruta_guardado)
	ruta_guardado = ruta_anterior
	ultimo_error = error_anterior

	if datos.is_empty():
		return {"ocupada": ocupada, "valida": false}
	var jugador: Variant = datos.get("jugador", {})
	if not jugador is Dictionary or (jugador as Dictionary).is_empty():
		return {"ocupada": true, "valida": false}
	return {
		"ocupada": true,
		"valida": true,
		"guardado_en": str(datos.get("guardado_en", "Fecha desconocida")),
		"habitacion": str((jugador as Dictionary).get("habitacion_actual", "Partida")),
	}


func hay_guardados() -> bool:
	for ranura in range(1, CANTIDAD_RANURAS + 1):
		if bool(informacion_ranura(ranura).get("valida", false)):
			return true
	return false


func borrar_ranura(ranura: int) -> bool:
	if not usar_ranura(ranura):
		return false
	return borrar()


func usar_prefijo_ranuras(prefijo: String) -> void:
	if not prefijo.is_empty():
		prefijo_ranuras = prefijo


func _asegurar_directorio() -> bool:
	var base := _base_dir(ruta_guardado)
	var ruta_absoluta := ProjectSettings.globalize_path(base)
	if DirAccess.dir_exists_absolute(ruta_absoluta):
		return true

	var codigo := DirAccess.make_dir_recursive_absolute(ruta_absoluta)
	if codigo != OK and codigo != ERR_ALREADY_EXISTS:
		ultimo_error = "No se pudo crear el directorio de guardado."
		return false
	return true


func _recuperar_respaldo() -> void:
	var respaldo := ruta_guardado + SUFIJO_RESPALDO
	if FileAccess.file_exists(ruta_guardado):
		_borrar_si_existe(respaldo)
		return
	if FileAccess.file_exists(respaldo):
		_renombrar(respaldo, ruta_guardado)


func _renombrar(origen: String, destino: String) -> bool:
	if _base_dir(origen) != _base_dir(destino):
		return false

	var dir := DirAccess.open(_base_dir(origen))
	if dir == null:
		return false
	return dir.rename(origen.get_file(), destino.get_file()) == OK


func _borrar_si_existe(ruta: String) -> bool:
	if not FileAccess.file_exists(ruta):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta)) == OK


func _base_dir(ruta: String) -> String:
	var base := ruta.get_base_dir()
	return base if not base.is_empty() else "user://"
