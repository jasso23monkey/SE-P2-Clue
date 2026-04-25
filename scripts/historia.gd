extends Node

var datos_fase = []
var indice_actual = 0
@onready var label = %RichTextLabel

# Ruta a la escena de diálogo
const ESCENA_DIALOGO = "res://scenes/dialogo.tscn" 

func _ready():
	cargar_json_dinamico()
	# Sincronizamos el índice con lo que diga el Global
	indice_actual = Global.indice_historia
	mostrar_texto()

func cargar_json_dinamico():
	var file = FileAccess.open("res://data/story.json", FileAccess.READ)
	if file:
		var json_data = JSON.parse_string(file.get_as_text())
		
		# Accedemos a la fase actual (prologo_1 o prologo_2) definida en Global
		# Usamos ["partes"] porque tu nuevo JSON separa el título del contenido
		if json_data.has(Global.fase_prologo):
			datos_fase = json_data[Global.fase_prologo]["partes"]
		else:
			print("ERROR: No se encontró la fase ", Global.fase_prologo, " en el JSON")

func _input(event):
	# Captura el click para avanzar
	if event.is_action_pressed("click_izquierdo"): 
		avanzar()

func avanzar():
	# 1. Lógica de transición de escena (Solo ocurre en prologo_1)
	# Si llegamos al final de la lista de prologo_1, saltamos al diálogo
	if Global.fase_prologo == "prologo_1" and indice_actual >= datos_fase.size() - 1:
		cambiar_a_escena_dialogo()
		return

	# 2. Lógica de avance de texto normal
	if indice_actual < datos_fase.size() - 1:
		indice_actual += 1
		Global.indice_historia = indice_actual # Actualizamos el Global por seguridad
		mostrar_texto()
	else:
		# Aquí llegas cuando termina el prologo_2 o cualquier fase final
		print("Fin de la narrativa de esta fase.")
		# Podrías llamar a una función para cambiar a modo investigación aquí

func mostrar_texto():
	# Verificamos que el índice sea válido para evitar errores de Array
	if indice_actual < datos_fase.size():
		label.text = datos_fase[indice_actual]
		
		# Efecto de Fade In
		label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.5)

func cambiar_a_escena_dialogo():
	print("Transicionando al diálogo de la fase: ", Global.fase_prologo)
	var error = get_tree().change_scene_to_file(ESCENA_DIALOGO)
	
	if error != OK:
		print("Error: No se pudo cargar la escena de diálogo en: ", ESCENA_DIALOGO)

func pausar_para_interaccion():
	$CanvasLayer.hide()
