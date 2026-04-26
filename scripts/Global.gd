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

func generar_misterio_aleatorio():
	var file = FileAccess.open("res://data/cases.json", FileAccess.READ)
	if file:
		var todos_los_casos = JSON.parse_string(file.get_as_text())
		# Escogemos un caso al azar de la lista (0 al 4)
		caso_actual = todos_los_casos[randi() % todos_los_casos.size()]
		
		print("--- MISTERIO GENERADO ---")
		print("ID Caso: ", caso_actual["id"])
		print("Culpable: ", caso_actual["culpable"])
		print("Arma Real: ", caso_actual["arma_real"])
		
# Función para reiniciar valores si el jugador vuelve a empezar el juego
func reiniciar_progreso():
	prologo_activo = true
	indice_prologo_actual = 0
	sospechoso_interrumpio = false
