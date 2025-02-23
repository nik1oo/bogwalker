out vec2 tex_coord;
void main(void) {
	tex_coord=vec2(0,1);
	gl_Position.zw=vec2(0.5,1);
	if((gl_VertexID+1)%6<3) {
		gl_Position.x=1;
		tex_coord.x=1; }
	else {
		gl_Position.x=-1;
		tex_coord.x=0; }
	if(gl_VertexID%2==0) {
		gl_Position.y=-1;
		tex_coord.y=0;
	} else {
		gl_Position.y=1;
		tex_coord.y=1; }}