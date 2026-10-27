"""Deliberately placed village details for draw_pixel_art.py; no image model."""
from PIL import Image, ImageDraw

house=Image.open(OUT/'house.png').convert('RGBA')
for suffix,colors in [('green',{'575e91':'4d8175','a2a2c4':'a6c1a3','3c426e':'36585e'}),('rose',{'575e91':'a57589','a2a2c4':'d6b8ad','3c426e':'6a526b'})]:
    image=house.copy()
    colors={tuple(bytes.fromhex(a)):tuple(bytes.fromhex(b)) for a,b in colors.items()}
    for y in range(image.height):
        for x in range(image.width):
            p=image.getpixel((x,y))
            if p[:3] in colors:image.putpixel((x,y),colors[p[:3]]+(p[3],))
    image.save(OUT/f'house_{suffix}.png')

tree=Image.open(OUT/'tree.png').convert('RGBA');d=ImageDraw.Draw(tree)
for x,y,w,h in [(14,17,15,7),(27,10,14,7),(40,22,14,8),(10,31,15,8),(24,26,19,9),(28,39,17,7)]:
    d.rectangle((x,y,x+w,y+h),fill='#407e6b')
    d.polygon([(x+3,y),(x+w-3,y),(x+w,y+2),(x+w,y+h-2),(x+w-3,y+h),(x+2,y+h),(x,y+h-2),(x,y+2)],fill='#75ad75')
    d.line((x+3,y,x+w-4,y),fill='#b8ce89',width=2)
    d.line((x+3,y+h,x+w-3,y+h),fill='#326558')
    d.point((x+4,y+3),fill='#a1c481');d.point((x+w-3,y+4),fill='#579c71')
tree.save(OUT/'tree.png')

im=Image.new('RGBA',(32,40));d=ImageDraw.Draw(im)
for x in [2,26]:
    d.rectangle((x,6,x+4,35),fill='#33404b');d.rectangle((x+1,8,x+3,33),fill='#d2af86')
for y in [15,26]:
    d.rectangle((0,y,31,y+3),fill='#4e4b58');d.line((0,y,31,y),fill='#e1bd8d')
im.save(OUT/'fence.png')
im=Image.new('RGBA',(48,32));d=ImageDraw.Draw(im)
d.rectangle((4,2,44,16),fill='#293747')
for y in [4,9]:
    d.rectangle((6,y,42,y+3),fill='#b69077');d.line((7,y,41,y),fill='#e2c49a')
d.rectangle((2,17,46,22),fill='#303748');d.rectangle((4,17,44,19),fill='#d6ae85')
for x in [7,39]:d.rectangle((x,22,x+3,29),fill='#4c4b59')
im.save(OUT/'bench.png')
im=Image.new('RGBA',(72,80));d=ImageDraw.Draw(im)
for x in [7,61]:
    d.rectangle((x,22,x+3,74),fill='#303b4c');d.line((x+1,24,x+1,72),fill='#c79b77')
d.polygon([(3,24),(12,2),(59,2),(69,24)],fill='#30364b')
for i,x in enumerate(range(9,64,9)):
    d.polygon([(x,5),(x+7,5),(min(66,x+10),23),(max(5,x-3),23)],fill='#b794b7' if i%2 else '#e8d6b4')
d.rectangle((4,24,67,30),fill='#34364c')
for i,x in enumerate(range(6,66,9)):d.rectangle((x,24,x+6,28),fill='#c4adc8' if i%2 else '#e8d6b4')
d.rectangle((5,54,66,74),fill='#31394b');d.rectangle((8,57,63,71),fill='#a98673');d.line((8,57,63,57),fill='#e2c49a',width=2)
for x in [20,45]:
    d.rectangle((x,49,x+9,54),fill='#8cab88');d.line((x+1,49,x+8,49),fill='#e9dab0')
im.save(OUT/'stall.png')

original=Image.open(OUT/'terrain.png').convert('RGBA')
terrain=Image.new('RGBA',(256,160));terrain.alpha_composite(original)
for variant in range(4):
    tile=Image.new('RGBA',(32,32),'#d2c6ab');d=ImageDraw.Draw(tile)
    for y in [0,8,16,24]:
        d.line((0,y,31,y),fill='#b2a58e')
        for x in [8+(8 if y%16 else 0),24+(8 if y%16 else 0)]:d.line((x%32,y,x%32,y+7),fill='#b2a58e')
    terrain.alpha_composite(tile,(variant*32,128))
terrain.save(OUT/'terrain.png')

# Six deliberate guardian poses: calm, core pulse, blink, then a raised-arm cast.
guardian=Image.open(OUT/'guardian.png').convert('RGBA')
sheet=Image.new('RGBA',(144,128))
for row in range(2):
    for frame in range(3):
        pose=guardian.copy(); d=ImageDraw.Draw(pose)
        if row==0 and frame==1:
            d.rectangle((23,36,25,40),fill='#fff5c2')
        if row==0 and frame==2:
            d.line((19,22,21,22),fill='#648e8a');d.line((27,22,29,22),fill='#648e8a')
        if row==1:
            left=pose.crop((0,32,13,55));right=pose.crop((35,32,48,55))
            d.rectangle((0,32,12,54),fill=(0,0,0,0));d.rectangle((35,32,47,54),fill=(0,0,0,0))
            d.line((12,33,12,46),fill='#223043');d.line((35,33,35,46),fill='#223043')
            pose.alpha_composite(left,(0,30-frame*4));pose.alpha_composite(right,(35,30-frame*4))
            d=ImageDraw.Draw(pose)
            for x,y in [(4,24-frame*3),(42,24-frame*3),(24,2)]:
                d.line((x-2,y,x+2,y),fill='#f9dea1');d.line((x,y-2,x,y+2),fill='#f9dea1')
        sheet.alpha_composite(pose,(frame*48,row*64))
sheet.save(OUT/'guardian_anim.png')
