package bogwalker
import gl "vendor:OpenGL"
import "core:image"
import "core:image/png"
read_and_load_texture::proc($path:string) {
	name:=name_from_path(path)
	texture:Texture; success:bool
	texture.name=name
	texture.image=nil
	texture.image,texture.size,success=read_texture_from_png(path)
	assert(success)
	load_texture(&texture)
	image.destroy(texture.image)
	texture.image=nil
	assert(success); if !success { return }
	ptr:=map_insert(&state.textures,texture.name,texture)
	assert(ptr!=nil) }
read_texture_from_png::proc($path:string)->(^image.Image,[2]u16,bool) {
	bytes:=#load(path)
	options:=(image.Options){.alpha_add_if_missing}
	texture_image,error:=png.load_from_bytes(bytes,options)
	assert(error==nil); if error!=nil { return {},{},false }
	return texture_image,{u16(texture_image.width),u16(texture_image.height)},true }
load_texture::proc(texture:^Texture) {
	assert(texture.image!=nil); if texture.image==nil { return }
	gl.GenTextures(1,&texture.handle)
	gl.BindTexture(gl.TEXTURE_2D,texture.handle)
	gl.TexImage2D(gl.TEXTURE_2D,0,gl.RGBA,i32(texture.size.x),i32(texture.size.y),0,gl.RGBA,gl.UNSIGNED_BYTE,&texture.image.pixels.buf[0])
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.REPEAT)
	texture_filtering(gl.LINEAR) }