shader_type particles;

uniform float gravity = 500.0;
uniform float trail_length = 0.4;

void start() {
	CUSTOM.x = 0.0;
	CUSTOM.z = float(INDEX);
	if (RESTART_POSITION) {
		COLOR = vec4(1.0, 1.0, 1.0, 1.0);
    }
}

void process() {
	VELOCITY = VELOCITY + vec3(0.0, gravity * DELTA, 0.0);
	TRANSFORM[3].y -= gravity * DELTA * DELTA * 0.5;
	CUSTOM.x += DELTA;
	if (CUSTOM.x >= CUSTOM.w + trail_length + 0.1) ACTIVE = false;
}