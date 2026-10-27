"""Original pixel designs, assembled from editable patterns and authored poses.

No image model, diffusion, AI image API, antialiasing, random noise, or resizing.
Every output pixel comes from the designs and palette below. Re-run to edit art.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/custom'
OUT.mkdir(parents=True, exist_ok=True)
P = {'o':'#21263d','h':'#554665','H':'#88759a','s':'#e6ad87','S':'#ffdbab','e':'#29243d','w':'#fff3cd','c':'#5d6997','C':'#9199c6','g':'#e5ae62','G':'#ffe29b','b':'#35475e','B':'#66818b','r':'#b25e6b','R':'#e08a82'}
HEAD = [
'.....oooooo.....','...oohhhhhhhoo...','..ohhhhhhhhhho..','..ohhHhhhhHhho..',
'.ohhHHHhhHHhho.','.ohhhhhhHhhhho.','.ohhooShhSooho.','..ohSSSSSSSSho..',
'..osSoeSSeoSso..','..osSoeSSeoSso..','...osSSSSSSso...','....osSrrSso....',
'.....osSSso.....','......oooo......']
BACK = [
'.....oooooo.....','...oohhhhhhhoo...','..ohhhhhhhhhho..','..ohhHhhhhHhho..',
'.ohhHHHhhHHhho.','.ohhhhhhHhhhho.','.ohhhhhhhhhhhho.','..ohhhhhhhhho..',
'..ohhHhhhhHhho..','...ohhhhhhhho...','....ohhhhhho....','.....ohhhho.....',
'.....obbbbo.....','......oooo......']
SIDE = [
'.....oooooo.....','...oohhhhhhhoo...','..ohhHHhhhhho...','..ohhhhhhhhhho..',
'..ohhHhhhHHhho..','..ohhhhhhhhho...','..ohhhSSSSSoo...','..ohhSSSSeSSSo..',
'...ohSSSSeSSSSo.','....osSSSSSSSoo.','....osSSSSSso...','.....osSSSso....',
'......osSso.....','.......ooo......']
TORSO = [
'..ooooGGoooo..','.ogggGGGGgggo.','occcoggggoccco','ocCCcooocCCcco',
'ocCCccocCCccco','ocCcccoCCCCcco','occcccocCcccco','occcccoCccccco',
'ocCccoGocCccco','occccoGoccccco','.occcooooCCco.','..ooo....ooo..']
SIDE_TORSO = ['..ooGGoo..','.ocggggco.','ocCCocCCco','ocCcoccCco','occCocccco','occcoccCco','occCocccco','occcogccco','.occbGcco.','..ocbbco..','...oooo...','..........']

def stamp(img, rows, xy, palette):
    for y,row in enumerate(rows):
        for x,char in enumerate(row):
            if char in palette: img.putpixel((xy[0]+x,xy[1]+y),palette[char])

def rgba(palette):
    return {k:tuple(bytes.fromhex(v.lstrip('#')))+(255,) for k,v in palette.items()}

def person(palette, direction, phase=0, action='walk', armor='cloth', npc=''):
    img=Image.new('RGBA',(32,40)); d=ImageDraw.Draw(img)
    colors=rgba(palette)
    bob=1 if action=='walk' and phase%4 in (1,3) else 0
    left=[0,-2,0,2][phase%4] if action=='walk' else 0
    right=-left
    if action=='dodge':
        bob=[1,2,1,0][phase%4]
        left=[-2,-3,-2,0][phase%4];right=-left
    # Distinct planted and passing poses. Boots move opposite the hands.
    legs=[(12+left,0),(17+right,0)] if direction in (1,2) else [(10,left),(18,right)]
    for x,shift in legs:
        d.rectangle((x,25+bob,x+4,33+shift),fill=colors['o'])
        d.rectangle((x+1,25+bob,x+3,32+shift),fill=colors['b'])
        d.rectangle((x-1,32+shift,x+5,35+shift),fill=colors['o'])
        d.line((x,33+shift,x+4,33+shift),fill=colors['B'])
    arms=[(10,-left),(21,-right)] if direction in (1,2) else [(7,-left),(24,-right)]
    for x,shift in arms:
        yy=19+bob+shift
        if action=='cast': yy=15-max(0,phase-1)
        if action=='attack' and (x==(21 if direction in (1,2) else 24) or direction==1): yy=17-phase%3
        d.rectangle((x-1,yy,x+1,yy+7),fill=colors['o'])
        d.rectangle((x,yy+1,x,yy+3),fill=colors['c'])
        d.rectangle((x,yy+5,x+1,yy+6),fill=colors['S'])
    stamp(img,SIDE_TORSO if direction in (1,2) else TORSO,(11 if direction in (1,2) else 9,15+bob),colors)
    if armor=='plate':
        d.rectangle((11,18+bob,21,23+bob),fill=colors['B'],outline=colors['o'])
        d.line((12,18+bob,20,18+bob),fill=colors['w'])
        d.rectangle((7,16+bob,10,19+bob),fill=colors['B'],outline=colors['o'])
        d.rectangle((22,16+bob,25,19+bob),fill=colors['B'],outline=colors['o'])
        d.point((16,20+bob),fill=colors['G'])
    elif armor=='leather':
        d.line((10,17+bob,21,25+bob),fill=colors['g'],width=2)
        d.rectangle((11,24+bob,21,25+bob),fill=colors['b'])
        d.rectangle((15,24+bob,17,26+bob),fill=colors['G'])
    if direction==3:
        d.rectangle((11,18+bob,21,27+bob),fill=colors['o'])
        d.rectangle((13,19+bob,19,25+bob),fill=colors['b'])
        d.line((13,20+bob,19,20+bob),fill=colors['g'])
        d.point((16,23+bob),fill=colors['G'])
    head=BACK if direction==3 else (SIDE if direction in (1,2) else HEAD)
    layer=Image.new('RGBA',(32,40));stamp(layer,head,(8,2+bob),colors)
    if direction==1: layer=layer.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    img.alpha_composite(layer)
    d=ImageDraw.Draw(img)
    if npc=='orin':
        d.rectangle((7,6+bob,25,8+bob),fill=colors['o'])
        d.rectangle((10,3+bob,22,6+bob),fill=colors['g'])
        d.line((8,7+bob,24,7+bob),fill=colors['G'])
        d.rectangle((13,13+bob,19,15+bob),fill=colors['w'])
    if npc=='sella':
        d.rectangle((10,17+bob,12,24+bob),fill=colors['g'])
        d.rectangle((19,17+bob,21,24+bob),fill=colors['g'])
        d.rectangle((13,21+bob,19,25+bob),fill=colors['c'])
    if action=='cast':
        points=[(7,17),(8,13),(24,12),(26,17),(20,9),(11,9)]
        for i,(x,y) in enumerate(points[:phase+1]):
            d.point((x,y),fill=colors['G']);d.point((x+1,y),fill=colors['w'])
    if action=='attack':
        # Six individually scheduled sword poses; no rotating or warping sprites.
        poses=[((23,23),(27,9)),((24,21),(35,9)),((24,19),(38,20)),((23,21),(34,31)),((22,23),(28,36)),((22,24),(25,35))]
        a,b=poses[phase%6]
        if direction==1: a,b=(31-a[0],a[1]),(31-b[0],b[1])
        if direction==3: a,b=(a[0],max(0,a[1]-5)),(b[0],max(0,b[1]-5))
        # Oversized cells keep the full sword inside its frame in every direction.
        outer=Image.new('RGBA',(48,48));outer.alpha_composite(img,(8,4));img=outer;d=ImageDraw.Draw(img)
        a,b=(a[0]+8,a[1]+4),(b[0]+8,b[1]+4)
        d.line((a,b),fill=colors['o'],width=3);d.line((a,b),fill=colors['w'],width=1)
        d.rectangle((a[0]-2,a[1]-1,a[0]+2,a[1]),fill=colors['g'])
    if action=='hurt':
        d.line((12,10+bob,14,12+bob),fill=colors['e']);d.line((14,10+bob,12,12+bob),fill=colors['e'])
        if phase%2: img=img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if action=='walk' and phase==4 and direction==0:
        d=ImageDraw.Draw(img)
        for x in [13,18]:
            d.rectangle((x,10+bob,x+2,11+bob),fill=colors['S'])
            d.line((x,11+bob,x+2,11+bob),fill=colors['e'])
    return img

def sprite_sheet(name,palette,armor='cloth',npc=''):
    sheet=Image.new('RGBA',(288,960))
    for state,action in enumerate(['walk','attack','cast','dodge','hurt']):
        for direction in range(4):
            for frame in range(6):
                pose=person(palette,direction,frame,action,armor,npc)
                offset=(8,4) if pose.size==(32,40) else (0,0)
                sheet.alpha_composite(pose,(frame*48+offset[0],(state*4+direction)*48+offset[1]))
    sheet.save(OUT/(name+'.png'))

sprite_sheet('wanderer_cloth',P)
sprite_sheet('wanderer_plate',dict(P,c='#547c87',C='#9fc8c2',h='#5b4f61'),armor='plate')
sprite_sheet('wanderer_leather',dict(P,c='#67526b',C='#a4768e',b='#494557'),armor='leather')
sprite_sheet('mira',dict(P,h='#b3b9c9',H='#eff3e6',c='#735b92',C='#b599c9'),npc='mira')
sprite_sheet('orin',dict(P,h='#8f9a9b',H='#e1e3d2',c='#577a68',C='#94b58b',s='#b67e6b',S='#e5b18a'),npc='orin')
sprite_sheet('sella',dict(P,h='#9d5260',H='#e79773',c='#5c876e',C='#98bc83'),npc='sella')

def asset(name, size):
    im=Image.new('RGBA',size); return im,ImageDraw.Draw(im)

# Small palette, stepped silhouettes, and deliberately placed leaf clusters.
tree,d=asset('tree',(64,88))
d.polygon([(24,44),(38,44),(39,66),(44,79),(40,83),(33,79),(27,84),(20,82),(25,68)],fill='#253c42')
d.polygon([(27,44),(34,45),(35,70),(39,79),(31,76),(26,80),(28,64)],fill='#9b765a')
d.line((29,50,29,72),fill='#d2ad78',width=2)
canopy=[(25,2),(38,2),(38,5),(47,5),(47,9),(54,9),(54,14),(59,14),(59,22),(63,22),(63,40),(59,40),(59,48),(52,48),(52,53),(41,53),(41,57),(22,57),(22,54),(11,54),(11,49),(4,49),(4,42),(0,42),(0,24),(4,24),(4,16),(10,16),(10,10),(17,10),(17,5),(25,5)]
d.polygon(canopy,fill='#223e44')
d.polygon([(26,6),(37,6),(37,9),(46,9),(46,14),(53,14),(53,21),(58,21),(58,39),(53,39),(53,46),(44,46),(44,50),(23,50),(23,47),(12,47),(12,42),(6,42),(6,26),(11,26),(11,18),(18,18),(18,12),(26,12)],fill='#407e6b')
for x,y,w,h in [(14,17,15,7),(27,10,14,7),(40,22,14,8),(10,31,15,8),(24,26,19,9),(28,39,17,7)]:
    d.rectangle((x,y,x+w,y+h),fill='#75ad75');d.line((x+2,y,x+w-3,y),fill='#b8ce89',width=2)
for x,y in [(16,29),(28,20),(43,35),(19,42),(48,17)]: d.rectangle((x,y,x+3,y+2),fill='#315f58')
tree.save(OUT/'tree.png')
pine,d=asset('pine',(48,80))
d.rectangle((21,45,28,75),fill='#253c42');d.rectangle((23,46,26,73),fill='#b18a63')
for y,w in [(1,7),(10,13),(22,19),(36,23)]:
    d.polygon([(24,y),(24+w,y+24),(24+w-5,y+27),(24+w-2,y+31),(24-w+2,y+31),(24-w+5,y+27),(24-w,y+24)],fill='#243e46')
    d.polygon([(24,y+4),(24+w-5,y+24),(24,y+21),(24-w+5,y+26)],fill='#457c70')
    d.line((24,y+7,24-w+8,y+23),fill='#8ab98d',width=2)
pine.save(OUT/'pine.png')

house,d=asset('house',(128,144))
d.rectangle((16,75,112,134),fill='#292c49')
d.rectangle((20,79,108,130),fill='#e3c6a1')
d.polygon([(20,79),(35,79),(35,130),(20,130)],fill='#b78a81')
d.rectangle((16,130,113,137),fill='#c6c0b1');d.line((19,131,110,131),fill='#f5e5bf',width=2)
d.polygon([(12,78),(29,20),(100,20),(118,78)],fill='#262a45')
d.polygon([(17,74),(33,24),(96,24),(112,74)],fill='#575e91')
for y in [29,39,49,59,69]:
    inset=(74-y)//4
    d.line((18+inset,y,111-inset,y),fill='#a2a2c4',width=1)
    for x in range(30+(5 if y in [39,59] else 0),105,16):
        if 18+inset<x<111-inset: d.line((x,y+1,x-2,y+8),fill='#3c426e')
d.rectangle((9,76,119,82),fill='#252b47');d.line((12,77,116,77),fill='#9696b2')
d.rectangle((52,93,77,132),fill='#292b44');d.rectangle((56,96,73,130),fill='#9f716c')
d.line((63,97,63,129),fill='#6c535c');d.point((69,115),fill='#ffe2a1')
for x in [28,88]:
    d.rectangle((x-2,92,x+14,113),fill='#31364f');d.rectangle((x,94,x+12,110),fill='#ffd78c')
    d.line((x+6,94,x+6,111),fill='#6a626e');d.line((x,102,x+12,102),fill='#6a626e')
    d.rectangle((x-4,112,x+16,116),fill='#9c736f')
d.rectangle((87,8,99,37),fill='#303247');d.rectangle((90,10,96,33),fill='#ae8e93')
house.save(OUT/'house.png')

# Frame-by-frame tiny original creatures with expressive, readable faces.
WISP=['.....oooooo.....','...ooaaaaaaoo...','..oaaaAAAaaaao..','.oaaaAAAAAaaaao.','.oaaAooooAooaao.','oaaaowwwwoWwoaao','oaaaowewwoewoaao','oaaaowewwoewoaao','.oaaaoooAoooao..','..oaaAAAAaaao...','...oaAAaaao.....','....oaaaao......','...oaaooo.......','..ooao..........','....o...........','................']
MOTH=['..oo........oo..','.oAAo......oAAo.','oAAAao....oaAAAo','oAAaaaobboaaaAAo','.oAaaobBBboaaAo.','..ooaobBBboaoo..','....oobBBboo....','...oAAobboAAo...','..oAAAobboAAAo..','...ooo....ooo...','................','................','................','................','................','................']
KNIGHT=['.....oooooo.....','....oaaaaaao....','...oaAAAAAAao...','...oAAooooAao...','...oAowwwoAao...','...oAowewoAao...','...oAoooooAao...','..oaaaaGaaaao...','.oaaAAAaAAAaao..','oaaaAAaaaAAaaao.','oaaaAAaaaAAaaao.','.oaAAAAAAAaao...','..oaaaGaaaao....','..oaaoooaaao....','..oao...oaao....','..ooo...oooo....']
palette=rgba({'o':'#252943','a':'#5f8f9a','A':'#a9d3c1','w':'#fff0ce','W':'#ffe6a1','e':'#302640','G':'#e2b96c','b':'#614c79','B':'#af91bd'})
MOSS=['......AA........','.....oAAo.......','...ooaaoooo.....','..oaAAAAAAao....','.oaAwwAAwwAao...','.oaAweAAweAao...','..oaAAAAAAao....','...oaaGGaao.....','...oaaaaaao.....','..oaaaooaaao....','..oooo..oooo....']
FANG=['...oo......oo...','..oAAo....oAAo..','..oaAAooooAAao..','...oaAAAAAAao...','..oaAwwAAwwAao..','..oaAweAAweAao..','...oaAAooAAao...','....oaAwwAao....','...oaAAAAAAao...','..oaAAAAAAAao...','..oaaaoooaaao...','..oooo...oooo...']
enemy=Image.new('RGBA',(96,160))
for kind,pattern in enumerate([MOSS,FANG,MOTH,KNIGHT,WISP]):
    for frame in range(4):
        pattern=[MOSS,FANG,MOTH,KNIGHT,WISP][kind]
        cell=Image.new('RGBA',(24,32)); cp=palette.copy()
        if kind==4: cp.update(rgba({'a':'#8c77ac','A':'#d1b7ce'}))
        if kind==0: cp.update(rgba({'a':'#4d8064','A':'#99c18a'}))
        if kind==2: cp.update(rgba({'a':'#c17a64','A':'#f1c58b'}))
        if kind==2 and frame%2:
            pattern=['......oooo......','.....oAAAao.....','....oAAbbaaAo....','....oAobBBbAo....','.....obBBbo.....','.....obBBbo.....','....oAobboAo....','....oAAooAAo....','.....oo..oo.....']
        stamp(cell,pattern,(4,5+(frame%2)),cp)
        if kind==2 and frame%2: cell=cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        enemy.alpha_composite(cell,(frame*24,kind*32))
enemy.save(OUT/'creatures.png')

guardian,d=asset('guardian',(48,64))
d.polygon([(16,8),(33,8),(33,13),(39,13),(39,30),(35,30),(39,35),(44,35),(47,51),(40,54),(35,49),(34,60),(28,62),(23,59),(17,62),(11,59),(12,48),(7,53),(1,51),(4,34),(11,31),(11,13),(16,13)],fill='#222d43')
for rect in [(16,12,33,28),(11,34,36,47),(13,48,20,58),(27,48,33,58),(5,36,10,48),(37,36,43,48)]:d.rectangle(rect,fill='#648e8a')
d.rectangle((18,13,31,17),fill='#bad0af');d.rectangle((17,20,32,25),fill='#303950')
d.point((20,22),fill='#ffe59c');d.point((28,22),fill='#ffe59c')
d.polygon([(24,33),(29,39),(24,45),(19,39)],fill='#d7c68b');d.point((24,38),fill='#fff2c2')
d.arc((9,0,39,20),185,355,fill='#dcb67c',width=2)
guardian.save(OUT/'guardian.png')

stone,d=asset('memory_stone',(24,40))
d.polygon([(6,4),(17,1),(21,7),(21,29),(23,33),(20,37),(3,37),(0,33),(3,29),(3,8)],fill='#263b4b')
d.polygon([(7,6),(16,4),(18,9),(18,28),(20,32),(4,32),(6,27)],fill='#799491')
d.line((7,9,7,26),fill='#b9c6ad',width=2)
for a,b in [((12,10),(12,24)),((8,14),(16,14)),((8,20),(16,20)),((12,24),(16,27))]:d.line((a,b),fill='#b9f0d2')
stone.save(OUT/'memory_stone.png')

lantern,d=asset('lantern',(32,64))
d.rectangle((6,8,11,60),fill='#293a48');d.rectangle((8,11,10,58),fill='#b28b69')
d.rectangle((6,7,27,11),fill='#28384b');d.line((9,8,26,8),fill='#dfb98a')
d.line((24,10,24,21),fill='#293a48',width=2)
d.polygon([(19,21),(28,21),(30,25),(28,40),(19,40),(17,25)],fill='#34334b')
d.rectangle((20,25,27,36),fill='#e9b56e');d.rectangle((22,26,25,34),fill='#fff2b0')
d.line((19,38,28,38),fill='#9f765d');lantern.save(OUT/'lantern.png')

stump,d=asset('stump',(32,32))
d.polygon([(5,9),(25,9),(27,23),(30,27),(22,29),(16,26),(8,29),(1,26),(4,21)],fill='#2b3c45')
d.rectangle((6,12,25,24),fill='#927054');d.line((9,15,9,25),fill='#c59c6e',width=2)
d.ellipse((3,4,27,17),fill='#3e4850');d.ellipse((5,5,25,15),fill='#e3c395')
d.ellipse((10,8,20,12),outline='#a37b63');stump.save(OUT/'stump.png')

flowers,d=asset('flowers',(32,24))
for x,y,c in [(6,8,'#e9a7b7'),(16,5,'#f7df91'),(25,10,'#b8c5ea')]:
    d.line((x,y+3,x,y+15),fill='#345b54');d.rectangle((x-4,y+8,x-1,y+9),fill='#75b57b')
    for dx,dy in [(-2,0),(2,0),(0,-2),(0,2)]:d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill=c)
    d.point((x,y),fill='#fff2c7')
flowers.save(OUT/'flowers.png')

board,d=asset('board',(40,56))
for x in [8,29]:d.rectangle((x,24,x+3,53),fill='#293846');d.line((x+1,27,x+1,50),fill='#b78664')
d.rectangle((2,7,38,35),fill='#293445');d.rectangle((5,10,35,32),fill='#b48a6b')
d.line((6,12,34,12),fill='#dfb794');d.rectangle((10,14,22,27),fill='#f8e8bf')
for y in [17,20,23]:d.line((12,y,19,y),fill='#9a8b8d')
d.rectangle((25,16,30,24),fill='#b0bd9d');board.save(OUT/'board.png')

chest,d=asset('chest',(32,32))
d.rectangle((2,9,29,28),fill='#272e46');d.rectangle((4,12,27,26),fill='#957287')
d.pieslice((2,1,30,22),180,360,fill='#272e46');d.pieslice((4,3,28,20),180,360,fill='#c28c8e')
for x in [7,23]:d.rectangle((x,7,x+2,26),fill='#e1b47b')
d.rectangle((3,16,28,18),fill='#30334c');d.rectangle((13,15,18,21),fill='#f5d38c');d.point((15,18),fill='#544b63')
chest.save(OUT/'chest.png')

ruin,d=asset('ruin',(96,112))
d.polygon([(4,92),(17,86),(81,86),(93,92),(93,103),(80,109),(17,109),(4,103)],fill='#2a384a')
d.rectangle((10,89,87,100),fill='#a4aba5');d.line((12,92,84,92),fill='#d5d3ba',width=2)
for x in [13,71]:
    d.rectangle((x,16,x+12,89),fill='#2d3e4d');d.rectangle((x+3,20,x+10,86),fill='#8aa39d')
    for y in [25,42,59,76]:d.line((x+3,y,x+10,y),fill='#c2c9b0')
d.arc((17,0,81,63),180,360,fill='#2c374d',width=12)
d.arc((19,3,79,61),180,360,fill='#a1ada5',width=7)
d.ellipse((30,30,65,66),fill='#283d54',outline='#d1bf89',width=2)
d.polygon([(48,35),(52,45),(62,48),(52,51),(48,61),(44,51),(34,48),(44,45)],fill='#f3d99c')
d.line((48,30,48,67),fill='#fff0b6');ruin.save(OUT/'ruin.png')

# Authored terrain palette and fixed clusters, deliberately free of random noise.
terrain=Image.new('RGBA',(256,128))
for kind in range(8):
 for variant in range(4):
    tile=Image.new('RGBA',(32,32)); td=ImageDraw.Draw(tile)
    bases=['#70a97d','#ddc69b','#579aa9','#426b63','#817d86','#afb7aa','#b79173','#b3ac9c']
    td.rectangle((0,0,31,31),fill=bases[kind])
    if kind in [0,3]:
        for x,y in [(5,8),(19,4),(26,18),(10,24),(20,28)]:
            x=(x+variant*3)%29;td.line((x,y,x,y-2),fill='#4f8a6c');td.point((x+2,y-1),fill='#a0c08b')
        if variant==3:
            for x,y in [(8,9),(23,24)]:td.point((x,y),fill='#eddfa4');td.point((x+1,y),fill='#eddfa4')
    elif kind==1:
        for x,y in [(4,5),(21,11),(11,26),(28,23)]:
            td.line((x,y,x+2,y),fill='#bba486');td.point((x+1,y-1),fill='#efddb6')
    elif kind==2:
        for y in [6,18,28]:
            x=(5+variant*3+y//2)%21;td.line((x,y,x+7,y),fill='#97c7c4');td.line((x+2,y+1,x+9,y+1),fill='#447e91')
    elif kind==4:
        td.rectangle((0,0,31,4),fill='#b9b49d' if variant==0 else '#817d86')
        for x in [6,18,27]:td.line((x,10,x-1,26),fill='#625f76');td.line((x+2,10,x+1,24),fill='#a19b9a')
        td.line((0,30,31,30),fill='#69677a')
    elif kind==5:
        for y in [0,8,16,24]:
            td.line((0,y,31,y),fill='#8b9994')
            for x in [8+(8 if y%16 else 0),24+(8 if y%16 else 0)]:td.line((x%32,y,x%32,y+7),fill='#8b9994')
    elif kind==6:
        for y in [0,8,16,24]:td.line((0,y,31,y),fill='#705f62');td.line((0,y+1,31,y+1),fill='#d5b48c')
        for x,y in [(5,4),(26,12),(8,20),(26,28)]:td.point((x,y),fill='#e6c898')
    elif kind==7:
        for y in [0,7,14,21,28]:td.line((0,y,31,y),fill='#625f74');td.line((0,y+2,31,y+2),fill='#e0d3b3')
    index=kind*4+variant;terrain.alpha_composite(tile,((index%8)*32,(index//8)*32))
terrain.save(OUT/'terrain.png')

# Village details have their own small, editable pixel-design module.
import runpy
runpy.run_path(str(ROOT/'tools/pixel_details.py'),init_globals={'OUT':OUT})

runpy.run_path(str(ROOT/'tools/draw_guardians.py'))
runpy.run_path(str(ROOT/'tools/draw_landmarks.py'))

# Update the audited manifest with explicitly identified project pixel sources.
manifest_path=ROOT/'assets/pixel/manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
manifest['images']=[x for x in manifest['images'] if not x['path'].startswith('assets/custom/')]
for path in sorted(OUT.glob('*.png')):
    manifest['images'].append({'path':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'source':'tools/draw_pixel_art.py: editable pixel patterns and authored poses','license':'Project original pixel artwork','source_type':'code-authored pixel art; no image-generation model'})
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Drew original sprite sheets, armor, townspeople, trees, cottage, and creatures from editable pixel designs.')
