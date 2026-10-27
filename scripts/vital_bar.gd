extends Control

var color = Color.WHITE
var value = 100.0:
	set(next):
		if not is_equal_approx(value,next):
			value = next
			queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("29413e"))
	draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(value/100.0,0,1),size.y)),color)
