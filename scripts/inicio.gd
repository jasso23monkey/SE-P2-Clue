extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

const ESCENA_HISTORIA = "res://scenes/historia.tscn"
	

func _on_button_pressed() -> void:
	# Esta es la función mágica para cambiar de escena
	var error = get_tree().change_scene_to_file(ESCENA_HISTORIA)
	
	# Como buen ingeniero, verificamos si hubo errores al cargar
	if error != OK:
		print("Error: No se pudo encontrar la escena de historia en: ", ESCENA_HISTORIA)
