extends Node2D

@onready var texture_rect = %TextureRect
@onready var sprite_patio_luz = %PatioLuz # El de prólogo
@onready var sprite_patio = %Patio         # El de interrogatorio

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Conectamos la señal que viene del UI
	# Conexión de señal que ya tenías
	#%DialogoUi.cambio_de_personaje.connect(_on_dialogo_ui_cambio_de_personaje)
	
	# --- LÓGICA DE FONDOS POR VISIBILIDAD ---
	if Global.fase_prologo == "prologo_2":
		# Estamos en interrogatorio
		sprite_patio_luz.hide()
		sprite_patio.show()
	else:
		# Estamos en prólogo o intermedio
		sprite_patio_luz.show()
		sprite_patio.hide()

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
