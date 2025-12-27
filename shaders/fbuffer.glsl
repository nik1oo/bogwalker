layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
out vec4 color;
void main(void) {
	color=texture(samp,tex_coord); }