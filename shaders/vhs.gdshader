/*
Shader from Godot Shaders - the free shader library.
godotshaders.com/shader/VHS-and-CRT-monitor-effect

Forced to SCREEN_TEXTURE for global overlay.
*/

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec2 resolution = vec2(640.0, 480.0); 

uniform bool pixelate = true; 

uniform bool roll = true;
uniform float roll_speed = 8.0; 
uniform float roll_size : hint_range(0.0, 100.0) = 15.0;
uniform float roll_variation : hint_range(0.1, 5.0) = 1.8; 
uniform float distort_intensity : hint_range(0.0, 0.2) = 0.05; 

uniform float noise_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_speed = 5.0; 

uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;

uniform float aberration : hint_range(-1.0, 1.0) = 0.03; 
uniform float brightness = 1.4; 
uniform bool discolor = true; 

uniform float warp_amount :hint_range(0.0, 5.0) = 1.0; 
uniform bool clip_warp = false;

uniform float vignette_intensity = 0.4; 
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

// Use a simpler random function for better compatibility
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 warp(vec2 uv){
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta.xy, delta.xy);
	float delta_offset = delta2 * warp_amount; // Simplified from delta4
	return uv + delta * delta_offset;
}

float border (vec2 uv){
	float radius = min(warp_amount, 0.08);
	if (radius <= 0.0) return 1.0;
	vec2 abs_uv = abs(uv * 2.0 - 1.0) - vec2(1.0, 1.0) + radius;
	float dist = length(max(vec2(0.0), abs_uv)) / radius;
	float square = smoothstep(0.96, 1.0, dist);
	return clamp(1.0 - square, 0.0, 1.0);
}

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float v = uv.x * uv.y * 15.0;
	return pow(clamp(v, 0.0, 1.0), vignette_intensity * vignette_opacity);
}

void fragment()
{
	// Detect resolution if not set properly
	vec2 res = resolution;
	if (res.x <= 1.0) res = 1.0 / SCREEN_PIXEL_SIZE;
	
	vec2 uv = warp(SCREEN_UV); 
	vec2 text_uv = uv;
	float time = roll ? TIME : 0.0;
	
	if (pixelate)
	{
		text_uv = floor(uv * res) / res;
	}
	
	float roll_line = 0.0;
	vec2 roll_uv = vec2(0.0);
	if (roll)
	{
		roll_line = smoothstep(0.3, 0.9, sin(uv.y * roll_size - (time * roll_speed) ) );
		roll_line *= roll_line * smoothstep(0.3, 0.9, sin(uv.y * roll_size * roll_variation - (time * roll_speed * roll_variation) ) );
		roll_uv = vec2(( roll_line * distort_intensity * (1.0-uv.x)), 0.0);
	}
	
	vec4 text;
	text.r = texture(SCREEN_TEXTURE, text_uv + roll_uv * 0.8 + vec2(aberration, 0.0) * .1).r;
	text.g = texture(SCREEN_TEXTURE, text_uv + roll_uv * 1.2 - vec2(aberration, 0.0) * .1 ).g;
	text.b = texture(SCREEN_TEXTURE, text_uv + roll_uv).b;
	text.a = 1.0;
	
	if (grille_opacity > 0.0){
		float g_r = smoothstep(0.85, 0.95, abs(sin(uv.x * (res.x * 3.14159))));
		text.r = mix(text.r, text.r * g_r, grille_opacity);
		float g_g = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (res.x * 3.14159))));
		text.g = mix(text.g, text.g * g_g, grille_opacity);
		float b_b = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (res.x * 3.14159))));
		text.b = mix(text.b, text.b * b_b, grille_opacity);
	}
	
	text.rgb = clamp(text.rgb * brightness, 0.0, 1.0);
	
	if (scanlines_opacity > 0.0)
	{
		float scanline = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (res.y * 3.14159))));
		text.rgb = mix(text.rgb, text.rgb * scanline, scanlines_opacity);
	}
	
	if (noise_opacity > 0.0)
	{
		// Simpler noise
		float n = rand(uv + vec2(time * 0.1, time * 0.2));
		text.rgb = mix(text.rgb, text.rgb + (n - 0.5) * 0.1, noise_opacity);
	}
	
	if (static_noise_intensity > 0.0)
	{
		text.rgb += (rand(text_uv + fract(TIME)) - 0.5) * static_noise_intensity;
	}
	
	text.rgb *= border(uv);
	text.rgb *= vignette(uv);
	
	if (discolor)
	{
		float greyscale = dot(text.rgb, vec3(0.299, 0.587, 0.114));
		text.rgb = mix(text.rgb, vec3(greyscale), 0.3); // Fixed saturation
	}
	
	COLOR = text;
}
