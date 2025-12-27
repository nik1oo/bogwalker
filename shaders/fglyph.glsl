layout (binding=0) uniform sampler2D samp;
uniform vec3 fill_color;
in vec2 tex_coord;
out vec4 color;
void main(void) {
	color.w=texture(samp,tex_coord).x;
	color.w=pow(color.w*2,2);
	color.xyz=fill_color; }