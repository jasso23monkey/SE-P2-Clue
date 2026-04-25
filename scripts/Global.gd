extends Node

# Controla si la fuente tiene la luz encendida (azul) o apagada
var prologo_activo : bool = true

# Guarda el progreso del diálogo para saber en qué parte del JSON retomar
# Útil si sales de una conversación y entras a otra
var indice_prologo_actual : int = 0


var sospechoso_mencionado : String = ""
# Variable para manejar eventos aleatorios (el sospechoso)
var sospechoso_interrumpio : bool = false

# Función para reiniciar valores si el jugador vuelve a empezar el juego
func reiniciar_progreso():
	prologo_activo = true
	indice_prologo_actual = 0
	sospechoso_interrumpio = false
