shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture;

// =====================
// PIXELATION
// =====================

uniform float pixel_resolution : hint_range(64.0, 512.0) = 240.0;
uniform int color_steps : hint_range(2, 64) = 16;

uniform float noise_strength : hint_range(0.0, 1.0) = 0.1;

uniform bool enable_dither = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.3;

uniform bool enable_glow = true;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.4;
uniform float glow_spread : hint_range(0.001, 0.01) = 0.005;

uniform bool enable_vintage = true;
uniform float vintage_strength : hint_range(0.0, 1.0) = 0.8;


// =====================
// BINOCULARS
// =====================

uniform bool binocular_enabled = false;

uniform float fisheye_strength : hint_range(-2.5, 2.5) = 1.0;

uniform sampler2D binocular_overlay;


// =====================
// UTILS
// =====================

float random(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float bayer_dither(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;

	float bayer[16] = float[](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);

	return bayer[index] / 16.0;
}

vec3 get_glow(vec2 uv) {
	vec3 col = vec3(0.0);
	float total = 0.0;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * glow_spread;
			col += texture(screen_texture, uv + offset).rgb;
			total += 1.0;
		}
	}

	return col / total;
}

vec3 apply_black_vintage_edges(vec3 color, vec2 uv) {
	float dist = distance(uv, vec2(0.5));

	float edge_mask = smoothstep(0.4, 0.8, dist);

	color = mix(color, vec3(0.0), edge_mask * vintage_strength);

	return color;
}


// =====================
// FISHEYE
// =====================

vec2 fisheye_uv(vec2 uv_input) {
	vec2 iResolution = vec2(textureSize(screen_texture, 0));

	vec2 p = uv_input;

	float prop = iResolution.x / iResolution.y;

	vec2 m = vec2(0.5, 0.5 / prop);

	vec2 adjusted_p = vec2(p.x, p.y / prop);

	vec2 d = adjusted_p - m;

	float r = length(d);

	float power = fisheye_strength;

	float bind;

	if (power > 0.0) {
		bind = length(m);
	} else {
		bind = (prop < 1.0) ? m.x : m.y;
	}

	vec2 uv;

	if (power > 0.0) {
		uv = m + normalize(d) * tan(r * power) * bind / tan(bind * power);
	}
	else if (power < 0.0) {
		uv = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
	}
	else {
		uv = adjusted_p;
	}

	uv.y *= prop;

	return uv;
}


// =====================
// MAIN
// =====================

void fragment() {

	vec2 final_uv = UV;

	// binocular fisheye
	if (binocular_enabled) {
		final_uv = fisheye_uv(UV);
	}

	// pixelation
	vec2 pixel_uv = floor(final_uv * pixel_resolution) / pixel_resolution;

	vec3 color = texture(screen_texture, pixel_uv).rgb;

	// binocular overlay BEFORE post-processing
	if (binocular_enabled) {
		vec4 overlay = texture(binocular_overlay, pixel_uv);

		color = mix(color, overlay.rgb, overlay.a);
	}

	// glow
	if (enable_glow) {
		vec3 blurred = get_glow(final_uv);
		color += blurred * glow_strength;
	}

	// color reduction
	float steps = float(color_steps);
	color = floor(color * steps + 0.5) / steps;

	// noise
	float noise = (random(final_uv + TIME) - 0.5) * noise_strength;
	color += noise;

	// dithering
	if (enable_dither) {
		float threshold = bayer_dither(FRAGCOORD.xy);
		color += (dither_strength * (threshold - 0.5));
	}

	// vintage vignette
	if (enable_vintage) {
		color = apply_black_vintage_edges(color, UV);
	}

	COLOR.rgb = clamp(color, 0.0, 1.0);
	COLOR.a = 1.0;
}