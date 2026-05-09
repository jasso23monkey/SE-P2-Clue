extends Node2D

# Referencias usando la ruta de tu árbol de nodos
@onready var menu_opciones = %Opciones
@onready var contenedor_libro = %Libro
@onready var boton_cerrar = %close
@onready var estandar_izq = %Estandar_izq
@onready var estandar_der = %Estandar_der
@onready var sprite_imagen = %sprite
@onready var label_nombre = %titulo
@onready var label_desc = %texto
@onready var boton_accion = %accion
@onready var notas_izq = %Notas_izq
@onready var notas_der = %Notas_der
@onready var item_list_notas = %Pistas # El que está dentro de tu panel izquierdo
@onready var label_detalle_titulo = %Objeto # Label en la derecha
@onready var label_detalle_info = %Info # Label o RichTextLabel en la derecha
@onready var label_sospechoso = %sospechoso
@onready var acusar_izq = %Acusar_izq
@onready var acusar_der = %Acusar_der
@onready var label_lugar = %lugar
@onready var lista_sospechosos = %Sos_list
@onready var lista_armas = %Arma_list
@onready var lista_lugares = %Lug_list
@onready var label_acusar_sospechoso = %sospechosin
@onready var label_acusar_arma = %arma
@onready var label_acusar_lugar = %lugarsin
@onready var imagen_acusado = %acusado
@onready var boton_acusar = %next

var lista_datos = [] # Aquí guardaremos las llaves del JSON (ej: ["despacho", "capilla"])
var indice_actual = 0
var dict_referencia : Dictionary = {} 
var categoria_actual = "" # "lugares" o "sospechosos"
var causa = ""
var datos_clues := {}
var datos_story := {}
var datos_suspects := {}

var acusado_sospechoso := ""
var acusado_arma := ""
var acusado_lugar := ""

func _ready():
	contenedor_libro.hide()
	menu_opciones.show()
	
	cargar_datos_acusacion()
	llenar_menu_acusacion()
	
	ocultar_paginas_libro()


func ocultar_paginas_libro():
	estandar_izq.hide()
	estandar_der.hide()
	notas_izq.hide()
	notas_der.hide()
	acusar_izq.hide()
	acusar_der.hide()
# --- Funciones para los botones de la barra inferior ---


func _on_mapa_pressed():
	categoria_actual = "lugares"
	contenedor_libro.show()
	menu_opciones.show()
	
	ocultar_paginas_libro()
	estandar_izq.show()
	estandar_der.show()
	
	preparar_datos()

func _on_interrogar_pressed():
	categoria_actual = "sospechosos"
	contenedor_libro.show()
	menu_opciones.show()
	
	ocultar_paginas_libro()
	estandar_izq.show()
	estandar_der.show()
	
	preparar_datos()

func _on_notas_pressed():
	contenedor_libro.show()
	menu_opciones.show()
	
	ocultar_paginas_libro()
	notas_izq.show()
	notas_der.show()
	
	llenar_item_list_pistas()

func _on_acusar_pressed():
	contenedor_libro.show()
	menu_opciones.show()
	
	ocultar_paginas_libro()
	acusar_izq.show()
	acusar_der.show()
	
	acusado_sospechoso = ""
	acusado_arma = ""
	acusado_lugar = ""
	
	lista_sospechosos.deselect_all()
	lista_armas.deselect_all()
	lista_lugares.deselect_all()
	
	llenar_menu_acusacion()
	actualizar_preview_acusacion()

# --- Lógica de apertura y cierre ---
func _on_close_pressed():
	contenedor_libro.hide()
	menu_opciones.show()
	ocultar_paginas_libro()

func preparar_datos():
	# Determinamos qué archivo abrir según la categoría
	var ruta_archivo = "res://data/story.json" if categoria_actual == "lugares" else "res://data/suspects.json"
	
	var file = FileAccess.open(ruta_archivo, FileAccess.READ)
	if file:
		var json_data = JSON.parse_string(file.get_as_text())
		
		# Si es lugares, los datos están dentro de una llave "lugares"
		# Si es sospechosos (suspects.json), los datos están en la raíz del archivo
		if categoria_actual == "lugares":
			dict_referencia = json_data["lugares"]
		else:
			dict_referencia = json_data # El JSON de sospechosos no tiene llave padre
			
		lista_datos = dict_referencia.keys()
		indice_actual = 0
		
		contenedor_libro.show()
		ocultar_paginas_libro()
		estandar_izq.show()
		estandar_der.show()
		actualizar_interfaz()

func actualizar_interfaz():
	var id_actual = lista_datos[indice_actual]
	var info = dict_referencia[id_actual]
	
	# Ahora ambos JSON tienen las mismas llaves: "nombre", "descripcion", "imagen"
	label_nombre.text = info["nombre"]
	label_desc.text = info["descripcion"]
	
	if info.has("imagen") and info["imagen"] != "":
		sprite_imagen.texture = load(info["imagen"])
	
	# El botón cambia de texto según la categoría
	boton_accion.text = "Viajar" if categoria_actual == "lugares" else "Interrogar"

func llenar_item_list_pistas():
	item_list_notas.clear()
	
	# --- NOTA PRECARGADA: CAUSA DE MUERTE ---
	# Usamos el efecto guardado en Global para generar la primera entrada
	var causa_idx = item_list_notas.add_item("NOTA MÉDICA: Causa de Muerte")
	item_list_notas.set_item_metadata(causa_idx, "causa_muerte") # ID especial
	
	# --- RESTO DE PISTAS ENCONTRADAS ---
	if Global.pistas_descubiertas.size() > 0:
		for id_pista in Global.pistas_descubiertas:
			var info = buscar_info_pista_completa(id_pista)
			var idx = item_list_notas.add_item(info["nombre"])
			item_list_notas.set_item_metadata(idx, id_pista)

# Esta función la conectas a la señal "item_selected" de tu ItemList (%Pistas)
func _on_pistas_item_selected(index: int) -> void:
	var id_pista = item_list_notas.get_item_metadata(index)
	
	# --- CASO ESPECIAL NOTA MÉDICA ---
	if id_pista == "causa_muerte":
		label_detalle_titulo.text = "INFORME FORENSE"
		label_sospechoso.text = "N/A"
		label_lugar.text = "N/A"
		label_detalle_info.text = "Causa de muerte: " + Global.caso_actual.get("efecto", "DESCONOCIDO").to_upper()
		return

	# --- BÚSQUEDA NORMAL ---
	var info = buscar_info_pista_completa(id_pista)
	
	# Si la info es null (por seguridad), limpiamos y salimos
	if info == null:
		return

	# Título: Si es evidencia directa, ponemos el marcador [!]
	if info.get("tipo") == "evidencia_directa" or info.get("tipo") == "arma":
		label_detalle_titulo.text = "[!] " + info["nombre"].to_upper()
	else:
		label_detalle_titulo.text = info["nombre"]

	# --- ASIGNACIÓN DE DATOS (PROTEGIDA CONTRA ERRORES) ---
	label_sospechoso.text = info.get("propietario", "Desconocido")
	
	# SOLUCIÓN AL ERROR: Si no tiene ubicación_original, usamos el lugar del crimen del Global
	label_lugar.text = info.get("ubicacion_original", Global.caso_actual["lugar"])
	
	label_detalle_info.text = info.get("descripcion", "Sin descripción.")

# Función para buscar en el JSON
func buscar_info_pista_completa(id_pista):
	var file = FileAccess.open("res://data/clues.json", FileAccess.READ)
	if not file:
		return null
		
	var datos = JSON.parse_string(file.get_as_text())
	
	# 1. Buscamos en pistas_armas
	if datos["pistas_armas"].has(id_pista):
		return datos["pistas_armas"][id_pista]
	
	# 2. Buscamos en pistas_personales
	if datos["pistas_personales"].has(id_pista):
		return datos["pistas_personales"][id_pista]
	
	# 3. BUSCAMOS EN LA NUEVA CATEGORÍA (Para Juan, Calixto, etc.)
	if datos.has("pistas_condenatorias") and datos["pistas_condenatorias"].has(id_pista):
		return datos["pistas_condenatorias"][id_pista]
	
	# Si no se encuentra en ningún lado, devolvemos un diccionario con llaves vacías
	# Esto evita el error "Invalid access to property 'propietario'"
	return {
		"nombre": "Desconocido", 
		"descripcion": "Sin detalles.", 
		"propietario": "N/A", 
		"ubicacion_original": "N/A"
	}


# --- LÓGICA DE LAS FLECHAS < > ---

func _on_izquierda_pressed():
	if indice_actual > 0:
		indice_actual -= 1
		actualizar_interfaz()

func _on_derecha_pressed():
	if indice_actual < lista_datos.size() - 1:
		indice_actual += 1
		actualizar_interfaz()


func _on_accion_pressed() -> void:
	if lista_datos.size() > 0:
		var id_seleccionado = lista_datos[indice_actual]
		
		# --- CASO: VIAJAR A UN LUGAR ---
		if categoria_actual == "lugares":
			Global.habitacion_actual = id_seleccionado
			get_tree().change_scene_to_file("res://scenes/lugar_base.tscn")
			
		# --- CASO: INTERROGAR A UN SOSPECHOSO ---
		elif categoria_actual == "sospechosos":
			# Guardamos quién es el sospechoso para que la escena de diálogo sepa a quién cargar
			Global.sospechoso_mencionado = id_seleccionado 
			
			# Cambiamos a la escena de Diálogo
			# Asegúrate de que esta ruta sea la correcta de tu escena de interrogatorio
			get_tree().change_scene_to_file("res://scenes/dialogo.tscn")
			
func cargar_datos_acusacion():
	var file_clues = FileAccess.open("res://data/clues.json", FileAccess.READ)
	if file_clues:
		datos_clues = JSON.parse_string(file_clues.get_as_text())
	else:
		print("No se encontró clues.json")
	
	var file_story = FileAccess.open("res://data/story.json", FileAccess.READ)
	if file_story:
		datos_story = JSON.parse_string(file_story.get_as_text())
	else:
		print("No se encontró story.json")
	
	var file_suspects = FileAccess.open("res://data/suspects.json", FileAccess.READ)
	if file_suspects:
		datos_suspects = JSON.parse_string(file_suspects.get_as_text())
	else:
		print("No se encontró suspects.json")
func llenar_menu_acusacion():
	llenar_lista_sospechosos()
	llenar_lista_armas()
	llenar_lista_lugares()
	
func llenar_lista_sospechosos():
	lista_sospechosos.clear()
	
	for id_sospechoso in datos_suspects.keys():
		var sospechoso = datos_suspects[id_sospechoso]
		
		lista_sospechosos.add_item(sospechoso["nombre"])
		lista_sospechosos.set_item_metadata(lista_sospechosos.item_count - 1, id_sospechoso)
func llenar_lista_armas():
	lista_armas.clear()
	
	if not datos_clues.has("pistas_armas"):
		print("No existen pistas_armas en clues.json")
		return
	
	for id_arma in datos_clues["pistas_armas"].keys():
		var arma = datos_clues["pistas_armas"][id_arma]
		
		lista_armas.add_item(arma["nombre"])
		lista_armas.set_item_metadata(lista_armas.item_count - 1, id_arma)
func llenar_lista_lugares():
	lista_lugares.clear()
	
	if not datos_story.has("lugares"):
		print("No existen lugares en story.json")
		return
	
	for id_lugar in datos_story["lugares"].keys():
		var lugar = datos_story["lugares"][id_lugar]
		
		lista_lugares.add_item(lugar["nombre"])
		lista_lugares.set_item_metadata(lista_lugares.item_count - 1, id_lugar)
		
func _on_sos_list_item_selected(index):
	acusado_sospechoso = lista_sospechosos.get_item_metadata(index)
	actualizar_preview_acusacion()
func _on_arma_list_item_selected(index):
	acusado_arma = lista_armas.get_item_metadata(index)
	actualizar_preview_acusacion()
func _on_lug_list_item_selected(index):
	acusado_lugar = lista_lugares.get_item_metadata(index)
	actualizar_preview_acusacion()
func actualizar_preview_acusacion():
	if acusado_sospechoso != "" and datos_suspects.has(acusado_sospechoso):
		var sospechoso = datos_suspects[acusado_sospechoso]
		
		label_acusar_sospechoso.text = "Acuso a: " + sospechoso["nombre"]
		
		if sospechoso.has("imagen"):
			imagen_acusado.texture = load(sospechoso["imagen"])
	else:
		label_acusar_sospechoso.text = "Acuso a:"
		imagen_acusado.texture = null
	
	if acusado_arma != "" and datos_clues.has("pistas_armas") and datos_clues["pistas_armas"].has(acusado_arma):
		var arma = datos_clues["pistas_armas"][acusado_arma]
		label_acusar_arma.text = "Con: " + arma["nombre"]
	else:
		label_acusar_arma.text = "Con:"
	
	if acusado_lugar != "" and datos_story.has("lugares") and datos_story["lugares"].has(acusado_lugar):
		var lugar = datos_story["lugares"][acusado_lugar]
		label_acusar_lugar.text = "En: " + lugar["nombre"]
	else:
		label_acusar_lugar.text = "En:"


func _on_next_pressed() -> void:
	if acusado_sospechoso == "" or acusado_arma == "" or acusado_lugar == "":
		print("Debes seleccionar sospechoso, arma y lugar antes de acusar.")
		return
	
	var culpable_correcto = acusado_sospechoso == Global.caso_actual["culpable"]
	var arma_correcta = acusado_arma == Global.caso_actual["arma_real"]
	var lugar_correcto = acusado_lugar == Global.caso_actual["escena_crimen"]
	
	if culpable_correcto and arma_correcta and lugar_correcto:
		Global.final_actual = Global.caso_actual["culpable"]
	else:
		Global.final_actual = "derrota"
	
	Global.sospechoso_acusado = acusado_sospechoso
	Global.arma_acusada = acusado_arma
	Global.lugar_acusado = acusado_lugar
	
	get_tree().change_scene_to_file("res://scenes/final.tscn")
