shader_type canvas_item;

uniform sampler2D grid_texture;
uniform vec2 grid_size;
uniform vec4 overlay_color : source_color;
uniform vec2 screen_size;

void fragment() {
    // Calculate the aspect ratio of the grid and the screen
    float grid_aspect = grid_size.x / grid_size.y;
    float screen_aspect = screen_size.x / screen_size.y;
    
    vec2 scaled_uv;
    if (screen_aspect > grid_aspect) {
        // Screen is wider, fit to height
        float scale = screen_size.y / grid_size.y;
        float adjusted_width = grid_size.x * scale;
        scaled_uv = vec2(
            (UV.x * screen_size.x - (screen_size.x - adjusted_width) * 0.5) / adjusted_width,
            UV.y
        );
    } else {
        // Screen is taller, fit to width
        float scale = screen_size.x / grid_size.x;
        float adjusted_height = grid_size.y * scale;
        scaled_uv = vec2(
            UV.x,
            (UV.y * screen_size.y - (screen_size.y - adjusted_height) * 0.5) / adjusted_height
        );
    }
    
    // Check if we're outside the grid bounds
    if (scaled_uv.x < 0.0 || scaled_uv.x > 1.0 || scaled_uv.y < 0.0 || scaled_uv.y > 1.0) {
        COLOR = vec4(0.0);  // Transparent outside grid bounds
    } else {
        float grid_value = texture(grid_texture, scaled_uv).r;
        COLOR = vec4(overlay_color.rgb, overlay_color.a * grid_value);
    }
}