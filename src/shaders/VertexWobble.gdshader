shader_type spatial;
// Vertex snapping in world coordinates

// No specular for retro look
// Per-vertex lighting like PSX
// Renders both face sides
render_mode world_vertex_coords, specular_disabled, vertex_lighting, cull_disabled;

// Screen resolution for vertex wobble
global uniform vec2 resolution;
// Main color texture applied to surfaces
uniform sampler2D color_texture: source_color, filter_nearest;
// Strength of vertex jitter on screen
global uniform float vertex_wobble;
// Depth-based texture coordinate distortion
global uniform float affine_mapping;

// Use a solid color instead of textures
uniform bool use_color = false;
// Solid color when use_color is active
uniform vec4 base_color: source_color = vec4(1.0);

// Enable world-space triplanar mapping
uniform bool use_triplanar = false;
// World offset for triplanar coordinates
uniform vec3 triplanar_offset = vec3(0.0);
// World scale for triplanar tiling
uniform vec3 triplanar_scale = vec3(1.0);

// Material ignores lighting, fully emissive
uniform bool unshaded = false;

// Show both sides of each face
uniform bool double_sided = false;

// Add extra emission above base color
uniform bool use_emission = false;
// Emission color before strength multiply
uniform vec4 emission_color: source_color = vec4(1.0);
// Brightness multiplier for emission
uniform float emission_strength: hint_range(0.0, 16.0) = 1.0;
// Optional texture modulating emission color
uniform sampler2D emission_texture: source_color, filter_nearest, hint_default_white;
// Multiply emission color by emission texture
uniform bool use_emission_texture = false;

// Continuous breathing vertex animation
uniform bool use_breathe = false;
// Maximum displacement from breathing
uniform float breathe_intensity: hint_range(0.0, 0.1) = 0.005;
// Oscillation speed of breathing cycle
uniform float breathe_frequency: hint_range(0.0, 10.0) = 1.0;
// Random phase shift per vertex
uniform float breathe_randomness: hint_range(0.0, 1.0) = 0.3;

// Original UV before affine distortion
varying vec2 original_uv;
// Vertex position in world space
varying vec3 world_pos;
// World normal for triplanar blending
varying vec3 world_normal;

// Simple hash from vertex position
float hash(vec3 p) {
	// Scatter and mix with dot product
	p = fract(p * vec3(127.1, 311.7, 74.7));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	// Apply breathing before vertex snapping
	if (use_breathe) {
		// Unique random offset per vertex
		float rand_offset = hash(floor(VERTEX * 100.0) * 0.01);
		// Phase with time, speed, and randomness
		float phase = TIME * breathe_frequency + rand_offset * breathe_randomness * 6.2831;
		// Vertical offset from sine wave
		float breath = sin(phase) * breathe_intensity;
		// Sideways sway out of phase
		float breath_xz = sin(phase * 0.7 + 1.0) * breathe_intensity * 0.4;
		VERTEX.y += breath;
		VERTEX.x += breath_xz;
		VERTEX.z += breath_xz * 0.6;
	}

	// Clip-space position for snapping
	vec4 position = PROJECTION_MATRIX * VIEW_MATRIX * vec4(VERTEX, 1.0);
	// Snapping grid from resolution and wobble
	vec2 snapping = resolution * vertex_wobble;
	// Snap screen XY to subpixel grid
	vec2 screen_position = round(position.xy * snapping) / snapping;
	// Final position with snapped coordinates
	POSITION = vec4(screen_position, position.zw);

	// Store UV before affine transform
	original_uv = UV;
	// Apply affine texture distortion by depth
	UV *= (VIEW_MATRIX * vec4(VERTEX, 1.0)).z;

	world_pos = VERTEX;
	world_normal = NORMAL;
}

void fragment() {
	// Discard backfaces unless double sided
	if (!double_sided && !FRONT_FACING) {
		discard;
	}
	// Flip normal for backfaces in double sided
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	vec4 albedo;
	// Pick solid color, triplanar, or UV map
	if (use_color) {
		albedo = base_color;
	} else if (use_triplanar) {
		// Blend weights from absolute world normal
		vec3 blend = abs(world_normal);
		blend = normalize(max(blend, 0.00001));
		blend /= (blend.x + blend.y + blend.z);
		// Triplanar UV with offset and scale
		vec3 pos = (world_pos + triplanar_offset) * triplanar_scale;
		// Sample three planes and blend
		albedo = texture(color_texture, pos.yz) * blend.x
		       + texture(color_texture, pos.xz) * blend.y
		       + texture(color_texture, pos.xy) * blend.z;
	} else {
		albedo = texture(color_texture, original_uv);
	}

	// Alpha discarded for opaque PSX look
	//ALPHA = albedo.a;

	// Full emission or albedo with lighting
	if (unshaded) {
		ALBEDO = vec3(0.0);
		EMISSION = albedo.rgb;
	} else {
		ALBEDO = albedo.rgb;
	}

	// Add extra emission on top
	if (use_emission) {
		vec3 emit = emission_color.rgb;
		if (use_emission_texture) {
			emit *= texture(emission_texture, original_uv).rgb;
		}
		EMISSION += emit * emission_strength;
	}
}