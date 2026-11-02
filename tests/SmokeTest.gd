extends Node
## Prueba de humo: carga Main, recorre la escena completa y comprueba parser,
## mapa, cordura, inventario, guardado/carga, requisitos, victoria y derrota.

var _fallos := 0


func _ready() -> void:
	await get_tree().process_frame

	SaveManager.usar_ruta("user://smoketest_save.json")
	SaveManager.usar_ruta_autoguardado("user://smoketest_autosave.json")
	if SaveManager.existe():
		SaveManager.borrar()
	if SaveManager.existe_autoguardado():
		SaveManager.borrar_autoguardado()

	# Las ranuras y el autoguardado deben ser independientes entre sí.
	SaveManager.usar_prefijo_ranuras("user://smoketest_slot")
	for ranura in range(1, SaveManager.CANTIDAD_RANURAS + 1):
		if bool(SaveManager.informacion_ranura(ranura).get("ocupada", false)):
			SaveManager.borrar_ranura(ranura)
	_check(
		SaveManager.usar_ranura(1)
		and SaveManager.guardar({"jugador": {"habitacion_actual": "plaza_pueblo"}}),
		"ranuras: guarda la primera partida"
	)
	_check(
		SaveManager.usar_ranura(2)
		and SaveManager.guardar({"jugador": {"habitacion_actual": "muelle"}}),
		"ranuras: guarda una partida independiente"
	)
	_check(
		str(SaveManager.informacion_ranura(1).get("habitacion", "")) == "plaza_pueblo"
		and str(SaveManager.informacion_ranura(2).get("habitacion", "")) == "muelle",
		"ranuras: metadatos separados por partida"
	)
	SaveManager.guardar_autoguardado({"tipo": "automatico"})
	var partida_ranura_dos := SaveManager.cargar()
	var punto_control := SaveManager.cargar_autoguardado()
	_check(
		str(partida_ranura_dos.get("jugador", {}).get("habitacion_actual", "")) == "muelle"
		and str(punto_control.get("tipo", "")) == "automatico",
		"ranuras: autoguardado aislado del guardado manual"
	)
	_check(not SaveManager.usar_ranura(0), "ranuras: rechaza índices fuera de rango")
	_check(SaveManager.borrar_ranura(2), "ranuras: borra una partida")
	_check(
		bool(SaveManager.informacion_ranura(1).get("valida", false))
		and not bool(SaveManager.informacion_ranura(2).get("ocupada", false)),
		"ranuras: borrar una no afecta a las otras"
	)
	SaveManager.borrar_ranura(1)
	SaveManager.usar_prefijo_ranuras(SaveManager.PREFIJO_RANURAS_PREDETERMINADO)
	SaveManager.usar_ruta("user://smoketest_save.json")
	SaveManager.usar_ruta_autoguardado("user://smoketest_autosave.json")
	if SaveManager.existe_autoguardado():
		SaveManager.borrar_autoguardado()

	SettingsManager.usar_ruta_configuracion("user://smoketest_settings.cfg")
	SettingsManager.restaurar_predeterminados()
	SettingsManager.establecer_tamano_texto(1.3)
	SettingsManager.establecer_alto_contraste(true)
	SettingsManager.establecer_reducir_efectos(true)
	SettingsManager.establecer_audio_habilitado(false)
	SettingsManager.establecer_efecto_tecleo(true)
	SettingsManager.establecer_volumen_ambiente(0.7)
	SettingsManager.recargar()
	_check(
		is_equal_approx(SettingsManager.tamano_texto, 1.3)
		and SettingsManager.alto_contraste
		and SettingsManager.reducir_efectos
		and not SettingsManager.audio_habilitado
		and SettingsManager.efecto_tecleo
		and is_equal_approx(SettingsManager.volumen_ambiente, 0.7),
		"ajustes: persiste y restaura accesibilidad y audio"
	)
	SettingsManager.restaurar_predeterminados()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://smoketest_settings.cfg"))
	SettingsManager.restaurar_ruta_configuracion()
	SettingsManager.recargar()

	var parser := CommandParser.new()
	var comando := parser.parsear("  Mirar   el AUTOBÚS  ")
	_check(str(comando.get("verbo", "")) == "examinar", "parser: mirar objeto")
	_check(str(comando.get("objetivo", "")) == "autobus", "parser: normaliza acentos/artículos")

	comando = parser.parsear("ir a la plaza del pueblo")
	_check(str(comando.get("objetivo", "")) == "plaza del pueblo", "parser: ir a lugar")
	comando = parser.parsear("ir-a-la-plaza-del-pueblo")
	_check(str(comando.get("objetivo", "")) == "plaza del pueblo", "parser: ir a lugar con guiones")
	comando = parser.parsear("usar la llave-oxidada")
	_check(str(comando.get("objetivo", "")) == "llave oxidada", "parser: normaliza guiones y subrayados")

	comando = parser.parsear("norte")
	_check(str(comando.get("direccion", "")) == "norte", "parser: dirección directa")
	comando = parser.parsear("noreste")
	_check(str(comando.get("direccion", "")) == "noreste", "parser: dirección diagonal a la refinería")
	comando = parser.parsear("suroeste")
	_check(str(comando.get("direccion", "")) == "suroeste", "parser: regreso diagonal desde la refinería")
	comando = parser.parsear("descender")
	_check(str(comando.get("direccion", "")) == "abajo", "parser: descender")
	comando = parser.parsear("subir")
	_check(str(comando.get("direccion", "")) == "arriba", "parser: subir")

	comando = parser.parsear("hablar con el conductor")
	_check(str(comando.get("objetivo", "")) == "conductor", "parser: hablar con")

	comando = parser.parsear("?")
	_check(str(comando.get("verbo", "")) == "ayuda", "parser: ayuda simbólica")

	comando = parser.parsear("guardar")
	_check(str(comando.get("verbo", "")) == "guardar", "parser: guardar")
	comando = parser.parsear("cargar partida")
	_check(str(comando.get("verbo", "")) == "cargar", "parser: cargar")
	comando = parser.parsear("continuar")
	_check(str(comando.get("verbo", "")) == "continuar", "parser: continuar")
	comando = parser.parsear("borrar partida")
	_check(str(comando.get("verbo", "")) == "borrar", "parser: borrar")
	comando = parser.parsear("objetivo")
	_check(str(comando.get("verbo", "")) == "objetivo", "parser: objetivo")
	comando = parser.parsear("misión")
	_check(str(comando.get("verbo", "")) == "objetivo", "parser: objetivo con acento")

	var invalido := [false]
	parser.comando_invalido.connect(func(_texto: String, _mensaje: String) -> void: invalido[0] = true)
	parser.parsear("bailar con las sombras")
	_check(invalido[0], "parser: comando inválido emite señal")
	parser.free()

	var salas := RoomDatabase.crear_habitaciones()
	_check(salas.size() == 14, "mapa: catorce salas")
	_check(salas.has("iglesia_dagon"), "mapa: iglesia de Dagon")
	_check(salas.has("hotel_gillman"), "mapa: hotel Gillman")
	_check(salas.has("archivo_aduana"), "mapa: archivo de la vieja aduana")
	_check(salas.has("tunel_bajo_muelle"), "mapa: pasadizo bajo el muelle")
	_check(salas.has("camara_arrecife"), "mapa: cámara bajo el arrecife")
	_check(salas.has("refineria_marsh"), "mapa: refinería de Marsh")
	_check(salas.has("oficina_refineria"), "mapa: oficina de cuentas de Marsh")
	_check(salas.has("bodega_zadok"), "mapa: bodega de Zadok Allen")
	_check(salas.has("borde_devils_reef"), "mapa: cornisa de Devil Reef")
	_check(salas.has("gruta_devils_reef"), "mapa: gruta de Devil Reef")
	_check(salas["camino_innsmouth"].conexion("norte") == "bodega_zadok", "mapa: acceso a la bodega")
	_check(salas["bodega_zadok"].conexion("arriba") == "camino_innsmouth", "mapa: regreso desde la bodega")
	_check(salas["camino_innsmouth"].conexion("este") == "plaza_pueblo", "mapa: conexión este")
	_check(salas["plaza_pueblo"].conexion("este") == "iglesia_dagon", "mapa: plaza-iglesia")
	_check(salas["plaza_pueblo"].conexion("norte") == "hotel_gillman", "mapa: plaza-hotel")
	_check(salas["iglesia_dagon"].conexion("oeste") == "plaza_pueblo", "mapa: iglesia-plaza")
	_check(salas["hotel_gillman"].conexion("sur") == "plaza_pueblo", "mapa: hotel-plaza")
	_check(salas["muelle"].conexion("este") == "archivo_aduana", "mapa: muelle-aduana")
	_check(salas["muelle"].conexion("abajo") == "tunel_bajo_muelle", "mapa: acceso al pasadizo")
	_check(salas["tunel_bajo_muelle"].conexion("arriba") == "muelle", "mapa: salida del pasadizo")
	_check(
		salas["tunel_bajo_muelle"].conexion("dentro") == "camara_arrecife",
		"mapa: conexión con la cámara del arrecife"
	)
	_check(
		salas["camara_arrecife"].conexion("fuera") == "tunel_bajo_muelle",
		"mapa: regreso desde la cámara"
	)
	_check(
		salas["camara_arrecife"].conexion("abajo") == "borde_devils_reef"
		and salas["borde_devils_reef"].conexion("arriba") == "camara_arrecife",
		"mapa: acceso reversible a la cornisa de Devil Reef"
	)
	_check(
		salas["borde_devils_reef"].conexion("dentro") == "gruta_devils_reef"
		and salas["gruta_devils_reef"].conexion("fuera") == "borde_devils_reef",
		"mapa: acceso reversible a la gruta de Devil Reef"
	)
	_check(
		salas["plaza_pueblo"].conexion("noreste") == "refineria_marsh"
		and salas["refineria_marsh"].conexion("suroeste") == "plaza_pueblo",
		"mapa: ida y vuelta entre la plaza y la refinería"
	)
	_check(
		salas["refineria_marsh"].conexion("dentro") == "oficina_refineria"
		and salas["oficina_refineria"].conexion("fuera") == "refineria_marsh",
		"mapa: ida y vuelta entre la refinería y la oficina"
	)
	_check(
		salas["tunel_bajo_muelle"].objetos_requeridos_conexion("dentro").has("libro_mareas")
		and salas["tunel_bajo_muelle"].objetos_requeridos_conexion("dentro").has("concha_ritual"),
		"mapa: cruzar a la cámara exige libro y concha"
	)
	_check(
		salas["archivo_aduana"].objetos_requeridos("libro_mareas").has("concha_ritual"),
		"historia: la concha abre el libro de mareas"
	)
	_check(not salas["camino_innsmouth"].buscar_examinable("casas").is_empty(), "mapa: examinable casas")
	_check(
		salas["iglesia_dagon"].objetos_requeridos("tiara_innsmouth").has("llave_oxidada"),
		"mapa: la tiara exige la llave oxidada"
	)

	var npcs := RoomDatabase.crear_npcs()
	_check(npcs.has("sacerdote_dagon"), "mapa: sacerdote de Dagon")
	_check(npcs.has("capataz_refineria"), "mapa: capataz de la refinería")
	_check(npcs.has("zadok_allen"), "mapa: Zadok Allen")
	_check(npcs.has("vigia_marea"), "mapa: vigía de la marea")
	_check(not ItemDB.obtener("tiara_innsmouth").is_empty(), "objetos: tiara registrada")
	_check(not ItemDB.obtener("libro_cuentas_marsh").is_empty(), "objetos: cuentas de Marsh registradas")
	_check(not ItemDB.obtener("cuaderno_zadok").is_empty(), "objetos: cuaderno de Zadok registrado")
	_check(not ItemDB.obtener("cuaderno_buzo").is_empty(), "objetos: cuaderno del buzo registrado")

	var escena_menu := _crear_escena_juego(true)
	add_child(escena_menu)
	await get_tree().process_frame
	var ui_menu := escena_menu.get_node("UI") as TerminalUI
	var menu_principal := escena_menu.get_node("MainMenu") as MainMenu
	_check(menu_principal.visible and not ui_menu.visible, "menú: se muestra antes de iniciar la historia")
	var audio_ambiente := escena_menu.get_node("AudioAmbiente") as AudioStreamPlayer
	_check(
		audio_ambiente.stream is AudioStreamWAV
		and (audio_ambiente.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"audio: ambiente original cargado en bucle"
	)
	SettingsManager.establecer_efecto_tecleo(true)
	ui_menu.mostrar_sistema("Texto progresivo de prueba.")
	_check(
		ui_menu.historial.visible_characters < ui_menu.historial.get_total_character_count(),
		"accesibilidad: el efecto progresivo revela texto gradualmente"
	)
	SettingsManager.establecer_efecto_tecleo(false)
	_check(
		ui_menu.historial.visible_characters == -1,
		"accesibilidad: desactivar el efecto muestra todo el texto"
	)
	menu_principal.nueva_partida.emit()
	await get_tree().process_frame
	_check(
		not menu_principal.visible and ui_menu.visible and PlayerState.habitacion_actual == "parada_autobus",
		"menú: nueva partida inicia el relato"
	)
	SaveManager.usar_prefijo_ranuras("user://smoketest_menu_slot")
	SaveManager.usar_ranura(1)
	escena_menu._guardar_partida()
	escena_menu._mostrar_pausa()
	_check(menu_principal.visible, "menú: Escape abre la pausa")
	escena_menu._reanudar()
	_check(not menu_principal.visible and ui_menu.visible, "menú: reanudar vuelve al juego")
	escena_menu._volver_al_inicio()
	_check(menu_principal.visible and not ui_menu.visible, "menú: vuelve al inicio sin perder el punto de control")
	menu_principal._mostrar_ranuras("cargar")
	menu_principal._seleccionar_ranura(1)
	_check(
		not menu_principal.visible
		and ui_menu.visible
		and PlayerState.habitacion_actual == "parada_autobus",
		"menú: carga una ranura manual"
	)
	escena_menu.queue_free()
	await get_tree().process_frame
	SaveManager.borrar_ranura(1)
	SaveManager.usar_prefijo_ranuras(SaveManager.PREFIJO_RANURAS_PREDETERMINADO)
	SaveManager.usar_ruta("user://smoketest_save.json")

	var escena: Node = _crear_escena_juego()
	add_child(escena)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui := escena.get_node("UI") as TerminalUI
	var room_manager := escena.get_node("RoomManager") as RoomManager
	_check(ui != null, "UI: instanciada")
	_check(PlayerState.habitacion_actual == "parada_autobus", "juego: habitación inicial")
	_check(PlayerState.salud_mental == 98, "juego: impacto inicial -2")
	_check(ui.historial.get_parsed_text().length() > 0, "UI: historial con texto")
	_check(ui.objetivo.text.contains("llave oxidada"), "UI: objetivo inicial en el panel")
	_check(room_manager.existe("deposito_aduana"), "contenido: carga una sala del paquete")

	escena._entrar_habitacion("muelle")
	var sala_muelle := room_manager.obtener("muelle")
	_check(
		escena._npcs_en_sala(sala_muelle).is_empty(),
		"marea: el vigía no aparece antes de medianoche"
	)
	PlayerState.poner_bandera("minutos_transcurridos", 180)
	_check(
		not escena._npcs_en_sala(sala_muelle).is_empty(),
		"marea: el vigía aparece a medianoche"
	)
	escena._al_recibir_comando("examinar escaleras")
	_check(
		ui.historial.get_parsed_text().contains("La corriente retrocede"),
		"marea: las escaleras revelan la bajamar"
	)
	escena._al_recibir_comando("hablar con el vigia")
	_check(
		ui.historial.get_parsed_text().contains("tienes cuatro horas para bajar"),
		"marea: el vigía ofrece una pista sobre el paso"
	)
	PlayerState.poner_bandera("minutos_transcurridos", 420)
	_check(
		escena._npcs_en_sala(sala_muelle).is_empty(),
		"marea: el vigía desaparece a las cuatro"
	)
	escena._iniciar_nueva_partida()

	escena._entrar_habitacion("archivo_aduana")
	escena._al_recibir_comando("dentro")
	_check(
		PlayerState.habitacion_actual == "deposito_aduana",
		"contenido: conecta una sala nueva a una sala existente"
	)
	escena._al_recibir_comando("hablar con el archivero")
	_check(
		int(PlayerState.progreso_dialogos.get("archivero_aduana", 0)) == 1,
		"contenido: usa los diálogos de un personaje añadido"
	)
	escena._al_recibir_comando("coger carta censurada")
	_check(
		PlayerState.tiene_objeto("carta_censurada"),
		"contenido: encuentra un objeto definido en el paquete"
	)
	escena._al_recibir_comando("examinar carta censurada")
	_check(
		ui.historial.get_parsed_text().contains("ningún pasajero será dado por perdido"),
		"contenido: examina el objeto definido en el paquete"
	)
	escena._iniciar_nueva_partida()
	_check(
		PlayerState.habitacion_actual == "parada_autobus"
		and not PlayerState.tiene_objeto("carta_censurada")
		and room_manager.objeto_visible("deposito_aduana", "carta_censurada"),
		"contenido: reinicia la partida sin retirar el paquete"
	)

	ui.entrada.text = "inventario"
	ui.entrada.text_submitted.emit("inventario")
	await get_tree().process_frame
	_check(ui.historial.get_parsed_text().contains("Llevas contigo"), "UI: señal de entrada conectada")

	escena._al_recibir_comando("mirar")
	escena._al_recibir_comando("examinar autobús")
	_check(PlayerState.salud_mental == 96, "juego: examinar autobús -2")
	_check(SaveManager.existe_autoguardado(), "autoguardado: crea punto de control tras una acción")
	var datos_autoguardados := SaveManager.cargar_autoguardado()
	var jugador_autoguardado: Dictionary = datos_autoguardados.get("jugador", {})
	_check(
		int(jugador_autoguardado.get("salud_mental", -1)) == 96,
		"autoguardado: conserva el estado actual"
	)

	escena._al_recibir_comando("hablar con joe")
	_check(PlayerState.salud_mental == 94, "juego: primera charla -2")
	escena._al_recibir_comando("hablar con joe")
	_check(PlayerState.salud_mental == 94, "juego: charla repetida sin impacto")

	escena._al_recibir_comando("este")
	_check(PlayerState.habitacion_actual == "camino_innsmouth", "juego: movimiento este")
	_check(PlayerState.salud_mental == 92, "juego: impacto camino -2")

	escena._al_recibir_comando("examinar las casas")
	_check(PlayerState.salud_mental == 85, "juego: casas -7")
	escena._al_recibir_comando("examinar las casas")
	_check(PlayerState.salud_mental == 85, "juego: examinar dos veces no repite impacto")

	escena._al_recibir_comando("hablar con el anciano")
	_check(PlayerState.salud_mental == 82, "juego: anciano -3")

	escena._al_recibir_comando("coger concha")
	_check(PlayerState.tiene_objeto("concha_ritual"), "juego: coger concha")
	_check(PlayerState.salud_mental == 78, "juego: concha al coger -4")

	escena._al_recibir_comando("inventario")
	_check(ui.inventario.text.contains("Concha negra"), "UI: inventario lateral")

	escena._al_recibir_comando("ir a la plaza")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "juego: ir a lugar por nombre")
	_check(PlayerState.salud_mental == 75, "juego: impacto plaza -3")

	escena._al_recibir_comando("examinar obelisco")
	_check(PlayerState.salud_mental == 69, "juego: obelisco -6")
	escena._al_recibir_comando("hablar con el hombre")
	_check(PlayerState.salud_mental == 66, "juego: hombre banco -3")

	# Sin la llave, el relicario debe bloquear la tiara.
	escena._al_recibir_comando("este")
	_check(PlayerState.habitacion_actual == "iglesia_dagon", "juego: entrar en la iglesia")
	_check(PlayerState.salud_mental == 61, "juego: impacto iglesia -5")
	escena._al_recibir_comando("coger tiara")
	_check(not PlayerState.tiene_objeto("tiara_innsmouth"), "requisito: tiara bloqueada sin llave")
	_check(
		ui.historial.get_parsed_text().contains("relicario"),
		"requisito: mensaje de cerradura"
	)

	escena._al_recibir_comando("oeste")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "juego: volver a la plaza")
	escena._al_recibir_comando("coger llave")
	_check(PlayerState.tiene_objeto("llave_oxidada"), "juego: coger llave")
	escena._al_recibir_comando("examinar llave")
	_check(PlayerState.salud_mental == 60, "juego: examinar llave -1")

	escena._al_recibir_comando("objetivo")
	_check(ui.historial.get_parsed_text().contains("relicario"), "objetivo: pista con la llave")
	_check(ui.objetivo.text.contains("relicario"), "UI: objetivo actualizado con la llave")

	escena._al_recibir_comando("ir al muelle")
	_check(PlayerState.habitacion_actual == "muelle", "juego: ir al muelle")
	_check(PlayerState.salud_mental == 56, "juego: impacto muelle -4")
	escena._al_recibir_comando("abajo")
	_check(PlayerState.habitacion_actual == "muelle", "historia: el pasadizo bloqueado sin el libro")
	_check(
		ui.historial.get_parsed_text().contains("libro de mareas"),
		"historia: indica cómo hallar el acceso"
	)
	escena._al_recibir_comando("este")
	_check(PlayerState.habitacion_actual == "archivo_aduana", "historia: entrar en la aduana")
	_check(PlayerState.salud_mental == 55, "historia: impacto del archivo")
	escena._al_recibir_comando("examinar formularios")
	_check(
		ui.historial.get_parsed_text().contains("bajo el arrecife"),
		"historia: formularios revelan el destino de los cargamentos"
	)
	escena._al_recibir_comando("coger libro de mareas")
	_check(PlayerState.tiene_objeto("libro_mareas"), "historia: recuperar el libro de mareas")
	_check(
		not room_manager.objetos_visibles("archivo_aduana").has("libro_mareas"),
		"historia: el libro se retira del archivo"
	)
	escena._al_recibir_comando("oeste")
	escena._al_recibir_comando("usar libro de mareas")
	escena._al_recibir_comando("abajo")
	_check(
		PlayerState.habitacion_actual == "tunel_bajo_muelle",
		"historia: el libro permite descender bajo el muelle"
	)
	_check(PlayerState.salud_mental == 48, "historia: impacto del pasadizo")
	escena._al_recibir_comando("examinar inscripción")
	_check(
		ui.historial.get_parsed_text().contains("La marea devuelve"),
		"historia: inscripción amplía el misterio"
	)
	escena._al_recibir_comando("arriba")
	_check(PlayerState.habitacion_actual == "muelle", "historia: volver desde el pasadizo")

	escena._al_recibir_comando("examinar agua")
	_check(PlayerState.salud_mental == 38, "juego: agua -6")
	_check(PlayerState.estado_texto() == "Inquieto", "estado: inquieto tras explorar el pasadizo")
	_check(ui.estado_cordura.text == "INQUIETO", "UI: estado de cordura")

	PlayerState.modificar_cordura(-25)
	_check(PlayerState.en_panico(), "estado: pánico por debajo de 30")
	_check(ui.estado_cordura.text == "AL BORDE DEL ABISMO", "UI: estado de pánico")
	var longitud_antes := ui.historial.get_parsed_text().length()
	escena._al_recibir_comando("bailar con las sombras")
	_check(ui.historial.get_parsed_text().length() > longitud_antes, "UI: mensaje atmosférico inválido")
	escena._al_recibir_comando("mirar")
	_check(ui.historial.get_parsed_text().contains("Muelle de Innsmouth"), "UI: mirar en pánico")

	# Guardado: debe conservar cordura, inventario, diálogos y objetos retirados.
	escena._al_recibir_comando("guardar")
	_check(SaveManager.existe(), "guardado: archivo creado")
	_check(
		ui.historial.get_parsed_text().contains("Partida guardada"),
		"guardado: confirmación en la UI"
	)

	escena._al_recibir_comando("ir a la plaza")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "guardado: estado modificado antes de cargar")
	escena._al_recibir_comando("cargar")
	_check(PlayerState.habitacion_actual == "muelle", "carga: restaura la habitación")
	_check(PlayerState.salud_mental == 13, "carga: restaura la cordura")
	_check(PlayerState.tiene_objeto("libro_mareas"), "carga: restaura el libro de mareas")
	_check(PlayerState.tiene_objeto("concha_ritual"), "carga: restaura el inventario")
	_check(PlayerState.tiene_objeto("llave_oxidada"), "carga: restaura la llave")
	_check(int(PlayerState.progreso_dialogos.get("joe_sargent", 0)) == 2, "carga: restaura diálogos")
	_check(
		not room_manager.objetos_visibles("camino_innsmouth").has("concha_ritual"),
		"carga: restaura objetos retirados"
	)
	_check(
		not room_manager.objetos_visibles("plaza_pueblo").has("llave_oxidada"),
		"carga: restaura la llave retirada"
	)
	_check(ui.historial.get_parsed_text().contains("PARTIDA CARGADA"), "carga: aviso en la UI")

	escena._al_recibir_comando("ir a la plaza")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "autoguardado: estado cambiado")
	escena._al_recibir_comando("continuar")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "continuar: recupera el último punto de control")
	_check(
		ui.historial.get_parsed_text().contains("PUNTO DE CONTROL RECUPERADO"),
		"continuar: confirma la recuperación"
	)

	escena._al_recibir_comando("borrar")
	_check(not SaveManager.existe(), "borrado: archivo eliminado")
	_check(not SaveManager.existe_autoguardado(), "borrado: elimina también el punto de control")
	escena._al_recibir_comando("cargar")
	_check(
		ui.historial.get_parsed_text().contains("No hay ninguna partida guardada"),
		"borrado: cargar sin archivo avisa"
	)
	escena._al_recibir_comando("continuar")
	_check(
		ui.historial.get_parsed_text().contains("No hay ningún punto de control automático"),
		"continuar: avisa si no hay punto de control"
	)

	# Con la llave, la tiara se puede coger y abre la victoria.
	escena._al_recibir_comando("ir a la plaza")
	escena._al_recibir_comando("este")
	_check(PlayerState.habitacion_actual == "iglesia_dagon", "juego: volver a la iglesia")
	escena._al_recibir_comando("hablar con el sacerdote")
	_check(PlayerState.salud_mental == 9, "juego: sacerdote -4")
	escena._al_recibir_comando("coger tiara")
	_check(PlayerState.tiene_objeto("tiara_innsmouth"), "requisito: tiara cogida con llave")
	_check(not PlayerState.tiene_objeto("llave_oxidada"), "requisito: llave consumida")
	_check(PlayerState.salud_mental == 6, "juego: tiara al coger -3")
	_check(ui.objetivo.text.contains("billete"), "UI: objetivo de victoria")

	escena._al_recibir_comando("oeste")
	escena._al_recibir_comando("norte")
	_check(PlayerState.habitacion_actual == "hotel_gillman", "juego: entrar en el hotel")
	_check(PlayerState.salud_mental == 5, "juego: impacto hotel -1")
	escena._al_recibir_comando("examinar cama")
	_check(PlayerState.salud_mental == 11, "juego: descansar en el hotel +6")
	_check(
		int(PlayerState.bandera("minutos_transcurridos", 0)) == 360
		and ui.historial.get_parsed_text().contains("03:00"),
		"hotel: dormir recupera cordura y avanza seis horas"
	)
	escena._al_recibir_comando("guardar")
	var datos_descanso := SaveManager.cargar()
	var jugador_descanso: Dictionary = datos_descanso.get("jugador", {})
	var banderas_descanso: Dictionary = jugador_descanso.get("banderas", {})
	_check(
		int(banderas_descanso.get("minutos_transcurridos", -1)) == 360
		and bool(banderas_descanso.get("hotel_descansado", false)),
		"hotel: el descanso y la hora se conservan en la partida guardada"
	)
	escena._al_recibir_comando("descansar")
	_check(
		PlayerState.salud_mental == 11
		and int(PlayerState.bandera("minutos_transcurridos", 0)) == 420,
		"hotel: no repite la recuperación y el tiempo sigue avanzando"
	)

	escena._al_recibir_comando("sur")
	escena._al_recibir_comando("oeste")
	escena._al_recibir_comando("oeste")
	_check(PlayerState.habitacion_actual == "parada_autobus", "juego: volver a la parada")
	escena._al_recibir_comando("usar billete")
	_check(PlayerState.partida_ganada, "victoria: partida ganada")
	_check(PlayerState.partida_terminada, "victoria: partida terminada")
	_check(ui.historial.get_parsed_text().contains("HAS ESCAPADO"), "UI: final de victoria")
	_check(ui.objetivo.text.contains("escapado"), "UI: objetivo final")

	escena._al_recibir_comando("mirar")
	_check(PlayerState.habitacion_actual == "parada_autobus", "victoria: comandos bloqueados")

	escena.queue_free()
	await get_tree().process_frame

	# La cámara ofrece una ruta de victoria alternativa basada en pruebas.
	var escena_arrecife: Node = _crear_escena_juego()
	add_child(escena_arrecife)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui_arrecife := escena_arrecife.get_node("UI") as TerminalUI
	PlayerState.habitacion_actual = "tunel_bajo_muelle"
	escena_arrecife._al_recibir_comando("entrar")
	_check(
		PlayerState.habitacion_actual == "tunel_bajo_muelle",
		"historia: no se cruza la abertura sin libro ni concha"
	)
	PlayerState.agregar_objeto("libro_mareas")
	escena_arrecife._al_recibir_comando("entrar")
	_check(
		PlayerState.habitacion_actual == "tunel_bajo_muelle",
		"historia: la abertura exige también la concha"
	)
	PlayerState.agregar_objeto("concha_ritual")
	escena_arrecife._al_recibir_comando("entrar")
	_check(
		PlayerState.habitacion_actual == "camara_arrecife",
		"historia: libro y concha permiten entrar en la cámara"
	)
	escena_arrecife._al_recibir_comando("examinar lista")
	_check(
		ui_arrecife.historial.get_parsed_text().contains("aún conserva la voz"),
		"historia: la lista anticipa la llegada del protagonista"
	)
	escena_arrecife._al_recibir_comando("coger placa")
	_check(PlayerState.tiene_objeto("placa_aduana"), "historia: recuperar la placa de la aduana")
	_check(ui_arrecife.objetivo.text.contains("prueba"), "objetivo: ofrece la ruta de la prueba")
	escena_arrecife._al_recibir_comando("salir")
	escena_arrecife._al_recibir_comando("arriba")
	escena_arrecife._al_recibir_comando("norte")
	escena_arrecife._al_recibir_comando("oeste")
	escena_arrecife._al_recibir_comando("oeste")
	_check(
		PlayerState.habitacion_actual == "parada_autobus",
		"historia: volver desde el arrecife a la parada"
	)
	escena_arrecife._al_recibir_comando("usar placa")
	_check(PlayerState.partida_ganada, "victoria: la placa permite escapar sin la tiara")
	_check(not PlayerState.tiene_objeto("tiara_innsmouth"), "victoria: la ruta alternativa no exige la tiara")
	_check(
		ui_arrecife.historial.get_parsed_text().contains("placa de cobre apretada en tu mano"),
		"victoria: el epílogo de la placa no menciona la tiara"
	)

	escena_arrecife.queue_free()
	await get_tree().process_frame

	# La refinería amplía la historia de Marsh y habilita otra salida opcional.
	var escena_refineria: Node = _crear_escena_juego()
	add_child(escena_refineria)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui_refineria := escena_refineria.get_node("UI") as TerminalUI
	escena_refineria._al_recibir_comando("este")
	escena_refineria._al_recibir_comando("este")
	_check(PlayerState.habitacion_actual == "plaza_pueblo", "historia: llegar a la plaza para investigar Marsh")
	escena_refineria._al_recibir_comando("noreste")
	_check(PlayerState.habitacion_actual == "refineria_marsh", "historia: entrar en la refinería de Marsh")
	escena_refineria._al_recibir_comando("hablar con el capataz")
	_check(
		ui_refineria.historial.get_parsed_text().contains("La refinería cerró hace años"),
		"historia: el capataz niega que la maquinaria siga activa"
	)
	escena_refineria._al_recibir_comando("examinar chimenea")
	_check(
		ui_refineria.historial.get_parsed_text().contains("conchas incrustadas"),
		"historia: la chimenea conecta la refinería con el mar"
	)
	escena_refineria._al_recibir_comando("entrar")
	_check(PlayerState.habitacion_actual == "oficina_refineria", "historia: entrar en la oficina de cuentas")
	escena_refineria._al_recibir_comando("coger libro de cuentas")
	_check(
		PlayerState.tiene_objeto("libro_cuentas_marsh"),
		"historia: recuperar las cuentas de oro de Devil Reef"
	)
	_check(ui_refineria.objetivo.text.contains("Devil Reef"), "objetivo: revela la prueba de Marsh")
	escena_refineria._al_recibir_comando("salir")
	escena_refineria._al_recibir_comando("suroeste")
	escena_refineria._al_recibir_comando("oeste")
	escena_refineria._al_recibir_comando("oeste")
	_check(PlayerState.habitacion_actual == "parada_autobus", "historia: regresar desde la refinería")
	escena_refineria._al_recibir_comando("usar libro de cuentas")
	_check(PlayerState.partida_ganada, "victoria: las cuentas de Marsh permiten escapar")
	_check(
		PlayerState.banderas.get("ruta_victoria", "") == "cuentas_marsh",
		"victoria: registra la ruta de las cuentas"
	)
	_check(
		ui_refineria.historial.get_parsed_text().contains("deuda pendiente"),
		"victoria: epílogo exclusivo de las cuentas de Marsh"
	)

	escena_refineria.queue_free()
	await get_tree().process_frame

	# El testimonio de Zadok habilita una investigación independiente en el pueblo.
	var escena_zadok: Node = _crear_escena_juego()
	add_child(escena_zadok)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui_zadok := escena_zadok.get_node("UI") as TerminalUI
	escena_zadok._al_recibir_comando("este")
	escena_zadok._al_recibir_comando("norte")
	_check(PlayerState.habitacion_actual == "bodega_zadok", "historia: encontrar la bodega de Zadok")
	escena_zadok._al_recibir_comando("hablar con Zadok")
	_check(
		ui_zadok.historial.get_parsed_text().contains("Devil Reef sin tripulación"),
		"historia: Zadok habla de los regresos desde Devil Reef"
	)
	escena_zadok._al_recibir_comando("hablar con Zadok")
	_check(
		ui_zadok.historial.get_parsed_text().contains("Obed Marsh"),
		"historia: Zadok recuerda el trato de Marsh y el cambio del pueblo"
	)
	escena_zadok._al_recibir_comando("coger cuaderno")
	_check(PlayerState.tiene_objeto("cuaderno_zadok"), "historia: recuperar el testimonio escrito de Zadok")
	_check(ui_zadok.objetivo.text.contains("barcos desaparecidos"), "objetivo: ofrece la ruta del testimonio")
	escena_zadok._al_recibir_comando("arriba")
	escena_zadok._al_recibir_comando("oeste")
	_check(PlayerState.habitacion_actual == "parada_autobus", "historia: regresar con el testimonio de Zadok")
	escena_zadok._al_recibir_comando("usar cuaderno")
	_check(PlayerState.partida_ganada, "victoria: el testimonio de Zadok permite escapar")
	_check(
		PlayerState.banderas.get("ruta_victoria", "") == "testimonio_zadok",
		"victoria: identifica el final del testimonio"
	)
	_check(
		ui_zadok.historial.get_parsed_text().contains("anotaciones terminan en la fecha de hoy"),
		"victoria: epílogo del testimonio de Zadok"
	)
	escena_zadok.queue_free()
	await get_tree().process_frame

	# La segunda rama opcional desciende a la gruta de Devil Reef y recupera el diario de una expedición.
	var escena_arrecife_profundo: Node = _crear_escena_juego()
	add_child(escena_arrecife_profundo)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui_arrecife_profundo := escena_arrecife_profundo.get_node("UI") as TerminalUI
	escena_arrecife_profundo._al_recibir_comando("este")
	escena_arrecife_profundo._al_recibir_comando("coger concha")
	escena_arrecife_profundo._al_recibir_comando("este")
	escena_arrecife_profundo._al_recibir_comando("sur")
	escena_arrecife_profundo._al_recibir_comando("este")
	escena_arrecife_profundo._al_recibir_comando("coger libro de mareas")
	escena_arrecife_profundo._al_recibir_comando("oeste")
	escena_arrecife_profundo._al_recibir_comando("abajo")
	escena_arrecife_profundo._al_recibir_comando("dentro")
	_check(
		PlayerState.habitacion_actual == "camara_arrecife",
		"historia: llegar a la cámara antes de la rama de Devil Reef"
	)
	PlayerState.quitar_objeto("concha_ritual")
	escena_arrecife_profundo._al_recibir_comando("abajo")
	_check(
		PlayerState.habitacion_actual == "camara_arrecife",
		"historia: el descenso a Devil Reef está bloqueado sin el equipo necesario"
	)
	_check(
		ui_arrecife_profundo.historial.get_parsed_text().contains("solo el libro de mareas y la concha negra"),
		"historia: el bloqueo del arrecife explica los requisitos"
	)
	PlayerState.agregar_objeto("concha_ritual")
	escena_arrecife_profundo._al_recibir_comando("abajo")
	_check(
		PlayerState.habitacion_actual == "borde_devils_reef",
		"historia: descender a la cornisa de Devil Reef"
	)
	escena_arrecife_profundo._al_recibir_comando("entrar")
	_check(
		PlayerState.habitacion_actual == "gruta_devils_reef",
		"historia: explorar la gruta de Devil Reef"
	)
	escena_arrecife_profundo._al_recibir_comando("examinar caja")
	_check(
		ui_arrecife_profundo.historial.get_parsed_text().contains("empujada hacia fuera"),
		"historia: las señales de la expedición sugieren que algo salió de la caja"
	)
	escena_arrecife_profundo._al_recibir_comando("coger cuaderno del buzo")
	_check(
		PlayerState.tiene_objeto("cuaderno_buzo"),
		"historia: recuperar el cuaderno de la expedición submarina"
	)
	escena_arrecife_profundo._al_recibir_comando("salir")
	escena_arrecife_profundo._al_recibir_comando("arriba")
	escena_arrecife_profundo._al_recibir_comando("fuera")
	escena_arrecife_profundo._al_recibir_comando("arriba")
	escena_arrecife_profundo._al_recibir_comando("norte")
	escena_arrecife_profundo._al_recibir_comando("oeste")
	escena_arrecife_profundo._al_recibir_comando("oeste")
	_check(
		PlayerState.habitacion_actual == "parada_autobus",
		"historia: regresar desde Devil Reef con el cuaderno"
	)
	escena_arrecife_profundo._al_recibir_comando("usar cuaderno del buzo")
	_check(PlayerState.partida_ganada, "victoria: el cuaderno de la expedición permite escapar")
	_check(
		PlayerState.banderas.get("ruta_victoria", "") == "devils_reef",
		"victoria: identifica el final de Devil Reef"
	)
	_check(
		ui_arrecife_profundo.historial.get_parsed_text().contains("ruta dibujada termina en un punto marcado"),
		"victoria: epílogo de Devil Reef"
	)
	escena_arrecife_profundo.queue_free()
	await get_tree().process_frame

	# Derrota en una partida nueva.
	var escena_derrota: Node = _crear_escena_juego()
	add_child(escena_derrota)
	await get_tree().process_frame
	await get_tree().process_frame

	var ui_derrota := escena_derrota.get_node("UI") as TerminalUI
	_check(PlayerState.salud_mental == 98, "reinicio: cordura inicial restaurada")
	escena_derrota._autoguardar_partida()
	PlayerState.modificar_cordura(-100)
	await get_tree().process_frame
	_check(PlayerState.partida_terminada, "final: partida terminada")
	_check(not PlayerState.partida_ganada, "final: derrota, no victoria")
	_check(PlayerState.salud_mental == 0, "final: cordura a cero")
	_check(ui_derrota.historial.get_parsed_text().contains("EL RELATO SE DETIENE"), "UI: final trágico")
	var datos_antes_de_derrota := SaveManager.cargar_autoguardado()
	var jugador_antes_de_derrota: Dictionary = datos_antes_de_derrota.get("jugador", {})
	_check(
		int(jugador_antes_de_derrota.get("salud_mental", -1)) == 98,
		"autoguardado: conserva el último estado antes de la derrota"
	)
	escena_derrota._volver_al_inicio()
	_check(
		(escena_derrota.get_node("MainMenu") as MainMenu).opcion_habilitada("Continuar"),
		"menú: ofrece recuperar el último punto de control"
	)
	escena_derrota._reanudar()

	escena_derrota._al_recibir_comando("mirar")
	_check(PlayerState.habitacion_actual == "parada_autobus", "final: comandos bloqueados")
	escena_derrota._al_recibir_comando("continuar")
	_check(not PlayerState.partida_terminada, "continuar: permite recuperarse tras la derrota")
	_check(PlayerState.salud_mental == 98, "continuar: recupera la cordura previa a la derrota")

	if SaveManager.existe():
		SaveManager.borrar()
	if SaveManager.existe_autoguardado():
		SaveManager.borrar_autoguardado()
	SaveManager.restaurar_rutas()

	if _fallos == 0:
		print("SMOKE TEST: OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE TEST: %d fallos" % _fallos)
		get_tree().quit(1)


func _check(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS · ", mensaje)
	else:
		_fallos += 1
		push_error("FAIL · " + mensaje)


func _crear_escena_juego(mostrar_menu: bool = false) -> Node:
	var escena := (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	escena.set("mostrar_menu_inicial", mostrar_menu)
	return escena
