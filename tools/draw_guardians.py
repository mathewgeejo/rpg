"""Editable pixel designs for the two optional guardians, with six deliberate poses."""
from PIL import Image, ImageDraw
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'assets/custom'
for name in ['briar_crown', 'tide_bell']:
    sheet = Image.new('RGBA', (144, 128))
    for state in range(2):
        for frame in range(3):
            pose = Image.new('RGBA', (48,64))
            d = ImageDraw.Draw(pose)
            lift = [0, 1, 0][frame] if state == 0 else [2, 4, 6][frame]
            if name == 'briar_crown':
                # Split roots anchor a hollow wooden mask beneath a thorn crown.
                for points in [[(22,41),(11,54),(3,57),(14,59),(27,47)],[(25,42),(36,53),(45,56),(35,59),(21,48)],[(22,44),(18,59),(24,61),(29,47)]]:
                    d.polygon(points,fill='#302b40')
                d.polygon([(14,29),(17,47),(24,53),(33,45),(36,27),(29,19),(21,21)],fill='#765b60')
                d.polygon([(19,30),(21,45),(26,48),(30,41),(30,27)],fill='#b88c77')
                d.line([(18,30),(20,39),(18,43)],fill='#493c4f',width=2)
                for x,y in [(8,26),(32,23),(16,18)]:
                    d.polygon([(x,y),(x-3,y-9-lift),(x+5,y-6-lift),(x+10,y-13-lift),(x+14,y),(x+7,y+4)],fill='#344b50')
                    d.polygon([(x,y-2),(x+3,y-7-lift),(x+7,y-3-lift),(x+10,y-8-lift),(x+11,y)],fill='#779878')
                d.rectangle((19,29,22,32),fill='#e8e8ac');d.rectangle((28,28,31,31),fill='#e8e8ac')
                d.rectangle((24,37,26,42),fill='#302b40')
                for x,y in [(9,21),(36,19),(23,11)]:
                    d.polygon([(x,y-lift),(x+2,y-3-lift),(x+4,y-lift),(x+2,y+3-lift)],fill='#e7be9a')
                if state: d.line([(4,41-lift),(10,35-lift),(16,36)],fill='#99c39b',width=2)
            else:
                # A cracked bronze diving bell carried by articulated stone legs.
                for x,sign in [(12,-1),(34,1)]:
                    d.line([(x,43),(x+sign*4,51-lift),(x+sign*7,58)],fill='#29344d',width=5)
                    d.rectangle((x+sign*7-3,57,x+sign*7+3,60),fill='#6d8c9b')
                d.polygon([(11,21),(16,15),(31,15),(37,22),(36,40),(42,47),(41,51),(6,51),(5,47),(11,40)],fill='#30354d')
                d.polygon([(14,23),(19,18),(29,18),(34,24),(33,40),(37,46),(10,46),(15,39)],fill='#a58d70')
                d.polygon([(17,24),(20,20),(24,20),(22,42),(15,43)],fill='#d8bc88')
                d.rectangle((10,47,37,49),fill='#d8bc88')
                d.line([(29,20),(25,29),(29,35),(25,43)],fill='#3d4c61',width=2)
                d.rectangle((19,29,22,31),fill='#8ce4e1');d.rectangle((29,29,32,31),fill='#8ce4e1')
                d.rectangle((20,10-lift,27,14-lift),fill='#3d4c61')
                d.rectangle((22,8-lift,25,11-lift),fill='#9bcacb')
                if state:
                    for x,y in [(5,25),(40,31),(10,11)]:
                        d.rectangle((x,y-lift,x+2,y+3-lift),fill='#a0eff0')
            sheet.alpha_composite(pose,(frame*48,state*64))
    sheet.save(OUT/(name+'.png'))
