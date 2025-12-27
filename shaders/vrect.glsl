uniform vec2 pos;
uniform vec2 size;
uniform vec2 resolution;
uniform float depth;
out vec2 tex_coord;
void main(void) {
	float x0=(float(pos.x-size.x/2)/resolution.x)*2;
	float x1=(float(pos.x+size.x/2)/resolution.x)*2;
	float y0=(float(pos.y-size.y/2)/resolution.y)*2;
	float y1=(float(pos.y+size.y/2)/resolution.y)*2;
	gl_Position=vec4(x0,y0,depth,1);
	if(gl_VertexID==0) {
		gl_Position.xy=vec2(x0,y1);
		tex_coord=vec2(0,0); }
	else if(gl_VertexID==1) {
		gl_Position.xy=vec2(x0,y0);
		tex_coord=vec2(0,1); }
	else if(gl_VertexID==2) {
		gl_Position.xy=vec2(x1,y0);
		tex_coord=vec2(1,1); }
	else if(gl_VertexID==3) {
		gl_Position.xy=vec2(x0,y1);
		tex_coord=vec2(0,0); }
	else if(gl_VertexID==4) {
		gl_Position.xy=vec2(x1,y0);
		tex_coord=vec2(1,1); }
	else if(gl_VertexID==5) {
		gl_Position.xy=vec2(x1,y1);
		tex_coord=vec2(1,0); } }