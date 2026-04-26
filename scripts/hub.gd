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
@onready var label_lugar = %lugar

var lista_datos = [] # Aquí guardaremos las llaves del JSON (ej: ["despacho", "capilla"])
var indice_actual = 0
var dict_referencia : Dictionary = {} 
var categoria_actual = "" # "lugares" o "sospechosos"

func _ready():
	# Estado inicial: Botones visibles, libro oculto
	contenedor_libro.hide()
	menu_opciones.show()

# --- Funciones para los botones de la barra inferior ---

func _on_mapa_pressed():
	categoria_actual = "lugares"
	notas_der.hide()
	notas_izq.hide()
	preparar_datos()

func _on_interrogar_pressed():
	categoria_actual = "sospechosos"
	notas_der.hide()
	notas_izq.hide()
	preparar_datos()

func _on_notas_pressed():
	contenedor_libro.show()
	# Ocultamos lo de Mapa/Sospechosos
	estandar_der.hide()
	estandar_izq.hide()
	# Mostramos tus nuevos paneles de Notas
	notas_izq.show()
	notas_der.show()
	
	llenar_item_list_pistas()

func _on_acusar_pressed():
	# Aquí podrías poner una confirmación antes de abrir
	contenedor_libro.show()
	notas_der.hide()
	notas_izq.hide()
	estandar_der.hide()
	estandar_izq.hide()

# --- Lógica de apertura y cierre ---
func _on_close_pressed():
	# Al cerrar, hacemos el proceso inverso
	contenedor_libro.hide()
	menu_opciones.show()

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
		estandar_der.show()
		estandar_izq.show()
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
	
	if Global.pistas_descubiertas.size() == 0:
		item_list_notas.add_item("Sin notas...")
		return
		
	for id_pista in Global.pistas_descubiertas:
		var info = buscar_info_pista_completa(id_pista)
		var idx = item_list_notas.add_item(info["nombre"])
		# Guardamos el ID en la metadata para saber cuál es al hacer clic
		item_list_notas.set_item_metadata(idx, id_pista)

# Esta función la conectas a la señal "item_selected" de tu ItemList (%Pistas)
func _on_pistas_item_selected(index: int) -> void:
	var id_pista = item_list_notas.get_item_metadata(index)
	var info = buscar_info_pista_completa(id_pista)
	
	# Usamos tus variables específicas del árbol de nodos
	label_detalle_titulo.text = info["nombre"]
	label_sospechoso.text =  info["propietario"]
	label_lugar.text =  info["ubicacion_original"]
	label_detalle_info.text = info["descripcion"]

# Función para buscar en el JSON
func buscar_info_pista_completa(id_pista):
	var file = FileAccess.open("res://data/clues.json", FileAccess.READ)
	var datos = JSON.parse_string(file.get_as_text())
	
	# Buscamos en ambas categorías del JSON
	if datos["pistas_armas"].has(id_pista):
		return datos["pistas_armas"][id_pista]
	elif datos["pistas_personales"].has(id_pista):
		return datos["pistas_personales"][id_pista]
	
	return {"nombre": "Desconocido", "descripcion": "", "sospechoso": "N/A", "ubicacion_original": "N/A"}


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
	# 1. Verificamos que haya algo seleccionado (puedes usar la lista_datos o el nombre del lugar)
	if lista_datos.size() > 0:
		var lugar_seleccionado = lista_datos[indice_actual] # Ej: "despacho"
		
		# 2. Guardamos en el Global para que la escena 'LugarBase' sepa qué cargar
		Global.habitacion_actual = lugar_seleccionado
		
		# 3. Cambiamos a la escena de la habitación
		# Asegúrate de que la ruta sea la correcta de tu archivo LugarBase.tscn
		get_tree().change_scene_to_file("res://scenes/lugar_base.tscn")
