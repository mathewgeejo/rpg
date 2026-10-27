extends Control

var game
var image: Texture2D
var last_room = -1
const COLORS = [Color("355346"),Color("b7a87b"),Color("376b7b"),Color("203b32"),Color("6c6049"),Color("899281"),Color("927453"),Color("b9a98a"),Color("d2c6ab")]

func _draw() -> void:
	if game.zone.is_empty(): return
	if last_room != game.room_id:
		last_room = game.room_id
		var height: int = game.zone.tiles.size()
		var width: int = game.zone.tiles[0].size()
		var pixels = Image.create(width,height,false,Image.FORMAT_RGBA8)
		for y in height:
			for x in width: pixels.set_pixel(x,y,COLORS[game.zone.tiles[y][x]])
		image = ImageTexture.create_from_image(pixels)
	draw_texture_rect(image,Rect2(Vector2.ZERO,size),false,Color(1,1,1,.8))
	for object in game.zone.objects:
		if object.kind in ["exit","npc","seal"]:
			var p: Vector2 = object.position/game.zone.size*size
			draw_circle(p,2,Color("d4b878"))
	for enemy in game.combat.enemies:
		if enemy.boss and enemy.hp > 0:
			var p: Vector2 = enemy.position/game.zone.size*size
			draw_rect(Rect2(p-Vector2(2,2),Vector2(4,4)),Color("e89da2"))
	var player: Vector2 = game.player_pos/game.zone.size*size
	draw_circle(player,3,Color("b4f0d7"))
	draw_arc(player,5,0,TAU,16,Color("e6e4bb"),1)
