extends Control

var game
var serif: Font = preload("res://assets/fonts/display.tres")
var sans: Font = preload("res://assets/fonts/body.tres")
var clock = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var area = size
	draw_rect(Rect2(Vector2.ZERO,area),Color("102d30"))
	for x in range(0,int(area.x),40): draw_line(Vector2(x,0),Vector2(x,area.y),Color(1,1,1,.025))
	for y in range(0,int(area.y),40): draw_line(Vector2(0,y),Vector2(area.x,y),Color(1,1,1,.025))
	var coastline = PackedVector2Array()
	for i in 100:
		var a = i*TAU/100
		var r = .75+sin(a*7)*.07+sin(a*13)*.035
		coastline.append(area*.5+Vector2(cos(a)*area.x*.51,sin(a)*area.y*.54)*r)
	draw_colored_polygon(coastline,Color("25483e"))
	coastline.append(coastline[0])
	draw_polyline(coastline,Color("65826a"),1,true)
	for i in 200:
		var p = Vector2(fmod(i*173.3,area.x),fmod(i*97.7,area.y))
		if Geometry2D.is_point_in_polygon(p,coastline):
			var radius = 1.5+sin(i*3.7)*.5
			draw_circle(p,radius,Color("49634b"))
	var graph: Dictionary = game.model.graph
	for route in graph.routes:
		var a: Dictionary = graph.towns[int(route.from)]
		var b: Dictionary = graph.towns[int(route.to)]
		draw_line(Vector2(a.x,a.y)*area,Vector2(b.x,b.y)*area,Color(.72,.73,.53,.22),1,true)
	var region_positions = [Vector2(.20,.82),Vector2(.15,.24),Vector2(.40,.42),Vector2(.44,.86),Vector2(.55,.11),Vector2(.81,.48),Vector2(.77,.84),Vector2(.83,.12)]
	for i in 8:
		var p: Vector2 = region_positions[i]*area
		var name_text: String = game.data.regions[i].name
		var width = serif.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_string(serif,p-Vector2(width*.5,0),name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("c3c29e"))
	for i in graph.towns.size():
		var town: Dictionary = graph.towns[i]
		var point = Vector2(town.x,town.y)*area
		draw_circle(point,5,Color("dfc995"))
		draw_arc(point,10,0,TAU,24,Color(.88,.79,.56,.5),1)
		if i == 0:
			draw_arc(point,16+sin(clock*2)*2,0,TAU,32,Color("88d8c6"),2)
			draw_string(sans,point+Vector2(15,5),town.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f0e3bd"))
	var compass = Vector2(area.x-50,area.y-70)
	for i in 4:
		var a = i*TAU/4-PI*.5
		draw_line(compass,compass+Vector2.from_angle(a)*24,Color("c9ba8e"),1)
	draw_string(serif,compass+Vector2(-6,-32),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d4c69e"))
