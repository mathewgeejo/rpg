extends Control

var kind = "circle"
var color = Color("d5c8ef")

func _draw() -> void:
	var c = size/2
	match kind:
		"sword":
			draw_line(c+Vector2(-9,9),c+Vector2(9,-10),color,4)
			draw_line(c+Vector2(-8,2),c+Vector2(-2,8),Color("e9bf7e"),3)
		"star":
			var points = PackedVector2Array()
			for i in 8: points.append(c+Vector2.from_angle(i*TAU/8-PI/2)*(13 if i%2==0 else 4))
			draw_colored_polygon(points,color)
		"ward":
			draw_polyline(PackedVector2Array([c+Vector2(-10,-11),c+Vector2(10,-11),c+Vector2(9,6),c+Vector2(0,13),c+Vector2(-9,6),c+Vector2(-10,-11)]),color,2)
			draw_line(c+Vector2(0,-7),c+Vector2(0,7),color,2)
		"evade":
			for i in 3: draw_polyline(PackedVector2Array([c+Vector2(-11+i*8,-8),c+Vector2(-5+i*8,0),c+Vector2(-11+i*8,8)]),Color(color,.35+i*.3),2)
		"fate":
			draw_rect(Rect2(c-Vector2(10,10),Vector2(21,21)),color,false,2)
			for p in [Vector2(-5,-5),Vector2(5,5),Vector2.ZERO]: draw_rect(Rect2(c+p-Vector2.ONE,Vector2(3,3)),color)
		_:
			draw_arc(c,12,0,TAU,32,color,2)
			draw_arc(c,8,0,TAU,32,Color(color,.5),1)
			for i in 3: draw_line(c+Vector2.from_angle(i*TAU/3-PI/2)*10,c+Vector2.from_angle((i+1)*TAU/3-PI/2)*10,color,1)
