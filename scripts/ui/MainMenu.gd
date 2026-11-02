extends Control
class_name MainMenu
## Menú inicial, pausa, gestión de ranuras y preferencias.

signal nueva_partida
signal continuar_partida
signal cargar_ranura(ranura: int)
signal guardar_ranura(ranura: int)
signal reanudar
signal volver_al_inicio
signal salir

var _modo := "inicio"
var _accion_ranura := "cargar"
var _en_partida := false
var _contenido: VBoxContainer
var _panel: PanelContainer
var _color_fondo: ColorRect
var _error_pendiente := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	SettingsManager.opciones_cambiadas.connect(_actualizar_accesibilidad_menu)

	_color_fondo = ColorRect.new()
	_color_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_color_fondo.color = Color(0.008, 0.014, 0.01, 0.88)
	_color_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_color_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(480, 0)
	var estilo_panel := StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0.018, 0.031, 0.022, 0.98)
	estilo_panel.border_color = Color(0.31, 0.43, 0.32, 1.0)
	estilo_panel.set_border_width_all(1)
	estilo_panel.set_corner_radius_all(3)
	_panel.add_theme_stylebox_override("panel", estilo_panel)
	centro.add_child(_panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 30)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_right", 30)
	margen.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(margen)

	_contenido = VBoxContainer.new()
	_contenido.add_theme_constant_override("separation", 10)
	margen.add_child(_contenido)
	hide()


func mostrar_inicio(hay_autoguardado: bool, hay_guardado: bool) -> void:
	_modo = "inicio"
	_en_partida = false
	_error_pendiente = ""
	visible = true
	_dibujar(hay_autoguardado, hay_guardado)


func mostrar_error(texto: String) -> void:
	_error_pendiente = texto
	if not is_instance_valid(_contenido):
		return
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_color_override("font_color", Color(0.95, 0.48, 0.4))
	_contenido.add_child(etiqueta)
	_actualizar_accesibilidad_menu()


func opcion_habilitada(texto: String) -> bool:
	for control in _contenido.get_children():
		if control is Button and (control as Button).text == texto:
			return not (control as Button).disabled
	return false


func mostrar_pausa() -> void:
	_modo = "pausa"
	_en_partida = true
	visible = true
	_dibujar(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())


func _dibujar(hay_autoguardado: bool, hay_guardado: bool) -> void:
	for hijo in _contenido.get_children():
		_contenido.remove_child(hijo)
		hijo.queue_free()

	var titulo := Label.new()
	titulo.text = "INNSMOUTH PROTOCOL"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color(0.89, 0.69, 0.39))
	titulo.set_meta("tamano_fuente_original", 23)
	_contenido.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "La marea siempre encuentra el camino de vuelta."
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitulo.add_theme_color_override("font_color", Color(0.73, 0.79, 0.7))
	_contenido.add_child(subtitulo)
	_agregar_separador()

	if _modo == "ranuras":
		_dibujar_ranuras()
		_actualizar_accesibilidad_menu()
		return
	if _modo == "ajustes":
		_dibujar_ajustes()
		_actualizar_accesibilidad_menu()
		return

	if _modo == "inicio":
		_agregar_boton("Nueva partida", func() -> void: nueva_partida.emit())
		_agregar_boton("Continuar", func() -> void: continuar_partida.emit(), not hay_autoguardado)
		_agregar_boton("Cargar partida", func() -> void: _mostrar_ranuras("cargar"), not hay_guardado)
	else:
		_agregar_boton("Volver al juego", func() -> void: reanudar.emit())
		_agregar_boton("Guardar en una ranura", func() -> void: _mostrar_ranuras("guardar"))
		_agregar_boton("Cargar partida", func() -> void: _mostrar_ranuras("cargar"), not hay_guardado)

	_agregar_boton("Ajustes", func() -> void: _mostrar_ajustes())
	if _modo == "pausa":
		_agregar_boton("Volver al menú principal", func() -> void: volver_al_inicio.emit())
	_agregar_boton("Salir", func() -> void: salir.emit())
	if not _error_pendiente.is_empty():
		mostrar_error(_error_pendiente)
		_error_pendiente = ""
	_actualizar_accesibilidad_menu()


func _mostrar_ranuras(accion: String) -> void:
	_accion_ranura = accion
	_modo = "ranuras"
	_dibujar(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())


func _dibujar_ranuras() -> void:
	var instruccion := Label.new()
	instruccion.text = "Elige dónde guardar." if _accion_ranura == "guardar" else "Elige una partida guardada."
	instruccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contenido.add_child(instruccion)

	for ranura in range(1, SaveManager.CANTIDAD_RANURAS + 1):
		var info := SaveManager.informacion_ranura(ranura)
		var texto := "Ranura %d — Vacía" % ranura
		var ocupada := bool(info.get("ocupada", false))
		if ocupada:
			if bool(info.get("valida", false)):
				texto = "Ranura %d — %s · %s" % [
					ranura,
					str(info.get("habitacion", "Partida")),
					str(info.get("guardado_en", ""))
				]
			else:
				texto = "Ranura %d — Archivo no válido" % ranura
		var callable := _seleccionar_ranura.bind(ranura)
		_agregar_boton(texto, callable, _accion_ranura == "cargar" and not bool(info.get("valida", false)))

	_agregar_boton("Volver", func() -> void:
		_modo = "pausa" if _en_partida else "inicio"
		_dibujar(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())
	)


func _seleccionar_ranura(ranura: int) -> void:
	if _accion_ranura == "guardar":
		guardar_ranura.emit(ranura)
	else:
		cargar_ranura.emit(ranura)


func _mostrar_ajustes() -> void:
	_modo = "ajustes"
	_dibujar(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())


func _dibujar_ajustes() -> void:
	var tamano := HSlider.new()
	tamano.min_value = 0.8
	tamano.max_value = 1.6
	tamano.step = 0.1
	tamano.value = SettingsManager.tamano_texto
	_agregar_control_con_etiqueta("Tamaño del texto", tamano)
	tamano.value_changed.connect(func(valor: float) -> void: SettingsManager.establecer_tamano_texto(valor))

	var contraste := CheckButton.new()
	contraste.text = "Activado"
	contraste.button_pressed = SettingsManager.alto_contraste
	_agregar_control_con_etiqueta("Alto contraste", contraste)
	contraste.toggled.connect(SettingsManager.establecer_alto_contraste)

	var efectos := CheckButton.new()
	efectos.text = "Reducir líneas CRT"
	efectos.button_pressed = SettingsManager.reducir_efectos
	_contenido.add_child(efectos)
	efectos.toggled.connect(SettingsManager.establecer_reducir_efectos)

	var escritura := CheckButton.new()
	escritura.text = "Escritura progresiva"
	escritura.button_pressed = SettingsManager.efecto_tecleo
	_contenido.add_child(escritura)
	escritura.toggled.connect(SettingsManager.establecer_efecto_tecleo)

	var audio := CheckButton.new()
	audio.text = "Audio ambiental"
	audio.button_pressed = SettingsManager.audio_habilitado
	_contenido.add_child(audio)
	audio.toggled.connect(SettingsManager.establecer_audio_habilitado)

	var volumen := HSlider.new()
	volumen.min_value = 0.0
	volumen.max_value = 1.0
	volumen.step = 0.05
	volumen.value = SettingsManager.volumen_ambiente
	_agregar_control_con_etiqueta("Volumen ambiental", volumen)
	volumen.value_changed.connect(func(valor: float) -> void: SettingsManager.establecer_volumen_ambiente(valor))

	_agregar_boton("Restaurar ajustes", func() -> void:
		SettingsManager.restaurar_predeterminados()
		_dibujar_ajustes()
	)
	_agregar_boton("Volver", func() -> void:
		_modo = "pausa" if _en_partida else "inicio"
		_dibujar(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())
	)


func _agregar_control_con_etiqueta(texto: String, control: Control) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	_contenido.add_child(etiqueta)
	_contenido.add_child(control)


func _agregar_boton(texto: String, accion: Callable, deshabilitado := false) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 42)
	boton.disabled = deshabilitado
	boton.set_meta("tamano_fuente_original", 15)
	boton.pressed.connect(accion)
	_contenido.add_child(boton)


func _actualizar_accesibilidad_menu() -> void:
	if not is_instance_valid(_contenido):
		return
	for nodo in find_children("*", "Control", true, false):
		var control := nodo as Control
		if not control is Label and not control is Button:
			continue
		if not control.has_meta("tamano_fuente_original"):
			control.set_meta("tamano_fuente_original", control.get_theme_font_size("font_size"))
		control.add_theme_font_size_override(
			"font_size",
			roundi(int(control.get_meta("tamano_fuente_original")) * SettingsManager.tamano_texto)
		)
		if not control.has_meta("color_fuente_original"):
			control.set_meta("color_fuente_original", control.get_theme_color("font_color"))
		var color_original: Color = control.get_meta("color_fuente_original")
		control.add_theme_color_override(
			"font_color",
			Color.WHITE if SettingsManager.alto_contraste else color_original
		)


func _agregar_separador() -> void:
	var separador := HSeparator.new()
	_contenido.add_child(separador)
