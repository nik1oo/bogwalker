package bogwalker
import "core:strings"
import fs "vendor:fontstash"
load_font::proc($path:string) {
	read_and_load_texture(path)
	name:=name_from_path(path)
	texture:=&state.textures[name]
	font:Font={ name=strings.clone(name),symbol_size=[2]u8{u8(texture.size.x/16),u8(texture.size.y/16)} }
	state.fonts[font.name]=font }
init_fontstash::proc() {
	// font_context: fs.FontContext
	// atlas_size: [2]i32 = { 720, 720 }
	// fs.Init(&font_context, cast(int)atlas_size.x, cast(int)atlas_size.y, .BOTTOMLEFT)
	// font_alegreya := fs.AddFontPath(&font_context, "alegreya", "fonts/alegreya.ttf")
	// font_arial := fs.AddFontPath(&font_context, "arial", "fonts/arial.ttf")
	// fs.SetFont(&font_context, font_arial)
	// fs.SetSize(&font_context, 13)
	// fs.SetAH(&font_context, .LEFT)
	// fs.SetAV(&font_context, .MIDDLE)
	// fs.SetSpacing(&font_context, 8)
	// fs.SetBlur(&font_context, 0)
	// glyphs: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !\"#$%'()*+,-./:;<=>?@[\\]^_`{|}~"
	// text_iter := fs.TextIterInit(&font_context, 0, 0, glyphs)
	// quad: fs.Quad
	// glyph_infos: map[rune]Glyph_Info
	// for glyph in glyphs {
	// 	fs.TextIterNext(&font_context, &text_iter, &quad)
	// 	glyph_info: Glyph_Info = { quad = quad, glyph = text_iter.font.glyphs[len(text_iter.font.glyphs) - 1] }
	// 	glyph_infos[glyph] = glyph_info }
	// assert(cast(i32)len(font_context.textureData) == atlas_size.x * atlas_size.y)
	// atlas_handle := load_texture_from_data_grayscale(font_context.textureData, atlas_size)
}