uniform vec2 pos;
uniform vec2 size;
uniform vec2 this_buffer_res;
out vec2 tex_coord;
void main(void) {
	float x0=(float(pos.x-size.x/2)/this_buffer_res.x)*2;
	float x1=(float(pos.x+size.x/2)/this_buffer_res.x)*2;
	float y0=(float(pos.y-size.y/2)/this_buffer_res.y)*2;
	float y1=(float(pos.y+size.y/2)/this_buffer_res.y)*2;
	gl_Position=vec4(x0,y0,0,1);
	tex_coord=vec2(0,0);
	if((gl_VertexID+1)%6>2){
		gl_Position.x=x1;
		tex_coord.x=1; }
	if(gl_VertexID%2==1){
		gl_Position.y=y1;
		tex_coord.y=1; } }