layout(binding=0) uniform sampler2D samp;
uniform vec2 resolution;
uniform float time;
flat in int waves;
flat in int windy;
flat in int caustics;
uniform mat3 view_matrix;
uniform float view_zoom;
in vec2 tex_coord;
out vec4 color;
#define EPSILON 0.01
in float lightness;
float flat_step(float edge0,float edge1,float x) { return clamp((x-edge0)/(edge1-edge0),0,1); }
mat3 rotate_matrix(float angle) {
	return mat3(
		cos(angle),-sin(angle),0,
		sin(angle),cos(angle),0,
		0,0,1); }
float wave_height(vec2 uv,vec2 dir,float speed,float w,float a) {
	return a*sin((dot(uv,dir)+speed*time)/w); }
float waves_height(vec2 uv) {
	float h=0;
	for(int i=0; i<6; i+=1) {
		h+=wave_height(uv,(rotate_matrix(i)*vec3(1,0,1)).xy,8+4*i,12-i,1.5); }
	return h; }
vec2 wave_slope(vec2 uv,vec2 dir,float speed,float w,float a) {
	return vec2(wave_height(uv+vec2(EPSILON,0),dir,speed,w,a)-wave_height(uv+vec2(-EPSILON,0),dir,speed,w,a),
		wave_height(uv+vec2(0,EPSILON),dir,speed,w,a)-wave_height(uv+vec2(0,-EPSILON),dir,speed,w,a))/EPSILON; }
vec2 waves_slope(vec2 uv) {
	return vec2(waves_height(uv+vec2(EPSILON,0))-waves_height(uv+vec2(-EPSILON,0)),
		waves_height(uv+vec2(0,EPSILON))-waves_height(uv+vec2(0,-EPSILON)))/EPSILON; }
vec2 wave(vec2 direction,float a,float f,float s) {
	return a*sin(f*time+normalize(direction)*tex_coord/s); }
float lum(vec3 c) {
	return length(c)/length(vec3(1)); }
void main(void) {
	vec2 uv=(inverse(view_matrix)*vec3((gl_FragCoord.xy-resolution/2),1)).xy;
	vec2 ws=waves_slope(uv);
	vec2 coord=tex_coord;
	if(waves==1) { coord+=ws*0.1; }
	if(windy==1) {
		float t=fract(0.25*(time+0.001*gl_FragCoord.x+0.001*3*gl_FragCoord.y));
		coord.y+=0.0025*sin((t-0.5)*32)/(t-0.5); }
	color=texture(samp,coord);
	float t=0.5*(sin(time)+1);
	float t1=flat_step(0.5,1.0,lightness);
	float t2=flat_step(0.0,0.5,lightness);
	float lm=lum(color.xyz);
	const float c1=0.0;
	const float c2=0.5;
	color.xyz=mix(vec3(0-(1-lm)),mix(color.xyz,vec3(1+lm),t1),t2);
	if(caustics==1) { if((ws.x>c1)&&(ws.x<c2)) { color.xyz*=vec3(1)+2*vec3(1,0.9,0.8)*pow(1-abs(2*flat_step(c1,c2,ws.x)-1),4.0); }}
	gl_FragDepth=gl_FragCoord.z;
	if(color.w==0) { gl_FragDepth=1; }}