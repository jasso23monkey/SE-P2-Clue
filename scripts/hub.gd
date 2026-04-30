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
var causa = ""

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
	# 1. Verificamos que haya algo seleccionado (puedes usar la lista_datos o el nombre del lugar)
	if lista_datos.size() > 0:
		var lugar_seleccionado = lista_datos[indice_actual] # Ej: "despacho"
		
		# 2. Guardamos en el Global para que la escena 'LugarBase' sepa qué cargar
		Global.habitacion_actual = lugar_seleccionado
		
		# 3. Cambiamos a la escena de la habitación
		# Asegúrate de que la ruta sea la correcta de tu archivo LugarBase.tscn
		get_tree().change_scene_to_file("res://scenes/lugar_base.tscn")
