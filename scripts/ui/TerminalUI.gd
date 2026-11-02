extends Control
class_name TerminalUI
## Capa de presentación. Solo conoce textos y estado visual; Game decide qué
## narrar y PlayerState guarda la verdad de la partida.

signal comando_enviado(texto: String)

const COLOR_TEXTO := "#c7d3c0"
const COLOR_VERDE := "#7fae87"
const COLOR_AMBAR := "#d8a657"
const COLOR_ROJO := "#c96a5a"
const COLOR_ROJO_OSCURO := "#8f4a42"
const COLOR_APAGADO := "#6f7d6b"
const COLOR_HABITACION := "#e0b36a"
const COLOR_LINEA := "#26352a"

@onready var historial: RichTextLabel = %Historial
@onready var scroll_historial: ScrollContainer = %ScrollHistorial
@onready var entrada: LineEdit = %Entrada
@onready var barra_cordura: ProgressBar = %BarraCordura
@onready var valor_cordura: Label = %ValorCordura
@onready var estado_cordura: Label = %EstadoCordura
@onready var inventario: RichTextLabel = %Inventario
@onready var ubicacion: Label = %Ubicacion
@onready var objetivo: Label = %Objetivo

var _hay_historial: bool = false
var _historial_comandos: Array[String] = []
var _indice_historial: int = 0
var _tween_barra: Tween = null
var _tween_escritura: Tween


func _ready() -> void:
	entrada.text_submitted.connect(_al_enviar)
	entrada.grab_focus()
	_configurar_barra()
	_estilizar_scrollbar(scroll_historial.get_v_scroll_bar())
	_estilizar_scrollbar(inventario.get_v_scroll_bar())
	actualizar_cordura(100, "Lúcido")
	actualizar_inventario([])


func _input(event: InputEvent) -> void:
	if not entrada.has_focus():
		return

	if event.is_action_pressed("ui_up"):
		if _historial_comandos.is_empty():
			return
		_indice_historial = maxi(0, _indice_historial - 1)
		entrada.text = _historial_comandos[_indice_historial]
		entrada.caret_column = entrada.text.length()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		if _historial_comandos.is_empty():
			return
		if _indice_historial < _historial_comandos.size() - 1:
			_indice_historial += 1
			entrada.text = _historial_comandos[_indice_historial]
			entrada.caret_column = entrada.text.length()
		else:
			_indice_historial = _historial_comandos.size()
			entrada.clear()
		get_viewport().set_input_as_handled()


func _al_enviar(texto: String) -> void:
	var limpio := texto.strip_edges()
	if limpio.is_empty():
		return

	entrada.clear()
	if _historial_comandos.is_empty() or _historial_comandos[-1] != limpio:
		_historial_comandos.append(limpio)
	_indice_historial = _historial_comandos.size()
	entrada.grab_focus()
	comando_enviado.emit(limpio)


func enfocar_entrada() -> void:
	entrada.grab_focus()


func aplicar_accesibilidad(escala: float, alto_contraste: bool) -> void:
	for control in find_children("*", "Control", true, false):
		var elemento := control as Control
		if elemento is Label or elemento is Button or elemento is LineEdit:
			if not elemento.has_meta("tamano_fuente_original"):
				elemento.set_meta("tamano_fuente_original", elemento.get_theme_font_size("font_size"))
			var base := int(elemento.get_meta("tamano_fuente_original"))
			elemento.add_theme_font_size_override("font_size", roundi(base * escala))
		elif elemento is RichTextLabel:
			if not elemento.has_meta("tamano_fuente_original"):
				elemento.set_meta("tamano_fuente_original", elemento.get_theme_font_size("normal_font_size"))
			var base := int(elemento.get_meta("tamano_fuente_original"))
			elemento.add_theme_font_size_override("normal_font_size", roundi(base * escala))

	if alto_contraste:
		historial.modulate = Color(1.25, 1.25, 1.25, 1.0)
		inventario.modulate = Color(1.25, 1.25, 1.25, 1.0)
		entrada.modulate = Color(1.2, 1.2, 1.2, 1.0)
	else:
		historial.modulate = Color.WHITE
		inventario.modulate = Color.WHITE
		entrada.modulate = Color.WHITE


func aplicar_efecto_tecleo(habilitado: bool) -> void:
	if _tween_escritura != null and _tween_escritura.is_valid():
		_tween_escritura.kill()
	if habilitado:
		historial.visible_characters = historial.get_total_character_count()
	else:
		historial.visible_characters = -1


func limpiar_historial() -> void:
	historial.clear()
	historial.visible_characters = -1
	if _tween_escritura != null and _tween_escritura.is_valid():
		_tween_escritura.kill()
	_hay_historial = false


func _agregar(texto: String) -> void:
	var caracteres_previos := historial.get_total_character_count()
	var caracteres_visibles := historial.visible_characters
	if caracteres_visibles < 0:
		caracteres_visibles = caracteres_previos
	if _hay_historial:
		historial.append_text("\n")
	historial.append_text(texto)
	_hay_historial = true
	if SettingsManager.efecto_tecleo:
		if _tween_escritura != null and _tween_escritura.is_valid():
			_tween_escritura.kill()
		var total := historial.get_total_character_count()
		historial.visible_characters = caracteres_visibles
		_tween_escritura = create_tween()
		var duracion := minf(float(total - caracteres_visibles) / 80.0, 3.0)
		_tween_escritura.tween_property(
			historial,
			"visible_characters",
			total,
			maxf(duracion, 0.05)
		).set_trans(Tween.TRANS_LINEAR)
	else:
		historial.visible_characters = -1
	_scroll_al_final()


func linea_en_blanco() -> void:
	_agregar(" ")


func separador() -> void:
	_agregar("[color=%s]────────────────────────────────────────────────────[/color]" % COLOR_LINEA)


func mostrar_titulo(texto: String) -> void:
	_agregar("\n[center][color=%s][font_size=24]%s[/font_size][/color][/center]" % [COLOR_AMBAR, texto])


func mostrar_subtitulo(texto: String) -> void:
	_agregar("[center][color=%s][font_size=13]%s[/font_size][/color][/center]" % [COLOR_APAGADO, texto])


func mostrar_habitacion(texto: String) -> void:
	_agregar("\n[color=%s][b]── %s ──[/b][/color]" % [COLOR_HABITACION, texto])


func mostrar_descripcion(texto: String) -> void:
	_agregar("[color=%s]%s[/color]" % [COLOR_TEXTO, texto])


func mostrar_dialogo(nombre: String, texto: String) -> void:
	_agregar("[color=%s][b]%s:[/b][/color] [color=#b8c9b0][i]%s[/i][/color]" % [COLOR_AMBAR, nombre, texto])


func mostrar_salidas(texto: String) -> void:
	_agregar("[color=%s][i]Salidas:[/i] %s[/color]" % [COLOR_APAGADO, texto])


func mostrar_objetos(texto: String) -> void:
	_agregar("[color=%s][i]Ves aquí:[/i] %s[/color]" % [COLOR_VERDE, texto])


func mostrar_personas(texto: String) -> void:
	_agregar("[color=%s][i]Personas:[/i] %s[/color]" % [COLOR_VERDE, texto])


func mostrar_sistema(texto: String) -> void:
	_agregar("[color=%s][i]%s[/i][/color]" % [COLOR_APAGADO, texto])


func mostrar_evento(texto: String) -> void:
	_agregar("[color=%s]%s[/color]" % [COLOR_AMBAR, texto])


func mostrar_peligro(texto: String) -> void:
	_agregar("[color=%s][i]%s[/i][/color]" % [COLOR_ROJO, texto])


func mostrar_panico(texto: String) -> void:
	_agregar("[shake rate=7 level=2][color=%s][b]%s[/b][/color][/shake]" % [COLOR_ROJO, texto])


func mostrar_susurro(texto: String) -> void:
	_agregar("[shake rate=12 level=1][color=%s][i]%s[/i][/color][/shake]" % [COLOR_ROJO_OSCURO, texto])


func mostrar_error(texto: String) -> void:
	_agregar("[color=%s]%s[/color]" % [COLOR_ROJO, texto])


func eco_comando(texto: String) -> void:
	_agregar("[color=%s]> %s[/color]" % [COLOR_AMBAR, _escapar(texto)])


func actualizar_cordura(valor: int, estado: String) -> void:
	var color := Color(COLOR_VERDE)
	if valor <= 30:
		color = Color(COLOR_ROJO)
	elif valor <= 60:
		color = Color(COLOR_AMBAR)

	if _tween_barra != null and _tween_barra.is_valid():
		_tween_barra.kill()
	_tween_barra = create_tween()
	_tween_barra.tween_property(barra_cordura, "value", float(valor), 0.25).set_trans(Tween.TRANS_SINE)

	valor_cordura.text = "%d / 100" % valor
	estado_cordura.text = estado.to_upper()
	estado_cordura.add_theme_color_override("font_color", color)
	_aplicar_color_barra(color)


func actualizar_inventario(nombres: Array[String]) -> void:
	if nombres.is_empty():
		inventario.text = "[color=%s][i](nada)[/i][/color]" % COLOR_APAGADO
		return

	var lineas := PackedStringArray()
	for nombre in nombres:
		lineas.append("[color=%s]•[/color] %s" % [COLOR_VERDE, _escapar(nombre)])
	inventario.text = "\n".join(lineas)


func actualizar_ubicacion(nombre: String) -> void:
	ubicacion.text = nombre


func actualizar_objetivo(texto: String) -> void:
	if objetivo == null:
		return
	objetivo.text = texto
	objetivo.add_theme_color_override("font_color", Color(COLOR_AMBAR) if not texto.is_empty() else Color(COLOR_APAGADO))


func _configurar_barra() -> void:
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#101812")
	fondo.border_color = Color("#26352a")
	fondo.border_width_left = 1
	fondo.border_width_top = 1
	fondo.border_width_right = 1
	fondo.border_width_bottom = 1
	fondo.corner_radius_top_left = 2
	fondo.corner_radius_top_right = 2
	fondo.corner_radius_bottom_left = 2
	fondo.corner_radius_bottom_right = 2
	barra_cordura.add_theme_stylebox_override("background", fondo)
	_aplicar_color_barra(Color(COLOR_VERDE))


func _aplicar_color_barra(color: Color) -> void:
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = color
	relleno.corner_radius_top_left = 2
	relleno.corner_radius_top_right = 2
	relleno.corner_radius_bottom_left = 2
	relleno.corner_radius_bottom_right = 2
	barra_cordura.add_theme_stylebox_override("fill", relleno)


func _estilizar_scrollbar(barra: VScrollBar) -> void:
	if barra == null:
		return

	barra.custom_minimum_size = Vector2(6, 0)

	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.02, 0.03, 0.02, 0.35)
	barra.add_theme_stylebox_override("scroll", fondo)

	var agarre := StyleBoxFlat.new()
	agarre.bg_color = Color("#2b3a2e")
	agarre.corner_radius_top_left = 2
	agarre.corner_radius_top_right = 2
	agarre.corner_radius_bottom_left = 2
	agarre.corner_radius_bottom_right = 2
	barra.add_theme_stylebox_override("grabber", agarre)

	var agarre_activo := StyleBoxFlat.new()
	agarre_activo.bg_color = Color("#4a624d")
	agarre_activo.corner_radius_top_left = 2
	agarre_activo.corner_radius_top_right = 2
	agarre_activo.corner_radius_bottom_left = 2
	agarre_activo.corner_radius_bottom_right = 2
	barra.add_theme_stylebox_override("grabber_highlight", agarre_activo)
	barra.add_theme_stylebox_override("grabber_pressed", agarre_activo)


func _escapar(texto: String) -> String:
	return texto.replace("[", "[lb]")


func _scroll_al_final() -> void:
	call_deferred("_hacer_scroll")


func _hacer_scroll() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	scroll_historial.scroll_vertical = int(scroll_historial.get_v_scroll_bar().max_value)
