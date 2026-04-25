extends Node2D

@onready var texture_rect = %TextureRect
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#%DialogoUi.cambio_de_personaje.connect(_on_dialogo_ui_cambio_de_personaje)
	pass

func _on_dialogo_ui_cambio_de_personaje(nombre_archivo):
	var ruta_final = "res://assets/sprites/characters/" + nombre_archivo + ".png"
	
	# Si te daba error de 'Nil', es vital esta comprobación:
	if texture_rect:
		if FileAccess.file_exists(ruta_final):
			texture_rect.texture = load(ruta_final)
		else:
			print("ERROR: No encontré la imagen en: ", ruta_final)
	else:
		print("ERROR: El nodo %TextureRect sigue siendo nulo")
