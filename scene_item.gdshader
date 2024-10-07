shader_type canvas_item;

uniform sampler2D mask;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 vmask = texture(mask, UV);
    color.a *= vmask.a;
    COLOR = color;
}
