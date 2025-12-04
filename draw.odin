package bogwalker
import "base:runtime"
import "base:intrinsics"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:math"
import "core:math/linalg"
import "core:path/filepath"
import "core:reflect"
import "core:strings"
import "core:strconv"
import "core:time"
init_glfw::proc() {
	glfw.SetErrorCallback(glfw_error_callback)
	assert(bool(glfw.Init()))
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR,4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR,6)
	glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT,1)
	glfw.WindowHint(glfw.SAMPLES,0)
	glfw.WindowHint(glfw.OPENGL_PROFILE,glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.VISIBLE,1)
	glfw.WindowHint(glfw.FOCUSED,1)
	glfw.WindowHint(glfw.FOCUS_ON_SHOW,1)
	state.window_size=(state.settings.display==.FULLSCREEN)?get_fullscreen_mode_resolution():get_windowed_mode_resolution()
	state.resolution=state.window_size
	state.window=glfw.CreateWindow(i32(state.window_size.x),i32(state.window_size.y),"BOGWALKER",(state.settings.display==.FULLSCREEN)?glfw.GetPrimaryMonitor():nil,nil)
	if state.settings.display==.FULLSCREEN do set_display_fullcreen(); else do set_display_windowed()
	assert(state.window!=nil)
	glfw.MakeContextCurrent(state.window)
	glfw.SwapInterval(0)
	gl.load_up_to(4,6,glfw.gl_set_proc_address)
	gl.DebugMessageCallback(error_callback,nil)
	glfw.RestoreWindow(state.window)
	glfw.ShowWindow(state.window)
	glfw.FocusWindow(state.window)
	glfw.SetKeyCallback(state.window,key_callback)
	glfw.SetScrollCallback(state.window,scroll_callback)
	glfw.SetCursorPosCallback(state.window,cursor_pos_callback)
	glfw.SetMouseButtonCallback(state.window,mouse_button_callback)
	glfw.SetWindowSizeCallback(state.window,resolution_callback)
	glfw.SetInputMode(state.window,glfw.CURSOR,glfw.CURSOR_NORMAL)
	glfw.SetInputMode(state.window,glfw.RAW_MOUSE_MOTION,0)
	width,height:i32=glfw.GetFramebufferSize(state.window)
	state.window_size.x=u16(width)
	state.window_size.y=u16(height) }
init_gl::proc() {
	gl.Viewport(0,0,i32(state.window_size.x),i32(state.window_size.y))
	add_vertex_array()
	bind_vertex_array(0)
	add_vertex_buffer()
	bind_vertex_buffer(0)
	gl.BindFramebuffer(gl.FRAMEBUFFER,0)
	gl.ClearColor(0,0,0,1)
	gl.PolygonMode(gl.FRONT_AND_BACK,gl.FILL)
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.FrontFace(gl.CW)
	gl.Disable(gl.CULL_FACE)
	gl.CullFace(gl.FRONT)
	gl.BlendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA) }
select_render_buffer::proc(render_buffer:^Render_Buffer) {
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	gl.Viewport(0,0,i32(state.resolution.x),i32(state.resolution.y)) }
clear_render_buffer::proc(render_buffer:^Render_Buffer) {
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Clear(gl.DEPTH_BUFFER_BIT) }
select_frame_buffer::proc(frame_buffer_handle:u32) {
	gl.BindFramebuffer(gl.FRAMEBUFFER,frame_buffer_handle)
	gl.Viewport(0,0,i32(state.window_size.x),i32(state.window_size.y)) }
clear_frame_buffer::proc(frame_buffer_handle:u32) {
	gl.BindFramebuffer(gl.FRAMEBUFFER,frame_buffer_handle)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Clear(gl.DEPTH_BUFFER_BIT) }
make_render_buffer_static::proc(size:[2]u16,n_buffers:int,internal_formats:[]i32,formats:[]u32,depth_component:bool=true)->(render_buffer:^Render_Buffer) {
	render_buffer=new(Render_Buffer)
	ok:=init_render_buffer_static(render_buffer,size,n_buffers,internal_formats,formats,depth_component)
	return ok?render_buffer:nil }
init_render_buffer_static::proc(render_buffer:^Render_Buffer,size:[2]u16,n_buffers:int,internal_formats:[]i32,formats:[]u32,depth_component:bool=true)->bool {
	if (size.x==0)||(size.y==0)||(n_buffers==0)||(len(internal_formats)!=n_buffers)||(len(formats)!=n_buffers) { return false }
	render_buffer.size=size
	render_buffer.texture_formats=make([]u32,len(formats))
	render_buffer.n_frames=1
	copy(render_buffer.texture_formats,formats)
	render_buffer.texture_internal_formats=make([]i32,len(internal_formats))
	copy(render_buffer.texture_internal_formats,internal_formats)
	gl.GenFramebuffers(1,(^u32)(&render_buffer.frame_buffer_handle))
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	render_buffer.texture_handles=make([]u32,n_buffers)
	for i in 0..<n_buffers {
		gl.GenTextures(i32(n_buffers),(^u32)(&render_buffer.texture_handles[i]))
		gl.BindTexture(gl.TEXTURE_2D,u32(render_buffer.texture_handles[i]))
		gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE)
		gl.TexImage2D(gl.TEXTURE_2D,0,internal_formats[i],i32(size.x),i32(size.y),0,formats[i],gl.UNSIGNED_BYTE,nil)
		texture_filtering(gl.NEAREST)
		gl.BindTexture(gl.TEXTURE_2D,0)
		gl.FramebufferTexture2D(gl.FRAMEBUFFER,u32(gl.COLOR_ATTACHMENT0+i),gl.TEXTURE_2D,u32(render_buffer.texture_handles[i]),0) }
	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER)!=gl.FRAMEBUFFER_COMPLETE { return false }
	gl.GenRenderbuffers(1,(^u32)(&render_buffer.render_buffer_handle))
	if depth_component {
		gl.BindRenderbuffer(gl.RENDERBUFFER,u32(render_buffer.render_buffer_handle))
		gl.RenderbufferStorage(gl.RENDERBUFFER,gl.DEPTH_COMPONENT32,i32(size.x),i32(size.y))
		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.RENDERBUFFER,u32(render_buffer.render_buffer_handle)) }
	if gl.CheckFramebufferStatus(gl.FRAMEBUFFER)!=gl.FRAMEBUFFER_COMPLETE { return false }
	render_buffer.initialized=true
	return true }
delete_render_buffer::proc(render_buffer:^Render_Buffer) {
	if render_buffer==nil { return }
	gl.DeleteFramebuffers(1,(^u32)(&render_buffer.frame_buffer_handle))
	for _ in 0..<len(render_buffer.texture_handles) do gl.DeleteTextures(1,(^u32)(&render_buffer.texture_handles))
	gl.DeleteRenderbuffers(1,(^u32)(&render_buffer.render_buffer_handle)) }
get_shader_param_handle::proc(shader_handle:u32,param_name:string)->(handle:i32) {
	cstr:cstring=strings.clone_to_cstring(param_name)
	handle=gl.GetUniformLocation(shader_handle,cstr)
	delete(cstr)
	return handle }
UNIT_MATRIX::linalg.MATRIX3F32_IDENTITY
pan_matrix::proc(offset:[2]f32)->matrix[3,3]f32 {
	return matrix[3,3]f32 {
		1,0,offset.x,
		0,1,offset.y,
		0,0,1 }}
rotate_matrix::proc(angle:f32)->matrix[3,3]f32 {
	return matrix[3,3]f32 {
		linalg.cos(angle),-linalg.sin(angle),0,
		linalg.sin(angle),linalg.cos(angle),0,
		0,0,1 }}
zoom_matrix::proc(zoom:f32)->matrix[3,3]f32 {
	return matrix[3,3]f32 {
		zoom,0,0,
		0,zoom,0,
		0,0,1 }}
set_shader_param_1f32::#force_inline proc(param_handle:i32,value:f32) {
	gl.Uniform1f(param_handle,value) }
set_shader_param_2f32::#force_inline proc(param_handle:i32,value:[2]f32) {
	gl.Uniform2f(param_handle,value.x,value.y) }
set_shader_param_3f32::#force_inline proc(param_handle:i32,value:[3]f32) {
	gl.Uniform3f(param_handle,value.x,value.y,value.z) }
set_shader_param_4f32::#force_inline proc(param_handle:i32,value:[4]f32) {
	gl.Uniform4f(param_handle,f32(value.x),f32(value.y),f32(value.z),f32(value.w)) }
set_shader_param_1i32::#force_inline proc(param_handle:i32,value:i32) {
	gl.Uniform1i(param_handle,value) }
set_shader_param_1i16::#force_inline proc(param_handle:i32,value:i16) {
	gl.Uniform1i(param_handle,i32(value)) }
set_shader_param_1i8::#force_inline proc(param_handle:i32,value:i8) {
	gl.Uniform1i(param_handle,i32(value)) }
set_shader_param_1u32::#force_inline proc(param_handle:i32,value:u32) {
	gl.Uniform1i(param_handle,i32(value)) }
set_shader_param_1u16::#force_inline proc(param_handle:i32,value:u16) {
	gl.Uniform1i(param_handle,i32(value)) }
set_shader_param_1u8::#force_inline proc(param_handle:i32,value:u8) {
	gl.Uniform1i(param_handle,i32(value)) }
set_shader_param_2i32::#force_inline proc(param_handle:i32,value:[2]i32) {
	gl.Uniform2i(param_handle,value.x,value.y) }
set_shader_param_2i16::#force_inline proc(param_handle:i32,value:[2]i16) {
	gl.Uniform2i(param_handle,i32(value.x),i32(value.y)) }
set_shader_param_2i8::#force_inline proc(param_handle:i32,value:[2]i8) {
	gl.Uniform2i(param_handle,i32(value.x),i32(value.y)) }
set_shader_param_2u32::#force_inline proc(param_handle:i32,value:[2]u32) {
	gl.Uniform2i(param_handle,i32(value.x),i32(value.y)) }
set_shader_param_2u16::#force_inline proc(param_handle:i32,value:[2]u16) {
	gl.Uniform2i(param_handle,i32(value.x),i32(value.y)) }
set_shader_param_2u8::#force_inline proc(param_handle:i32,value:[2]u8) {
	gl.Uniform2i(param_handle,i32(value.x),i32(value.y)) }
set_shader_param_3i32::#force_inline proc(param_handle:i32,value:[3]i32) {
	gl.Uniform3i(param_handle,value.x,value.y,value.z) }
set_shader_param_3i16::#force_inline proc(param_handle:i32,value:[3]i16) {
	gl.Uniform3i(param_handle,i32(value.x),i32(value.y),i32(value.z)) }
set_shader_param_3i8::#force_inline proc(param_handle:i32,value:[3]i8) {
	gl.Uniform3i(param_handle,i32(value.x),i32(value.y),i32(value.z)) }
set_shader_param_3u32::#force_inline proc(param_handle:i32,value:[3]u32) {
	gl.Uniform3i(param_handle,i32(value.x),i32(value.y),i32(value.z)) }
set_shader_param_3u16::#force_inline proc(param_handle:i32,value:[3]u16) {
	gl.Uniform3i(param_handle,i32(value.x),i32(value.y),i32(value.z)) }
set_shader_param_3u8::#force_inline proc(param_handle:i32,value:[3]u8) {
	gl.Uniform3i(param_handle,i32(value.x),i32(value.y),i32(value.z)) }
set_shader_param_matrix_3f::#force_inline proc(param_handle:i32,value:^matrix[3,3]f32) {
	gl.UniformMatrix3fv(param_handle,1,false,&value[0][0]) }
set_shader_param_matrix_4f::#force_inline proc(param_handle:i32,value:^matrix[4,4]f32) {
	gl.UniformMatrix4fv(param_handle,1,false,&value[0][0]) }
set_shader_param::proc{set_shader_param_1f32,set_shader_param_2f32,set_shader_param_3f32,set_shader_param_4f32,set_shader_param_1i32,set_shader_param_1i16,set_shader_param_1i8,set_shader_param_1u32,set_shader_param_1u16,set_shader_param_1u8,set_shader_param_2i32,set_shader_param_2i16,set_shader_param_2i8,set_shader_param_2u32,set_shader_param_2u16,set_shader_param_2u8,set_shader_param_3i32,set_shader_param_3i16,set_shader_param_3i8,set_shader_param_3u32,set_shader_param_3u16,set_shader_param_3u8,set_shader_param_matrix_3f,set_shader_param_matrix_4f}
bind_texture::proc(binding_point:u32,handle:u32) {
	gl.ActiveTexture(binding_point)
	gl.BindTexture(gl.TEXTURE_2D,u32(handle)) }
draw_triangles::proc(count:i32) {
	gl.DrawArrays(gl.TRIANGLES,0,count) }
use_shader::proc(shader:^$T,loc:=#caller_location)->(^T) {
	assert(shader!=nil,loc=loc); assert(shader.handle!=0,loc=loc)
	gl.UseProgram(u32(shader.handle))
	return shader }
set_blend::proc(value:bool) {
	if value { gl.Enable(gl.BLEND) } else { gl.Disable(gl.BLEND) } }
set_depth_test::proc(value:bool) {
	if value { gl.Enable(gl.DEPTH_TEST) } else { gl.Disable(gl.DEPTH_TEST) } }
render_texture::proc(name:string,pos:[2]f16,size:[2]f16={-1,-1},rotation:f16=0.0,depth:f16=0.0,lightness:f16=0.5,flags:Cell_Flags_Register={}) {
	use_shader(state.texture_shader)
	rotation_matrix:matrix[3,3]f32=pan_matrix(cast_array(pos,f32))*rotate_matrix(f32(rotation))*pan_matrix(cast_array(-pos,f32))
	_,commands,_,_:=map_entry(&state.texture_draw_commands,name)
	if cap(commands)==0 do commands^=make_soa_dynamic_array_len_cap(#soa[dynamic]Texture_Draw_Command,length=0,capacity=TEXTURE_COMMANDS_CAP)
	command:Texture_Draw_Command
	command.pos=cast_array(pos,f32)
	command.size=cast_array(size,f32)
	command.params_0={f32(depth),f32(i32(.WAVY in flags)),f32(i32(.WINDY in flags)),f32(i32(.CAUSTICS in flags))}
	command.params_1={f32(lightness),f32(rotation)}
	copy_slice(command.rotmat_0[:],rotation_matrix[0][:])
	copy_slice(command.rotmat_1[:],rotation_matrix[1][:])
	copy_slice(command.rotmat_2[:],rotation_matrix[2][:])
	for _ in 0..<QUAD_VERTS {
		_,err:=append_soa_elem(commands,command)
		assert(err==.None) }}
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
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.rotmat_2[0],n)
	bind_texture(gl.TEXTURE0,state.textures[name].handle)
	texture_wrapping(gl.CLAMP_TO_EDGE)
	texture_filtering(gl.NEAREST)
	draw_triangles(i32(6*n))
	runtime.clear_soa_dynamic_array(commands) }
render_text_group::proc(name:string) {
	use_shader(state.font_shader)
	commands,ok:=&state.text_draw_commands[name]; if !ok do return
	n:=len(commands); if n==0 do return
	font:=&state.fonts[name]
	set_shader_param(state.font_shader.this_buffer_res,cast_array(state.resolution,f32))
	set_shader_param(state.font_shader.symbol_size,[2]f32{f32(font.symbol_size.x),f32(font.symbol_size.y)})
	bind_vertex_array(0)
	i:int=0
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.symbols[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.positions[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.scale_factors[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.colors[0],n)
	bind_texture(gl.TEXTURE0,state.textures[font.name].handle)
	texture_filtering(gl.NEAREST)
	draw_triangles(i32(6*n)) }
render_bloom_threshold::proc(render_buffer:^Render_Buffer) {
	use_shader(state.bloom_threshold_shader)
	bind_texture(gl.TEXTURE0,render_buffer.texture_handles[0])
	draw_triangles(6) }
render_blur::proc(render_buffer:^Render_Buffer,step:i8) {
	use_shader(state.blur_shader)
	set_shader_param(state.blur_shader.resolution,cast_array(state.resolution,f32))
	set_shader_param(state.blur_shader.step,i32(step))
	bind_texture(gl.TEXTURE0,render_buffer.texture_handles[0])
	draw_triangles(6) }
render_bloom::proc(base_render_buffer:^Render_Buffer,bloom_render_buffer:^Render_Buffer) {
	use_shader(state.bloom_shader)
	set_shader_param(state.bloom_shader.grayscale,i32(.DEAD in state.flags))
	bind_texture(gl.TEXTURE0,base_render_buffer.texture_handles[0])
	bind_texture(gl.TEXTURE1,bloom_render_buffer.texture_handles[0])
	draw_triangles(6) }
init_shader_params::proc($Type:typeid,shader:^Type) {
	field_names:=reflect.struct_field_names(Type)
	field_offsets:=reflect.struct_field_offsets(Type)
	field_types:=reflect.struct_field_types(Type)
	for param,i in field_names {
		#partial switch type:=reflect.type_kind(field_types[i].id); type {
		case reflect.Type_Kind.Integer:
			((^i32)(uintptr(shader)+field_offsets[i]))^=get_shader_param_handle(u32(shader.handle),field_names[i])
		case reflect.Type_Kind.Array:
		case reflect.Type_Kind.Named:
			continue
		case:
			fmt.println(" Shader \"",shader.vert_name,shader.frag_name,"\" has parameter field \"",param,"\" of invalid type. Ignoring field.",sep="") }}}
init_shader::proc(name:string,$Type:typeid,$vert_name:string,$frag_name:string)->(shader:^Type) {
	shader=new(Type)
	shader.name=strings.clone(name)
	shader.vert_name,shader.frag_name=strings.clone(vert_name),strings.clone(frag_name)
	_,err:=append(&state.shaders,&shader.shader)
	if err!=.None { return nil }
	ok,_:=compile_shader(shader,context.allocator,vert_name,frag_name)
	if !ok { return nil }
	init_shader_params(Type,shader)
	return shader }
init_shaders::proc() {
	state.shaders=make([dynamic]^Shader,0,7)
	state.texture_shader=init_shader("texture",Texture_Shader,"./shaders/vtexture.glsl","./shaders/ftexture.glsl"); assert(state.texture_shader!=nil)
	state.buffer_shader=init_shader("buffer",Buffer_Shader,"./shaders/vfill.glsl","./shaders/fbuffer.glsl"); assert(state.buffer_shader!=nil)
	state.bloom_threshold_shader=init_shader("bloom-threshold",Bloom_Threshold_Shader,"./shaders/vfill.glsl","./shaders/fbloom_threshold.glsl"); assert(state.bloom_threshold_shader!=nil)
	state.blur_shader=init_shader("blur",Blur_Shader,"./shaders/vfill.glsl","./shaders/fblur.glsl"); assert(state.blur_shader!=nil)
	state.bloom_shader=init_shader("bloom",Bloom_Shader,"./shaders/vfill.glsl","./shaders/fbloom.glsl"); assert(state.bloom_shader!=nil)
	state.font_shader=init_shader("font",Font_Shader,"./shaders/vfont.glsl","./shaders/ffont.glsl"); assert(state.font_shader!=nil)
	state.rect_shader=init_shader("rect",Rect_Shader,"./shaders/vrect.glsl","./shaders/frect.glsl"); assert(state.rect_shader!=nil)
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.resolution,cast_array(state.resolution,f32)) }
print_glsl_error::proc(message:string,message_type:gl.Shader_Type,shader:^Shader,vert_string:string,frag_string:string) {
	content:string
	#partial switch message_type {
	case gl.Shader_Type.VERTEX_SHADER: content=vert_string
	case gl.Shader_Type.FRAGMENT_SHADER: content=frag_string
	case: fmt.println(" ",shader.name,": ",message_type,": ",message,": ?",sep="") }
	bl:=strings.index_rune(message,'(')
	br:=strings.index_rune(message,')')
	line_n:=strconv.parse_int(message[bl+1:br]) or_else -1
	line:=nth_line(content,line_n-1)
	fmt.println(" ",message_type,"/",shader.name,"(",line_n,")",": ",":\n",message,": \n",line,sep="") }
compile_shader::proc(shader:^Shader,allocator:=context.allocator,$vert_name:string,$frag_name:string)->(ok:bool,err_loc:runtime.Source_Code_Location) {
	vert_source,frag_source,extended_vert_name,extended_frag_name:string
	if ((shader.vert_name!="")&&(shader.frag_name!="")) {
		vert_source=#load(vert_name)
		frag_source=#load(frag_name) }
	else if ((shader.vert_source!="")&&(shader.frag_source!="")) {
		vert_source=shader.vert_source
		frag_source=shader.frag_source }
	else { return false,#location() }
	file_handle:os.Handle
	vert_string:string=strings.concatenate({GLSL_VERSION_STRING,"\n",vert_source})
	frag_string:string=strings.concatenate({GLSL_VERSION_STRING,"\n",frag_source})
	handle,success:=gl.load_shaders_source(vert_string,frag_string)
	compile_message,compile_message_type,link_message,_:=gl.get_last_error_messages()
	if(compile_message_type!=.NONE)&&(len(compile_message)>0) {
		print_glsl_error(compile_message,compile_message_type,shader,vert_string,frag_string) }
	if len(link_message) > 0 {
		print_glsl_error(link_message,compile_message_type,shader,vert_string,frag_string) }
	if ! success { return false,#location() }
	shader.handle = cast(u32)handle
	shader.last_compile_time = time.now()
	return true,{} }
swap_buffers::proc() {
	glfw.SwapBuffers(state.window) }
texture_filtering::proc(mode:i32) {
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,mode)
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,mode) }
texture_wrapping::proc(mode:i32) {
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,mode)
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,mode) }
resolution_callback::proc"c"(window:glfw.WindowHandle,width,height:i32) {
	context=runtime.default_context()
	state.window_size=[2]u16{u16(width),u16(height)}
	state.resolution=state.window_size
	gl.Viewport(0,0,i32(state.window_size.x),i32(state.window_size.y))
	delete_render_buffer(state.default_sb)
	delete_render_buffer(state.bloom_sb)
	state.default_sb=make_render_buffer_static(state.window_size,1,{gl.RGBA8},{gl.RGBA}); assert(state.default_sb!=nil)
	state.bloom_sb=make_render_buffer_static(state.window_size,1,{gl.RGBA8},{gl.RGBA}); assert(state.bloom_sb!=nil)
	state.settings.window_size=(state.settings.display==.WINDOWED)?state.window_size:DEFAULT_WINDOW_SIZE
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.resolution,cast_array(state.resolution,f32))
	init_view()	}
error_callback::proc"c"(source:u32,type:u32,id:u32,severity:u32,length:i32,message:cstring,userParam:rawptr) {
	context=runtime.default_context()
	if severity>gl.DEBUG_SEVERITY_NOTIFICATION do fmt.println(source,type,id,severity,length,message) }
render_text::proc(args:..any,sep:string="",pos:[2]f16={0,0},color:[4]f16=WHITE,scale_multiplier:f16=1.0,pivot:bit_set[Compass]={},font_name:string="font-medium",shadow:bool=true,spacing:f16=1.0,waviness:f16=0.0) {
	_,commands,_,_:=map_entry(&state.text_draw_commands,font_name)
	if cap(commands)==0 do commands^=make_soa_dynamic_array_len_cap(#soa[dynamic]Text_Draw_Command,length=0,capacity=TEXT_COMMANDS_CAP)
	text:=fmt.aprint(..args,sep=sep)
	pos:=pos
	font:=&state.fonts[font_name]; if font==nil do return
	width:f16=f16(len(text))*f16(font.symbol_size.x)*spacing
	height:f16=f16(font.symbol_size.y)
	pos=pos-0.5*{width,height}+0.5*cast_array(font.symbol_size,f16)
	if .EAST in pivot { pos.x-=0.5*width }
	if .WEST in pivot { pos.x+=0.5*width }
	if .NORTH in pivot { pos.y-=0.5*height }
	if .SOUTH in pivot { pos.y+=0.5*height }
	use_shader(state.font_shader)
	set_shader_param(state.font_shader.this_buffer_res,cast_array(state.resolution,f32))
	set_shader_param(state.font_shader.symbol_size,[2]f32{f32(font.symbol_size.x),f32(font.symbol_size.y)})
	sym_pos:[2]f16=pos
	for c,i in text {
		command:Text_Draw_Command
		command.symbols=f32(c)
		wavy_offset:f16=waviness*f16(math.sin(3.12*state.net_time+f32(i))+math.cos(7.31*state.net_time+f32(i)))
		command.positions=[3]f32{f32(sym_pos.x),f32(sym_pos.y+wavy_offset),0}
		command.scale_factors=f32(scale_multiplier)
		command.colors=cast_array(color,f32)
		sym_pos.x+=spacing*f16(font.symbol_size.x)
		for _ in 0..<QUAD_VERTS do append_soa_elem(commands,command) }}
glfw_error_callback::proc"c"(error:i32,description:cstring) {
	context=runtime.default_context()
	fmt.println("glfw error",error,description) }
init_draw::proc() {
	init_glfw()
	init_gl()
	init_shaders()
	use_shader(state.texture_shader)
	state.default_sb=make_render_buffer_static(state.window_size,1,{gl.RGBA8},{gl.RGBA}); assert(state.default_sb!=nil)
	state.bloom_sb=make_render_buffer_static(state.window_size,1,{gl.RGBA8},{gl.RGBA}); assert(state.bloom_sb!=nil) }
destroy_renderer::proc() {
	delete_render_buffer(state.default_sb)
	delete_render_buffer(state.bloom_sb)
	glfw.DestroyWindow(state.window)
	glfw.Terminate() }
draw_tick::proc() {
	set_blend(true)
	state.texture_draw_commands=make_map_cap(map[string]#soa[dynamic]Texture_Draw_Command,capacity=TEXTURE_GROUPS_CAP,allocator=context.allocator)
	state.text_draw_commands=make_map_cap(map[string]#soa[dynamic]Text_Draw_Command,capacity=TEXT_GROUPS_CAP,allocator=context.allocator)
	clear_frame_buffer(0)
	clear_render_buffer(state.default_sb)
	select_render_buffer(state.default_sb)
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.time,f32(state.net_time))
	set_shader_param(state.texture_shader.view_matrix,&state.view_matrix)
	set_shader_param(state.texture_shader.view_zoom,f32(state.view_zoom))
	switch state.control_state.screen {
	case .GAME: render_board()
	case .MENU: render_menu() }
	set_depth_test(true)
	for name,_ in state.texture_draw_commands do render_texture_group(name)
	select_render_buffer(state.bloom_sb)
	set_depth_test(false)
	render_bloom_threshold(state.default_sb)
	render_blur(state.bloom_sb,1)
	render_blur(state.bloom_sb,2)
	render_blur(state.bloom_sb,4)
	select_frame_buffer(0)
	render_bloom(state.default_sb,state.bloom_sb)
	set_depth_test(false)
	for name,_ in state.text_draw_commands do render_text_group(name)
	swap_buffers() }
get_windowed_mode_resolution::proc()->[2]u16 {
	return state.settings.window_size }
get_fullscreen_mode_resolution::proc()->[2]u16 {
	monitor:=glfw.GetPrimaryMonitor()
	video_mode:=glfw.GetVideoMode(monitor)
	return {u16(video_mode.width),u16(video_mode.height)} }
set_display_windowed::proc() {
	monitor:=glfw.GetPrimaryMonitor()
	state.window_size=(state.settings.display==.FULLSCREEN)?DEFAULT_WINDOW_SIZE:state.settings.window_size
	video_mode:=glfw.GetVideoMode(monitor)
	glfw.SetWindowMonitor(state.window,nil,video_mode.width/2-i32(state.window_size.x)/2,video_mode.height/2-i32(state.window_size.y)/2,i32(state.window_size.x),i32(state.window_size.y),0)
	state.settings.display=.WINDOWED }
set_display_fullcreen::proc() {
	monitor:=glfw.GetPrimaryMonitor()
	video_mode:=glfw.GetVideoMode(monitor)
	glfw.SetWindowMonitor(state.window,monitor,0,0,video_mode.width,video_mode.height,video_mode.refresh_rate)
	state.settings.display=.FULLSCREEN }
// get_vertex_array::proc(index:int)->u32 {
// 	if index>=len(state.vertex_arrays) do add_vertex_array()
// 	return state.vertex_arrays[index] }
// get_vertex_buffer::proc(index:int)->u32 {
// 	if index>=len(state.vertex_buffers) do add_vertex_buffer()
// 	return state.vertex_buffers[index] }
// set_vertex_array::proc(index:int,value:u32) {
// 	if index>=len(state.vertex_arrays) do add_vertex_array()
// 	state.vertex_arrays[index]=value }
// set_vertex_buffer::proc(index:int,value:u32) {
// 	if index>=len(state.vertex_buffers) do add_vertex_buffer()
// 	state.vertex_buffers[index]=value }
add_vertex_array::proc() {
	append(&state.vertex_arrays,0)
	gl.GenVertexArrays(1,&state.vertex_arrays[len(state.vertex_arrays)-1]) }
add_vertex_buffer::proc() {
	append(&state.vertex_buffers,0)
	gl.GenBuffers(1,&state.vertex_buffers[len(state.vertex_buffers)-1]) }
bind_vertex_array::proc(index:int) {
	if index>=len(state.vertex_arrays) do add_vertex_array()
	gl.BindVertexArray(state.vertex_arrays[index]) }
bind_vertex_buffer::proc(index:int) {
	if index>=len(state.vertex_buffers) do add_vertex_buffer()
	gl.BindBuffer(gl.ARRAY_BUFFER,state.vertex_buffers[index]) }
upload_vertex_buffer_data::proc(attribute_index:Attribute_Index,vbo_index:VBO_Index,type:u32,data:^$T,n_commands:int) {
	bind_vertex_buffer(int(vbo_index))
	gl.BufferData(gl.ARRAY_BUFFER,n_commands*size_of(T),data,gl.DYNAMIC_DRAW)
	gl.VertexAttribPointer(u32(attribute_index),i32(len(T) when intrinsics.type_is_array(T) else 1),type,false,0,0)
	gl.EnableVertexAttribArray(u32(attribute_index)) }