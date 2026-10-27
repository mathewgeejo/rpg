"""Check sprite frame boundaries, useful motion, and crisp pixel transparency."""
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
checks=0
for name in ['wanderer_cloth','wanderer_plate','wanderer_leather','mira','orin','sella']:
    image=Image.open(root/f'assets/custom/{name}.png').convert('RGBA')
    assert image.size==(288,960),name
    assert set(image.getchannel('A').getdata()) <= {0,255},f'{name}: antialiasing in pixel source'
    checks+=2
    for row in range(20):
        frames=[]
        for frame in range(6):
            cell=image.crop((frame*48,row*48,(frame+1)*48,(row+1)*48))
            bbox=cell.getchannel('A').getbbox()
            assert bbox is not None,f'{name}: empty frame {row}/{frame}'
            assert bbox[1]>=1 and bbox[3]<=47,f'{name}: vertically clipped pose'
            frames.append(cell.tobytes());checks+=2
        if row<4 or 4<=row<12 or 12<=row<16:
            assert len(set(frames))>=3,f'{name}: insufficient distinct poses in row {row}'
            checks+=1
terrain=Image.open(root/'assets/custom/terrain.png').convert('RGBA')
for index in range(36):
    tile=terrain.crop((index%8*32,index//8*32,index%8*32+32,index//8*32+32))
    assert tile.getchannel('A').getextrema()==(255,255),f'Terrain tile {index} contains holes'
    checks+=1
guardian=Image.open(root/'assets/custom/guardian_anim.png').convert('RGBA')
assert guardian.size==(144,128)
checks+=1
for name in ['briar_crown','tide_bell']:
    image=Image.open(root/f'assets/custom/{name}.png').convert('RGBA')
    assert image.size==(144,128),name
    assert set(image.getchannel('A').getdata()) <= {0,255},name
    poses=[image.crop((x*48,y*64,(x+1)*48,(y+1)*64)).tobytes() for y in range(2) for x in range(3)]
    assert len(set(poses)) >= 4,f'{name}: insufficient distinct guardian poses'
    checks+=3
creatures=Image.open(root/'assets/custom/creatures.png').convert('RGBA')
assert creatures.size==(96,160)
checks+=1
species=[]
for row in range(5):
    frames=[creatures.crop((x*24,row*32,(x+1)*24,(row+1)*32)).tobytes() for x in range(4)]
    assert len(set(frames))>=2,f'Creature {row}: no animation'
    species.append(frames[0]);checks+=1
assert len(set(species))==5,'Species must have different pixel designs'
checks+=1
for name in ['root_gate','bell_chapel','observatory_dome']:
    image=Image.open(root/f'assets/custom/{name}.png').convert('RGBA')
    assert set(image.getchannel('A').getdata()) <= {0,255},name
    assert image.width>=144 and image.height>=144,name
    checks+=2
print(f'PASS: {checks} pixel-art checks; character poses, three guardians, five animated species, landmarks, and opaque terrain.')
