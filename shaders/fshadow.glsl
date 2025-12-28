layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
out vec4 color;
uniform vec2 resolution;
uniform int length;
uniform float opacity;
void main(void) {
	color=vec4(0);
	vec2 offset=vec2(1)/resolution;
	color.w=texture(samp,tex_coord+vec2(-offset.x,offset.y)*length).w;
	color.w*=opacity; }