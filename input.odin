#+feature dynamic-literals
package bogwalker
import "base:runtime"
import "vendor:glfw"
import "core:math"
import "core:fmt"
import tracy "shared:tracy"
keymap:map[i32]Key = {
	'F'=Key.F,
	'R'=Key.R,
	glfw.KEY_ESCAPE=Key.ESCAPE }
input_tick::proc() {
	when TRACY_ENABLE { tracy.ZoneN("input tick") }
	state.flags-={.INPUT_RECEIVED}
	glfw.PollEvents() }
key_callback::proc"c"(window:glfw.WindowHandle,key,scancode,action,mods:i32) {
	context=runtime.default_context()
	// fmt.println("key",key,action)
	state.flags+={.INPUT_RECEIVED}
	if key in keymap {
		switch(action) {
		case glfw.PRESS: state.keys_pressed+={keymap[key]}
		case glfw.REPEAT: state.keys_pressed+={keymap[key]}
		case glfw.RELEASE: state.keys_pressed-={keymap[key]} } } }
scroll_callback::proc"c"(window:glfw.WindowHandle,dx,dy:f64) {
	state.flags+={.INPUT_RECEIVED}
	if state.control_state.screen==.GAME do state.view_zoom_pivot=clamp(state.view_zoom_pivot+f16(dy)*0.05*state.view_zoom_pivot,0.025,2) }
cursor_pos_callback::proc"c"(window:glfw.WindowHandle,x,y:f64) {
	context=runtime.default_context()
	state.flags+={.INPUT_RECEIVED}
	@(static) called:bool=false
	mouse_pos:=[2]f32{f32(x),f32(state.resolution.y)-f32(y)}
	if called {
		state.mouse_delta=mouse_pos-state.mouse_pos
	}
	// if (abs(state.mouse_delta.x)<100)&&(abs(state.mouse_delta.y)<100) {
	// 	state.mouse_delta={0,0} }
	state.mouse_pos=mouse_pos
	if state.control_state.screen==.GAME do if mouse_pressed(.MOUSE_RIGHT) {
		state.view_pan+=cast_array(state.mouse_delta,f16)/state.view_zoom }
	state.cursor+=state.mouse_delta/f32(state.view_zoom)
	state.cursor=mouse_pos-{f32(state.window_size.x)/2,f32(state.window_size.y)/2}
	state.cursor.x=min(max(state.cursor.x,-f32(state.window_size.x)/2),f32(state.window_size.x)/2)
	state.cursor.y=min(max(state.cursor.y,-f32(state.window_size.y)/2),f32(state.window_size.y)/2)
	state.cursor_delta=state.mouse_delta
	called=true }
mouse_button_callback::proc"c"(window:glfw.WindowHandle,button,action,mods:i32) {
	context=runtime.default_context()
	// fmt.println("mouse button",button,action)
	state.flags+={.INPUT_RECEIVED}
	// if action==glfw.PRESS do fmt.println("mouse was pressed"); else do fmt.println("mouse was released")
	switch button {
	case glfw.MOUSE_BUTTON_LEFT:
		if action==glfw.PRESS do state.mouse_pressed+={Mouse_Button.MOUSE_LEFT}
		if action==glfw.RELEASE do state.mouse_pressed-={Mouse_Button.MOUSE_LEFT}
	case glfw.MOUSE_BUTTON_RIGHT:
		if action==glfw.PRESS do state.mouse_pressed+={Mouse_Button.MOUSE_RIGHT}
		if action==glfw.RELEASE do state.mouse_pressed-={Mouse_Button.MOUSE_RIGHT} }
	if action==glfw.PRESS||action==glfw.RELEASE { }}
mouse_pressed::proc(button:Mouse_Button)->bool {
	return (button in state.mouse_pressed) }
mouse_was_pressed::proc(button:Mouse_Button)->bool {
	return (button in state.mouse_pressed)&&(button in state.mouse_switched) }
mouse_was_switched::proc(button:Mouse_Button)->bool {
	return (button in state.mouse_switched) }
key_was_pressed::proc(key:Key)->bool {
	return (key in state.keys_pressed)&&(key in state.keys_switched) }
mouse_was_released::proc(button:Mouse_Button)->bool {
	return (button in state.mouse_pressed==false)&&(button in state.mouse_switched) }