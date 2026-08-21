shader_type canvas_item;

/**
 * The maximum width a particle trail can have. Affects the performance.
 */
uniform float trail_max_width = 10.0;
/**
 * The length of a trail defined by the time offset of the tail in seconds. 0.4s means the end of the trail is 0.4s behind the the front.
 */
uniform float trail_length = 0.4;

group_uniforms Base_Shape;
/**
 * The rate of change for the shape of the trail. Usually between 0.0 (No change) - 1.0 (A lot of change).
 */
uniform float shape_change_rate = 0.75;
/**
 * The shape baseline, 0.0 = means full shape - 1.0 = means faded out shape.
 */
uniform float shape_base = 0.25;
/**
 * The portion of the trail, that gets special treatment and smoothed to make a rounder shape.
 */
uniform float trail_fade_head: hint_range(0.0, 1.0, 0.001) = 0.1;
/**
 * The trail width is split by this rate. 1.0 means every pixel width is shaped diffently, 0.0 means the trail is shaped as one thick line regardless of width.
 */
uniform float trail_split_rate = 1.0;
/**
 * Defines the border fade curve of the trail. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
 */
uniform float border_fade_falloff = 0.25;
/**
 * Modifies fadeout threshold, can't really describe it, sorry!
 */
uniform float first_fade_rate: hint_range(0.0, 1.0, 0.001) = 0.6;
/**
 * Modifies fadeout value compared to the threshold, can't really describe it, sorry!
 */
uniform float second_fade_rate: hint_range(0.0, 1.0, 0.001) = 0.85;
group_uniforms Noise;
/**
 * Defines the pixel noise curve, changing how frequent the trails are. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
 */
uniform float pixel_noise_falloff = 0.25;
/**
 * Defines the line noise curve, changing how long the trail splits are. 1.0 - linear, 2.0 - quadratic, 0.5 - square root.
 */
uniform float line_noise_falloff = 0.5;
/**
 * How fast should the line noise vary in general, lower values mean longer lines.
 */
uniform float line_noise_variation = 10.0;
group_uniforms Noise.Primary;
/**
 * Set which noise type should be used for the primary (start) of the trail shape.
 */
uniform int primary_noise_type: hint_enum("Line", "Pixel") = 0;
/**
 * Influence of trails lifetime on the fading of the primary (start)  part of the trail.
 */
uniform float primary_time_fade_strength: hint_range(0.0, 1.0, 0.01) = 0.8;
/**
 * Influence of the noise value on the trails shape of the primary (start) part of the trail.
 */
uniform float primary_noise_strength: hint_range(0.0, 1.0, 0.01) = 0.8;
group_uniforms Noise.Secondary;
uniform bool enable_secondary_noise = true;
/**
 * Set which noise type should be used for the secondary (end) part of the trail shape.
 */
uniform int secondary_noise_type: hint_enum("Line", "Pixel") = 0;
/**
 * Influence of trails lifetime on the fading of the secondary (end) part of the trail.
 */
uniform float secondary_time_fade_strength: hint_range(0.0, 1.0, 0.01) = 0.5;
/**
 * Influence of the noise value on the trails shape of the secondary (end) part of the trail.
 */
uniform float secondary_noise_strength: hint_range(0.0, 1.0, 0.01) = 1.0;
group_uniforms Color;
/**
 * Color of the trail.
 */
uniform vec4 trail_color: source_color = vec4(1.0);

varying vec4 custom_data;

#include "random.gdshaderinc"

void vertex() {
	custom_data = INSTANCE_CUSTOM;
}

void fragment() {
	float trail_width = max(0.9, ceil(custom_data.y * trail_max_width));
	float uv_start = (trail_max_width - trail_width) / 2.0;
	if (UV.x * trail_max_width <= uv_start || UV.x * trail_max_width > uv_start + trail_width) discard;
	
	float width_variation = floor((UV.x * trail_max_width - uv_start) * trail_split_rate);
	float border_fade_value = 1.0 - abs(UV.x - 0.5) * 2.0 * (trail_max_width / trail_width);
	float trail_position = COLOR.r;
	float trail_position_noise = COLOR.r;
	bool head = false;
	if (trail_position > 1.0 - trail_fade_head) {
		head = true;
		trail_position = 1.0 - (trail_position - (1.0 - trail_fade_head)) / trail_fade_head;
		vec2 border_position = vec2(1.0 - border_fade_value, 1.0 - trail_position);
		border_fade_value = 1.0 - min(1.0, length(border_position));
	} else {
		trail_position = trail_position / (1.0 - trail_fade_head);
	}
	border_fade_value = float(trail_width > 1.0) * pow(border_fade_value, border_fade_falloff) + float(trail_width <= 1.0);
	
	float pixel_noise = random(floor(SCREEN_UV / (1.0 * SCREEN_PIXEL_SIZE)) + vec2(mod(custom_data.z, 10000.0)));
	pixel_noise = pow(pixel_noise, pixel_noise_falloff);
	float line_noise = noise(line_noise_variation * trail_position + 0.1 * custom_data.x + mod(custom_data.z, 10000.0) + 100.0 * width_variation);
	if (head) line_noise = sqrt(line_noise * border_fade_value * border_fade_value);
	line_noise = pow(line_noise, line_noise_falloff);
	float noise_value = mix(line_noise, pixel_noise, float(primary_noise_type == 1));
	float full_duration = custom_data.w;
	float frames = max(ceil(full_duration * 10.0), 1.0);
	float progress = (full_duration - custom_data.x) / full_duration;
	float inv_progress = clamp(quantizeEqualBins(progress, frames), 0.0, 1.0);
	float inv_progress_first = mix(1.0, inv_progress, first_fade_rate) * shape_change_rate + shape_base;
	float inv_progress_second = mix(1.0, inv_progress, second_fade_rate);
	bool time_not_up = (custom_data.x < full_duration + (1.0 - COLOR.r) * trail_length * 0.9);
	float visual_threshold = pow((1.0 - trail_position), inv_progress_first);
	float primary_check_value = (noise_value * primary_noise_strength + inv_progress_second * primary_time_fade_strength) * border_fade_value;
	if (primary_check_value > visual_threshold && time_not_up) {
		COLOR = trail_color;
	} else {
		noise_value = mix(line_noise, pixel_noise, float(secondary_noise_type == 1));
		float secondary_check_value = (noise_value * secondary_noise_strength + inv_progress_second * secondary_time_fade_strength) * border_fade_value;
		if (secondary_check_value > visual_threshold && time_not_up && enable_secondary_noise) {
			COLOR = trail_color;
		} else {
			COLOR = vec4(0.0);
		}
	}
}
