layout (binding=0) uniform sampler2D base_samp;
layout (binding=1) uniform sampler2D bloom_samp;
in vec2 tex_coord;
out vec4 color;
uniform int grayscale;
float luminance(vec3 c) {
	return length(c)/length(vec3(1)); }
void main(void) {
	// color=texture(bloom_samp,tex_coord); return;
	// color.w=1;
	// color.xyz=0.5*(vec3(1)-pow(vec3(1)-texture(bloom_samp,tex_coord).xyz,vec3(4))); return;
	// color=texture(base_samp,tex_coord)+1.0*texture(bloom_samp,tex_coord);
	color=texture(base_samp,tex_coord)*(vec4(1)+0.5*texture(bloom_samp,tex_coord));
	float lm=luminance(color.xyz);
	if(grayscale==1) {
		color.xyz=vec3(lm); }
	float t=4*(-pow(lm-0.5,2.0)+0.25);
	// vec3 hue=vec3(0.8,1,0.2);
	vec3 hue=vec3(1.0);
	color.xyz=mix(color.xyz,color.xyz*hue,0.75*t); }