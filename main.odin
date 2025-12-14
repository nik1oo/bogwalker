package bogwalker
import "core:mem"
import "core:fmt"
import "core:math/rand"
import "vendor:glfw"
main::proc() {
	init_data()
	init_savefile()
	init_draw()
	init_assets()
	init_sound()
	init_clock()
	start_level(.BEGINNER)
	mem.arena_init(&state.arena,make([]u8,8_388_608))
	context.allocator=mem.arena_allocator(&state.arena)
	init_view()
	for state.frame_count=0; (!glfw.WindowShouldClose(state.window))&&(.RUNNING in state.flags); state.frame_count+=1 {
		rand.reset(u64(transmute(u32)state.net_time))
		input_tick()
		if !should_update() do continue
		clock_tick()
		game_tick()
		draw_tick()
		sound_tick()
		mem.arena_free_all(&state.arena)
		state.tick_count+=1
		when BOUNDED_RUNTIME do if state.tick_count==600 do break }
	destroy_renderer()
	save_savefile() }