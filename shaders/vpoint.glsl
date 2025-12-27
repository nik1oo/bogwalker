uniform vec2 pos;
uniform vec2 resolution;
uniform float depth;
void main(void) {
	float x=(pos.x/resolution.x)*2;
	float y=(pos.y/resolution.y)*2;
	gl_Position=vec4(x,y,depth,1); }