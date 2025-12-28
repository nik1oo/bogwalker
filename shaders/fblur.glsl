layout (binding=0) uniform sampler2D samp;
in vec2 tex_coord;
const float STEPS=4;
const float STEP_SIZE=1;
uniform vec2 resolution;
uniform int step;
out vec4 color;
float gaus(float x,float y,float r) {
	r=r/6;
	float rx=x/r;
	float ry=y/r;
	return pow(2.0,(-rx*rx-ry*ry)); }
void main(void) {
	vec2 step_size=vec2(step)/resolution.xy;
	color=vec4(0,0,0,0);
	for(float i=0; i<STEPS; i+=1) {
		for(float j=0; j<STEPS; j+=1) {
			color+=texture(samp,tex_coord+(vec2(i,j)-vec2(STEPS-1)/2)*step_size); }}
	color/=10; }