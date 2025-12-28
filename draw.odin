package bogwalker
import "base:runtime"
import "base:intrinsics"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:math"
import la "core:math/linalg"
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
	polygon_mode(gl.FILL)
	set_blend(true)
	gl.Enable(gl.DEPTH_TEST)
	gl.DepthFunc(gl.LESS)
	gl.FrontFace(gl.CW)
	gl.Disable(gl.CULL_FACE)
	gl.CullFace(gl.FRONT)
	gl.BlendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA) }
polygon_mode::proc(mode:u32) {
	gl.PolygonMode(gl.FRONT_AND_BACK,mode) }
select_render_buffer::proc(render_buffer:^Render_Buffer) {
	state.current_render_buffer=render_buffer
	if render_buffer==nil {
		select_frame_buffer(0)
		return }
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	gl.Viewport(0,0,i32(state.resolution.x),i32(state.resolution.y)) }
clear_render_buffer::proc(render_buffer:^Render_Buffer,color:[4]f16) {
	gl.ClearColor(cast(f32)color.r,cast(f32)color.g,cast(f32)color.b,cast(f32)color.a)
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Clear(gl.DEPTH_BUFFER_BIT) }
select_frame_buffer::proc(frame_buffer_handle:u32) {
	state.current_render_buffer=nil
	gl.BindFramebuffer(gl.FRAMEBUFFER,frame_buffer_handle)
	gl.Viewport(0,0,i32(state.window_size.x),i32(state.window_size.y)) }
clear_frame_buffer::proc(frame_buffer_handle:u32) {
	gl.BindFramebuffer(gl.FRAMEBUFFER,frame_buffer_handle)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	gl.Clear(gl.DEPTH_BUFFER_BIT) }
init_render_buffer::proc(render_buffer:^Render_Buffer,size:[2]u16,internal_format:i32,format:u32,depth_component:bool=true) {
	render_buffer^={initialized=true,size=size,texture_format=format,texture_internal_format=internal_format}
	gl.GenFramebuffers(1,(^u32)(&render_buffer.frame_buffer_handle))
	gl.BindFramebuffer(gl.FRAMEBUFFER,u32(render_buffer.frame_buffer_handle))
	gl.GenTextures(1,(^u32)(&render_buffer.texture_handle))
	gl.BindTexture(gl.TEXTURE_2D,u32(render_buffer.texture_handle))
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE)
	gl.TexParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE)
	gl.TexImage2D(gl.TEXTURE_2D,0,internal_format,i32(size.x),i32(size.y),0,format,gl.UNSIGNED_BYTE,nil)
	texture_filtering(gl.NEAREST)
	gl.BindTexture(gl.TEXTURE_2D,0)
	gl.FramebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,u32(render_buffer.texture_handle),0)
	assert(gl.CheckFramebufferStatus(gl.FRAMEBUFFER)==gl.FRAMEBUFFER_COMPLETE)
	gl.GenRenderbuffers(1,(^u32)(&render_buffer.render_buffer_handle))
	if depth_component {
		gl.BindRenderbuffer(gl.RENDERBUFFER,u32(render_buffer.render_buffer_handle))
		gl.RenderbufferStorage(gl.RENDERBUFFER,gl.DEPTH_COMPONENT32,i32(size.x),i32(size.y))
		gl.FramebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.RENDERBUFFER,u32(render_buffer.render_buffer_handle)) }
	assert(gl.CheckFramebufferStatus(gl.FRAMEBUFFER)==gl.FRAMEBUFFER_COMPLETE) }
delete_render_buffer::proc(render_buffer:^Render_Buffer) {
	if render_buffer==nil { return }
	gl.DeleteFramebuffers(1,(^u32)(&render_buffer.frame_buffer_handle))
	gl.DeleteTextures(1,(^u32)(&render_buffer.texture_handle))
	gl.DeleteRenderbuffers(1,(^u32)(&render_buffer.render_buffer_handle)) }
get_shader_param_handle::proc(shader_handle:u32,param_name:string)->(handle:i32) {
	cstr:cstring=strings.clone_to_cstring(param_name)
	handle=gl.GetUniformLocation(shader_handle,cstr)
	delete(cstr)
	return handle }
UNIT_MATRIX::la.MATRIX3F32_IDENTITY
pan_matrix::proc(offset:[2]f32)->matrix[3,3]f32 {
	return matrix[3,3]f32 {
		1,0,offset.x,
		0,1,offset.y,
		0,0,1 }}
rotate_matrix::proc(angle:f32)->matrix[3,3]f32 {
	return matrix[3,3]f32 {
		la.cos(angle),-la.sin(angle),0,
		la.sin(angle),la.cos(angle),0,
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
	gl.ActiveTexture(gl.TEXTURE0+binding_point)
	gl.BindTexture(gl.TEXTURE_2D,u32(handle)) }
draw_triangles::proc(count:i32,depth_test:bool) {
	set_depth_test(depth_test)
	gl.DrawArrays(gl.TRIANGLES,0,count) }
draw_points::proc(count:i32,depth_test:bool) {
	set_depth_test(depth_test)
	gl.DrawArrays(gl.POINTS,0,count) }
draw_lines::proc(count:i32,depth_test:bool) {
	set_depth_test(depth_test)
	gl.DrawArrays(gl.LINES,0,count) }
use_shader::proc(shader:^$T,loc:=#caller_location)->(^T) {
	assert(shader!=nil,loc=loc); assert(shader.handle!=0,loc=loc)
	gl.UseProgram(u32(shader.handle))
	return shader }
set_blend::proc(value:bool) {
	if value { gl.Enable(gl.BLEND) } else { gl.Disable(gl.BLEND) } }
set_depth_test::proc(value:bool) {
	if value { gl.Enable(gl.DEPTH_TEST) } else { gl.Disable(gl.DEPTH_TEST) } }
render_text_group::proc(name:string) {
	use_shader(state.font_shader)
	commands,ok:=&state.text_draw_commands[name]; if !ok do return
	n:=len(commands); if n==0 do return
	font:=&state.fonts[name]
	set_shader_param(state.font_shader.this_buffer_res,la.array_cast(state.resolution,f32))
	set_shader_param(state.font_shader.symbol_size,[2]f32{f32(font.symbol_size.x),f32(font.symbol_size.y)})
	bind_vertex_array(0)
	i:int=0
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.symbols[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.positions[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.scale_factors[0],n); i+=1
	upload_vertex_buffer_data(Attribute_Index(i),VBO_Index(i),gl.FLOAT,&commands.colors[0],n)
	bind_texture(0,state.textures[font.name].handle)
	texture_filtering(gl.NEAREST)
	draw_triangles(i32(6*n),depth_test=true) }
render_bloom_threshold::proc(render_buffer:^Render_Buffer) {
	use_shader(state.bloom_threshold_shader)
	bind_texture(0,render_buffer.texture_handle)
	draw_triangles(6,depth_test=false) }
render_blur::proc(render_buffer:^Render_Buffer,step:i8) {
	use_shader(state.blur_shader)
	set_shader_param(state.blur_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.blur_shader.step,i32(step))
	bind_texture(0,render_buffer.texture_handle)
	draw_triangles(6,depth_test=false) }
render_outline::proc(render_buffer:^Render_Buffer,stroke_color:[4]f16,size:u8) {
	use_shader(state.outline_shader)
	set_shader_param(state.outline_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.outline_shader.size,i32(size))
	set_shader_param(state.outline_shader.stroke_color,la.array_cast(stroke_color,f32))
	bind_texture(0,render_buffer.texture_handle)
	draw_triangles(6,depth_test=false) }
render_render_buffer::proc(render_buffer:^Render_Buffer,alpha:f16=1.0) {
	use_shader(state.buffer_shader)
	bind_texture(0,render_buffer.texture_handle)
	set_shader_param(state.buffer_shader.alpha,f32(alpha))
	draw_triangles(6,depth_test=false) }
render_rect::proc(rect:Rect(f16),color:[4]f32,rounding:f32,depth:f32) {
	use_shader(state.rect_shader)
	set_shader_param(state.rect_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.rect_shader.pos,la.array_cast(rect.pos,f32))
	set_shader_param(state.rect_shader.size,la.array_cast(rect.size,f32))
	set_shader_param(state.rect_shader.fill_color,color)
	set_shader_param(state.rect_shader.rounding,rounding)
	set_shader_param(state.rect_shader.depth,depth)
	draw_triangles(6,depth_test=true) }
// DICK
// render_tile::proc(name:string,rect:Rect(f16),depth:f32) {
// 	use_shader(state.rect_shader)
// 	set_shader_param(state.rect_shader.resolution,la.array_cast(state.resolution,f32))
// 	set_shader_param(state.rect_shader.pos,la.array_cast(rect.pos,f32))
// 	set_shader_param(state.rect_shader.size,la.array_cast(rect.size,f32))
// 	set_shader_param(state.rect_shader.fill_color,color)
// 	set_shader_param(state.rect_shader.rounding,rounding)
// 	set_shader_param(state.rect_shader.depth,depth)
// 	draw_triangles(6,depth_test=true) }
render_point::proc(pos:[2]f16,size:f16,color:[3]f32,depth:f32) {
	gl.UseProgram(state.point_shader.handle)
	gl.PointSize(auto_cast size)
	set_shader_param(state.point_shader.pos,la.array_cast(pos,f32))
	set_shader_param(state.point_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.point_shader.point_color,color)
	set_shader_param(state.point_shader.depth,depth)
	draw_points(1,depth_test=true) }
render_bloom::proc(base_render_buffer:^Render_Buffer,bloom_render_buffer:^Render_Buffer) {
	use_shader(state.bloom_shader)
	// TEMP
	// set_shader_param(state.bloom_shader.grayscale,i32(.DEAD in state.flags))
	bind_texture(0,base_render_buffer.texture_handle)
	bind_texture(1,bloom_render_buffer.texture_handle)
	draw_triangles(6,depth_test=false) }
render_shadow::proc(foreground_render_buffer:^Render_Buffer,background_render_buffer:^Render_Buffer,length:u8,blur:u8,opacity:f16) {
	prev_render_buffer:=state.current_render_buffer
	defer select_render_buffer(prev_render_buffer)
	select_render_buffer(&state.scratch_render_buffer)
	use_shader(state.shadow_shader)
	set_shader_param(state.shadow_shader.resolution,la.array_cast(state.resolution,f32))
	set_shader_param(state.shadow_shader.length,i32(length))
	set_shader_param(state.shadow_shader.opacity,1.0)
	bind_texture(0,foreground_render_buffer.texture_handle)
	draw_triangles(6,depth_test=false)
	for i in 0..<blur do render_blur(&state.scratch_render_buffer,auto_cast math.pow_f32(2,auto_cast i))
	select_render_buffer(background_render_buffer)
	render_render_buffer(&state.scratch_render_buffer,alpha=opacity) }
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
	state.texture_shader=init_shader("texture",Texture_Shader,"./shaders/vtexture.glsl","./shaders/ftexture.glsl")
	state.buffer_shader=init_shader("buffer",Buffer_Shader,"./shaders/vfill.glsl","./shaders/fbuffer.glsl")
	state.bloom_threshold_shader=init_shader("bloom-threshold",Bloom_Threshold_Shader,"./shaders/vfill.glsl","./shaders/fbloom_threshold.glsl")
	state.blur_shader=init_shader("blur",Blur_Shader,"./shaders/vfill.glsl","./shaders/fblur.glsl")
	state.bloom_shader=init_shader("bloom",Bloom_Shader,"./shaders/vfill.glsl","./shaders/fbloom.glsl")
	state.outline_shader=init_shader("outline",Outline_Shader,"./shaders/vfill.glsl","./shaders/foutline.glsl")
	state.font_shader=init_shader("font",Font_Shader,"./shaders/vfont.glsl","./shaders/ffont.glsl")
	state.rect_shader=init_shader("rect",Rect_Shader,"./shaders/vrect.glsl","./shaders/frect.glsl")
	state.glyph_shader=init_shader("glyph",Glyph_Shader,"./shaders/vglyph.glsl","./shaders/fglyph.glsl")
	state.point_shader=init_shader("point",Point_Shader,"./shaders/vpoint.glsl","./shaders/fpoint.glsl")
	state.shadow_shader=init_shader("shadow",Shadow_Shader,"./shaders/vfill.glsl","./shaders/fshadow.glsl")
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.resolution,la.array_cast(state.resolution,f32)) }
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
	delete_render_buffer(&state.default_render_buffer)
	delete_render_buffer(&state.bloom_render_buffer)
	init_render_buffer(&state.default_render_buffer,state.window_size,gl.RGBA8,gl.RGBA)
	init_render_buffer(&state.bloom_render_buffer,state.window_size,gl.RGBA8,gl.RGBA)
	state.settings.window_size=(state.settings.display==.WINDOWED)?state.window_size:DEFAULT_WINDOW_SIZE
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.resolution,la.array_cast(state.resolution,f32))
	init_view()	}
error_callback::proc"c"(source:u32,type:u32,id:u32,severity:u32,length:i32,message:cstring,userParam:rawptr) {
	context=runtime.default_context()
	if severity>gl.DEBUG_SEVERITY_NOTIFICATION do fmt.println(source,type,id,severity,length,message) }
// _render_text::proc(args:..any,sep:string="",pos:[2]f16={0,0},color:[4]f16=WHITE,scale_multiplier:f16=1.0,pivot:bit_set[Compass]={},font_name:string="font-medium",shadow:bool=true,spacing:f16=1.0,waviness:f16=0.0) {
// 	_,commands,_,_:=map_entry(&state.text_draw_commands,font_name)
// 	if cap(commands)==0 do commands^=make_soa_dynamic_array_len_cap(#soa[dynamic]Text_Draw_Command,length=0,capacity=TEXT_COMMANDS_CAP)
// 	text:=fmt.aprint(..args,sep=sep)
// 	pos:=pos
// 	font:=&state.fonts[font_name]; if font==nil do return
// 	width:f16=f16(len(text))*f16(font.symbol_size.x)*spacing
// 	height:f16=f16(font.symbol_size.y)
// 	pos=pos-0.5*{width,height}+0.5*la.array_cast(font.symbol_size,f16)
// 	if .EAST in pivot { pos.x-=0.5*width }
// 	if .WEST in pivot { pos.x+=0.5*width }
// 	if .NORTH in pivot { pos.y-=0.5*height }
// 	if .SOUTH in pivot { pos.y+=0.5*height }
// 	use_shader(state.font_shader)
// 	set_shader_param(state.font_shader.this_buffer_res,la.array_cast(state.resolution,f32))
// 	set_shader_param(state.font_shader.symbol_size,[2]f32{f32(font.symbol_size.x),f32(font.symbol_size.y)})
// 	sym_pos:[2]f16=pos
// 	for c,i in text {
// 		command:Text_Draw_Command
// 		command.symbols=f32(c)
// 		wavy_offset:f16=waviness*f16(math.sin(3.12*state.net_time+f32(i))+math.cos(7.31*state.net_time+f32(i)))
// 		command.positions=[3]f32{f32(sym_pos.x),f32(sym_pos.y+wavy_offset),0}
// 		command.scale_factors=f32(scale_multiplier)
// 		command.colors=la.array_cast(color,f32)
// 		sym_pos.x+=spacing*f16(font.symbol_size.x)
// 		for _ in 0..<QUAD_VERTS do append_soa_elem(commands,command) }}
glfw_error_callback::proc"c"(error:i32,description:cstring) {
	context=runtime.default_context()
	fmt.println("glfw error",error,description) }
init_draw::proc() {
	init_glfw()
	init_gl()
	init_shaders()
	init_fontstash()
	use_shader(state.texture_shader)
	init_render_buffer(&state.default_render_buffer,state.window_size,gl.RGBA8,gl.RGBA)
	init_render_buffer(&state.bloom_render_buffer,state.window_size,gl.RGBA8,gl.RGBA)
	init_render_buffer(&state.icons_and_text_render_buffer,state.window_size,gl.RGBA8,gl.RGBA)
	init_render_buffer(&state.scratch_render_buffer,state.window_size,gl.RGBA8,gl.RGBA) }
destroy_renderer::proc() {
	delete_render_buffer(&state.default_render_buffer)
	delete_render_buffer(&state.bloom_render_buffer)
	delete_render_buffer(&state.icons_and_text_render_buffer)
	delete_render_buffer(&state.scratch_render_buffer)
	glfw.DestroyWindow(state.window)
	glfw.Terminate() }
draw_tick::proc() {
	state.texture_draw_commands=make_map_cap(map[string]#soa[dynamic]Texture_Draw_Command,capacity=TEXTURE_GROUPS_CAP,allocator=context.allocator)
	state.text_draw_commands=make_map_cap(map[string]#soa[dynamic]Text_Draw_Command,capacity=TEXT_GROUPS_CAP,allocator=context.allocator)
	clear_frame_buffer(0)
	gl.ClearColor(0,0,0,1)
	clear_render_buffer(&state.default_render_buffer,GRAY)
	clear_render_buffer(&state.icons_and_text_render_buffer,TRANSPARENT)
	clear_render_buffer(&state.scratch_render_buffer,TRANSPARENT)
	select_render_buffer(&state.default_render_buffer)
	use_shader(state.texture_shader)
	set_shader_param(state.texture_shader.time,f32(state.net_time))
	set_shader_param(state.texture_shader.view_matrix,&state.view_matrix)
	set_shader_param(state.texture_shader.view_zoom,f32(state.view_zoom))
	switch state.control_state.screen {
	case .GAME: render_board()
	case .MENU: render_menu() }
	render_texture_groups()
	select_render_buffer(&state.bloom_render_buffer)
	render_bloom_threshold(&state.default_render_buffer)
	render_blur(&state.bloom_render_buffer,1)
	render_blur(&state.bloom_render_buffer,2)
	render_blur(&state.bloom_render_buffer,4)
	select_frame_buffer(0)
	render_bloom(&state.default_render_buffer,&state.bloom_render_buffer)
	select_render_buffer(&state.icons_and_text_render_buffer)
	render_outline(&state.icons_and_text_render_buffer,BLACK,1)
	// DICK
	render_shadow(&state.icons_and_text_render_buffer,nil,2,2,0.3)
	// render_blur(&state.icons_and_text_render_buffer,1)
	select_frame_buffer(0)
	render_render_buffer(&state.icons_and_text_render_buffer)
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
upload_vertex_buffer_data::proc(attribute_index:Attribute_Index,vbo_index:VBO_Index,$type:u32,data:^$T,n_commands:int) {
	// fmt.printfln("attribute index: %v", cast(int)attribute_index)
	// fmt.printfln("element type: %v", type_info_of(T))
	// fmt.printfln("element size: %v", size_of(T))
	bind_vertex_buffer(int(vbo_index))
	gl.BufferData(gl.ARRAY_BUFFER,n_commands*size_of(T),data,gl.DYNAMIC_DRAW)
	// fmt.println("array length:", i32(len(T) when intrinsics.type_is_array(T) else 1))
	// fmt.println("element type:", type)
	when type==gl.FLOAT do gl.VertexAttribPointer(u32(attribute_index),i32(len(T) when intrinsics.type_is_array(T) else 1),type,false,0,0)
	else do gl.VertexAttribIPointer(u32(attribute_index),i32(len(T) when intrinsics.type_is_array(T) else 1),type,0,0)
	gl.EnableVertexAttribArray(u32(attribute_index)) }