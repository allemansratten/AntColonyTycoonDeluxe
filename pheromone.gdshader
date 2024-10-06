shader_type canvas_item;

uniform sampler2D grid_texture;
uniform vec2 grid_size;
uniform vec4 overlay_color : source_color;
uniform vec2 screen_size;
uniform vec4 overlay_color_1;
uniform vec4 overlay_color_2;
uniform vec4 overlay_color_3;
uniform vec4 overlay_color_4;

const int NUM_LEVELS = 5;

float alpha_to_level(float alpha) {
    return floor(alpha * float(NUM_LEVELS - 1) + 0.5);
}

float discretize_alpha(float alpha) {
    float step = 1.0 / float(NUM_LEVELS - 1);
    return floor(alpha * float(NUM_LEVELS - 1) + 0.5) * step;
}

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

    // kinda fixes a +/-1 error, don't ask me why this works
     scaled_uv += vec2(1) / grid_size;

    // Check if we're outside the grid bounds
    if (scaled_uv.x < 0.0 || scaled_uv.x > 1.0 || scaled_uv.y < 0.0 || scaled_uv.y > 1.0) {
        COLOR = vec4(0.0);  // Transparent outside grid bounds
    } else {
        float grid_value = texture(grid_texture, scaled_uv).r;
        int level = int(alpha_to_level(grid_value));
        switch (level) {
            case 0:
                COLOR = vec4(overlay_color.rgb, 0);
                break;
            case 1:
                COLOR = overlay_color_1;
                break;
            case 2:
                COLOR = overlay_color_2;
                break;
            case 3:
                COLOR = overlay_color_3;
                break;
            case 4:
                COLOR = overlay_color_4;
                break;
            default:
                break;
        }
    }
}