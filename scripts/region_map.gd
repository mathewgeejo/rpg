extends Control

var game
var serif: Font = preload("res://assets/fonts/display.tres")
var sans: Font = preload("res://assets/fonts/body.tres")
var miniatures: Dictionary = {}

func _draw() -> void:
	var colors = [Color("74aa7c"),Color("ddc69b"),Color("579aa9"),Color("426b63"),Color("817d86"),Color("afb7aa"),Color("b79173"),Color("b3ac9c"),Color("d2c6ab")]
	draw_rect(Rect2(Vector2.ZERO,size),Color("192938"))
	for route in game.model.graph.routes:
		var a: Dictionary = game.model.graph.locations[route.from]
		var b: Dictionary = game.model.graph.locations[route.to]
		var from = Vector2(a.x,a.y)*size
		var to = Vector2(b.x,b.y)*size
		for i in range(0,21,2): draw_circle(from.lerp(to,i/20.0),2,Color("c4b78f"))
	for location in game.model.graph.locations:
		var zone: Dictionary = game.model.room(location.id)
		if not miniatures.has(location.id):
			var image = Image.create(zone.tiles[0].size(),zone.tiles.size(),false,Image.FORMAT_RGBA8)
			for y in zone.tiles.size():
				for x in zone.tiles[y].size(): image.set_pixel(x,y,colors[zone.tiles[y][x]])
			miniatures[location.id] = ImageTexture.create_from_image(image)
		var point = Vector2(location.x,location.y)*size
		var rect = Rect2(point-Vector2(70,56),Vector2(140,112))
		draw_rect(rect.grow(4),Color("e9d9b3") if game.room_id == location.id else Color("607778"),false,2)
		draw_texture_rect(miniatures[location.id],rect,false)
		for enemy in zone.enemies:
			if enemy.boss:
				var marker: Vector2 = rect.position+enemy.position/zone.size*rect.size
				draw_rect(Rect2(marker-Vector2(3,3),Vector2(6,6)),Color("9bd4ab") if game.changed.has(enemy.id) else Color("e89da2"))
		var width = sans.get_string_size(location.name,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
		draw_string(sans,rect.position+Vector2(70-width/2,135),location.name,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("eee4c9"))
		if game.room_id == location.id: draw_string(sans,rect.position+Vector2(17,-13),"YOU ARE HERE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b5d9b9"))
