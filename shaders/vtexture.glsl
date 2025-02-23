layout(location=0) in vec2 pos;
layout(location=1) in vec2 size;
layout(location=2) in vec4 params_0;
layout(location=3) in vec2 params_1;
layout(location=4) in vec3 rotation_matrix_0;
layout(location=5) in vec3 rotation_matrix_1;
layout(location=6) in vec3 rotation_matrix_2;
uniform vec2 resolution;
uniform mat3 view_matrix;
uniform float time;
out vec2 tex_coord;
flat out int waves;
flat out int windy;
flat out int caustics;
flat out float lightness;
vec2 project(vec2 point) {
	return 2*point/resolution; }
void main(void) {
	mat3 rotation_matrix=mat3(rotation_matrix_0,rotation_matrix_1,rotation_matrix_2);
	waves=int(params_0.y);
	windy=int(params_0.z);
	caustics=int(params_0.w);
	lightness=params_1.x;
	vec2 en=vec2(pos.x+0.5*size.x,pos.y-0.5*size.y);
	vec2 es=vec2(pos.x+0.5*size.x,pos.y+0.5*size.y);
	vec2 wn=vec2(pos.x-0.5*size.x,pos.y-0.5*size.y);
	vec2 ws=vec2(pos.x-0.5*size.x,pos.y+0.5*size.y);
	mat3 matrix=view_matrix*rotation_matrix;
	en=(matrix*vec3(en,1)).xy;
	es=(matrix*vec3(es,1)).xy;
	wn=(matrix*vec3(wn,1)).xy;
	ws=(matrix*vec3(ws,1)).xy;
	vec2 point=vec2(0);
	if((gl_VertexID%6)==0) {      point=ws; tex_coord=vec2(0,0); }
	else if((gl_VertexID%6)==1) { point=es; tex_coord=vec2(1,0); }
	else if((gl_VertexID%6)==2) { point=en; tex_coord=vec2(1,1); }
	else if((gl_VertexID%6)==3) { point=ws; tex_coord=vec2(0,0); }
	else if((gl_VertexID%6)==4) { point=en; tex_coord=vec2(1,1); }
	else if((gl_VertexID%6)==5) { point=wn; tex_coord=vec2(0,1); }
	gl_Position.xyz=vec3(project(point),params_0.x); }