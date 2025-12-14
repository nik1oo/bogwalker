package bogwalker
import "core:time"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:slice"
import "core:sys/windows"
rect_left::proc "fastcall"(rect:Rect($T))->T {
	return rect.pos.x-rect.size.x/2 }
rect_right::proc "fastcall"(rect:Rect($T))->T {
	return rect.pos.x+rect.size.x/2 }
rect_bottom::proc "fastcall"(rect:Rect($T))->T {
	return rect.pos.y-rect.size.y/2 }
rect_top::proc "fastcall"(rect:Rect($T))->T {
	return rect.pos.y+rect.size.y/2 }
in_rect::proc "fastcall"(point:[2]$T,rect:Rect(T))->bool {
	return (point.x>rect_left(rect))&&(point.x<rect_right(rect))&&(point.y>rect_bottom(rect))&&(point.y<rect_top(rect)) }
zero_and_start_timer::proc(timer:^time.Stopwatch) {
	time.stopwatch_reset(timer)
	time.stopwatch_start(timer) }
pause_timer::proc(timer:^time.Stopwatch) {
	time.stopwatch_stop(timer) }
read_timer::proc(timer:^time.Stopwatch)->f32 {
	return f32(time.duration_seconds(time.stopwatch_duration(timer^))) }
clock_tick::proc() {
	state.frame_time=f32(read_timer(&state.frame_timer))
	zero_and_start_timer(&state.frame_timer)
	state.net_time = read_timer(&state.timer)
	state.play_time = read_timer(&state.play_timer)
	if state.frame_count%30==0 { state.fps=f32(f32(state.frame_count)/state.net_time) } }
make_if_none::proc(dir:string)->(was_none:bool) {
	if os.exists(dir)==false {
		handle,errno:=os.open(dir,os.O_CREATE,0o777)
		assert(errno==os.ERROR_NONE)
		os.close(handle)
		return true }
	else {
		return false }}
open_or_make::proc(dir:string)->(os.Handle,os.Errno) {
	if os.exists(dir)==false {
		handle,errno:=os.open(dir,os.O_CREATE,0o777)
		if errno!=os.ERROR_NONE { return 0,0 }
		os.close(handle) }
	return os.open(dir,os.O_RDWR) }
read_file::proc(filename:string)->(res:string,ok:bool) #optional_ok {
	bytes,success:=os.read_entire_file_from_filename(filename)
	return string(bytes),success }
nth_line::proc(text:string,target_line:int)->(res:string) {
	curr_line:=0
	for r,i in text {
		if r=='\n' { curr_line+=1 }
		if curr_line==target_line {
			cap:=strings.index_rune(text[i+1:],'\n')
			return text[i:i+cap+1] } }
	return "" }
cast_array::proc{cast_array2,cast_array3,cast_array4}
cast_array4::proc "fastcall"(x:[4]$T1,$T2:typeid)->(y:[4]T2) {
	return[4]T2{T2(x[0]),T2(x[1]),T2(x[2]),T2(x[3])} }
cast_array3::proc "fastcall"(x:[3]$T1,$T2:typeid)->(y:[3]T2) {
	return[3]T2{T2(x[0]),T2(x[1]),T2(x[2])} }
cast_array2::proc "fastcall"(x:[2]$T1,$T2:typeid)->(y:[2]T2) {
	return[2]T2{T2(x[0]),T2(x[1])} }
name_from_path::proc(path:string)->string {
	return strings.clone(filepath.stem(filepath.base(path))) }
in_range::proc { in_range_int,in_range_f32,in_range_2int,in_range_2f32 }
in_range_int::proc(#any_int x:int,#any_int lo:int,#any_int hi:int)->bool {
	return (x>=lo)&&(x<=hi) }
in_range_f16::proc(x:f16,lo:f16,hi:f16)->bool {
	return (x>=lo)&&(x<=hi) }
in_range_f32::proc(x:f32,lo:f32,hi:f32)->bool {
	return (x>=lo)&&(x<=hi) }
in_range_2int::proc(p:[2]int,lo:[2]int,hi:[2]int)->bool {
	return (p.x>=lo.x)&&(p.x<=hi.x)&&(p.y>=lo.y)&&(p.y<=hi.y) }
in_range_2f16::proc(p:[2]f16,lo:[2]f16,hi:[2]f16)->bool {
	return (p.x>=lo.x)&&(p.x<=hi.x)&&(p.y>=lo.y)&&(p.y<=hi.y) }
in_range_2f32::proc(p:[2]f32,lo:[2]f32,hi:[2]f32)->bool {
	return (p.x>=lo.x)&&(p.x<=hi.x)&&(p.y>=lo.y)&&(p.y<=hi.y) }
project_rect::proc "fastcall"(rect:Rect($T),mat:matrix[3,3]f32)->(Rect(T)) {
	pos:[3]f32=mat*[3]f32{f32(rect.pos.x),f32(rect.pos.y),1}
	size:=rect.size*T(mat[0][0])
	return Rect(T){{T(pos.x),T(pos.y)},{T(size.x),T(size.y)}} }
seconds::proc(s:f32)->f32 { return s }
milliseconds::proc(ms:f32)->(s:f32) { return ms/1000 }
init_clock::proc() {
	zero_and_start_timer(&state.timer)
	zero_and_start_timer(&state.frame_timer)
	zero_and_start_timer(&state.draw_tick_timer) }
make_2d_slice::proc($T:typeid,w:int,h:int)->[][]T {
	result:[][]T=make([][]T,w)
	for _,i in result do result[i]=make([]T,h)
	return result }
delete_2d_slice::proc(array:[][]$T) {
	// TODO
}
fill_2d_slice::proc(array:[][]$T, value: T) {
	for _,i in array do slice.fill(array[i], value) }
clone_2d_slice::proc(array:[][]$T)->(result:[][]T) {
	result=make_2d_slice(T,len(array),len(array[0]))
	for _,i in array do for _,j in array[0] do result[i][j]=array[i][j]
	return result }
make_square::proc(center:[2]i8,radius:i8,board_size:[2]i8)->[][2]i8 {
	square:[dynamic][2]i8=make_dynamic_array([dynamic][2]i8)
	for i in center.x-radius..=center.x+radius do for j in center.y-radius..=center.y+radius {
		if (i<0)||(j<0)||(i>=board_size.x)||(j>=board_size.y) do continue
		append(&square,[2]i8{i,j}) }
	return square[:] }
// make_rhomb_offsets::proc()->[][2]i8 {
// }