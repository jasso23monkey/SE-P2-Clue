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
	
	# 2. Cargar clues_4.json para sacar las armas
	var file_clues = FileAccess.open("res://data/clues.json", FileAccess.READ)
	var datos_clues = JSON.parse_string(file_clues.get_as_text())
	
	# --- GENERACIÓN INDEPENDIENTE ---
	# Elegimos culpable de la lista de finales (excepto 'derrota')
	var lista_finales = datos_story["finales"].keys()
	lista_finales.erase("derrota")
	var id_culpable = lista_finales[randi() % lista_finales.size()]
	
	# Elegimos arma real de pistas_armas
	var lista_armas = datos_clues["pistas_armas"].keys()
	var id_arma = lista_armas[randi() % lista_armas.size()]
	
	# --- EXTRACCIÓN DEL EFECTO ---
	# Accedemos al diccionario del arma elegida para obtener su efecto específico
	efecto_arma_real = datos_clues["pistas_armas"][id_arma]["efecto"]
	
	# Elegimos lugar del crimen[cite: 9]
	var lista_lugares = datos_story["lugares"].keys()
	var id_lugar = lista_lugares[randi() % lista_lugares.size()]
	
	# Guardamos la "Verdad" de esta partida incluyendo el efecto
	caso_actual = {
		"culpable": id_culpable,
		"arma": id_arma,
		"lugar": id_lugar,
		"efecto": efecto_arma_real # Guardado para referencia rápida
	}
	
	# Debug para verificar en consola
	print("--- MISTERIO GENERADO ---")
	print("Culpable: ", caso_actual["culpable"])
	print("Arma: ", caso_actual["arma"])
	print("Efecto: ", efecto_arma_real) # Ejemplo: "asfixia" o "corte profundo"[cite: 11]
	print("Lugar: ", caso_actual["lugar"])

		
# Función para reiniciar valores si el jugador vuelve a empezar el juego
func reiniciar_progreso():
	prologo_activo = true
	indice_prologo_actual = 0
	sospechoso_interrumpio = false
	efecto_arma_real = ""
