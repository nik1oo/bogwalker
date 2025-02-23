layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
out vec4 color;
float luminance(vec3 c) {
	return length(c)/length(vec3(1)); }
void main(void) {
	color=texture(samp,tex_coord);
	color=vec4(mix(vec3(0),color.xyz,smoothstep(0.5,1.0,luminance(color.xyz))),1);
	color.xyz=normalize(color.xyz)*(vec3(1)-pow(vec3(1)-color.xyz,vec3(32))); return; }