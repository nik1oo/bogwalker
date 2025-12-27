layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
uniform vec2 resolution;
uniform int size;
out vec4 color;
void main(void) {
	color=texture(samp,tex_coord);
	vec2 delta=vec2(1)/resolution.xy;
	for (int i=-size;i<size;i+=1) {
		for (int j=-size;j<size;j+=1) {
			float sample_w=texture(samp,tex_coord+delta*vec2(i,j)).w;
			if (sample_w>0.0) { color=vec4(1,0,0,1); } } } }