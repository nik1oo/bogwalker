package bogwalker
import "base:runtime"
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
render_texture::proc(name:string,rect:Rect(f16)={},rotation:f16=0.0,depth:f16=0.0,lightness:f16=0.5,flags:Cell_Flags_Register={},space:Space=.WORLD)->Rect(f16) {
	use_shader(state.texture_shader)
	rotation_matrix:matrix[3,3]f32=pan_matrix(cast_array(rect.pos,f32))*rotate_matrix(f32(rotation))*pan_matrix(cast_array(-rect.pos,f32))
	_,commands,_,_:=map_entry(&state.texture_draw_commands,name)
	if cap(commands)==0 do commands^=make_soa_dynamic_array_len_cap(#soa[dynamic]Texture_Draw_Command,length=0,capacity=TEXTURE_COMMANDS_CAP)
	command:Texture_Draw_Command
	command.pos=cast_array(rect.pos,f32)
	command.size=cast_array(rect.size,f32)
	command.params_0={f32(depth),f32(i32(.WAVY in flags)),f32(i32(.WINDY in flags)),f32(i32(.CAUSTICS in flags))}
	command.params_1={f32(lightness),f32(rotation)}
	command.space=cast(i32)space // (TODO): Figure out why space is not being set. It's always 0.
	copy_slice(command.rotmat_0[:],rotation_matrix[0][:])
	copy_slice(command.rotmat_1[:],rotation_matrix[1][:])
	copy_slice(command.rotmat_2[:],rotation_matrix[2][:])
	for _ in 0..<QUAD_VERTS {
		_,err:=append_soa_elem(commands,command)
		assert(err==.None) }
	return rect }
render_texture_group::proc(name:string) {
	use_shader(state.texture_shader)
	commands,ok:=&state.texture_draw_commands[name]; if !ok do return
	n:=len(commands); if n==0 do return
	bind_vertex_array(0)
	i:int=0
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.pos[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.size[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.params_0[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.params_1[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.rotmat_0[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.rotmat_1[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.rotmat_2[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.INT,&commands.space[0],n)
	bind_texture(gl.TEXTURE0,state.textures[name].handle)
	texture_wrapping(gl.CLAMP_TO_EDGE)
	texture_filtering(gl.NEAREST)
	draw_triangles(i32(6*n),depth_test=true)
	runtime.clear_soa_dynamic_array(commands) }
render_texture_groups::proc() {
	for name,_ in state.texture_draw_commands do render_texture_group(name) }