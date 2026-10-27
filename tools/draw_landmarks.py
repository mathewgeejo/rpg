"""Original fixed pixel structures, drawn at native pixel resolution."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets/custom'

def stone(d, rect, front='#8d9b9b', edge='#313a53'):
    x,y,xx,yy=rect
    d.rectangle(rect,fill=edge)
    d.rectangle((x+2,y+2,xx-3,yy-2),fill=front)
    d.line((x+2,y+2,xx-4,y+2),fill='#ded9bc',width=2)
    d.line((xx-2,y+3,xx-2,yy-2),fill='#59677d',width=2)
    for row in range(y+12,yy,12):
        d.line((x+2,row,xx-3,row),fill='#59677d')
        joint=x+7+(6 if (row//12)%2 else 0)
        if joint<xx-2:d.line((joint,row-9,joint,row),fill='#647585')

# A gate grown around the remnant of a circular shrine.
im=Image.new('RGBA',(160,144));d=ImageDraw.Draw(im)
stone(d,(19,56,39,132));stone(d,(121,56,141,132))
d.polygon([(27,57),(29,28),(49,9),(109,9),(132,30),(133,59),(118,59),(117,36),(103,24),(57,24),(43,38),(43,59)],fill='#30354c')
d.line([(35,57),(37,33),(53,16),(106,16),(124,34),(125,57)],fill='#91a49a',width=6)
for points in [[(5,137),(27,103),(22,71),(32,45),(38,54),(33,79),(38,111),(24,135)],[(155,137),(128,105),(137,75),(126,46),(120,55),(125,81),(120,112),(136,136)]]:
    d.polygon(points,fill='#34394a');d.line(points[:4],fill='#916f68',width=4)
for x,y,w in [(17,26,31),(37,7,40),(78,3,38),(112,20,30)]:
    d.polygon([(x,y+9),(x+7,y),(x+w-5,y),(x+w,y+8),(x+w-5,y+19),(x+4,y+19)],fill='#315c56')
    d.line((x+8,y+3,x+w-7,y+3),fill='#adc68c',width=3)
    d.rectangle((x+7,y+6,x+w-8,y+12),fill='#6f9b79')
for x,y in [(25,83),(129,86),(76,16)]:
    d.rectangle((x-3,y-4,x+3,y+4),fill='#28374d');d.line((x,y-2,x,y+2),fill='#f3d292')
d.line([(28,133),(54,127),(68,132),(80,127),(104,132),(132,134)],fill='#776b65',width=3)
im.save(OUT/'root_gate.png')

# A roofless bell chapel: narrow pillars, deep side faces, cracked lintel.
im=Image.new('RGBA',(144,144));d=ImageDraw.Draw(im)
for x in [13,108]:
    stone(d,(x,43,x+23,134),front='#7f91a0')
    stone(d,(x-4,126,x+27,139),front='#a5b3b0')
d.polygon([(7,44),(23,15),(70,0),(121,16),(138,44)],fill='#303a55')
d.polygon([(17,39),(29,22),(70,8),(115,23),(129,39)],fill='#7b94a1')
d.line([(25,36),(37,26),(68,17),(113,31)],fill='#c5d1bf',width=2)
stone(d,(6,40,137,52),front='#a7b2b1')
d.line([(87,14),(78,27),(83,36),(74,46)],fill='#38435b',width=2)
for x,y in [(27,66),(119,67)]:
    d.rectangle((x-3,y,x+3,y+12),fill='#36465b')
    d.line((x,y+3,x,y+9),fill='#8fdfd9',width=2)
for x,y in [(4,129),(43,133),(87,135),(133,130)]:stone(d,(x,y,x+7,y+5))
im.save(OUT/'bell_chapel.png')

# Observatory facade with a recessed violet dome and visible masonry thickness.
im=Image.new('RGBA',(224,176));d=ImageDraw.Draw(im)
d.polygon([(22,94),(28,49),(52,21),(90,4),(135,4),(174,21),(198,49),(204,94)],fill='#252d48')
d.polygon([(32,89),(37,53),(60,28),(94,13),(131,13),(167,28),(189,53),(194,89)],fill='#55567e')
d.line([(40,79),(47,53),(66,33),(96,20),(129,20),(159,33),(181,53),(187,79)],fill='#9d91b1',width=3)
for x in [69,111,154]:d.line([(111,15),(x,59),(x-5,88)],fill='#323d5c',width=3)
for x,y in [(68,43),(97,31),(141,43),(165,66),(52,67)]:
    d.line((x-2,y,x+2,y),fill='#ead6a4');d.line((x,y-2,x,y+2),fill='#ead6a4')
stone(d,(17,90,206,104),front='#a9a7ae')
for x in [22,177]:
    stone(d,(x,103,x+23,162),front='#8e929f')
    stone(d,(x-6,157,x+29,171),front='#bbb4ae')
    d.rectangle((x+7,114,x+14,140),fill='#41435e');d.line((x+11,118,x+11,137),fill='#c5ba91',width=2)
d.line([(111,15),(119,29),(111,40),(117,52)],fill='#252d48',width=2)
im.save(OUT/'observatory_dome.png')
