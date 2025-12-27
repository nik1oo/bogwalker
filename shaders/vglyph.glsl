uniform vec2 pos;
uniform vec2 size;
uniform vec2 resolution;
uniform float s0;
uniform float s1;
uniform float t0;
uniform float t1;
out vec2 tex_coord;
void main(void) {
	gl_Position=vec4(0,0,0,1);
	float x0=pos.x;
	float x1=pos.x+size.x;
	float y0=pos.y;
	float y1=pos.y+size.y;
	vec2 point=vec2(x0,y0);
	tex_coord=vec2(s0,t0);
	if ((gl_VertexID+1)%6>2) {
		point.x=x1;
		tex_coord.x=s1; }
	if (gl_VertexID%2==1){
		point.y=y1;
		tex_coord.y=t1; }
	gl_Position.xy=2*point/resolution; }