package bogwalker
rect_contains::proc(rect:Rect(f16),point:[2]f16)->bool {
	return (point.x>=rect.pos.x-rect.size.x/2)&&
	       (point.x<=rect.pos.x+rect.size.x/2)&&
	       (point.y>=rect.pos.y-rect.size.y/2)&&
	       (point.y<=rect.pos.y+rect.size.y/2) }
rect_hovered::proc(rect:Rect(f16))->bool {
	return rect_contains(rect,{cast(f16)state.cursor.x,cast(f16)state.cursor.y}) }