extends Node

# Controla si la fuente tiene la luz encendida (azul) o apagada
var prologo_activo : bool = true
# Estado inicial
var fase_prologo : String = "prologo_1"
var indice_historia : int = 0
#habitacion
var habitacion_actual : String = "caballerizas"
var pistas_descubiertas : Array = []

# Guarda el progreso del diálogo para saber en qué parte del JSON retomar
# Útil si sales de una conversación y entras a otra
var indice_prologo_actual : int = 0


var sospechoso_mencionado : String = ""
# Variable para manejar eventos aleatorios (el sospechoso)
var sospechoso_interrumpio : bool = false
var caso_actual : Dictionary = {}
var efecto_arma_real : String = "" # Variable para guardar el efecto

func generar_misterio_aleatorio():
	# 1. Cargar story.json para sacar culpables y lugares
	var file_story = FileAccess.open("res://data/story.json", FileAccess.READ)
	var datos_story = JSON.parse_string(file_story.get_as_text())
	
	# 2. Cargar clues_4.json para sacar las armas y pistas
	var file_clues = FileAccess.open("res://data/clues.json", FileAccess.READ)
	var datos_clues = JSON.parse_string(file_clues.get_as_text())
	
	# --- GENERACIÓN INDEPENDIENTE ---
	var lista_finales = datos_story["finales"].keys()
	lista_finales.erase("derrota")
	var id_culpable = lista_finales[randi() % lista_finales.size()]
	
	var lista_armas = datos_clues["pistas_armas"].keys()
	var id_arma = lista_armas[randi() % lista_armas.size()]
	
	efecto_arma_real = datos_clues["pistas_armas"][id_arma]["efecto"]
	
	var lista_lugares = datos_story["lugares"].keys()
	var id_lugar = lista_lugares[randi() % lista_lugares.size()]
	
	# --- LÓGICA DE LA PISTA ACUSATORIA EXTRA ---
	# --- LÓGICA DE LA PISTA ACUSATORIA EXTRA ---
	var id_pista_maestra = ""
	
	# Accedemos a la sección de pistas_condenatorias usando el ID del culpable
	
	if datos_clues.has("pistas_condenatorias") and datos_clues["pistas_condenatorias"].has(id_culpable):
		# 1. Usamos el id_culpable directamente como ID de la pista (ej: "juan")
		id_pista_maestra = id_culpable 
		
		# 2. Sacamos la info
		var info_pista_extra = datos_clues["pistas_condenatorias"][id_pista_maestra].duplicate()
		
		# 3. Le ponemos la ubicación del crimen
		info_pista_extra["ubicacion_original"] = id_lugar
		
		# 4. LA CLAVE: La guardamos en el diccionario de pistas con el nombre del sospechoso
		# Así, cuando busques "juan" en el diccionario de pistas, lo encontrará.
		datos_clues["pistas_personales"][id_pista_maestra] = info_pista_extra
	
	# Guardamos todo en el diccionario del caso
	caso_actual = {
		"culpable": id_culpable,
		"arma": id_arma,
		"lugar": id_lugar,
		"efecto": efecto_arma_real,
		"pista_maestra": id_pista_maestra 
	}
	
	# Debug para verificar en consola
	print("--- MISTERIO GENERADO ---")
	print("Culpable: ", caso_actual["culpable"])
	print("Arma: ", caso_actual["arma"])
	print("Efecto: ", efecto_arma_real) 
	print("Lugar: ", caso_actual["lugar"])
	print("Pista Maestra Generada: ", caso_actual["pista_maestra"])

		
# Función para reiniciar valores si el jugador vuelve a empezar el juego
func reiniciar_progreso():
	prologo_activo = true
	indice_prologo_actual = 0
	sospechoso_interrumpio = false
	efecto_arma_real = ""
