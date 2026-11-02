extends Node
## Preferencias locales persistentes, independientes de las partidas guardadas.

signal opciones_cambiadas

const TAMANO_TEXTO_PREDETERMINADO := 1.0
const VOLUMEN_PREDETERMINADO := 0.35

var ruta_configuracion := "user://settings.cfg"
var tamano_texto := TAMANO_TEXTO_PREDETERMINADO
var alto_contraste := false
var reducir_efectos := false
var audio_habilitado := true
var volumen_ambiente := VOLUMEN_PREDETERMINADO
var efecto_tecleo := false


func _ready() -> void:
	recargar()


func establecer_tamano_texto(valor: float) -> void:
	tamano_texto = snappedf(clampf(valor, 0.8, 1.6), 0.1)
	_guardar()


func establecer_alto_contraste(valor: bool) -> void:
	alto_contraste = valor
	_guardar()


func establecer_reducir_efectos(valor: bool) -> void:
	reducir_efectos = valor
	_guardar()


func establecer_audio_habilitado(valor: bool) -> void:
	audio_habilitado = valor
	_guardar()


func establecer_efecto_tecleo(valor: bool) -> void:
	efecto_tecleo = valor
	_guardar()


func establecer_volumen_ambiente(valor: float) -> void:
	volumen_ambiente = clampf(valor, 0.0, 1.0)
	_guardar()


func restaurar_predeterminados() -> void:
	tamano_texto = TAMANO_TEXTO_PREDETERMINADO
	alto_contraste = false
	reducir_efectos = false
	audio_habilitado = true
	volumen_ambiente = VOLUMEN_PREDETERMINADO
	efecto_tecleo = false
	_guardar()


func recargar() -> void:
	tamano_texto = TAMANO_TEXTO_PREDETERMINADO
	alto_contraste = false
	reducir_efectos = false
	audio_habilitado = true
	volumen_ambiente = VOLUMEN_PREDETERMINADO
	efecto_tecleo = false

	var config := ConfigFile.new()
	var error := config.load(ruta_configuracion)
	if error == ERR_FILE_NOT_FOUND:
		opciones_cambiadas.emit()
		return
	if error != OK:
		push_error("No se pudieron leer las preferencias (%s): %s" % [ruta_configuracion, error])
		opciones_cambiadas.emit()
		return

	tamano_texto = clampf(float(config.get_value("accesibilidad", "tamano_texto", tamano_texto)), 0.8, 1.6)
	alto_contraste = bool(config.get_value("accesibilidad", "alto_contraste", alto_contraste))
	reducir_efectos = bool(config.get_value("accesibilidad", "reducir_efectos", reducir_efectos))
	audio_habilitado = bool(config.get_value("audio", "habilitado", audio_habilitado))
	volumen_ambiente = clampf(float(config.get_value("audio", "volumen", volumen_ambiente)), 0.0, 1.0)
	efecto_tecleo = bool(config.get_value("accesibilidad", "efecto_tecleo", efecto_tecleo))
	opciones_cambiadas.emit()


func usar_ruta_configuracion(ruta: String) -> void:
	if not ruta.is_empty():
		ruta_configuracion = ruta


func restaurar_ruta_configuracion() -> void:
	ruta_configuracion = "user://settings.cfg"


func _guardar() -> void:
	var config := ConfigFile.new()
	config.set_value("accesibilidad", "tamano_texto", tamano_texto)
	config.set_value("accesibilidad", "alto_contraste", alto_contraste)
	config.set_value("accesibilidad", "reducir_efectos", reducir_efectos)
	config.set_value("audio", "habilitado", audio_habilitado)
	config.set_value("audio", "volumen", volumen_ambiente)
	config.set_value("accesibilidad", "efecto_tecleo", efecto_tecleo)
	var error := config.save(ruta_configuracion)
	if error != OK:
		push_error("No se pudieron guardar las preferencias (%s): %s" % [ruta_configuracion, error])
		return
	opciones_cambiadas.emit()
