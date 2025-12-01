shader_type canvas_item;

// Parâmetros configuráveis
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform float shadow_width : hint_range(0.1, 2.0) = 1.0;
uniform float shadow_height : hint_range(0.1, 2.0) = 0.5;
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.3;
uniform vec2 shadow_offset = vec2(0.0, 0.0);

void fragment() {
    // Centraliza as coordenadas UV
    vec2 centered_uv = UV - 0.5 + shadow_offset;
    
    // Aplica a proporção da elipse
    centered_uv.x /= shadow_width;
    centered_uv.y /= shadow_height;
    
    // Calcula a distância do centro
    float dist = length(centered_uv);
    
    // Cria um gradiente suave para a sombra
    float shadow = 1.0 - smoothstep(0.5 - shadow_softness, 0.5, dist);
    
    // Define a cor final com alpha baseado na intensidade da sombra
    COLOR = vec4(shadow_color.rgb, shadow_color.a * shadow);
}
