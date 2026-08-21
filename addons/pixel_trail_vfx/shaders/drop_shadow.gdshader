shader_type canvas_item;

uniform vec2 shadow_offset = vec2(-1.0, -1.0);
uniform vec4 shadow_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D vp_texture: filter_nearest;

void fragment() {
	vec4 vp_color_offset = texture(vp_texture, UV + shadow_offset * TEXTURE_PIXEL_SIZE);
	if (COLOR.a < 0.1) {
		if (vp_color_offset.a > 0.0) {
			COLOR = vec4(shadow_color.rgb, shadow_color.a * vp_color_offset.a);
		} else {
			COLOR = vec4(0.0);
		}
	}
}
