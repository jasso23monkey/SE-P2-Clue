# SE-P2-Clue
*Un misterio de vapor, fe y traición.**

Bienvenido al repositorio oficial de **Clue: Catolic Mexa Steampunk**. Este es un simulador de misterio desarrollado en **Godot Engine** donde deberás resolver el asesinato de **Don Amado** en un México alternativo lleno de tecnología de vapor y estética neogótica.

---

## 📖 Sinopsis
En un México donde la tecnología de vapor se entrelaza con la devoción religiosa, el legendario Don Amado ha sido hallado sin vida. Cinco sospechosos, cinco armas y cinco lugares posibles. El sistema genera un caso único en cada partida. ¿Podrás encontrar la verdad entre los engranajes y el incienso?

## 🎮 Cómo Jugar
El juego es una aventura "point-and-click" donde la investigación es la clave del éxito:

1.  **El HUB:** Desde aquí accedes a los cuatro pilares de tu investigación:
    * **Inspeccionar:** Visita las locaciones y busca pistas visuales (lupas) para recolectar evidencia física.
    * **Interrogar:** Habla con los sospechosos. Si has encontrado pistas previas, podrás desbloquear preguntas ocultas para exponer sus mentiras.
    * **Notas:** Consulta tu base de hechos. Aquí verás la causa de muerte y todas las pistas recolectadas.
    * **Acusar:** Cuando estés listo, selecciona al Culpable, el Arma y el Lugar. 
2.  **Victoria o Derrota:** El sistema comparará tu acusación con el caso generado aleatoriamente. Si fallas, el culpable escapará y obtendrás el "Final Malo".

## 🛠️ Requisitos
* **Godot Engine 4.x** (Versión recomendada: 4.2 o superior).
* Espacio en disco: ~50MB.

## 📥 Instalación y Ejecución

Para abrir y editar el proyecto en tu computadora, sigue estos pasos:

1.  **Clonar el repositorio:**
    Abre una terminal y ejecuta:
    ```bash
    git clone https://github.com/tu-usuario/clue-mexa-steampunk.git
    ```
    *(O descarga el archivo .ZIP desde el botón verde 'Code' y descomprímelo).*

2.  **Importar en Godot:**
    * Abre **Godot Engine**.
    * En el Administrador de Proyectos, haz clic en el botón **"Importar"**.
    * Navega hasta la carpeta donde descargaste el proyecto y selecciona el archivo `project.godot`.
    * Haz clic en **"Importar y Editar"**.

3.  **Ejecutar el juego:**
    * Una vez abierto el editor, presiona **F5** o el botón de "Play" en la esquina superior derecha.

## 📁 Estructura del Proyecto
* `/scenes`: Contiene las escenas de Godot (.tscn) para el HUB, mapas y menús.
* `/scripts`: Archivos .gd con la lógica del motor de inferencia y manejo de JSON.
* `/data`: Archivos JSON que contienen las historias, pistas y diálogos.
* `/assets`: Arte, sonidos y fuentes con estética Steampunk.

---
**Desarrollado por:** [Juan Diego Jasso Ramírez]
*Proyecto para la materia de Sistemas Expertos.*
