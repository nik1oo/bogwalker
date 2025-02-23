layout(binding=0) uniform sampler2D samp;
in flat float frag_symbol;
in flat vec4 frag_text_color;
in vec2 tex_coords;
out vec4 color;
vec2 invert_y(vec2 vec) {
	return vec2(vec.x,1-vec.y); }
vec2 offset=vec2(int(frag_symbol)%16,int(frag_symbol)/16-15);
vec4 sample_bitmap(vec2 uv) {
	return texture(samp,(vec2(uv.x/16,1-uv.y/16)+offset/16)); }
void main(void) {
	vec4 bitmap_sample=sample_bitmap(tex_coords);
	color.xyz=vec3(bitmap_sample.x)*frag_text_color.xyz;
	color.xyz=bitmap_sample.xyz*frag_text_color.xyz;
	color.w=bitmap_sample.w*frag_text_color.w;
	color.xyz=mix(color.xyz,vec3(1,1,0),0.1); }