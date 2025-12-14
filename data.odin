#+feature dynamic-literals
package bogwalker
import "core:image"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:mem"
import "vendor:glfw"
import "vendor:miniaudio"
import gl "vendor:OpenGL"
BOUNDED_RUNTIME::#config(BOUNDED_RUNTIME,false)
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
Layer:struct{BOTTOM,CROCODILES,FISHES,SURFACE,FLOWERS,GUI_LINES,GUI_ICONS,GUI_TEXT:f16}:{0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1}
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
State::struct {
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
	hovered_pos:[2]i8,
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
	blend_shader:^Blend_Shader,
	font_shader:^Font_Shader,
	rect_shader:^Rect_Shader,
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
	default_sb:^Render_Buffer,
	bloom_sb:^Render_Buffer }
Texture_Draw_Command::struct #packed {
	pos:[2]f32,
	size:[2]f32,
	params_0:[4]f32,
	params_1:[2]f32,
	rotmat_0:[3]f32,
	rotmat_1:[3]f32,
	rotmat_2:[3]f32 }
Text_Draw_Command::struct #packed {
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
	texture_handles:[]u32,
	texture_formats:[]u32,
	texture_internal_formats:[]i32,
	render_buffer_handle:u32,
	size:[2]u16,
	n_frames:i16 }
Shader::struct {
	name:string,
	handle:u32,
	vert_name,frag_name:string,
	vert_source,frag_source:string,
	last_compile_time:time.Time }
Font_Shader::struct {
	using shader:Shader,
	symbol:i32,
	pos:i32,
	this_buffer_res:i32,
	symbol_size:i32,
	text_color:i32,
	scale_multiplier:i32 }
Rect_Shader::struct {
	using shader:Shader,
	pos:i32,
	size:i32,
	fill_color:i32,
	this_buffer_res:i32,
	main_buffer_res:i32,
	blue_noise_res:i32,
	threshold_res:i32,
	time:i32,
	rounding:i32 }
Texture_Shader::struct {
	using shader:Shader,
	pos:i32,
	size:i32,
	rotation:i32,
	resolution:i32,
	depth:i32,
	time:i32,
	flip_y:i32,
	lightness:i32,
	view_matrix:i32,
	view_zoom:i32,
	rotation_matrix:i32,
	waves:i32,
	caustics:i32,
	windy:i32 }
Buffer_Shader::struct {
	using shader:Shader }
Bloom_Threshold_Shader::struct {
	using shader:Shader }
Bloom_Shader::struct {
	grayscale:i32,
	using shader:Shader }
Blur_Shader::struct {
	using shader:Shader,
	resolution:i32,
	step:i32 }
Blend_Shader::struct {
	using shader:Shader }
Mouse_Button::enum u8 { MOUSE_LEFT,MOUSE_RIGHT }
Key::enum u8 { Q,W,E,F,R,ESCAPE,SPACE,ONE,TWO,THREE }
Entity_Kind::enum u8 { KROKUL,IGNESA,BACKA,BORDANA,BRAGUL,DRAKUL,DURRUL,GRENDUL,MOOSUL,NOKUR,RIHTUL,RUSALKA,TRUL,VONDUL }
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
	flags:[][]bool,
	threats:[][]i8,
	estimated_threats:[][]i8,
	entities:[dynamic][2]i8,
	n_flags:u8,
	fishes:[dynamic]Fish,
	last_click:[2]i8,
	untouched:bool }
init_data::proc() {
	state=new(State)
	state.flags+={.RUNNING}
	state.textures=make(map[string]Texture,37)
	state.fonts=make(map[string]Font,4)
	state.sounds=make(map[string]Sound,13)
	state.control_state.screen=.MENU }
init_assets::proc() {
	read_and_load_texture("./images/bottom-1.png")
	read_and_load_texture("./images/bottom-2.png")
	read_and_load_texture("./images/bottom-3.png")
	read_and_load_texture("./images/bottom-4.png")
	read_and_load_texture("./images/surface-1.png")
	read_and_load_texture("./images/surface-2.png")
	read_and_load_texture("./images/surface-3.png")
	read_and_load_texture("./images/surface-4.png")
	read_and_load_texture("./images/croc-head.png")
	read_and_load_texture("./images/croc-tail.png")
	read_and_load_texture("./images/fish.png")
	read_and_load_texture("./images/fishes.png")
	read_and_load_texture("./images/crab.png")
	read_and_load_texture("./images/line-1.png")
	read_and_load_texture("./images/line-2.png")
	read_and_load_texture("./images/line-3.png")
	read_and_load_texture("./images/line-4.png")
	read_and_load_texture("./images/whiteline-1.png")
	read_and_load_texture("./images/whiteline-2.png")
	read_and_load_texture("./images/whiteline-3.png")
	read_and_load_texture("./images/whiteline-4.png")
	read_and_load_texture("./images/whiteline-end.png")
	read_and_load_texture("./images/start.png")
	read_and_load_texture("./images/display.png")
	read_and_load_texture("./images/audio.png")
	read_and_load_texture("./images/exit.png")
	read_and_load_texture("./images/lotus.png")
	read_and_load_texture("./images/iris.png")
	read_and_load_texture("./images/marigold.png")
	read_and_load_texture("./images/lily.png")
	read_and_load_texture("./images/buoy.png")
	read_and_load_texture("./images/title-0.png")
	read_and_load_texture("./images/title-1.png")
	read_and_load_texture("./images/krokul.png")
	read_and_load_texture("./images/ignesa.png")
	read_and_load_texture("./images/grendul.png")
	read_and_load_texture("./images/bordana.png")
	read_and_load_texture("./images/nokur.png")
	read_and_load_texture("./images/backa.png")
	read_and_load_texture("./images/vondul.png")
	read_and_load_texture("./images/rusalka.png")
	read_and_load_texture("./images/durrul.png")
	read_and_load_texture("./images/bragul.png")
	read_and_load_texture("./images/moosul.png")
	read_and_load_texture("./images/rihtul.png")
	read_and_load_texture("./images/trul.png")
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
	entity_names[.MOOSUL]="moosul"
	entity_names[.RIHTUL]="rihtul"
	entity_names[.TRUL]="trul" }