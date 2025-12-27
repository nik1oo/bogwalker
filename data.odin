#+feature dynamic-literals
package bogwalker
import "core:image"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:mem"
import "core:math/linalg"
import "vendor:glfw"
import "vendor:miniaudio"
import gl "vendor:OpenGL"
import fs "vendor:fontstash"
BOUNDED_RUNTIME::#config(BOUNDED_RUNTIME,false)
TRANSPARENT:[4]f16:{0,0,0,0}
BLACK:[4]f16:{0,0,0,1}
WHITE:[4]f16:{1,1,1,1}
YELLOW:[4]f16:{1,1,0,1}
RED:[4]f16:{1,0,0,1}
GREEN:[4]f16:{0,1,0,1}
BLUE:[4]f16:{0,0,1,1}
AUX_BUF_FMT::gl.RGB12
TILE_SIZE::64
GLSL_VERSION_STRING::"#version 460 core"
PERIOD_UNLIMITED_NSEC:i64:0
PERIOD_30FPS_NSEC:i64:33_333_333
PERIOD_60FPS_NSEC:i64:16_666_666
PERIOD_120FPS_NSEC:i64:8_333_333
PERIOD_144FPS_NSEC:i64:6_944_444
PERIOD_240FPS_NSEC:i64:4_166_666
PERIOD_540FPS_NSEC:i64:1_851_851
Attribute_Index::distinct u32
VBO_Index::distinct int
TEXTURE_GROUPS_CAP::24
TEXT_GROUPS_CAP::4
TEXTURE_COMMANDS_CAP::4096
TEXT_COMMANDS_CAP::8192
state:^State=nil
DEFAULT_WINDOW_SIZE:[2]u16:{1728,972}
LAYER_BELOW_SURFACE::0.4
LAYER_SURFACE::0.5
LAYER_ABOVE_SURFACE::0.4
MENU_J::4
MENU_START_I::BOARD_SIZE_MENU.x/2-3
MENU_DISPLAY_I::BOARD_SIZE_MENU.x/2-1
MENU_AUDIO_I::BOARD_SIZE_MENU.x/2+1
MENU_EXIT_I::BOARD_SIZE_MENU.x/2+3
DEFAULT_VIEW_ZOOM::0.625
FISH_NAME:string:"fish"
FISHES_NAME:string:"fishes"
CROC_HEAD_NAME:string:"krokul"
CROC_TAIL_NAME:string:"croc-tail"
START_NAME:string:"start"
DISPLAY_NAME:string:"display"
AUDIO_NAME:string:"audio"
EXIT_NAME:string:"exit"
DIRECTION_STEP:map[Compass][2]i8={
	.EAST=[2]i8{+1,0},
	.WEST=[2]i8{-1,0},
	.NORTH=[2]i8{0,+1},
	.SOUTH=[2]i8{0,-1}}
QUAD_VERTS::6
DEFAULT_DISPLAY_SETTING::0
DEFAULT_AUDIO_SETTING::1.0
Flags::bit_set[enum{INPUT_RECEIVED,AUDIO_MENU_DRAWN,HIGHSCORE_SET,DEAD,VICTORIOUS,RUNNING,FULLSCREEN,}]
entity_names:map[Entity_Kind]string
matrix3_identity:=linalg.MATRIX3F32_IDENTITY
State::struct {
	font_atlas_handle:u32,
	glyph_infos:map[rune]Glyph_Info,
	marker_kind:Entity_Kind,
	flags:Flags,
	texture_draw_commands:map[string]#soa[dynamic]Texture_Draw_Command,
	text_draw_commands:map[string]#soa[dynamic]Text_Draw_Command,
	vertex_arrays:[dynamic]u32,
	vertex_buffers:[dynamic]u32,
	settings:Settings,
	highscores:Highscores,
	control_state:Control_State,
	hovered_name:string,
	hovered_name_stable:string,
	hovered_pos:Maybe([2]i8),
	view_top_left:[2]f16,
	view_bottom_right:[2]f16,
	view_pan:[2]f16,
	view_zoom_pivot:f16,
	view_zoom:f16,
	view_scale:f16,
	view_matrix:matrix[3,3]f32,
	arena:mem.Arena,
	board:Board,
	window_size:[2]u16,
	windowed_mode_resolution:[2]u16,
	resolution:[2]u16,
	window:glfw.WindowHandle,
	shaders:[dynamic]^Shader,
	textures:map[string]Texture,
	fonts:map[string]Font,
	sounds:map[string]Sound,
	ma_rm:miniaudio.resource_manager,
	ma_res:miniaudio.result,
	ma_rm_conf:miniaudio.resource_manager_config,
	ma_ctx:miniaudio.context_type,
	ma_dev_infos:[^]miniaudio.device_info,
	ma_dev_count:u32,
	ma_devs:[16]miniaudio.device,
	ma_dev_confs:[^]miniaudio.device_config,
	ma_engs:[16]miniaudio.engine,
	ma_audio_engine:^miniaudio.engine,
	ma_eng_confs:[^]miniaudio.engine_config,
	ma_default_device_index:int,
	mouse_pos:[2]f32,
	cursor:[2]f32,
	cursor_delta:[2]f32,
	mouse_delta:[2]f32,
	keys_pressed:bit_set[Key],
	old_keys_pressed:bit_set[Key],
	keys_switched:bit_set[Key],
	mouse_pressed:bit_set[Mouse_Button],
	old_mouse_pressed:bit_set[Mouse_Button],
	mouse_switched:bit_set[Mouse_Button],
	texture_shader:^Texture_Shader,
	buffer_shader:^Buffer_Shader,
	bloom_threshold_shader:^Bloom_Threshold_Shader,
	bloom_shader:^Bloom_Shader,
	blur_shader:^Blur_Shader,
	outline_shader:^Outline_Shader,
	blend_shader:^Blend_Shader,
	font_shader:^Font_Shader,
	rect_shader:^Rect_Shader,
	glyph_shader:^Glyph_Shader,
	point_shader:^Point_Shader,
	frame_count:u64,
	tick_count:u64,
	fps:f32,
	timer:time.Stopwatch,
	play_timer:time.Stopwatch,
	frame_timer:time.Stopwatch,
	draw_tick_timer:time.Stopwatch,
	update_time:f32,
	net_time:f32,
	play_time:f32,
	frame_time:f32,
	hover_time:f32,
	default_render_buffer:Render_Buffer,
	bloom_render_buffer:Render_Buffer,
	icons_and_text_render_buffer:Render_Buffer,
	current_render_buffer:^Render_Buffer }
Texture_Draw_Command::struct {
	pos:[2]f32,
	size:[2]f32,
	params_0:[4]f32,
	params_1:[2]f32,
	rotmat_0:[3]f32,
	rotmat_1:[3]f32,
	rotmat_2:[3]f32,
	space:[1]i32 }
Text_Draw_Command::struct {
	symbols:f32,
	positions:[3]f32,
	scale_factors:f32,
	colors:[4]f32 }
Difficulty::enum u8 {
	BEGINNER,
	EASY,
	MEDIUM,
	HARD }
Savefile::struct {
	settings:Settings,
	highscores:Highscores }
Highscores::[4]f32
Settings::struct {
	display:enum u8 { WINDOWED,FULLSCREEN },
	window_size:[2]u16,
	audio:f16 }
Control_State::struct {
	screen:enum { MENU,GAME },
	submenu:enum { NONE,START,DISPLAY,AUDIO,EXIT },
	drag:f16 }
Texture::struct {
	name:string,
	handle:u32,
	size:[2]u16,
	image:^image.Image }
Font::struct {
	name:string,
	symbol_size:[2]u8 }
Rect::struct($T:typeid) {
	pos:[2]T,
	size:[2]T }
Compass::enum u8 { EAST,WEST,NORTH,SOUTH }
Sound::struct {
	name:string,
	filepath:string,
	cfilepath:cstring,
	duration:f32,
	start_time:f32,
	sound:miniaudio.sound,
	loop:bool }
Render_Buffer::struct {
	initialized:bool,
	frame_buffer_handle:u32,
	texture_handle:u32,
	texture_format:u32,
	texture_internal_format:i32,
	render_buffer_handle:u32,
	size:[2]u16 }
Shader::struct {
	name:string,
	handle:u32,
	vert_name,frag_name:string,
	vert_source,frag_source:string,
	last_compile_time:time.Time }
Font_Shader::struct {
	using shader:Shader,
	symbol,pos,this_buffer_res,symbol_size,text_color,scale_multiplier:i32 }
Rect_Shader::struct {
	using shader:Shader,
	pos,size,fill_color,resolution,rounding,depth:i32 }
Texture_Shader::struct {
	using shader:Shader,
	pos,size,rotation,resolution,depth,time,flip_y,lightness,view_matrix,view_zoom,rotation_matrix,waves,caustics,windy:i32 }
Buffer_Shader::struct {
	using shader:Shader }
Bloom_Threshold_Shader::struct {
	using shader:Shader }
Bloom_Shader::struct {
	grayscale:i32,
	using shader:Shader }
Blur_Shader::struct {
	using shader:Shader,
	resolution,step:i32 }
Outline_Shader::struct {
	using shader:Shader,
	resolution,size,stroke_color:i32 }
Blend_Shader::struct {
	using shader:Shader }
Glyph_Shader::struct {
	using shader:Shader,
	pos,size,resolution,s0,s1,t0,t1,fill_color:i32 }
Point_Shader::struct {
	using shader:Shader,
	pos,resolution,point_color,depth:i32 }
Space::enum u8 { WORLD,SCREEN }
Mouse_Button::enum u8 { MOUSE_LEFT,MOUSE_RIGHT }
Key::enum u8 { Q,W,E,F,R,ESCAPE,SPACE,ONE,TWO,THREE }
Entity_Kind::enum u8 { HERO,KROKUL,IGNESA,BACKA,BORDANA,BRAGUL,DRAKUL,DURRUL,GRENDUL,MOOSUL,NOKUR,RIHTUL,RUSALKA,TRUL,VONDUL }
Cell_Flags::enum u8 { WAVY,CAUSTICS,WINDY }
Cell_Flags_Register::bit_set[Cell_Flags]
PI:f16:3.14159265358979323846264338327950288
DIRECTION_ROTATION:[4]f16={-0.5*PI,0.5*PI,0,PI}
Entity::struct {
	kind:Entity_Kind,
	direction:Compass }
Fish::struct {
	seed:f32,
	cluster:bool,
	position:[2]f16,
	direction:[2]f16 }
Board::struct {
	size:[2]i8,
	difficulty:Difficulty,
	vision:[][]bool,
	cells:[][]Maybe(Entity),
	projected_cell_rects:[][]Rect(f16),
	seeds:[][]u32,
	flags:[][]Maybe(Entity),
	threats:[][]i8,
	estimated_threats:[][]i8,
	entities:[dynamic][2]i8,
	n_flags:u8,
	fishes:[dynamic]Fish,
	last_click:Maybe([2]i8),
	untouched:bool }
Glyph_Info::struct {
	quad:fs.Quad,
	glyph:fs.Glyph }
init_data::proc() {
	state=new(State)
	state.marker_kind=.KROKUL
	state.flags+={.RUNNING}
	state.textures=make(map[string]Texture,37)
	state.fonts=make(map[string]Font,4)
	state.sounds=make(map[string]Sound,13)
	state.vertex_arrays=make([dynamic]u32)
	state.vertex_buffers=make([dynamic]u32)
	state.control_state.screen=.MENU }
init_assets::proc() {
	load_texture_from_filepath("./images/bottom-1.png")
	load_texture_from_filepath("./images/bottom-2.png")
	load_texture_from_filepath("./images/bottom-3.png")
	load_texture_from_filepath("./images/bottom-4.png")
	load_texture_from_filepath("./images/surface-1.png")
	load_texture_from_filepath("./images/surface-2.png")
	load_texture_from_filepath("./images/surface-3.png")
	load_texture_from_filepath("./images/surface-4.png")
	load_texture_from_filepath("./images/croc-head.png")
	load_texture_from_filepath("./images/croc-tail.png")
	load_texture_from_filepath("./images/fish.png")
	load_texture_from_filepath("./images/fishes.png")
	load_texture_from_filepath("./images/crab.png")
	load_texture_from_filepath("./images/line-1.png")
	load_texture_from_filepath("./images/line-2.png")
	load_texture_from_filepath("./images/line-3.png")
	load_texture_from_filepath("./images/line-4.png")
	load_texture_from_filepath("./images/whiteline-1.png")
	load_texture_from_filepath("./images/whiteline-2.png")
	load_texture_from_filepath("./images/whiteline-3.png")
	load_texture_from_filepath("./images/whiteline-4.png")
	load_texture_from_filepath("./images/whiteline-end.png")
	load_texture_from_filepath("./images/start.png")
	load_texture_from_filepath("./images/display.png")
	load_texture_from_filepath("./images/audio.png")
	load_texture_from_filepath("./images/exit.png")
	load_texture_from_filepath("./images/lotus.png")
	load_texture_from_filepath("./images/iris.png")
	load_texture_from_filepath("./images/marigold.png")
	load_texture_from_filepath("./images/lily.png")
	load_texture_from_filepath("./images/buoy.png")
	load_texture_from_filepath("./images/title-0.png")
	load_texture_from_filepath("./images/title-1.png")
	load_texture_from_filepath("./images/krokul.png")
	load_texture_from_filepath("./images/ignesa.png")
	load_texture_from_filepath("./images/grendul.png")
	load_texture_from_filepath("./images/bordana.png")
	load_texture_from_filepath("./images/nokur.png")
	load_texture_from_filepath("./images/backa.png")
	load_texture_from_filepath("./images/vondul.png")
	load_texture_from_filepath("./images/rusalka.png")
	load_texture_from_filepath("./images/durrul.png")
	load_texture_from_filepath("./images/bragul.png")
	load_texture_from_filepath("./images/drakul.png")
	load_texture_from_filepath("./images/moosul.png")
	load_texture_from_filepath("./images/rihtul.png")
	load_texture_from_filepath("./images/trul.png")
	load_texture_from_filepath("./images/hero.png")
	load_font("./images/font.png")
	load_font("./images/font-title.png")
	load_font("./images/font-huge.png")
	load_font("./images/font-medium.png")
	load_sound("./sounds/water.wav",seconds(40)+milliseconds(485))
	load_sound("./sounds/victory.wav",milliseconds(453))
	load_sound("./sounds/defeat.wav")
	load_sound("./sounds/clear0.wav")
	load_sound("./sounds/clear1.wav")
	load_sound("./sounds/clear2.wav")
	load_sound("./sounds/clear3.wav")
	load_sound("./sounds/clear4.wav")
	load_sound("./sounds/clear5.wav")
	load_sound("./sounds/clear6.wav")
	load_sound("./sounds/clear7.wav")
	load_sound("./sounds/clear8.wav")
	load_sound("./sounds/clear9.wav")
	entity_names=make(map[Entity_Kind]string)
	entity_names[.HERO]="hero"
	entity_names[.KROKUL]="krokul"
	entity_names[.IGNESA]="ignesa"
	entity_names[.GRENDUL]="grendul"
	entity_names[.BORDANA]="bordana"
	entity_names[.NOKUR]="nokur"
	entity_names[.BACKA]="backa"
	entity_names[.VONDUL]="vondul"
	entity_names[.RUSALKA]="rusalka"
	entity_names[.DURRUL]="durrul"
	entity_names[.BRAGUL]="bragul"
	entity_names[.DRAKUL]="drakul"
	entity_names[.MOOSUL]="moosul"
	entity_names[.RIHTUL]="rihtul"
	entity_names[.TRUL]="trul" }