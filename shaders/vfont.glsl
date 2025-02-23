layout(location=0) in float symbol;
layout(location=1) in vec3 position;
layout(location=2) in float scale_factor;
layout(location=3) in vec4 text_color;
uniform vec2 symbol_size;
uniform vec2 this_buffer_res;
out vec2 tex_coords;
out float frag_symbol;
out vec4 frag_text_color;
void main(void) {
	frag_symbol=symbol;
	frag_text_color=text_color;
	int j=gl_VertexID/6;
	float x=(float(position.x)/this_buffer_res.x)*2;
	float y=(float(position.y)/this_buffer_res.y)*2;
	float z=position.z;
	float w=(symbol_size.x/this_buffer_res.x)*2*scale_factor;
	float h=(symbol_size.y/this_buffer_res.y)*2*scale_factor;
	float half_w=0.5*w;
	float half_h=0.5*h;
	tex_coords=vec2(0,0);
	if((gl_VertexID%6)==0) {
		gl_Position=vec4(x-half_w,y+half_h,z,1);
		tex_coords=vec2(0,0); }
	else if((gl_VertexID%6)==1) {
		gl_Position=vec4(x-half_w,y-half_h,z,1);
		tex_coords=vec2(0,1); }
	else if((gl_VertexID%6)==2) {
		gl_Position=vec4(x+half_w,y-half_h,z,1);
		tex_coords=vec2(1,1); }
	else if((gl_VertexID%6)==3) {
		gl_Position=vec4(x-half_w,y+half_h,z,1);
		tex_coords=vec2(0,0); }
	else if((gl_VertexID%6)==4) {
		gl_Position=vec4(x+half_w,y-half_h,z,1);
		tex_coords=vec2(1,1); }
	else if((gl_VertexID%6)==5) {
		gl_Position=vec4(x+half_w,y+half_h,z,1);
		tex_coords=vec2(1,0); }
	tex_coords.y=1.0-tex_coords.y; }