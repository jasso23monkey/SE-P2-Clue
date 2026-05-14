extends Node2D

@onready var titulo_final = %Final
@onready var texto_final = %explica
@onready var imagen_final = %TextureRect

var datos_story := {}
var datos_suspects := {}
var datos_clues := {}
var paginas_final: Array[String] = []
var indice_pagina_final := 0

func _ready():
	cargar_jsons()
	mostrar_final()


func cargar_jsons():
	datos_story = leer_json("res://data/story.json")
	datos_suspects = leer_json("res://data/suspects.json")
	datos_clues = leer_json("res://data/clues.json")


func leer_json(ruta: String) -> Dictionary:
	var file = FileAccess.open(ruta, FileAccess.READ)
	
	if not file:
		print("No se pudo abrir el archivo: ", ruta)
		return {}
	
	var datos = JSON.parse_string(file.get_as_text())
	
	if typeof(datos) != TYPE_DICTIONARY:
		print("El JSON no es válido o no es un diccionario: ", ruta)
		return {}
	
	return datos


func mostrar_final():
	if not datos_story.has("finales"):
		print("No existe la sección 'finales' en story.json")
		return
	
	var id_final = Global.final_actual
	
	# Seguridad por si por algún motivo llega vacío
	if id_final == "":
		id_final = "derrota"
	
	if not datos_story["finales"].has(id_final):
		print("No existe el final: ", id_final)
		id_final = "derrota"
	
	var datos_final = datos_story["finales"][id_final]
	
	# Título del final
	titulo_final.text = str(datos_final.get("titulo", "Final desconocido"))
	
	# Texto base del final que viene de story.json
	var texto_base: String = str(datos_final.get("texto", ""))
	
	# Limpiamos páginas anteriores del final
	paginas_final.clear()
	indice_pagina_final = 0
	
	# Página 1: narrativa principal del final
	paginas_final.append(texto_base)
	
	# Página 2: solo si el jugador se equivocó
	if id_final == "derrota":
		paginas_final.append(obtener_explicacion_derrota())
	
	# Mostramos la primera página
	mostrar_pagina_final()
	
	# Si acertó, mostramos la imagen del culpable.
	# Si falló, mostramos la imagen del verdadero culpable.
	mostrar_imagen_final()
func mostrar_pagina_final():
	if paginas_final.is_empty():
		texto_final.text = ""
		return
	
	texto_final.text = paginas_final[indice_pagina_final]
	
	# Reinicia el efecto de escritura
	texto_final.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(texto_final, "visible_ratio", 1.0, 0.8)

func _input(event):
	if event.is_action_pressed("click_izquierdo"):
		avanzar_final()

func avanzar_final():
	# Si el texto todavía se está escribiendo, el primer click lo completa
	if texto_final.visible_ratio < 1.0:
		texto_final.visible_ratio = 1.0
		return
	
	# Si todavía hay otra página, avanzamos a la siguiente
	# Ejemplo:
	# Derrota página 1 -> explicación real página 2
	if indice_pagina_final < paginas_final.size() - 1:
		indice_pagina_final += 1
		mostrar_pagina_final()
		return
	
	# Si ya no hay más páginas, regresamos al inicio
	get_tree().change_scene_to_file("res://scenes/inicio.tscn")

func obtener_explicacion_derrota() -> String:
	var culpable_real = Global.caso_actual.get("culpable", "")
	
	var arma_real = Global.caso_actual.get("arma_real", "")
	if arma_real == "":
		arma_real = Global.caso_actual.get("arma", "")
	
	var lugar_real = Global.caso_actual.get("escena_crimen", "")
	if lugar_real == "":
		lugar_real = Global.caso_actual.get("lugar", "")
	if lugar_real == "":
		lugar_real = Global.caso_actual.get("habitacion", "")
	
	var nombre_culpable = obtener_nombre_sospechoso(culpable_real)
	var nombre_arma = obtener_nombre_arma(arma_real)
	var nombre_lugar = obtener_nombre_lugar(lugar_real)
	
	var texto := ""
	texto += "El verdadero culpable era: " + nombre_culpable + ".\n"
	texto += "El arma homicida era: " + nombre_arma + ".\n"
	texto += "El crimen ocurrió en: " + nombre_lugar + "."
	
	return texto


func obtener_nombre_sospechoso(id_sospechoso: String) -> String:
	if datos_suspects.has(id_sospechoso):
		return datos_suspects[id_sospechoso].get("nombre", id_sospechoso.capitalize())
	
	return id_sospechoso.capitalize()


func obtener_nombre_arma(id_arma: String) -> String:
	if id_arma == "":
		return "desconocida"
	
	if datos_clues.has("pistas_armas"):
		if datos_clues["pistas_armas"].has(id_arma):
			return str(datos_clues["pistas_armas"][id_arma].get("nombre", id_arma))
	
	return id_arma


func obtener_nombre_lugar(id_lugar: String) -> String:
	if id_lugar == "":
		return "desconocido"
	
	if datos_story.has("lugares"):
		if datos_story["lugares"].has(id_lugar):
			return str(datos_story["lugares"][id_lugar].get("nombre", id_lugar.capitalize()))
	
	return id_lugar.capitalize()


func mostrar_imagen_final():
	var culpable_real = Global.caso_actual.get("culpable", "")
	
	if datos_suspects.has(culpable_real):
		var sospechoso = datos_suspects[culpable_real]
		
		if sospechoso.has("imagen"):
			imagen_final.texture = load(sospechoso["imagen"])
