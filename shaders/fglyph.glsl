layout (binding=0) uniform sampler2D samp;
uniform vec4 fill_color;
in vec2 tex_coord;
out vec4 color;
void main(void) {
	color.w=texture(samp,tex_coord).x;
	color.w=pow(color.w*2,2)*fill_color.w;
	if (color.w==0.0) {
		gl_FragDepth=1.0; }
	gl_FragDepth=1.0-color.w;
	color.xyz=fill_color.xyz; }