extends Control

# Definimos la señal (como un canal de comunicación)
signal cambio_de_personaje(nombre_archivo)
# Referencias a los nodos hijos
@onready var label_nombre = %Label
@onready var label_texto = %RichTextLabel
@onready var preguntas = %ItemList
@onready var boton_regresar = %Regresar 

var modo_interrogatorio = false
var sospechoso_actual = "" # Debes asignarlo al iniciar el interrogatorio
var puntos_nervios = 0

var leyendo_respuesta := false
var bloqueando_pregunta := false

# Lista de sospechosos para el momento aleatorio
var sospechosos = ["casilda", "calixto", "eulalio", "basilio", "juan"]
var datos_dialogo = {}
var datos_clues = {}
var viendo_presentacion = false # Para saber si ya pasamos a la parte de los sospechosos



func _ready():
	cargar_json()
	cargar_json_pistas()
	boton_regresar.hide() # Empezamos con el botón oculto
	await get_tree().process_frame
	
	# Si ya no estamos en el prólogo, saltamos directo al interrogatorio
	if Global.fase_prologo == "prologo_2":
		# Esta es la función que definimos antes para llenar el ItemList y mostrar al sospechoso
		preparar_interrogatorio(Global.sospechoso_mencionado)
	else:
		# Lógica normal del inicio del juego
		mostrar_paso_prologo()

func cargar_json():
	var file = FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if file:
		datos_dialogo = JSON.parse_string(file.get_as_text())

func cargar_json_pistas():
	var file = FileAccess.open("res://data/clues.json", FileAccess.READ)
	if file:
		datos_clues = JSON.parse_string(file.get_as_text())
	else:
		print("Error: No se encontró clues.json")

func _input(event):
	if event.is_action_pressed("click_izquierdo"):
		# Si estamos en interrogatorio y el menú de preguntas está visible,
		# NO dejamos que el click general haga nada.
		# El ItemList se encarga de elegir la pregunta.
		if modo_interrogatorio and preguntas.visible:
			return
		
		# Si acabamos de seleccionar una pregunta,
		# ignoramos este click para que no avance solo.
		if bloqueando_pregunta:
			return
		
		avanzar_logica()

func avanzar_logica():
	if modo_interrogatorio:
		# Solo si estamos leyendo una respuesta, el click regresa al menú.
		if leyendo_respuesta:
			leyendo_respuesta = false
			alternar_visibilidad(true)
		return
	
	if not viendo_presentacion:
		if Global.indice_prologo_actual < datos_dialogo["prologo_amado"].size() - 1:
			Global.indice_prologo_actual += 1
			mostrar_paso_prologo()
		else:
			iniciar_presentacion_sospechoso()
	else:
		regresar_a_historia_fase_2()

func regresar_a_historia_fase_2():
	# 1. IMPORTANTE: Cambiamos el estado global
	Global.fase_prologo = "prologo_2"
	Global.indice_historia = 0 # Para que la historia empiece desde el texto 0 de la fase 2
	
	# 2. Limpieza de flags
	viendo_presentacion = false
	Global.prologo_activo = false
	
	print("Handshake completo: Cambiando a Prologo 2")
	get_tree().change_scene_to_file("res://scenes/historia.tscn")

func mostrar_paso_prologo():
	var paso = datos_dialogo["prologo_amado"][Global.indice_prologo_actual]
	var texto_final = paso["texto"]
	
	# 1. Lógica del sospechoso (solo para el último diálogo)
	if "{sospechoso}" in texto_final:
		var elegido = sospechosos[randi() % sospechosos.size()]
		Global.sospechoso_mencionado = elegido
		texto_final = texto_final.replace("{sospechoso}", elegido.capitalize())
	
	actualizar_interfaz(paso["nombre"], texto_final)

	# 2. CAMBIO DE IMAGEN DE DON AMADO
	# Como tus archivos se llaman amado_1 y amado_2,
	# forzamos el nombre "amado" manualmente para esta parte:
	var nombre_archivo = "amado_" + str(paso["expresion"])
	
	# Emitimos la señal para que la escena de Diálogo lo cargue
	emit_signal("cambio_de_personaje", nombre_archivo)

func preparar_interrogatorio(nombre_sospechoso):
	modo_interrogatorio = true
	sospechoso_actual = nombre_sospechoso.to_lower()
	puntos_nervios = 0
	
	# 1. Actualizamos el Label del nombre inmediatamente[cite: 6]
	label_nombre.text = nombre_sospechoso.capitalize()
	
	# 2. Emitimos la señal para que la escena cargue la imagen (ej: "juan_1")
	emit_signal("cambio_de_personaje", sospechoso_actual + "_1")
	
	# 3. Limpiamos el texto de bienvenida
	label_texto.text = "Selecciona una pregunta para comenzar el interrogatorio."
	
	configurar_menu_preguntas()
	alternar_visibilidad(true)
	
func configurar_menu_preguntas():
	preguntas.clear()
	preguntas.deselect_all()
	
	# Pregunta base 1
	preguntas.add_item("¿Dónde estaba usted?", null, true)
	preguntas.set_item_metadata(preguntas.item_count - 1, "coartada")
	
	# Pregunta base 2
	preguntas.add_item("¿Quién cree que fue?", null, true)
	preguntas.set_item_metadata(preguntas.item_count - 1, "opinion_culpable")
	
	# Pregunta sobre el arma/objeto del sospechoso:
	# Solo aparece si ya encontraste el arma ligada a este sospechoso.
	var id_arma_sospechoso = obtener_arma_del_sospechoso(sospechoso_actual)
	
	if id_arma_sospechoso != "" and Global.pistas_descubiertas.has(id_arma_sospechoso):
		preguntas.add_item("Sobre este objeto suyo...", null, true)
		preguntas.set_item_metadata(preguntas.item_count - 1, "reaccion_arma")
	
	# Pregunta base 3
	preguntas.add_item("Usted oculta algo...", null, true)
	preguntas.set_item_metadata(preguntas.item_count - 1, "presion_general")
	
	# Pregunta extra / condenatoria:
	# Solo aparece si:
	# 1. Este sospechoso ES el culpable.
	# 2. Ya encontraste su pista extra/condenatoria.
	if Global.caso_actual.has("culpable") and Global.caso_actual.has("pista_maestra"):
		var es_culpable = sospechoso_actual == Global.caso_actual["culpable"]
		var id_pista_extra = Global.caso_actual["pista_maestra"]
		var pista_extra_encontrada = Global.pistas_descubiertas.has(id_pista_extra)
		
		if es_culpable and pista_extra_encontrada:
			preguntas.add_item("¿Cómo explica esto?", null, true)
			preguntas.set_item_metadata(preguntas.item_count - 1, "pista_maestra")

func _on_item_list_item_selected(index):
	if bloqueando_pregunta:
		return
	
	bloqueando_pregunta = true
	
	# Guardamos SOLO la pregunta seleccionada
	var tipo_pregunta = preguntas.get_item_metadata(index)
	
	# Quitamos selección visual
	preguntas.deselect_all()
	
	# IMPORTANTE:
	# Oculta preguntas y muestra el RichTextLabel
	alternar_visibilidad(false)
	
	# Mostramos SOLO la respuesta de esa pregunta
	procesar_respuesta(tipo_pregunta)
	
	await get_tree().create_timer(0.20).timeout
	bloqueando_pregunta = false

func procesar_respuesta(tipo):
	leyendo_respuesta = true
	
	var datos_i = datos_dialogo["interrogatorio"][sospechoso_actual]
	var texto_respuesta = datos_i[tipo]
	
	texto_respuesta = limpiar_shake_del_texto(texto_respuesta)
	
	var nivel_shake = 0
	
	if tipo == "presion_general":
		nivel_shake = 4
	
	if tipo == "pista_maestra":
		if Global.caso_actual.has("culpable"):
			if sospechoso_actual == Global.caso_actual["culpable"]:
				nivel_shake = 12
				emit_signal("cambio_de_personaje", sospechoso_actual + "_3")
	
	actualizar_interfaz_interrogatorio(texto_respuesta, nivel_shake)

func limpiar_shake_del_texto(texto: String) -> String:
	var regex_inicio = RegEx.new()
	regex_inicio.compile("\\[shake[^\\]]*\\]")
	texto = regex_inicio.sub(texto, "", true)
	
	var regex_cierre = RegEx.new()
	regex_cierre.compile("\\[/shake\\]")
	texto = regex_cierre.sub(texto, "", true)
	
	return texto
	
func actualizar_interfaz_interrogatorio(texto, nivel_shake):
	label_nombre.text = sospechoso_actual.capitalize()
	label_texto.bbcode_enabled = true
	
	if nivel_shake > 0:
		label_texto.text = "[shake rate=20.0 level=%d]%s[/shake]" % [nivel_shake * 2, texto]
	else:
		label_texto.text = texto
	
	label_texto.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(label_texto, "visible_ratio", 1.0, 0.5)

func alternar_visibilidad(preguntando: bool):
	preguntas.visible = preguntando
	label_texto.visible = !preguntando
	# Si estamos leyendo la respuesta, el click izquierdo nos regresará al menú
	# Esto hay que ajustarlo en avanzar_logica()
	# El botón de regresar SOLO se muestra si:
	# 1. Estamos en modo interrogatorio (fase 2)
	# 2. El menú de preguntas está abierto
	if modo_interrogatorio and preguntando:
		boton_regresar.show()
	else:
		boton_regresar.hide()
		
func _on_regresar_pressed() -> void:
	# Simplemente cambiamos de escena de vuelta al HUB
	# El Global mantendrá tus pistas y estado del caso intactos
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func iniciar_presentacion_sospechoso():
	viendo_presentacion = true
	var clave = Global.sospechoso_mencionado # Ej: "juan"
	
	# CAMBIO AQUÍ: Ahora buscamos en 'bienvenida_prologo'
	var datos_personaje = datos_dialogo["bienvenida_prologo"][clave]
	
	actualizar_interfaz(datos_personaje["nombre"], datos_personaje["texto"])
	
	# Construimos el nombre del archivo: "juan_1"
	var nombre_archivo = clave.to_lower() + "_" + str(datos_personaje["expresion"])
	
	# Avisamos a la escena principal que cambie la imagen
	emit_signal("cambio_de_personaje", nombre_archivo)

func actualizar_interfaz(nombre, texto):
	label_nombre.text = nombre
	label_texto.text = texto
	# Reiniciar el efecto de escritura (opcional)
	label_texto.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(label_texto, "visible_ratio", 1.0, 1.0)

func obtener_arma_del_sospechoso(id_sospechoso: String) -> String:
	if not datos_clues.has("pistas_armas"):
		return ""
	
	for id_arma in datos_clues["pistas_armas"].keys():
		var arma = datos_clues["pistas_armas"][id_arma]
		var propietario = arma.get("propietario", "").to_lower()
		
		if propietario == id_sospechoso.to_lower():
			return id_arma
	
	return ""
