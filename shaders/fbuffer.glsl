layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
out vec4 color;
float lum(vec3 c) {
	return length(c)/length(vec3(1)); }
void main(void) {
	color.xyz=texture(samp,tex_coord).xyz;
	color.w=1.0;
	float lm=lum(color.xyz);
	gl_FragDepth=texture(samp,tex_coord).w; }