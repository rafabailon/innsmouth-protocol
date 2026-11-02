extends Control
## Controlador principal: conecta parser, estado, mapa y UI. Toda la narración
## pasa por aquí para que la lógica de las salas no dependa de la presentación.

const HABITACION_INICIAL := "parada_autobus"
const CORDURA_MAXIMA := 100
const UMBRAL_INQUIETUD := 60

const SUSURROS_AMBIENTALES: Array[String] = [
	"Por un instante, todas las puertas de la calle parecen abrirse a la vez. Luego vuelven a estar cerradas.",
	"El aire huele a agua estancada y a algo que se está pudriendo muy despacio.",
	"Escuchas pasos detrás de ti. Cuando te giras, solo hay una sombra que tarda demasiado en desaparecer.",
	"Las letras de tus pensamientos parecen reordenarse en una frase que no te atreves a leer.",
	"Alguien tararea una melodía sin melodía. El sonido viene de debajo de tus pies.",
	"Durante un segundo, el cielo tiene la textura de una piel mojada.",
]

@onready var ui: TerminalUI = $UI
@onready var parser: CommandParser = $CommandParser
@onready var room_manager: RoomManager = $RoomManager
@onready var menu: MainMenu = $MainMenu
@onready var capa_crt: CRTOverlay = $CRT

var _cordura_previa: int = CORDURA_MAXIMA
var _suprimir_avisos: bool = false
var _partida_iniciada := false
var _audio_ambiente: AudioStreamPlayer

@export var mostrar_menu_inicial := true


func _ready() -> void:
	randomize()
	room_manager.cargar_mapa()

	ui.comando_enviado.connect(_al_recibir_comando)
	menu.nueva_partida.connect(_iniciar_nueva_partida)
	menu.continuar_partida.connect(_continuar_desde_menu)
	menu.cargar_ranura.connect(_cargar_ranura)
	menu.guardar_ranura.connect(_guardar_en_ranura)
	menu.reanudar.connect(_reanudar)
	menu.volver_al_inicio.connect(_volver_al_inicio)
	menu.salir.connect(func() -> void: get_tree().quit())
	parser.comando_invalido.connect(_al_comando_invalido)
	PlayerState.cordura_cambiada.connect(_al_cambiar_cordura)
	PlayerState.inventario_cambiado.connect(_al_cambiar_inventario)
	PlayerState.alucinacion.connect(_al_alucinar)
	PlayerState.umbral_panico.connect(_al_cambiar_panico)
	PlayerState.derrota.connect(_al_derrotar)
	PlayerState.victoria.connect(_al_victorizar)
	SettingsManager.opciones_cambiadas.connect(_aplicar_opciones)

	_preparar_audio()
	_aplicar_opciones()
	if mostrar_menu_inicial:
		ui.hide()
		menu.mostrar_inicio(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())
	else:
		_iniciar_nueva_partida()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if menu.visible:
		if _partida_iniciada:
			_reanudar()
	else:
		_mostrar_pausa()
	get_viewport().set_input_as_handled()


func _iniciar_nueva_partida() -> void:
	PlayerState.reset()
	room_manager.cargar_mapa()
	_cordura_previa = PlayerState.salud_mental
	_partida_iniciada = true
	menu.hide()
	ui.show()
	ui.limpiar_historial()
	_actualizar_panel()
	_mostrar_intro()
	_entrar_habitacion(HABITACION_INICIAL)
	_autoguardar_partida()
	ui.enfocar_entrada()


func _continuar_desde_menu() -> void:
	var datos := SaveManager.cargar_autoguardado()
	if datos.is_empty():
		menu.mostrar_inicio(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())
		menu.mostrar_error("No se pudo recuperar el punto de control: %s" % SaveManager.ultimo_error)
		return
	_partida_iniciada = true
	menu.hide()
	ui.show()
	ui.limpiar_historial()
	_restaurar_partida(datos, "PUNTO DE CONTROL RECUPERADO", SaveManager.ruta_autoguardado_legible())
	ui.enfocar_entrada()


func _cargar_ranura(ranura: int) -> void:
	if not SaveManager.usar_ranura(ranura):
		menu.mostrar_error(SaveManager.ultimo_error)
		return
	var datos := SaveManager.cargar()
	if datos.is_empty():
		menu.mostrar_inicio(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())
		menu.mostrar_error("No se pudo cargar la ranura: %s" % SaveManager.ultimo_error)
		return
	_partida_iniciada = true
	menu.hide()
	ui.show()
	ui.limpiar_historial()
	_restaurar_partida(datos, "PARTIDA CARGADA", SaveManager.ruta_legible())
	ui.enfocar_entrada()


func _guardar_en_ranura(ranura: int) -> void:
	if not SaveManager.usar_ranura(ranura):
		menu.mostrar_error(SaveManager.ultimo_error)
		return
	_guardar_partida()
	menu.mostrar_pausa()


func _mostrar_pausa() -> void:
	if not _partida_iniciada:
		return
	ui.entrada.release_focus()
	menu.mostrar_pausa()


func _reanudar() -> void:
	menu.hide()
	if _partida_iniciada:
		ui.show()
		ui.enfocar_entrada()


func _volver_al_inicio() -> void:
	_autoguardar_partida()
	_partida_iniciada = false
	ui.hide()
	menu.mostrar_inicio(SaveManager.existe_autoguardado(), SaveManager.hay_guardados())


func _preparar_audio() -> void:
	var stream := load("res://assets/audio/innsmouth_ambience.wav") as AudioStreamWAV
	if stream == null:
		push_error("No se pudo cargar el audio ambiental del proyecto.")
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	_audio_ambiente = AudioStreamPlayer.new()
	_audio_ambiente.name = "AudioAmbiente"
	_audio_ambiente.stream = stream
	add_child(_audio_ambiente)


func _aplicar_opciones() -> void:
	if is_instance_valid(ui):
		ui.aplicar_accesibilidad(SettingsManager.tamano_texto, SettingsManager.alto_contraste)
		ui.aplicar_efecto_tecleo(SettingsManager.efecto_tecleo)
		$Fondo.color = Color(0.005, 0.005, 0.005, 1.0) if SettingsManager.alto_contraste else Color(0.027, 0.043, 0.031, 1.0)
	if is_instance_valid(capa_crt):
		capa_crt.visible = not SettingsManager.reducir_efectos
	if not is_instance_valid(_audio_ambiente):
		return
	if SettingsManager.audio_habilitado and DisplayServer.get_name() != "headless":
		_audio_ambiente.volume_db = linear_to_db(maxf(SettingsManager.volumen_ambiente, 0.001))
		if not _audio_ambiente.playing:
			_audio_ambiente.play()
	else:
		_audio_ambiente.stop()


func _al_recibir_comando(texto: String) -> void:
	ui.eco_comando(texto)

	if PlayerState.partida_terminada:
		var normalizado := TextUtils.normalizar(texto)
		if normalizado in ["reiniciar", "reset", "empezar"]:
			_reiniciar()
		elif normalizado in ["ayuda", "comandos"]:
			_mostrar_ayuda()
		elif normalizado in ["cargar", "load", "recuperar"]:
			_cargar_partida()
		elif normalizado in ["continuar", "resume", "reanudar"]:
			_continuar_partida()
		elif normalizado in ["objetivo", "mision", "tarea", "proposito"]:
			_mostrar_objetivo()
		else:
			var cierre := "El relato ya ha escrito su última línea."
			if PlayerState.partida_ganada:
				cierre = "Ya has escapado de Innsmouth."
			ui.mostrar_sistema("%s Escribe REINICIAR para volver a empezar o CONTINUAR para recuperar el último punto de control." % cierre)
		return

	var comando := parser.parsear(texto)
	if comando.is_empty():
		return

	_ejecutar_comando(comando)
	if str(comando.get("verbo", "")) in [
		"mover", "examinar", "coger", "usar", "hablar", "esperar",
		"guardar",
	]:
		_autoguardar_partida()


func _ejecutar_comando(comando: Dictionary) -> void:
	var verbo := str(comando.get("verbo", ""))
	var objetivo := str(comando.get("objetivo", ""))
	var direccion := str(comando.get("direccion", ""))

	match verbo:
		"mirar":
			_mirar_habitacion()
		"examinar":
			_examinar(objetivo)
		"mover":
			_mover(direccion, objetivo)
		"inventario":
			_mostrar_inventario()
		"coger":
			_coger(objetivo)
		"usar":
			_usar(objetivo)
		"hablar":
			_hablar(objetivo)
		"esperar":
			_esperar()
		"guardar":
			_guardar_partida()
		"cargar":
			_cargar_partida()
		"continuar":
			_continuar_partida()
		"borrar":
			_borrar_partida()
		"objetivo":
			_mostrar_objetivo()
		"ayuda":
			_mostrar_ayuda()
		"reiniciar":
			_reiniciar()
		_:
			ui.mostrar_error("Las sombras se cierran sobre esa idea.")


func _mostrar_intro() -> void:
	ui.limpiar_historial()
	ui.mostrar_titulo("LA SOMBRA SOBRE INNSMOUTH")
	ui.mostrar_subtitulo("Un relato interactivo  ·  Innsmouth, Massachusetts  ·  1927")
	ui.separador()
	ui.mostrar_descripcion(
		"En el invierno de 1927 tomaste un autobús desde Newburyport para investigar unos rumores que nadie quería repetir en voz alta. El vehículo te ha dejado en el borde de un pueblo que los mapas preferían olvidar.\n\nNo sabías entonces que Innsmouth no devuelve a todos los que entran."
	)
	ui.mostrar_sistema("Escribe AYUDA para consultar los comandos. Escribe MIRAR para observar lo que te rodea.")
	ui.separador()


func _entrar_habitacion(habitacion_id: String) -> void:
	var sala := room_manager.obtener(habitacion_id)
	if sala == null:
		ui.mostrar_error("El camino se disuelve antes de que puedas recorrerlo. No hay nada al otro lado.")
		return

	var primera_visita := not PlayerState.ha_visitado(habitacion_id)
	PlayerState.habitacion_actual = habitacion_id
	PlayerState.marcar_visitado(habitacion_id)
	_actualizar_panel()

	ui.separador()
	_describir_sala(sala, primera_visita)

	if primera_visita and sala.impacto_cordura != 0:
		_aplicar_impacto(sala.impacto_cordura, "la visión de este lugar")


func _describir_sala(sala: Room, completa: bool) -> void:
	ui.mostrar_habitacion(sala.nombre)
	var descripcion := sala.descripcion_larga if completa else sala.descripcion_corta
	descripcion = _distorsionar_descripcion(descripcion)
	ui.mostrar_descripcion(descripcion)

	if completa and not sala.ambiente.is_empty():
		ui.mostrar_sistema(sala.ambiente)

	var salidas := _salidas_texto(sala)
	if not salidas.is_empty():
		ui.mostrar_salidas(salidas)

	var objetos := _nombres_objetos(sala)
	if not objetos.is_empty():
		ui.mostrar_objetos(TextUtils.formatear_lista(objetos))

	var personas := _nombres_npcs(sala)
	if not personas.is_empty():
		ui.mostrar_personas(TextUtils.formatear_lista(personas))

	if completa:
		_maybe_alucinacion()


func _mirar_habitacion() -> void:
	var sala := _sala_actual()
	if sala == null:
		return
	_describir_sala(sala, true)


func _mover(direccion: String, objetivo: String) -> void:
	var sala := _sala_actual()
	if sala == null:
		return

	var salida := direccion
	if salida.is_empty() and not objetivo.is_empty():
		salida = room_manager.resolver_conexion(sala, objetivo)

	if salida.is_empty():
		if objetivo.is_empty():
			var disponibles := _salidas_texto(sala)
			if disponibles.is_empty():
				ui.mostrar_sistema("No hay ninguna salida visible. Solo paredes, niebla y el peso de la mirada de Innsmouth.")
			else:
				ui.mostrar_sistema("Las únicas salidas son: %s." % disponibles)
		else:
			ui.mostrar_error("No hay ningún camino hacia «%s» desde aquí." % _seguro(objetivo))
		return

	var requisito_salida := sala.requisito_para_conexion(salida)
	var faltantes_salida: Array[String] = []
	for requerido_id in sala.objetos_requeridos_conexion(salida):
		if not PlayerState.tiene_objeto(requerido_id):
			faltantes_salida.append(ItemDB.nombre(requerido_id))
	if not faltantes_salida.is_empty():
		var mensaje_salida := str(requisito_salida.get("mensaje", ""))
		if mensaje_salida.is_empty():
			mensaje_salida = "Necesitas %s para seguir por aquí." % TextUtils.formatear_lista(faltantes_salida).to_lower()
		ui.mostrar_error(mensaje_salida)
		return

	var destino_id := sala.conexion(salida)

	# Compatibilidad con salas que usen una conexión llamada "entrar".
	if destino_id.is_empty() and salida == "dentro":
		destino_id = sala.conexion("entrar")

	if destino_id.is_empty():
		ui.mostrar_error(_mensaje_sin_salida(salida))
		return

	if not room_manager.existe(destino_id):
		ui.mostrar_error("Ese lugar existe en el mapa, pero no en el mundo. La niebla ha debido de tragárselo.")
		return

	_entrar_habitacion(destino_id)


func _mensaje_sin_salida(direccion: String) -> String:
	match direccion:
		"dentro":
			return "No hay ninguna puerta abierta ante ti. Solo madera húmeda y ventanas que no quieren dejarte entrar."
		"fuera":
			return "No hay ningún interior del que salir. O tal vez ya estás fuera, y esto es todo lo que queda."
		_:
			return "No puedes ir hacia el %s desde aquí. Una pared, una puerta cerrada o la niebla te lo impiden." % direccion


func _examinar(objetivo: String) -> void:
	if objetivo.is_empty():
		ui.mostrar_sistema("¿Qué quieres examinar? Puedes probar con un objeto, una persona o una parte de la sala.")
		return

	if objetivo in ["habitacion", "sala", "lugar", "alrededor", "aqui"]:
		_mirar_habitacion()
		return

	var sala := _sala_actual()
	if sala == null:
		return

	if TextUtils.normalizar(objetivo) == TextUtils.normalizar(sala.nombre) or TextUtils.normalizar(objetivo) == TextUtils.normalizar(sala.id):
		_mirar_habitacion()
		return

	var npc := _npc_en_sala(sala, objetivo)
	if npc != null:
		ui.mostrar_evento(npc.nombre)
		ui.mostrar_descripcion(npc.descripcion)
		ui.mostrar_sistema("Puedes hablar con %s." % npc.nombre)
		_maybe_alucinacion()
		return

	var examinable := sala.buscar_examinable(objetivo)
	if not examinable.is_empty():
		var clave := "examinar:%s:%s" % [sala.id, str(examinable.get("clave", ""))]
		ui.mostrar_evento(str(examinable.get("nombre", "Algo")))
		ui.mostrar_descripcion(str(examinable.get("descripcion", "")))

		if sala.id == "hotel_gillman" and str(examinable.get("clave", "")) == "cama":
			_descansar_hotel()
			return

		if not PlayerState.ya_examinado(clave):
			PlayerState.marcar_examinado(clave)
			_aplicar_impacto(
				int(examinable.get("impacto_cordura", 0)),
				"lo que acabas de ver"
			)
		else:
			ui.mostrar_sistema("Ya habías examinado esto. La memoria no lo hace más fácil.")

		_maybe_alucinacion()
		return

	var objeto_id := ItemDB.buscar(objetivo)
	if not objeto_id.is_empty() and PlayerState.tiene_objeto(objeto_id):
		_examinar_objeto(objeto_id, false)
		return

	if not objeto_id.is_empty() and room_manager.objeto_visible(sala.id, objeto_id):
		_examinar_objeto(objeto_id, true)
		return

	ui.mostrar_error("No ves nada parecido a «%s» entre las sombras." % _seguro(objetivo))


func _examinar_objeto(objeto_id: String, esta_en_sala: bool) -> void:
	ui.mostrar_evento(ItemDB.nombre(objeto_id))
	ui.mostrar_descripcion(ItemDB.descripcion(objeto_id))

	var clave := "item:%s" % objeto_id
	if not PlayerState.ya_examinado(clave):
		PlayerState.marcar_examinado(clave)
		_aplicar_impacto(
			ItemDB.cordura_al_examinar(objeto_id),
			"examinar %s" % ItemDB.nombre(objeto_id).to_lower()
		)

	if esta_en_sala:
		ui.mostrar_sistema("Podrías cogerlo.")

	_maybe_alucinacion()


func _coger(objetivo: String) -> void:
	if objetivo.is_empty():
		ui.mostrar_sistema("¿Qué quieres coger?")
		return

	var sala := _sala_actual()
	if sala == null:
		return

	var objeto_id := ItemDB.buscar(objetivo)
	if objeto_id.is_empty():
		if _npc_en_sala(sala, objetivo) != null:
			ui.mostrar_error("No vas a llevarte a una persona. Innsmouth ya tiene suficientes problemas.")
		elif not sala.buscar_examinable(objetivo).is_empty():
			ui.mostrar_error("Eso no se puede llevar. Está clavado al lugar por algo más que el óxido.")
		else:
			ui.mostrar_error("No hay nada parecido a «%s» que puedas coger." % _seguro(objetivo))
		return

	if PlayerState.tiene_objeto(objeto_id):
		ui.mostrar_sistema("Ya llevas %s." % ItemDB.nombre(objeto_id))
		return

	if not room_manager.objeto_visible(sala.id, objeto_id):
		ui.mostrar_error("No hay %s aquí." % ItemDB.nombre(objeto_id).to_lower())
		return

	var requisito := sala.requisito_para(objeto_id)
	if not requisito.is_empty():
		var faltantes: Array[String] = []
		for requerido in sala.objetos_requeridos(objeto_id):
			if not PlayerState.tiene_objeto(requerido):
				faltantes.append(ItemDB.nombre(requerido))
		if not faltantes.is_empty():
			var mensaje := str(requisito.get("mensaje", ""))
			if mensaje.is_empty():
				mensaje = "Necesitas %s para coger %s." % [
					TextUtils.formatear_lista(faltantes).to_lower(),
					ItemDB.nombre(objeto_id).to_lower(),
				]
			ui.mostrar_error(mensaje)
			return

	room_manager.retirar_objeto(sala.id, objeto_id)
	var consumir: Variant = requisito.get("consumir", [])
	if consumir is Array:
		for consumido in consumir:
			PlayerState.quitar_objeto(str(consumido))
	PlayerState.agregar_objeto(objeto_id)
	ui.mostrar_evento("Coges %s." % ItemDB.nombre(objeto_id))
	ui.mostrar_sistema("Lo guardas con cuidado, como si el objeto pudiera morderte.")
	_aplicar_impacto(
		ItemDB.cordura_al_coger(objeto_id),
		"tocar %s" % ItemDB.nombre(objeto_id).to_lower()
	)
	_maybe_alucinacion()


func _usar(objetivo: String) -> void:
	if objetivo.is_empty():
		ui.mostrar_sistema("¿Qué quieres usar?")
		return

	var objeto_id := ItemDB.buscar(objetivo)
	if objeto_id.is_empty() or not PlayerState.tiene_objeto(objeto_id):
		ui.mostrar_error("No llevas nada parecido a «%s»." % _seguro(objetivo))
		return

	var es_escape := objeto_id == "billete_autobus" and PlayerState.habitacion_actual == HABITACION_INICIAL
	var es_prueba := (
		objeto_id in ["placa_aduana", "libro_cuentas_marsh", "cuaderno_zadok", "cuaderno_buzo"]
		and PlayerState.habitacion_actual == HABITACION_INICIAL
	)

	if es_escape and PlayerState.tiene_objeto("tiara_innsmouth"):
		PlayerState.banderas["ruta_victoria"] = "tiara"
		PlayerState.marcar_victoria(
			"Joe Sargent ve la tiara en tus manos y apaga el cigarrillo. No hace preguntas. El motor del autobús arranca a la tercera sacudida y la carretera de Newburyport se abre entre la niebla como una herida que empieza a cerrarse."
		)
		return
	if es_prueba and objeto_id == "placa_aduana":
		PlayerState.banderas["ruta_victoria"] = "placa"
		PlayerState.marcar_victoria(
			"Joe reconoce el sello de la aduana. Durante un instante parece mucho más viejo. «Así que también te han apuntado», murmura. Arranca el autobús sin pedir la tiara y toma la carretera de Newburyport. No te devuelve el billete; dice que ya figurabas en la lista."
		)
		return
	if es_prueba and objeto_id == "libro_cuentas_marsh":
		PlayerState.banderas["ruta_victoria"] = "cuentas_marsh"
		PlayerState.marcar_victoria(
			"Joe hojea las cuentas y reconoce las fechas de los cargamentos de Marsh. Deja de fumar. «Mi padre también conducía esta ruta», dice. «Nunca quiso contarme qué llevaba de vuelta.» Arranca el autobús y toma la carretera de Newburyport; esta vez, mira por el retrovisor hasta que Innsmouth desaparece."
		)
		return
	if es_prueba and objeto_id == "cuaderno_zadok":
		PlayerState.banderas["ruta_victoria"] = "testimonio_zadok"
		PlayerState.marcar_victoria(
			"Joe reconoce varios nombres de barco en las notas de Zadok. Su expresión cambia al encontrar el de su padre. «Él también volvió de aquí», dice, y guarda silencio. El autobús arranca hacia Newburyport mientras el cuaderno registra, en una página que antes estaba en blanco, la hora exacta de la partida."
		)
		return
	if es_prueba and objeto_id == "cuaderno_buzo":
		PlayerState.banderas["ruta_victoria"] = "devils_reef"
		PlayerState.marcar_victoria(
			"Joe reconoce el nombre del barco de la expedición y abre la puerta del autobús. «No voy a esperar a que vuelva la marea», dice. El vehículo toma la carretera de Newburyport; bajo el asiento, el cuaderno se abre solo por una página que muestra la ruta que acabas de recorrer."
		)
		return

	ui.mostrar_evento("Usas %s." % ItemDB.nombre(objeto_id))
	ui.mostrar_descripcion(ItemDB.uso(objeto_id))

	if es_escape:
		ui.mostrar_sistema("El autobús no volverá hasta que puedas demostrar lo que has visto. Te falta una prueba que Innsmouth reconozca.")
		_maybe_alucinacion()
		return

	if objeto_id == "revolver_viejo" and PlayerState.habitacion_actual == "muelle":
		ui.mostrar_peligro("El revólver parece ridículo frente al agua. Aun así, no lo guardas.")
	elif objeto_id == "billete_autobus" and PlayerState.habitacion_actual == "muelle":
		ui.mostrar_sistema("El billete de vuelta pesa en tu bolsillo. Newburyport se siente a años de distancia.")

	_maybe_alucinacion()


func _hablar(objetivo: String) -> void:
	var sala := _sala_actual()
	if sala == null:
		return

	var personas := _npcs_en_sala(sala)
	if personas.is_empty():
		ui.mostrar_sistema("No hay nadie con quien hablar. Solo el viento y las casas que fingen no escuchar.")
		return

	var npc: NpcData = null
	if objetivo.is_empty():
		if personas.size() == 1:
			npc = personas[0]
		else:
			var nombres: Array[String] = []
			for persona in personas:
				nombres.append(persona.nombre)
			ui.mostrar_sistema("¿Con quién quieres hablar? Aquí están: %s." % TextUtils.formatear_lista(nombres))
			return
	else:
		npc = _npc_en_sala(sala, objetivo)
		if npc == null:
			var ausente := room_manager.buscar_npc(objetivo)
			if ausente != null:
				ui.mostrar_error("%s no está aquí ahora mismo." % ausente.nombre)
			else:
				ui.mostrar_error("No hay nadie parecido a «%s» con quien hablar." % _seguro(objetivo))
			return

	_conversar(npc)


func _conversar(npc: NpcData) -> void:
	var indice := int(PlayerState.progreso_dialogos.get(npc.id, 0))

	if indice < npc.dialogos.size():
		ui.mostrar_dialogo(npc.nombre, npc.dialogos[indice])
		PlayerState.progreso_dialogos[npc.id] = indice + 1
	else:
		ui.mostrar_dialogo(npc.nombre, npc.despedida)

	if indice == 0:
		var clave := "conocio:%s" % npc.id
		if not bool(PlayerState.bandera(clave)):
			PlayerState.poner_bandera(clave)
			_aplicar_impacto(npc.impacto_cordura_inicial, "la conversación con %s" % npc.nombre)

	_maybe_alucinacion()


func _mostrar_inventario() -> void:
	if PlayerState.inventario.is_empty():
		ui.mostrar_sistema("No llevas nada. Ni siquiera una excusa convincente.")
		return

	ui.mostrar_evento("Llevas contigo:")
	for objeto_id in PlayerState.inventario:
		ui.mostrar_sistema("• %s" % ItemDB.nombre(objeto_id))
	ui.mostrar_sistema("Cordura: %d / 100 · %s" % [PlayerState.salud_mental, PlayerState.estado_texto()])


func _mostrar_objetivo() -> void:
	ui.separador()
	ui.mostrar_evento("OBJETIVO ACTUAL")
	ui.mostrar_descripcion(_objetivo_actual())
	if not PlayerState.partida_terminada:
		ui.mostrar_sistema("El panel lateral también muestra el objetivo. GUARDAR crea una copia manual; CONTINUAR recupera el último punto de control.")
	ui.separador()


func _objetivo_actual() -> String:
	if PlayerState.partida_ganada:
		return "Has escapado de Innsmouth. El relato ha terminado."
	if PlayerState.partida_terminada:
		return "Tu mente se ha quebrado. Escribe REINICIAR para volver a empezar."
	if PlayerState.tiene_objeto("tiara_innsmouth"):
		return "Vuelve a la parada del autobús y usa el billete para escapar."
	if PlayerState.tiene_objeto("placa_aduana"):
		return "Tienes una prueba de lo que ocurre bajo el arrecife. Puedes mostrarla a Joe en la parada o seguir buscando la tiara."
	if PlayerState.tiene_objeto("libro_cuentas_marsh"):
		return "Las cuentas de Marsh prueban el comercio secreto con Devil Reef. Puedes enseñárselas a Joe en la parada o seguir investigando."
	if PlayerState.tiene_objeto("cuaderno_zadok"):
		return "El cuaderno de Zadok registra barcos desaparecidos y regresos extraños. Puedes enseñárselo a Joe en la parada o seguir investigando."
	if PlayerState.tiene_objeto("cuaderno_buzo"):
		return "El cuaderno del buzo confirma una entrada bajo Devil Reef. Puedes enseñárselo a Joe en la parada o seguir investigando."
	if PlayerState.tiene_objeto("llave_oxidada"):
		return "Entra en la iglesia de Dagon y abre el relicario con la llave oxidada."
	return "Encuentra la llave oxidada en la plaza y llega a la iglesia de Dagon."


func _guardar_partida() -> void:
	var datos := {
		"jugador": PlayerState.serializar(),
		"mapa": room_manager.serializar_objetos(),
	}
	if SaveManager.guardar(datos):
		ui.mostrar_evento("Partida guardada.")
		ui.mostrar_sistema("Archivo: %s" % SaveManager.ruta_legible())
	else:
		ui.mostrar_error("No se pudo guardar la partida: %s" % SaveManager.ultimo_error)


func _cargar_partida() -> void:
	_restaurar_partida(
		SaveManager.cargar(),
		"PARTIDA CARGADA",
		SaveManager.ruta_legible()
	)


func _continuar_partida() -> void:
	var datos := SaveManager.cargar_autoguardado()
	if datos.is_empty() and not SaveManager.existe_autoguardado():
		ui.mostrar_error("No hay ningún punto de control automático.")
		return

	_restaurar_partida(
		datos,
		"PUNTO DE CONTROL RECUPERADO",
		SaveManager.ruta_autoguardado_legible()
	)


func _restaurar_partida(datos: Dictionary, titulo: String, ruta: String) -> void:
	if datos.is_empty():
		ui.mostrar_error(SaveManager.ultimo_error)
		return

	var jugador: Variant = datos.get("jugador", {})
	if not jugador is Dictionary or (jugador as Dictionary).is_empty():
		ui.mostrar_error("El archivo de guardado no contiene una partida válida.")
		return

	_suprimir_avisos = true
	PlayerState.deserializar(jugador as Dictionary)
	_suprimir_avisos = false
	_cordura_previa = PlayerState.salud_mental

	var mapa: Variant = datos.get("mapa", {})
	if mapa is Dictionary:
		room_manager.deserializar_objetos(mapa as Dictionary)
	else:
		room_manager.deserializar_objetos({})

	if PlayerState.habitacion_actual.is_empty() or not room_manager.existe(PlayerState.habitacion_actual):
		PlayerState.habitacion_actual = HABITACION_INICIAL

	ui.separador()
	ui.mostrar_evento(titulo)
	ui.mostrar_sistema("Archivo: %s" % ruta)
	_entrar_habitacion(PlayerState.habitacion_actual)

	if PlayerState.partida_ganada:
		_mostrar_victoria(_motivo_victoria_guardada())
	elif PlayerState.partida_terminada:
		ui.mostrar_peligro("La partida guardada termina en derrota. Escribe REINICIAR para volver a empezar.")
	else:
		_autoguardar_partida()


func _autoguardar_partida() -> void:
	if PlayerState.partida_terminada:
		return

	var datos := {
		"jugador": PlayerState.serializar(),
		"mapa": room_manager.serializar_objetos(),
	}
	if not SaveManager.guardar_autoguardado(datos):
		ui.mostrar_error("No se pudo actualizar el punto de control: %s" % SaveManager.ultimo_error)


func _borrar_partida() -> void:
	var hay_guardado := SaveManager.existe()
	var hay_autoguardado := SaveManager.existe_autoguardado()
	if not hay_guardado and not hay_autoguardado:
		ui.mostrar_sistema("No hay ninguna partida ni punto de control que borrar.")
		return

	if hay_guardado and not SaveManager.borrar():
		ui.mostrar_error("No se pudo borrar la partida: %s" % SaveManager.ultimo_error)
		return
	if hay_autoguardado and not SaveManager.borrar_autoguardado():
		ui.mostrar_error("No se pudo borrar el punto de control: %s" % SaveManager.ultimo_error)
		return

	ui.mostrar_evento("Partida borrada.")
	ui.mostrar_sistema("Se eliminaron los guardados manuales y automáticos.")


func _mostrar_victoria(motivo: String) -> void:
	ui.separador()
	ui.mostrar_evento("HAS ESCAPADO DE INNSMOUTH")
	ui.mostrar_descripcion(motivo)
	ui.mostrar_descripcion(_epilogo_victoria())
	ui.mostrar_sistema("Escribe REINICIAR para volver a empezar o CONTINUAR para recuperar el último punto de control.")
	_actualizar_panel()


func _epilogo_victoria() -> String:
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "placa":
		return "La niebla se cierra detrás del autobús. Durante un segundo, todas las ventanas del pueblo se giran a la vez. Luego solo queda la carretera, el motor y la placa de cobre apretada en tu mano. No sabes si has escapado o si Innsmouth te ha dejado marchar por algún motivo."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "cuentas_marsh":
		return "El libro de cuentas descansa sobre tus rodillas. Las cifras de oro y las fechas siguen pareciendo nítidas, incluso cuando la niebla borra el pueblo. En la última página, una anotación nueva aparece bajo tu nombre: «deuda pendiente»."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "testimonio_zadok":
		return "El cuaderno de Zadok descansa junto a ti. Las anotaciones terminan en la fecha de hoy, aunque la última página sigue húmeda. Al mirar por la ventana, las marismas parecen extenderse hasta el horizonte."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "devils_reef":
		return "La carretera se aleja del arrecife, pero el cuaderno del buzo se abre sobre tus rodillas. La ruta dibujada termina en un punto marcado con tu nombre y una fecha futura."
	return "Recuerdas el amanecer en la carretera de Newburyport, la tiara envuelta en tu abrigo y el autobús alejándose de Innsmouth. No sabes si has escapado o si Innsmouth te ha dejado marchar por algún motivo."


func _motivo_victoria_guardada() -> String:
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "placa":
		return "Joe reconoce el sello de la aduana. No pregunta nada más. El autobús arranca hacia Newburyport."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "cuentas_marsh":
		return "Joe reconoce los cargamentos de Marsh y arranca el autobús hacia Newburyport."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "testimonio_zadok":
		return "Joe reconoce los nombres de los barcos en el cuaderno de Zadok y arranca hacia Newburyport."
	if str(PlayerState.banderas.get("ruta_victoria", "")) == "devils_reef":
		return "Joe reconoce el nombre de la expedición a Devil Reef y arranca hacia Newburyport."
	return "Recuerdas el amanecer en la carretera de Newburyport, la tiara envuelta en tu abrigo y el autobús alejándose de Innsmouth."


func _mostrar_ayuda() -> void:
	ui.separador()
	ui.mostrar_evento("COMANDOS DISPONIBLES")
	ui.mostrar_sistema("Movimiento: norte, sur, este, oeste, diagonales (noreste/suroeste), abajo, arriba, ir [lugar], entrar, salir.")
	ui.mostrar_sistema("Exploración: mirar, examinar [objeto o zona], inspeccionar [objeto].")
	ui.mostrar_sistema("Inventario: inventario, items.")
	ui.mostrar_sistema("Interacción: coger [objeto], usar [objeto], hablar con [personaje].")
	ui.mostrar_sistema("Partida: objetivo, guardar, cargar, continuar, borrar.")
	ui.mostrar_sistema("Otros: esperar (avanza una hora), descansar (seis horas en el hotel), ayuda, reiniciar. Usa ↑/↓ para recuperar comandos.")
	ui.mostrar_sistema("Consejo: no todo lo que se puede mirar debería mirarse.")
	ui.separador()


func _esperar() -> void:
	if PlayerState.habitacion_actual == "hotel_gillman":
		_descansar_hotel()
		return
	_avanzar_tiempo(1)
	ui.mostrar_sistema("Esperas. El viento arrastra sal por la calle. Nada cambia, salvo la certeza de que algo te está esperando.")
	_maybe_alucinacion()


func _descansar_hotel() -> void:
	if PlayerState.habitacion_actual != "hotel_gillman":
		ui.mostrar_sistema("No hay ningún lugar seguro donde descansar. Solo puedes esperar.")
		_esperar()
		return

	if bool(PlayerState.bandera("hotel_descansado", false)):
		_avanzar_tiempo(1)
		ui.mostrar_sistema("Vuelves a cerrar los ojos, pero el colchón ya no parece una cama. El reloj avanza una hora sin traerte descanso.")
		_maybe_alucinacion()
		return

	PlayerState.poner_bandera("hotel_descansado")
	_avanzar_tiempo(6)
	ui.mostrar_evento("Te despiertas en la habitación 7.")
	ui.mostrar_sistema("Has dormido seis horas. El rumor de la marea está ahora más cerca.")
	_aplicar_impacto(6, "el breve descanso en el hotel Gillman")


func _avanzar_tiempo(horas: int) -> void:
	var transcurridos := int(PlayerState.bandera("minutos_transcurridos", 0))
	transcurridos += maxi(horas, 0) * 60
	PlayerState.poner_bandera("minutos_transcurridos", transcurridos)
	var minutos_del_dia := (21 * 60 + transcurridos) % (24 * 60)
	var hora := floori(float(minutos_del_dia) / 60.0)
	var minuto := minutos_del_dia % 60
	ui.mostrar_sistema("El reloj marca las %02d:%02d." % [hora, minuto])


func _salidas_texto(sala: Room) -> String:
	var salidas: Array[String] = []
	for direccion in sala.conexiones:
		salidas.append(str(direccion))
	return TextUtils.formatear_lista(salidas)


func _nombres_objetos(sala: Room) -> Array[String]:
	var nombres: Array[String] = []
	for objeto_id in room_manager.objetos_visibles(sala.id):
		nombres.append(ItemDB.nombre(objeto_id))
	return nombres


func _npcs_en_sala(sala: Room) -> Array[NpcData]:
	var personas: Array[NpcData] = []
	for npc_id in sala.npcs:
		var npc := room_manager.obtener_npc(str(npc_id))
		if npc != null:
			personas.append(npc)
	return personas


func _nombres_npcs(sala: Room) -> Array[String]:
	var nombres: Array[String] = []
	for npc in _npcs_en_sala(sala):
		nombres.append(npc.nombre)
	return nombres


func _npc_en_sala(sala: Room, objetivo: String) -> NpcData:
	for npc in _npcs_en_sala(sala):
		if npc.coincide(objetivo):
			return npc
	return null


func _sala_actual() -> Room:
	return room_manager.obtener(PlayerState.habitacion_actual)


func _actualizar_panel() -> void:
	var sala := _sala_actual()
	ui.actualizar_ubicacion(sala.nombre if sala != null else "—")
	ui.actualizar_cordura(PlayerState.salud_mental, PlayerState.estado_texto())
	ui.actualizar_objetivo(_objetivo_actual())
	_refrescar_inventario()


func _refrescar_inventario() -> void:
	var nombres: Array[String] = []
	for objeto_id in PlayerState.inventario:
		nombres.append(ItemDB.nombre(objeto_id))
	ui.actualizar_inventario(nombres)


func _aplicar_impacto(cantidad: int, motivo: String) -> void:
	if cantidad == 0 or PlayerState.partida_terminada:
		return

	var anterior := PlayerState.salud_mental
	PlayerState.modificar_cordura(cantidad)
	var delta := PlayerState.salud_mental - anterior

	if delta < 0 and not PlayerState.partida_terminada:
		ui.mostrar_peligro("Tu cordura se resquebraja (%s).  −%d Cordura." % [motivo, abs(delta)])
	elif delta > 0:
		ui.mostrar_sistema("Algo en tu mente se recompone.  +%d Cordura." % delta)


func _al_cambiar_cordura(valor: int, _delta: int) -> void:
	ui.actualizar_cordura(valor, PlayerState.estado_texto())

	if _suprimir_avisos:
		_cordura_previa = valor
		return

	if valor < _cordura_previa and _cordura_previa > 60 and valor <= 60:
		ui.mostrar_evento("Una inquietud sorda se instala detrás de tus ojos. El mundo sigue ahí, pero ya no exactamente igual.")

	_cordura_previa = valor


func _al_cambiar_panico(activo: bool) -> void:
	if activo:
		ui.mostrar_panico("El borde de tu visión tiembla. Las sombras ya no están quietas.")
	else:
		ui.mostrar_sistema("La opresión retrocede, aunque no del todo.")


func _al_cambiar_inventario(_inventario: Array[String]) -> void:
	_refrescar_inventario()
	ui.actualizar_objetivo(_objetivo_actual())


func _al_alucinar(texto: String) -> void:
	ui.mostrar_susurro(texto)


func _al_comando_invalido(_texto_original: String, mensaje: String) -> void:
	ui.mostrar_error(mensaje)


func _al_derrotar(motivo: String) -> void:
	ui.separador()
	ui.mostrar_panico("EL RELATO SE DETIENE")
	ui.mostrar_descripcion(motivo)
	ui.mostrar_descripcion(
		"Las casas se inclinan hacia ti. El olor del puerto llena tus pulmones hasta que dejas de distinguir dónde terminas tú y dónde empieza Innsmouth. Alguien, muy lejos, cierra una puerta."
	)
	ui.mostrar_sistema("Escribe REINICIAR para volver a empezar o CONTINUAR para recuperar el último punto de control.")
	ui.actualizar_cordura(0, "Quebrado")
	_actualizar_panel()


func _al_victorizar(motivo: String) -> void:
	_mostrar_victoria(motivo)


func _maybe_alucinacion() -> void:
	if PlayerState.partida_terminada or PlayerState.salud_mental > UMBRAL_INQUIETUD:
		return

	var probabilidad := 0.18
	if PlayerState.en_panico():
		probabilidad = 0.50

	if randf() < probabilidad:
		ui.mostrar_susurro(SUSURROS_AMBIENTALES.pick_random())


func _seguro(texto: String) -> String:
	return texto.replace("[", "[lb]")


func _distorsionar_descripcion(texto: String) -> String:
	if PlayerState.partida_terminada or PlayerState.salud_mental > UMBRAL_INQUIETUD:
		return texto

	var probabilidad := 0.14
	if PlayerState.en_panico():
		probabilidad = 0.45
	if randf() >= probabilidad:
		return texto

	if PlayerState.en_panico():
		var sustituciones := {
			"agua": "aagua",
			"casas": "cassas",
			"casa": "cassa",
			"ojos": "ojjos",
			"ojo": "ojjo",
			"puerta": "puertta",
			"marea": "mareaa",
			"sombras": "ssombras",
			"sombra": "ssombra",
		}
		for palabra in sustituciones:
			if texto.contains(palabra):
				texto = texto.replace(palabra, str(sustituciones[palabra]))
				break
		texto += "\n\n[color=#8f4a42][i]Una palabra de la descripción no estaba ahí hace un momento. Jurarías que acaba de moverse.[/i][/color]"
	else:
		texto += "\n\n[color=#6f7d6b][i]Sientes una presencia al borde de la visión, como si la sala tuviera un pasillo más que antes.[/i][/color]"

	return texto


func _reiniciar() -> void:
	if SaveManager.existe_autoguardado() and not SaveManager.borrar_autoguardado():
		ui.mostrar_error("No se pudo descartar el punto de control anterior: %s" % SaveManager.ultimo_error)
		return
	call_deferred("_recargar_escena")


func _recargar_escena() -> void:
	_iniciar_nueva_partida()
