extends Node

var datos_prologo = []
var indice_actual = 0
@onready var label = %RichTextLabel

# Define la ruta a tu escena de diálogo para no escribirla varias veces
const ESCENA_DIALOGO = "res://scenes/dialogo.tscn" 

func _ready():
	cargar_json()
	mostrar_texto()

func cargar_json():
	var file = FileAccess.open("res://data/story.json", FileAccess.READ)
	if file:
		var json_data = JSON.parse_string(file.get_as_text())
		datos_prologo = json_data["prologo"]["partes"]

func _input(event):
	if event.is_action_pressed("click_izquierdo"): 
		avanzar()

func avanzar():
	# Si ya estamos mostrando el último texto (índice 4) 
	# y el usuario da clic, cambiamos de escena.
	if indice_actual == 4: 
		cambiar_a_escena_dialogo()
		return

	indice_actual += 1
	
	if indice_actual < datos_prologo.size():
		mostrar_texto()
	else:
		# Por si el JSON tiene más de 5 partes y quieres un respaldo
		cambiar_a_escena_dialogo()

func mostrar_texto():
	label.text = datos_prologo[indice_actual]
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)

func cambiar_a_escena_dialogo():
	print("Transicionando a la escena de diálogo con Don Amado...")
	var error = get_tree().change_scene_to_file(ESCENA_DIALOGO)
	
	if error != OK:
		print("Error: No se pudo cargar la escena de diálogo en: ", ESCENA_DIALOGO)

# Mantenemos esta por si decides usarla luego para habilitar movimiento
func pausar_para_interaccion():
	$CanvasLayer.hide()
