extends Control

# Definimos la señal (como un canal de comunicación)
signal cambio_de_personaje(nombre_archivo)
# Referencias a los nodos hijos
@onready var label_nombre = %Label
@onready var label_texto = %RichTextLabel

# Lista de sospechosos para el momento aleatorio
var sospechosos = ["casilda", "calixto", "eulalio", "basilio", "juan"]
var datos_dialogo = {}
var viendo_presentacion = false # Para saber si ya pasamos a la parte de los sospechosos

func _ready():
	cargar_json()
	await get_tree().process_frame
	mostrar_paso_prologo()

func cargar_json():
	var file = FileAccess.open("res://data/dialogues.json", FileAccess.READ)
	if file:
		datos_dialogo = JSON.parse_string(file.get_as_text())

func _input(event):
	if event.is_action_pressed("click_izquierdo"): # O tu acción de avanzar
		avanzar_logica()

func avanzar_logica():
	if not viendo_presentacion:
		# Lógica de Don Amado
		if Global.indice_prologo_actual < datos_dialogo["prologo_amado"].size() - 1:
			Global.indice_prologo_actual += 1
			mostrar_paso_prologo()
		else:
			# Terminó Don Amado, vamos al sospechoso aleatorio
			iniciar_presentacion_sospechoso()
	else:
		# SI ESTAMOS AQUÍ, es porque el sospechoso ya habló.
		# Al dar click ahora, DEBEMOS REGRESAR.
		regresar_a_historia_fase_2()

func regresar_a_historia_fase_2():
	# 1. IMPORTANTE: Cambiamos el estado global
	Global.fase_prologo = "prologo_2"
	Global.indice_historia = 0 # Para que la historia empiece desde el texto 0 de la fase 2
	
	# 2. Limpieza de flags
	viendo_presentacion = false
	Global.prologo_activo = false
	
	print("Handshake completo: Cambiando a Prologo 2")
	get_tree().change_scene_to_file("res://scenes/historia.tscn")

func mostrar_paso_prologo():
	var paso = datos_dialogo["prologo_amado"][Global.indice_prologo_actual]
	var texto_final = paso["texto"]
	
	# 1. Lógica del sospechoso (solo para el último diálogo)
	if "{sospechoso}" in texto_final:
		var elegido = sospechosos[randi() % sospechosos.size()]
		Global.sospechoso_mencionado = elegido
		texto_final = texto_final.replace("{sospechoso}", elegido.capitalize())
	
	actualizar_interfaz(paso["nombre"], texto_final)

	# 2. CAMBIO DE IMAGEN DE DON AMADO
	# Como tus archivos se llaman amado_1 y amado_2,
	# forzamos el nombre "amado" manualmente para esta parte:
	var nombre_archivo = "amado_" + str(paso["expresion"])
	
	# Emitimos la señal para que la escena de Diálogo lo cargue
	emit_signal("cambio_de_personaje", nombre_archivo)

func iniciar_presentacion_sospechoso():
	viendo_presentacion = true
	var clave = Global.sospechoso_mencionado # Ej: "juan"
	
	# CAMBIO AQUÍ: Ahora buscamos en 'bienvenida_prologo'
	var datos_personaje = datos_dialogo["bienvenida_prologo"][clave]
	
	actualizar_interfaz(datos_personaje["nombre"], datos_personaje["texto"])
	
	# Construimos el nombre del archivo: "juan_1"
	var nombre_archivo = clave.to_lower() + "_" + str(datos_personaje["expresion"])
	
	# Avisamos a la escena principal que cambie la imagen
	emit_signal("cambio_de_personaje", nombre_archivo)

func actualizar_interfaz(nombre, texto):
	label_nombre.text = nombre
	label_texto.text = texto
	# Reiniciar el efecto de escritura (opcional)
	label_texto.visible_ratio = 0
	var tween = create_tween()
	tween.tween_property(label_texto, "visible_ratio", 1.0, 1.0)
