package bogwalker
import "core:strings"
load_font::proc($path:string) {
	read_and_load_texture(path)
	name:=name_from_path(path)
	texture:=&state.textures[name]
	font:Font={ name=strings.clone(name),symbol_size=[2]u8{u8(texture.size.x/16),u8(texture.size.y/16)} }
	state.fonts[font.name]=font }