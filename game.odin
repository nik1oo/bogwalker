package bogwalker
import "base:runtime"
import "core:fmt"
import "core:c"
import "core:math"
import "core:math/linalg"
import "core:slice"
import "core:math/rand"
import "core:time"
seed_board::proc(board:^Board) {
	for i in 0..<board.size.x { for j in 0..<board.size.y {
		board.seeds[i][j]=u32(rand.int31()) }}
	// board.seeds[MENU_START_I][MENU_J]+=50_000_000
	// board.seeds[MENU_DISPLAY_I][MENU_J]+=50_000_000
	// board.seeds[MENU_AUDIO_I][MENU_J]+=50_000_000
	// board.seeds[MENU_EXIT_I][MENU_J]+=50_000_000
	}
clear_board::proc(board:^Board) {
	for i in 0..<board.size.x do for j in 0..<board.size.y {
		board.vision[i][j]=false
		board.cells[i][j]=nil
		fill_2d_slice(board.projected_cell_rects, Rect(f16){})
		fill_2d_slice(board.flags,false) }
	clear_dynamic_array(&board.fishes) }
random_direction::proc(pool:[]Compass)->Compass {
	i:=rand.int31_max(i32(len(pool)))
	return pool[i] }
despawn_entity::proc(board:^Board,i,j:i8) {
	// entity,ok:=board.cells[i][j].?
	// if !ok do return
	// index,found:=slice.linear_search(board.entities[:],[2]i8{i,j})
	// if found do unordered_remove(&board.entities,index)
	// board.threats[i][j]=0
	// board.cells[i][j]=nil
}
spawn_entity::proc(board:^Board,i,j:i8,entity_kind:Entity_Kind,direction:Compass) {
	if cell_occupied(board,i,j) do return
	board.cells[i][j]=Entity{entity_kind,direction}
	fmt.println("putting entity on", [2]i8{i,j})
	append(&board.entities,[2]i8{i,j}) }
CROC_DIRECTIONS:[4]Compass={.EAST,.WEST,.NORTH,.SOUTH}
init_board::proc(difficulty:Difficulty) {
	// DICK
	context.allocator=runtime.heap_allocator()
	state.board.difficulty=difficulty
	if state.control_state.screen==.GAME {
		switch difficulty {
		case .BEGINNER: state.board.size=BOARD_SIZE_BEGINNER
		case .EASY: state.board.size=BOARD_SIZE_EASY
		case .MEDIUM: state.board.size=BOARD_SIZE_MEDIUM
		case .HARD: state.board.size=BOARD_SIZE_HARD }}
	else {
		state.board.size=BOARD_SIZE_MENU }
	state.board.entities=make_dynamic_array_len_cap([dynamic][2]i8,0,128)
	state.board.vision=make_2d_slice(bool,cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.cells=make_2d_slice(Maybe(Entity),cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.projected_cell_rects=make_2d_slice(Rect(f16),cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.seeds=make_2d_slice(u32,cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.flags=make_2d_slice(bool,cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.threats=make_2d_slice(i8,cast(int)state.board.size.x,cast(int)state.board.size.y)
	state.board.estimated_threats=make_2d_slice(i8,cast(int)state.board.size.x,cast(int)state.board.size.y)
	clear_board(&state.board)
	clear(&state.board.entities)
	state.board.n_flags=0
	if state.control_state.screen==.GAME do populate_board(&state.board,difficulty)
	else do menu_board(&state.board)
	seed_board(&state.board)
	state.flags-={.DEAD}
	state.flags-={.VICTORIOUS}
	state.flags-={.HIGHSCORE_SET}
	state.board.untouched=true
	//reveal_random(&state.board)
	// TEMP
	if state.control_state.screen==.GAME do board_set_vision(&state.board,false)
	// TEMP
	// DICK
	calculate_threats(&state.board)
	board_tick()
	zero_and_start_timer(&state.play_timer) }
menu_board::proc(board:^Board) {
	set_depth_test(true)
	i,j:i8; board_iterator(&i,&j)
	for iterate_board(board,&i,&j) do if cells_distance(BOARD_SIZE_MENU.x/2,BOARD_SIZE_MENU.y/2,i,j)>(8+i8(rand.int31_max(16))) do board.vision[i][j]=true }
random_normalized_vector::proc()->[2]f16 {
	return linalg.normalize([2]f16{f16(rand.float32())*2-1,f16(rand.float32())*2-1}) }
random_fish::proc(board:^Board)->Fish {
	return Fish{seed=rand.float32(),cluster=bool(rand.int31_max(2)),position={f16(rand.float32_range(1,f32(board.size.x-1))),f16(rand.float32_range(1,f32(board.size.y-1)))},direction=random_normalized_vector()} }
// reveal_board::proc(board:^Board) {
// 	i,j:i8; board_iterator(&i,&j)
// 	for iterate_board(board,&i,&j) do board.vision[i][j]=true }
board_set_vision::proc(board:^Board,vision:bool) {
	i,j:i8; board_iterator(&i,&j)
	for iterate_board(board,&i,&j) do board.vision[i][j]=vision }
// hide_board::proc(board:^Board) {
// 	i,j:i8; board_iterator(&i,&j)
// 	for iterate_board(board,&i,&j) do board.vision[i][j]=true }
hide_entities::proc(board:^Board) {
	for pos in board.entities do board.vision[pos.x][pos.y]=false }
hide_enclosed::proc(board:^Board) {
	for i in 0..<board.size.x do for j in 0..<board.size.y {
		if board.vision[i][j]==false do continue
		if i>0 do if board.threats[i-1][j]==0 do continue
		if i<board.size.x-1 do if board.threats[i+1][j]==0 do continue
		if j>0 do if board.threats[i][j-1]==0 do continue
		if j<board.size.y-1 do if board.threats[i][j+1]==0 do continue
		board.vision[i][j]=false }}
hide_semienclosed::proc(board:^Board) {
	for i in 0..<board.size.x do for j in 0..<board.size.y {
		n_adjacent_threats:int=0
		offsets:=[?][2]i8{{-1,0},{1,0},{0,-1},{0,1}}
		for offset in offsets {
			m:i8=i+offset.x
			n:i8=j+offset.y
			if (m<0)||(n<0)||(m>=board.size.x)||(n>=board.size.y) do continue
			if board.threats[m][n]>0 do n_adjacent_threats+=1 }
		if n_adjacent_threats>=3 do board.vision[i][j]=false }}
spawn_entities::proc(board:^Board,entity_kind:Entity_Kind,density:f32,cluster_density:int,cluster_size:int) {
	i,j:i8; board_iterator(&i,&j)
	for iterate_board(board,&i,&j) do if rand.float32()<density {
		spawn_entity(board,i,j,entity_kind,Compass(rand.int31_max(4)))
		// TEMP
		// if cluster_density>0 {
		// 	for l in 0..<cluster_density {
		// 		w:[2]i8={i,j}
		// 		for k in 0..<cluster_size do w+=DIRECTION_STEP[Compass(rand.int31_max(4))]
		// 		if inside_board(board,w.x,w.y) do spawn_entity(board,w.x,w.y,entity_kind,Compass(rand.int31_max(4))) }}
	}}
despawn_invalid_entities::proc(board:^Board) {
	/// remove ignesas that have a bait outside the board
}
populate_board::proc(board:^Board,difficulty:Difficulty) {
	spawn_entities(board,.KROKUL,0.04,0,32)
	// spawn_entities(board,.IGNESA,0.005,0,32)
	// spawn_entities(board,.GRENDUL,0.02,0,32)
	// spawn_entities(board,.BORDANA,0.02,0,32)
	// TEMP
	// board.fishes=runtime.make_dynamic_array_len_cap([dynamic]Fish,0,100)
	// for k in 0..=100 {
	// 	append_elem(&board.fishes,random_fish(board))
	// 	rand.reset(u64(k)) }
	}
entity_pos::proc(i,j:f16)->[2]f16 {
	return [2]f16{(f16(i)-f16(state.board.size.x-1)/2)*TILE_SIZE,(f16(j)-f16(state.board.size.y-1)/2)*TILE_SIZE} }
render_entity::proc(entity:Entity,i,j:i8) {
	render_cell(name=entity_names[entity.kind],i=f16(i),j=f16(j),layer=Layer.CROCODILES,flags={.WAVY}) }
render_whiteline::proc(i,j0,j1:f16) {
	render_cell(name="whiteline-end",i=f16(i),j=f16(j1+1),layer=Layer.GUI_LINES)
	for j in j0..=j1 do render_cell(name="whiteline-1",i=f16(i),j=f16(j),layer=Layer.GUI_LINES)
	render_cell(name="whiteline-end",i=f16(i),j=f16(j0-1),direction=.SOUTH,layer=Layer.GUI_LINES) }
all_entities_are_flagged::proc(board:^Board)->bool {
	for entity,_ in board.entities do if !entity_is_flagged(board,entity.x,entity.y) do return false
	return true }
render_cell::proc(name:string,i,j:f16,extra_rotation:f16=0,direction:Compass=.NORTH,layer:f16=Layer.BOTTOM,flags:Cell_Flags_Register={}) {
	pos:[2]f16=entity_pos(i,j)
	// @(static) DIRECTION_ROTATION:[4]f16={-0.5*math.PI,0.5*math.PI,0,math.PI}
	rotation:f16=DIRECTION_ROTATION[int(direction)]+extra_rotation
	hovered:=(!mouse_pressed(.MOUSE_LEFT))&&inside_board(&state.board,f16(i),f16(j))?in_rect(cast_array(state.cursor,f16),state.board.projected_cell_rects[int(i)][int(j)]):false
	render_texture(name=name,pos=pos,size={TILE_SIZE,TILE_SIZE},rotation=rotation,depth=layer,lightness=hovered?(0.6+0.05*f16(math.sin(8*state.net_time))):(state.board.last_click==[2]i8{auto_cast i,auto_cast j})?0.7:0.5,flags=flags)
	if hovered do state.hovered_name=name }
render_fish::proc(fish:Fish) {
	render_cell(name=fish.seed<0.1?FISHES_NAME:FISH_NAME,i=auto_cast fish.position.x,j=auto_cast fish.position.y,extra_rotation=0.1*f16(math.sin(4*state.net_time)),layer=Layer.FISHES,flags={.WAVY,.CAUSTICS}) }
// clear_cell::proc(board:^Board,i,j:int) {
// 	deep_entity,found_deep:=board.cells[i][j].?
// 	if found_deep&&(deep_entity.kind==.CROC_HEAD) do despawn_entity(board,i,j)
// 	else if found_deep&&(deep_entity.kind==.CROC_TAIL) do despawn_entity(board,i,j) }
entity_is_flagged::proc(board:^Board,i,j:i8)->bool {
	entity,ok:=board.cells[i][j].?
	if !ok do return false
	return board.flags[i][j] }
cell_occupied::proc(board:^Board,i,j:i8)->bool {
	return board.cells[i][j]!=nil }
fish_tick::proc(fish:^Fish) {
	// board:^Board=&state.board
	// t:=state.net_time
	// speed:=f16(0+(1-math.pow(math.sin(f32(t+fish.seed*100)),6)))
	// fish.direction=linalg.normalize(fish.direction+0.01*random_normalized_vector())
	// fish.position+=1.2*fish.direction*speed*f16(state.frame_time)
	// if !inside_board(board,fish.position.x,fish.position.y) {
	// 	fish.direction*=-1 }
	}
LINE_NAMES:=[?]string{"line-1","line-2","line-3","line-4"}
FLOWER_NAMES:=[?]string{"lotus","iris","marigold","lily"}
render_border::proc(directions:bit_set[Compass],i,j:i8) {
	seed:=state.board.seeds[i][j]
	pos:[2]f16={(f16(i)-f16(state.board.size.x-1)/2)*TILE_SIZE,(f16(j)-f16(state.board.size.y-1)/2)*TILE_SIZE}
	if .EAST in directions { render_texture(name=LINE_NAMES[(seed+0)%4],pos=(pos+{TILE_SIZE/2,0}),size={TILE_SIZE,TILE_SIZE}) }
	if .WEST in directions { render_texture(name=LINE_NAMES[(seed+1)%4],pos=(pos+{-TILE_SIZE/2,0}),size={TILE_SIZE,TILE_SIZE}) }
	if .NORTH in directions { render_texture(name=LINE_NAMES[(seed+2)%4],pos=(pos+{0,TILE_SIZE/2}),size={TILE_SIZE,TILE_SIZE},rotation=math.PI/2) }
	if .SOUTH in directions { render_texture(name=LINE_NAMES[(seed+3)%4],pos=(pos+{0,-TILE_SIZE/2}),size={TILE_SIZE,TILE_SIZE},rotation=math.PI/2) }}
SURFACE_NAMES:=[?]string{"surface-1","surface-2","surface-3","surface-4"}
render_surface::proc(i,j:i8,seed:u32) {
	render_cell(name=SURFACE_NAMES[seed%4],i=f16(i),j=f16(j),layer=Layer.SURFACE,flags={.WAVY})
	if seed<50_000_000 {
		render_cell(name=FLOWER_NAMES[seed%4],i=f16(i),j=f16(j),layer=Layer.FLOWERS,flags={.WINDY}) }}
BOTTOM_NAMES:=[?]string{"bottom-1","bottom-2","bottom-3","bottom-4"}
render_bottom::proc(i,j:i8,seed:u32) {
	render_cell(name=BOTTOM_NAMES[seed%4],i=f16(i),j=f16(j),layer=Layer.BOTTOM,flags={.WAVY,.CAUSTICS}) }
board_iterator::proc(i,j:^i8) {
	i^,j^=0,-1 }
iterate_board::proc(board:^Board,i,j:^i8)->bool {
	if j^>=board.size.y-1 { i^+=1; j^=0 } else { j^+=1 }
	if i^>=board.size.x { return false }
	return true }
cells_distance::proc(i1,j1,i2,j2:i8)->i8 {
	return i8(math.round(linalg.length([2]f32{f32(i1-i2),f32(j1-j2)}))) }
	// return auto_cast math.sqrt_f16(f16((i1-i2)*(i1-i2)+(j1-j2)*(j1-j2))) }
	// return int(linalg.floor(linalg.length([2]f32{f32(i1),f32(j1)}-[2]f32{f32(i2),f32(j2)}))) }
distance_to_entity::proc(board:^Board,i,j:i8)->i8 {
	min_dist:i8=auto_cast c.INT8_MAX
	for entity in board.entities {
		dist:=cells_distance(i,j,entity.x,entity.y)
		if dist<min_dist do min_dist=dist }
	return min_dist }
// croc_threat::proc(i,j,ci,cj:i8)->i8 {
// 	when LINEAR_THREAT do return max(CROC_WIGGLINESS-cells_distance(i,j,ci,cj),0)
// 	else do return cells_distance(i,j,ci,cj)<CROC_WIGGLINESS?1:0 }
// calculate_estimated_threat::proc(board:^Board,i,j:i8)->i8 {
// 	threat:i8=0
// 	for croc in board.crocs do threat+=croc_threat(i,j,croc.x,croc.y)
// 	k,l:i8; board_iterator(&k,&l)
// 	for iterate_board(board,&k,&l) do if board.flags[k][l] do threat-=croc_threat(i,j,k,l)
// 	return threat }
// calculate_threat::proc(board:^Board,i,j:i8)->i8 {
// 	threat:i8=0
// 	for croc in board.crocs do threat+=croc_threat(i,j,croc.x,croc.y)
// 	return threat }
clear_threats::proc(board:^Board) {
	i,j:i8; board_iterator(&i,&j)
	for iterate_board(board,&i,&j) do board.threats[i][j]=0 }
calculate_threats::proc(board:^Board) {
	for kind in Entity_Kind {
		threats_in:=clone_2d_slice(board.threats)
		defer delete_2d_slice(threats_in)
		for pos in board.entities {
			entity,found:=board.cells[pos.x][pos.y].?
			if !found do continue
			if entity.kind!=kind do continue
			fmt.println("putting threat on",pos,entity.kind)
			// board.threats[pos.x][pos.y]=(cast(i8)entity.kind)+1
			#partial switch kind {
			case .KROKUL: calculate_threats_krokul(pos,entity.direction,board.size,threats_in,board.threats)
			case .IGNESA: calculate_threats_ignesa(pos,entity.direction,board.size,threats_in,board.threats)
			case .BORDANA: calculate_threats_bordana(pos,entity.direction,board.size,threats_in,board.threats) }}}}
calculate_threats_krokul::proc(pos:[2]i8,direction:Compass,board_size:[2]i8,threats_in:[][]i8,threats_out:[][]i8) {
	offsets:=[?][2]i8{{-1,0},{1,0},{0,-1},{0,1}}
	for offset in offsets {
		i:=pos.x+offset.x
		j:=pos.y+offset.y
		if (i<0)||(j<0)||(i>=board_size.x)||(j>=board_size.y) do continue
		if ([2]i8{i,j}==pos) do continue
		threats_out[i][j] += 1 }}
calculate_threats_ignesa::proc(pos:[2]i8,direction:Compass,board_size:[2]i8,threats_in:[][]i8,threats_out:[][]i8) {
	offsets_b:=[?][2]i8{
		{-1,0},{0,-1},{0,1},{1,0} }
	for offset in offsets_b {
		i:=pos.x+offset.x
		j:=pos.y+offset.y
		if (i<0)||(j<0)||(i>=board_size.x)||(j>=board_size.y) do continue
		if ([2]i8{i,j}==pos) do continue
		threats_out[i][j] += 1 }
	offsets_a:=[?][2]i8{
		{-2,0},{2,0},{0,-2},{0,2},{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1} }
	direction_offset:=DIRECTION_STEP[direction]
	for offset in offsets_a {
		i:=pos.x+offset.x+4*direction_offset.x
		j:=pos.y+offset.y+4*direction_offset.y
		if (i<0)||(j<0)||(i>=board_size.x)||(j>=board_size.y) do continue
		if ([2]i8{i,j}==pos) do continue
		threats_out[i][j] += 1 }}
BORDANA_DESCRIPTION:string:"For every tile in a 5x5 square around Ignesa, increase threat by 1 if a neighboring tile has a threat greater than 0, or if a neighboring tile has this Bordana."
calculate_threats_bordana::proc(pos:[2]i8,direction:Compass,board_size:[2]i8,threats_in:[][]i8,threats_out:[][]i8) {
	points:=make_square(pos,2,board_size)
	for point in points {
		neighbor_points:=make_square(point,1,board_size)
		ok:bool=false
		for neighbor_point in neighbor_points do if ((threats_in[neighbor_point.x][neighbor_point.y]>0)||(neighbor_point==pos)) {
			ok=true
			break }
		if ok do threats_out[point.x][point.y] += 1 }}
// calculate_threats::proc(board:^Board) {
// 	i,j:i8; board_iterator(&i,&j)
// 	for iterate_board(board,&i,&j) {
// 		board.threats[i][j]=calculate_threat(board,i,j)
// 		board.estimated_threats[i][j]=calculate_estimated_threat(board,i,j) }}
// calculate_threats_at::proc(board:^Board,i,j:i8) {
// 	board.threats[i][j]=calculate_threat(board,i,j)
// 	board.estimated_threats[i][j]=calculate_estimated_threat(board,i,j) }
// calculate_threats_about::proc(board:^Board,center_i,center_j:i8) {
// 	i0:=max(0,center_i-CROC_WIGGLINESS+1)
// 	i1:=min(center_i+CROC_WIGGLINESS-1,board.size.x-1)
// 	j0:=max(0,center_j-CROC_WIGGLINESS+1)
// 	j1:=min(center_j+CROC_WIGGLINESS-1,board.size.y-1)
// 	for i in i0..=i1 do for j in j0..=j1 {
// 		calculate_threats_at(board,i,j) }}
render_menu::proc() {
	state.hovered_name=""
	defer {
		if state.hovered_name_stable!=state.hovered_name do state.hover_time=state.net_time
		state.hovered_name_stable=state.hovered_name }
	state.hovered_pos={0,0}
	board:^Board=&state.board
	i,j:i8; board_iterator(&i,&j)
	set_depth_test(true)
	for iterate_board(board,&i,&j) {
		board.projected_cell_rects[i][j]=project_rect(Rect(f16){entity_pos(f16(i),f16(j)),TILE_SIZE},state.view_matrix)
		hovered:=in_rect(cast_array(state.cursor,f16),state.board.projected_cell_rects[int(i)][int(j)])
		if hovered do state.hovered_pos={i,j} }
	board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		if !board.vision[i][j] do render_surface(i,j,board.seeds[i][j])
		else do render_bottom(i,j,board.seeds[i][j]) }
	render_borders(board)
	board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		if !board.vision[i][j] do continue
		entity,found:=board.cells[i][j].?
		if found do render_entity(entity,i,j) }
	set_depth_test(false)
	submenu:=&state.control_state.submenu
	menu_j:f16=MENU_J
	start_i:f16=f16(MENU_START_I)
	display_i:f16=f16(MENU_DISPLAY_I)
	audio_i:f16=f16(MENU_AUDIO_I)
	exit_i:f16=f16(MENU_EXIT_I)
	drag:=state.control_state.drag
	if (submenu^==.START)||(submenu^==.NONE) do render_cell(name=START_NAME,i=f16(start_i),j=f16(menu_j+drag),layer=Layer.GUI_ICONS,flags={.WINDY})
	if (submenu^==.DISPLAY)||(submenu^==.NONE) do render_cell(name=DISPLAY_NAME,i=f16(display_i),j=f16(menu_j+drag),layer=Layer.GUI_ICONS,flags={.WINDY})
	if (submenu^==.AUDIO)||(submenu^==.NONE) do render_cell(name=AUDIO_NAME,i=f16(audio_i),j=f16(menu_j+drag),layer=Layer.GUI_ICONS,flags={.WINDY})
	if (submenu^==.EXIT)||(submenu^==.NONE) do render_cell(name=EXIT_NAME,i=f16(exit_i),j=f16(menu_j+drag),layer=Layer.GUI_ICONS,flags={.WINDY})
	set_blend(true)
	set_depth_test(false)
	render_texture(name="title-0",pos={0,280+8*f16(math.sin(state.net_time*4))+40*f16(math.pow(math.sin(state.net_time),16.0))},size=5*{256,82},depth=Layer.GUI_ICONS)
	render_texture(name="title-1",pos={0,200+8*f16(math.sin(state.net_time*4))+20*f16(math.pow(math.sin(state.net_time),16.0))},size=5*{256,82},depth=Layer.GUI_ICONS)
	render_text("BOGWALKER",pos={0,0},color=WHITE,font_name="font-title",waviness=2.0,spacing=state.view_scale*1.2,scale_multiplier=state.view_scale*1.5+0.02*(f16(math.sin(3.12*state.net_time))+f16(math.cos(7.31*state.net_time))))
	t:f16=min(8*f16(state.net_time-state.hover_time),1)
	if slice.contains([]string{START_NAME,DISPLAY_NAME,AUDIO_NAME,EXIT_NAME},state.hovered_name)&&(submenu^==.NONE) do render_text(state.hovered_name,pos=project_pos(entity_pos(f16(state.hovered_pos.x),f16(state.hovered_pos.y)+0.70)),pivot={.SOUTH},font_name="font-medium",scale_multiplier=1.5+0.5*t,spacing=1+0.5*t)
	#partial switch submenu^ {
	case .START:
		select:=math.round(drag)
		t1:f16=clamp(1-abs(state.control_state.drag-(-0)),0,1)
		t2:f16=clamp(1-abs(state.control_state.drag-(-1)),0,1)
		t3:f16=clamp(1-abs(state.control_state.drag-(-2)),0,1)
		t4:f16=clamp(1-abs(state.control_state.drag-(-3)),0,1)
		render_whiteline(i=start_i,j0=menu_j-3,j1=menu_j)
		text_pos:[2]f16=entity_pos(start_i+1,menu_j-0)
		render_text("beginner",pos=project_pos(text_pos),color={1,1,(select==0)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t1),spacing=1+t1)
		text_pos=entity_pos(start_i+1,menu_j-1)
		render_text("easy",pos=project_pos(text_pos),color={1,1,(select==-1)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t2),spacing=1+t2)
		text_pos=entity_pos(start_i+1,menu_j-2)
		render_text("medium",pos=project_pos(text_pos),color={1,1,(select==-2)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t3),spacing=1+t3)
		text_pos=entity_pos(start_i+1,menu_j-3)
		render_text("hard",pos=project_pos(text_pos),color={1,1,(select==-3)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t4),spacing=1+t4)
	case .DISPLAY:
		select:=drag+((state.settings.display==.WINDOWED)?0:-1)
		t1:f16=clamp(1-abs(state.control_state.drag+((state.settings.display==.WINDOWED)?0:-1)-(-0)),0,1)
		t2:f16=clamp(1-abs(state.control_state.drag+((state.settings.display==.WINDOWED)?0:-1)-(-1)),0,1)
		render_whiteline(i=display_i,j0=menu_j+((state.settings.display==.WINDOWED)?-1:0),j1=menu_j+((state.settings.display==.WINDOWED)?0:1))
		text_pos:[2]f16=entity_pos(display_i+1,menu_j+((state.settings.display==.WINDOWED)?0:1))
		render_text("windowed",pos=project_pos(text_pos),color={1,1,(math.round(select)==0)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t1),spacing=1+t1)
		text_pos=entity_pos(display_i+1,menu_j+((state.settings.display==.WINDOWED)?(-1):0))
		render_text("fullscreen",pos=project_pos(text_pos),color={1,1,(math.round(select)==-1)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t2),spacing=1+t2)
	case .AUDIO:
		select:=min(max(state.settings.audio-(-state.control_state.drag/3),0),1)
		t1:=clamp(select,0,1)
		t2:=clamp(1-select,0,1)
		// state.settings.audio=min(max(select,0),1)
		render_whiteline(i=audio_i,j0=menu_j-3+3-state.settings.audio*3,j1=menu_j+3-state.settings.audio*3)
		text_pos:[2]f16=entity_pos(audio_i+1,menu_j-0+3-state.settings.audio*3)
		render_text("100%",pos=project_pos(text_pos),color=WHITE,pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t1),spacing=1+t1)
		text_pos=entity_pos(audio_i+1,menu_j-3+3-state.settings.audio*3)
		render_text("  0%",pos=project_pos(text_pos),color=WHITE,pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t2),spacing=1+t2)
		state.flags+={.AUDIO_MENU_DRAWN}
	case .EXIT:
		select:=math.round(drag)
		t1:f16=clamp(1-abs(state.control_state.drag-(-0)),0,1)
		t2:f16=clamp(1-abs(state.control_state.drag-(-1)),0,1)
		render_whiteline(i=exit_i,j0=menu_j-1,j1=menu_j)
		text_pos:[2]f16=entity_pos(exit_i+1,menu_j-0)
		render_text("no",pos=project_pos(text_pos),color={1,1,(select==0)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t1),spacing=1+t1)
		text_pos=entity_pos(exit_i+1,menu_j-1)
		render_text("yes",pos=project_pos(text_pos),color={1,1,(select==-1)?0:1,1},pivot={.WEST},font_name="font-medium",scale_multiplier=math.lerp(f16(1.5),f16(2.0),t2),spacing=1+t2)
	case:
		state.flags-={.AUDIO_MENU_DRAWN} }}
project_pos::proc(pos:[2]f16)->[2]f16 {
	p:[3]f32=state.view_matrix*[3]f32{f32(pos.x),f32(pos.y),1}
	return [2]f16{f16(p.x),f16(p.y)} }
inverse_project_pos::proc(pos:[2]f16)->[2]f16 {
	p:[3]f32=linalg.inverse(state.view_matrix)*[3]f32{f32(pos.x),f32(pos.y),1}
	return [2]f16{f16(p.x),f16(p.y)} }
inverse_project_vector::proc(vec:[2]f16)->[2]f16 {
	return inverse_project_pos(vec)-inverse_project_pos({0,0}) }
render_borders::proc(board:^Board) {
	i,j:i8; board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		center_vision:=board.vision[i][j]
		borders:=bit_set[Compass]{}
		if inside_board(board,i+1,j) { if board.vision[i+1][j]!=center_vision { borders+={.EAST} } }
		if inside_board(board,i-1,j) { if board.vision[i-1][j]!=center_vision { borders+={.WEST} } }
		if inside_board(board,i,j+1) { if board.vision[i][j+1]!=center_vision { borders+={.NORTH} } }
		if inside_board(board,i,j-1) { if board.vision[i][j-1]!=center_vision { borders+={.SOUTH} } }
		render_border(borders,i,j) }}
render_board::proc() {
	state.hovered_name=""
	defer state.hovered_name_stable=state.hovered_name
	state.hovered_pos={0,0}
	board:^Board=&state.board
	i,j:i8; board_iterator(&i,&j)
	set_depth_test(true)
	for iterate_board(board,&i,&j) {
		board.projected_cell_rects[i][j]=project_rect(Rect(f16){entity_pos(f16(i),f16(j)),TILE_SIZE},state.view_matrix)
		hovered:=in_rect(cast_array(state.cursor,f16),state.board.projected_cell_rects[int(i)][int(j)])
		if hovered do state.hovered_pos={i,j} }
	board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		if (!board.vision[i][j])&&(!((.DEAD in state.flags)||(.VICTORIOUS in state.flags))) {
			render_surface(i,j,board.seeds[i][j]) }
		else {
			render_bottom(i,j,board.seeds[i][j]) }}
	for fish in board.fishes {
		render_fish(fish) }
	render_borders(board)
	board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		if board.flags[i][j] do render_cell(name="buoy",i=auto_cast i,j=auto_cast j,extra_rotation=0.1*f16(math.sin(2*state.net_time)),flags={.WINDY},layer=Layer.GUI_TEXT)
		if (!board.vision[i][j])&&(!((.DEAD in state.flags)||(.VICTORIOUS in state.flags))) { continue }
		use_shader(state.texture_shader)
		deep_entity,found_deep:=board.cells[i][j].?
		if found_deep do render_entity(deep_entity,i,j) }
	set_blend(true)
	set_depth_test(true)
	set_depth_test(false)
	board_iterator(&i,&j)
	for iterate_board(board,&i,&j) {
		threat:=board.threats[i][j]
		ep:=entity_pos(f16(i),f16(j))
		tp:[3]f32=state.view_matrix*[3]f32{f32(ep.x),f32(ep.y),1}
		// TEMP
		if (threat!=0)/*&&(!cell_occupied(board,i,j))*//*&&(board.vision[i][j])*/ do render_text(fmt.aprint(threat),pos={f16(tp.x),f16(tp.y)},color=WHITE,spacing=0.5,font_name="font-medium",scale_multiplier=1.25+0.75*max(1-f16(linalg.length(state.cursor-[2]f32{tp.x,tp.y}))/(250*f16(state.view_zoom)),0.0))
		}
	text_pos:=[2]f16{0,-0.5*f16(state.window_size.y)+8}
	text_pos={-0.5*f16(state.window_size.x)+8,-0.5*f16(state.window_size.y)+8}
	render_text("ESC give up",pos=text_pos,pivot={.WEST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("R   restart",pos=text_pos,pivot={.WEST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("F   mark croc",pos=text_pos,pivot={.WEST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("\"   reveal",pos=text_pos,pivot={.WEST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("#   look",pos=text_pos,pivot={.WEST,.SOUTH},font_name="font-medium",scale_multiplier=1.5)
	text_pos={0.5*f16(state.window_size.x)-8,-0.5*f16(state.window_size.y)+8}
	render_text("hide entities   E",pos=text_pos,pivot={.EAST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("reveal board   W",pos=text_pos,pivot={.EAST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24
	render_text("hide board   Q",pos=text_pos,pivot={.EAST,.SOUTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y+=24



	text_pos={-0.5*f16(state.window_size.x)+8,0.5*f16(state.window_size.y)-8}
	render_text("remaining monsters: ",fmt.aprint(len(board.entities)-int(board.n_flags)),pos=text_pos,pivot={.WEST,.NORTH},font_name="font-medium",scale_multiplier=1.5)
	text_pos={0.5*f16(state.window_size.x)-8,0.5*f16(state.window_size.y)-8}
	render_text(fmt.aprintf("time: %.2f",state.play_time),pos=text_pos,pivot={.EAST,.NORTH},font_name="font-medium",scale_multiplier=1.5); text_pos.y-=24
	if state.highscores[int(board.difficulty)]!=math.F32_MAX do render_text(fmt.aprintf("highscore: %.2f",state.highscores[int(board.difficulty)]),pos=text_pos,pivot={.EAST,.NORTH},font_name="font-medium",scale_multiplier=1.5)
	text_pos={0,f16(state.resolution.y/2)-48}
	if .VICTORIOUS in state.flags {
		render_text("WINNER",pos=text_pos,color=WHITE,font_name="font-title",waviness=2.0,spacing=0.8)
		if .HIGHSCORE_SET in state.flags do render_text("new highscore!",pos=text_pos+{0,-f16(state.resolution.y)+96},font_name="font-title",waviness=2.0,spacing=0.6) }
	if .DEAD in state.flags do render_text("LOSER",pos=text_pos,color=WHITE,font_name="font-title",waviness=2.0,spacing=0.8)
	pos:=[2]f16{0,-0.5*f16(state.window_size.y)+8+TILE_SIZE/2}
	render_texture(name="krokul",pos=pos,size={TILE_SIZE,TILE_SIZE})
}
board_tick::proc() {
	board:^Board=&state.board
	// TEMP
	// if all_entities_are_flagged(board) {
	// 	pause_timer(&state.play_timer)
	// 	state.flags+={.VICTORIOUS}
	// 	play_sound("victory")
	// 	time:=state.play_time
	// 	highscore:=state.highscores[int(board.difficulty)]
	// 	if time<=highscore {
	// 		state.flags+={.HIGHSCORE_SET}
	// 		state.highscores[int(board.difficulty)]=time }}
}
game_tick::proc() {
	state.keys_switched=state.keys_pressed~state.old_keys_pressed
	state.mouse_switched=state.mouse_pressed~state.old_mouse_pressed
	state.old_keys_pressed=state.keys_pressed
	state.old_mouse_pressed=state.mouse_pressed
	state.view_matrix=zoom_matrix(f32(state.view_zoom))*pan_matrix(cast_array(state.view_pan,f32))
	state.view_top_left={-f16(state.window_size.x)/2,f16(state.window_size.y)/2}
	state.view_bottom_right={f16(state.window_size.x)/2,-f16(state.window_size.y)/2}
	top_left:=state.view_matrix*[3]f32{f32(state.view_top_left.x),f32(state.view_top_left.y),1}
	bottom_right:=state.view_matrix*[3]f32{f32(state.view_bottom_right.x),f32(state.view_bottom_right.y),1}
	state.view_top_left={f16(top_left.x),f16(top_left.y)}
	state.view_bottom_right={f16(bottom_right.x),f16(bottom_right.y)}
	if state.control_state.submenu!=.NONE {
		state.control_state.drag+=inverse_project_vector(cast_array(state.mouse_delta,f16)).y/64
		select:=math.round(state.control_state.drag)
		if mouse_was_released(.MOUSE_LEFT) {
			#partial switch state.control_state.submenu {
			case .START: switch select {
				case  0: start_level(.BEGINNER)
				case -1: start_level(.EASY)
				case -2: start_level(.MEDIUM)
				case -3: start_level(.HARD) }
			case .DISPLAY:
				select+=((state.settings.display==.WINDOWED)?0:-1)
				switch select {
					case 0: set_display_windowed()
					case -1: set_display_fullcreen() }
			case .AUDIO:
				select=state.settings.audio-(-state.control_state.drag/3)
				state.settings.audio=min(max(select,0),1)
				set_audio_volume(state.settings.audio)
			case .EXIT: switch select {
				case 0:
				case -1: state.flags-={.RUNNING} }}
			state.control_state.drag=0
			state.control_state.submenu=.NONE }
		if mouse_pressed(.MOUSE_LEFT) {
			#partial switch state.control_state.submenu {
			case .AUDIO:
				select=state.settings.audio-(-state.control_state.drag/3)
				set_audio_volume(min(max(select,0),1)) }}}
	board:=&state.board
	for _,i in board.fishes {
		fish_tick(&board.fishes[i]) }
	switch state.control_state.screen {
		case .MENU:
		submenu:=&state.control_state.submenu
		if (submenu^==.NONE)&&(state.hovered_name==START_NAME)&&mouse_was_pressed(.MOUSE_LEFT) {
			submenu^=.START
			state.hover_time=state.net_time }
		if (submenu^==.NONE)&&(state.hovered_name==DISPLAY_NAME)&&mouse_was_pressed(.MOUSE_LEFT) {
			submenu^=.DISPLAY
			state.hover_time=state.net_time }
		if (submenu^==.NONE)&&(state.hovered_name==AUDIO_NAME)&&mouse_was_pressed(.MOUSE_LEFT) {
			submenu^=.AUDIO
			state.hover_time=state.net_time }
		if (submenu^==.NONE)&&(state.hovered_name==EXIT_NAME)&&mouse_was_pressed(.MOUSE_LEFT) {
			submenu^=.EXIT
			state.hover_time=state.net_time }
		if mouse_was_released(.MOUSE_LEFT) do submenu^=.NONE
		case .GAME:
		if key_was_pressed(.ESCAPE) do start_menu()
		// TEMP
		// if key_was_pressed(.R) do start_level(state.board.difficulty)
		if key_was_pressed(.R) do init_board(state.board.difficulty)
		switch (.DEAD in state.flags)||(.VICTORIOUS in state.flags) {
			case false:
			if mouse_pressed(.MOUSE_LEFT) {
				click_pos:=state.hovered_pos
				if board.untouched {
					if cell_occupied(board,click_pos.x,click_pos.y) do despawn_entity(board,click_pos.x,click_pos.y)
					when AREAL_FIRST_CLEAR do for entity in board.entities do if cells_distance(entity.x,entity.y,click_pos.x,click_pos.y)<=CROC_WIGGLINESS do despawn_entity(board,entity.x,entity.y)
					clear_threats(&state.board)
					calculate_threats(&state.board) }
				if !board.flags[click_pos.x][click_pos.y] do if reveal_cell(board,click_pos.x,click_pos.y) {
					switch rand.int31_max(10) {
						case 0: play_sound("clear0")
						case 1: play_sound("clear1")
						case 2: play_sound("clear2")
						case 3: play_sound("clear3")
						case 4: play_sound("clear4")
						case 5: play_sound("clear5")
						case 6: play_sound("clear6")
						case 7: play_sound("clear7")
						case 8: play_sound("clear8")
						case 9: play_sound("clear9") }
					board.last_click=click_pos
					board.untouched=false
					 } board_tick() }
			if key_was_pressed(.F) {
				result:=!board.flags[state.hovered_pos.x][state.hovered_pos.y]
				if result&&(int(board.n_flags)<len(board.entities)) {
					board.flags[state.hovered_pos.x][state.hovered_pos.y]=result
					board.n_flags+=1 }
				if !result {
					board.flags[state.hovered_pos.x][state.hovered_pos.y]=result
					board.n_flags-=1 }
				board_tick() }
			if key_pressed(.Q) {
				board_set_vision(&state.board,false) }
			if key_pressed(.W) {
				board_set_vision(&state.board,true) }
			if key_pressed(.E) {
				board_set_vision(&state.board,true)
				hide_entities(&state.board)
				hide_semienclosed(&state.board) }
			case true: }}
	state.view_zoom+=8*f16(state.frame_time)*(state.view_zoom_pivot-state.view_zoom)
	state.mouse_delta={0,0}
	state.cursor_delta={0,0} }
inside_board::proc{inside_board_int,inside_board_f16}
inside_board_int::proc(board:^Board,i,j:i8)->bool {
	return in_range(i,0,board.size.x-1)&&in_range(j,0,board.size.y-1) }
inside_board_f16::proc(board:^Board,i,j:f16)->bool {
	return in_range(i,0,f16(board.size.x-1))&&in_range(j,0,f16(board.size.y-1)) }
reveal_cell::proc(board:^Board,i,j:i8)->(revealed:bool) {
	if !inside_board(board,i,j) do return false
	if board.flags[i][j] do return false
	if board.vision[i][j] do return false
	board.vision[i][j]=true
	if distance_to_entity(board,i,j)<=KILL_DISTANCE {
		state.flags+={.DEAD}
		play_sound("defeat") }
	// TEMP
	when REVEAL_BASED_ON_ESTIMATED_THREAT { if board.threats[i][j]==0 do reveal_adjacent(board,i,j) }
	else { if board.threats[i][j]==0 do reveal_adjacent(board,i,j) }
	return true }
reveal_adjacent::proc(board:^Board,i,j:i8) {
	reveal_cell(board,i-1,j)
	reveal_cell(board,i+1,j)
	reveal_cell(board,i,j-1)
	reveal_cell(board,i,j+1) }
start_menu::proc() {
	fmt.println("STARTING MENU")
	state.control_state.screen=.MENU
	init_board(.EASY)
	init_view() }
start_level::proc(difficulty:Difficulty) {
	fmt.println("STARTING LEVEL")
	state.control_state.screen=.GAME
	init_board(difficulty)
	init_view() }
init_view::proc() {
	state.view_scale=(f16(state.window_size.y)/f16(DEFAULT_WINDOW_SIZE.y))
	state.view_zoom_pivot=DEFAULT_VIEW_ZOOM/(f16(DEFAULT_WINDOW_SIZE.y)/f16(state.window_size.y))
	state.view_zoom=state.view_zoom_pivot
	state.view_matrix=linalg.MATRIX3F32_IDENTITY
	state.view_pan={0,0} }
should_update::proc()->bool {
	if .INPUT_RECEIVED in state.flags do return true
	desired_time:time.Time=time.from_nanoseconds(PERIOD_120FPS_NSEC)
	elapsed_time:time.Time=time.from_nanoseconds(i64(time.stopwatch_duration(state.draw_tick_timer)))
	frame_diff:=time.diff(elapsed_time,desired_time)
	if time.duration_nanoseconds(frame_diff)<=0 {
		zero_and_start_timer(&state.draw_tick_timer)
		return true }
	return false }