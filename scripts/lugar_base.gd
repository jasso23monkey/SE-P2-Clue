extends Node2D

# Referencias a la UI
@onready var label_conteo = %Label 
@onready var textura_fondo = %Fondo

# Lista de tus nodos de pista (según tu árbol de nodos)
@onready var lista_lupas = [%Pista_1, %Pista_2, %Pista_3, %Pista_4]
@onready var pista_extra = %extra

var pistas_encontradas_esta_sesion : int = 0
var datos_clues : Dictionary = {}
var ids_en_esta_escena : Array = []

func _ready():
	cargar_json_pistas()
	configurar_habitacion()
	conectar_señales_lupas()

func cargar_json_pistas():
	var file = FileAccess.open("res://data/clues.json", FileAccess.READ)
	if file:
		datos_clues = JSON.parse_string(file.get_as_text())
	else:
		print("Error: No se encontró clues.json")

func configurar_habitacion():
	var zona = Global.habitacion_actual
	
	# 1. Cambiar el fondo
	textura_fondo.texture = load("res://assets/sprites/backgrounds/" + zona + ".jpeg")
	
	# 2. Filtrar IDs de pistas normales (Armas y Personales)
	ids_en_esta_escena.clear()
	for cat in ["pistas_armas", "pistas_personales"]:
		for id_p in datos_clues[cat]:
			if datos_clues[cat][id_p].get("ubicacion_original") == zona:
				if not Global.pistas_descubiertas.has(id_p):
					ids_en_esta_escena.append(id_p)
	
	# 3. LÓGICA PARA LA PISTA EXTRA (ACUSATORIA)
	var id_maestra = Global.caso_actual["pista_maestra"]
	
	# Comprobación: ¿Es esta la escena del crimen y la pista no ha sido descubierta?
	if zona == Global.caso_actual["lugar"] and not Global.pistas_descubiertas.has(id_maestra):
		pista_extra.show()
		pista_extra.set_meta("id_pista", id_maestra)
		# Conectar la señal si no está conectada
		if not pista_extra.input_event.is_connected(_on_lupa_input_event):
			pista_extra.input_event.connect(_on_lupa_input_event.bind(pista_extra))
	else:
		pista_extra.hide()
	
	# 4. Mostrar u ocultar las lupas normales
	for i in range(lista_lupas.size()):
		if i < ids_en_esta_escena.size():
			lista_lupas[i].show()
			lista_lupas[i].set_meta("id_pista", ids_en_esta_escena[i])
		else:
			lista_lupas[i].hide()

func conectar_señales_lupas():
	# Conectamos la señal de cada Area2D a una función local
	for lupa in lista_lupas:
		if not lupa.input_event.is_connected(_on_lupa_input_event):
			lupa.input_event.connect(_on_lupa_input_event.bind(lupa))

func _on_lupa_input_event(_viewport, event, _shape_idx, objeto_lupa):
	# Detectamos el clic
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id_p = objeto_lupa.get_meta("id_pista")
		recolectar_pista(id_p, objeto_lupa)

func recolectar_pista(id_p, objeto_lupa):
	# 1. Guardar en Global (Asegúrate de que Global.pistas_descubiertas sea un Array)
	if not Global.pistas_descubiertas.has(id_p):
		Global.pistas_descubiertas.append(id_p)
		pistas_encontradas_esta_sesion += 1
		
		# Actualizamos el conteo (ahora sobre 4 si es el lugar del crimen)
		var max_pistas = 4
		if Global.habitacion_actual == Global.caso_actual["lugar"]:
			max_pistas = 5
		label_conteo.text = "PISTAS: " + str(pistas_encontradas_esta_sesion) + "/" + str(max_pistas)
	
	# 2. Desaparecer la lupa
	objeto_lupa.hide()
	
	# 3. Buscar info (Inyectamos la búsqueda en pistas_condenatorias también)
	var info = buscar_info_pista_completa(id_p)
	print("Encontraste: ", info["nombre"])

func buscar_info_pista_completa(id_p):
	# Extendemos la búsqueda para incluir la categoría de pistas condenatorias
	if datos_clues["pistas_armas"].has(id_p):
		return datos_clues["pistas_armas"][id_p]
	if datos_clues["pistas_personales"].has(id_p):
		return datos_clues["pistas_personales"][id_p]
	if datos_clues.has("pistas_condenatorias") and datos_clues["pistas_condenatorias"].has(id_p):
		return datos_clues["pistas_condenatorias"][id_p]
	return null

func buscar_info_pista(id_p):
	# Busca la info en ambas categorías del JSON
	if datos_clues["pistas_armas"].has(id_p):
		return datos_clues["pistas_armas"][id_p]
	return datos_clues["pistas_personales"][id_p]

func _on_regresar_pressed():
	get_tree().change_scene_to_file("res://scenes/hub.tscn")
