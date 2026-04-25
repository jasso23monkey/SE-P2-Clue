shader_type canvas_item;

// Controla qué tan difuminado está el borde (0.0 a 0.5)
uniform float feather : hint_range(0.0, 0.5) = 0.05;

// Controla la transparencia general de toda la imagen (0.0 a 1.0)
uniform float opacity : hint_range(0.0, 1.0) = 0.75;

void fragment() {
    // Obtenemos el color original de la textura
    vec4 color = texture(TEXTURE, UV);
    
    // Calculamos la distancia de los bordes (UV va de 0.0 a 1.0)
    vec2 border_dist = min(UV, 1.0 - UV);
    
    // Creamos la máscara para los bordes
    float mask = smoothstep(0.0, feather, border_dist.x) * smoothstep(0.0, feather, border_dist.y);
    
    // Multiplicamos el alpha original por la máscara de bordes Y por la opacidad general
    color.a *= mask * opacity;
    
    COLOR = color;
}