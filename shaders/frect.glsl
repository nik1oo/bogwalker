out vec4 color;
uniform vec4 fill_color;
uniform vec2 pos;
uniform vec2 size;
uniform vec2 resolution;
uniform float rounding;
in vec2 tex_coord;
void main(void) {
	color=vec4(1,0,0,1);
	return;
	vec2 p=gl_FragCoord.xy-resolution*0.5-pos;
	vec2 b=size/2-vec2(rounding);
	vec2 d=abs(p)-b;
	float dist=length(max(d,0.0))+min(max(d.x,d.y),0.0);
	if(dist<rounding) {
		color=fill_color; }
	if(dist>(rounding-2)) { color.xyz=vec3(1); }
	if(dist>(rounding-1)) { color.xyz=vec3(0); }}