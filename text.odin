package bogwalker
import "core:fmt"
import "core:strings"
import la "core:math/linalg"
import fs "vendor:fontstash"
import gl "vendor:OpenGL"
load_font::proc($path:string) {
	load_texture_from_filepath(path)
	name:=name_from_path(path)
	texture:=&state.textures[name]
	font:Font={ name=strings.clone(name),symbol_size=[2]u8{u8(texture.size.x/16),u8(texture.size.y/16)} }
	state.fonts[font.name]=font }
init_fontstash::proc() {
	font_context:fs.FontContext
	atlas_size:[2]i32={720,720}
	fs.Init(&font_context,cast(int)atlas_size.x,cast(int)atlas_size.y,.BOTTOMLEFT)
	// goudy-bookletter-1911
	// metamorphous
	// inknut-antiqua
	font_alegreya:=fs.AddFontPath(&font_context,"alegreya","fonts/labrada.ttf")
	font_arial:=fs.AddFontPath(&font_context,"arial","fonts/arial.ttf")
	fs.SetFont(&font_context,font_alegreya)
	fs.SetSize(&font_context,44)
	fs.SetAH(&font_context,.LEFT)
	fs.SetAV(&font_context,.MIDDLE)
	fs.SetSpacing(&font_context,8)
	fs.SetBlur(&font_context,0)
	glyphs:string="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !\"#$%'()*+,-./:;<=>?@[\\]^_`{|}~"
	text_iter:=fs.TextIterInit(&font_context,0,0,glyphs)
	quad:fs.Quad
	for glyph in glyphs {
		fs.TextIterNext(&font_context,&text_iter,&quad)
		glyph_info:Glyph_Info={quad=quad,glyph=text_iter.font.glyphs[len(text_iter.font.glyphs)-1]}
		state.glyph_infos[glyph]=glyph_info }
	assert(cast(i32)len(font_context.textureData)==atlas_size.x*atlas_size.y)
	state.font_atlas_handle=load_texture_from_data_grayscale(font_context.textureData,atlas_size) }
// _render_text::proc(args:..any,sep:string="",pos:[2]f16={0,0},color:[4]f16=WHITE,scale_multiplier:f16=1.0,pivot:bit_set[Compass]={},font_name:string="font-medium",shadow:bool=true,spacing:f16=1.0,waviness:f16=0.0) {
// 	width:f16=f16(len(text))*f16(font.symbol_size.x)*spacing
// 	height:f16=f16(font.symbol_size.y)
// 	pos=pos-0.5*{width,height}+0.5*la.array_cast(font.symbol_size,f16)
// 	if .EAST in pivot { pos.x-=0.5*width }
// 	if .WEST in pivot { pos.x+=0.5*width }
// 	if .NORTH in pivot { pos.y-=0.5*height }
// 	if .SOUTH in pivot { pos.y+=0.5*height }
text_rect::proc(text:string,pos:[2]f16)->Rect(f16){
	pos0:[2]f16=pos
	pos1:[2]f16=pos
	for c,i in text {
		quad:=state.glyph_infos[c].quad
		glyph:=state.glyph_infos[c].glyph
		if c==' ' do quad=state.glyph_infos['_'].quad
		pos1.x+=cast(f16)(quad.x1-quad.x0) }
	o_quad:=state.glyph_infos['O'].quad
	pos1.y=pos0.y+cast(f16)(o_quad.y0-o_quad.y1)
	return {pos={(pos0.x+pos1.x)/2,(pos0.y+pos1.y)/2},size=pos1-pos0} }
render_text::proc(text:string,pos:[2]f16,color:[3]f32={1,1,1},pivot:bit_set[Compass]={}) {
	pos:=pos
	render_point(pos,3,{1,0,0},depth=0.0)
	rect:Rect(f16)=text_rect(text,pos)
	pos=pos-0.5*rect.size
	if .EAST in pivot { pos.x-=0.5*rect.size.x }
	if .WEST in pivot { pos.x+=0.5*rect.size.x }
	if .NORTH in pivot { pos.y-=0.5*rect.size.y }
	if .SOUTH in pivot { pos.y+=0.5*rect.size.y }
	for c,i in text {
		quad:=state.glyph_infos[c].quad
		glyph:=state.glyph_infos[c].glyph
		if c!=' ' do render_glyph(c,quad,color,pos-{cast(f16)glyph.xoff,cast(f16)glyph.yoff})
		else do quad=state.glyph_infos['_'].quad
		pos.x+=cast(f16)(quad.x1-quad.x0) } }
render_glyph::proc(glyph:rune,quad:fs.Quad,color:[3]f32,pos:[2]f16) {
	gl.UseProgram(state.glyph_shader.handle)
	set_shader_param(state.glyph_shader.pos,la.array_cast(pos,f32))
	set_shader_param(state.glyph_shader.size,[2]f32{cast(f32)(quad.x1-quad.x0),cast(f32)(quad.y1-quad.y0)})
	set_shader_param(state.glyph_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.glyph_shader.fill_color,color)
	set_shader_param(state.glyph_shader.s0,quad.s0)
	set_shader_param(state.glyph_shader.s1,quad.s1)
	set_shader_param(state.glyph_shader.t0,quad.t0)
	set_shader_param(state.glyph_shader.t1,quad.t1)
	bind_texture(0,state.font_atlas_handle)
	draw_triangles(6,depth_test=true) }