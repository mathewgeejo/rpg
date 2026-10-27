"""Fixed level blueprints. Coordinates and every encounter are authored below."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'data/maps'
OUT.mkdir(exist_ok=True)
LEGEND={'.':0,':':1,'~':2,'#':3,'v':4,'=':5,'+':6,'^':7,'p':8}

def room(i,name,w,h,spawn,finish):
    grid=[['.' for _ in range(w)] for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if x<2 or y<2 or x>=w-2 or y>=h-2:grid[y][x]='#'
    return dict(id=i,name=name,subtitle='LANTERN VALE · '+['A TOWN THAT KNOWS YOUR NAME','A ROAD WITH SOMETHING TO SAY','THE RIVER KEEPS ITS PROMISES','THE MEMORY UNDER THE STARS'][i],width=w,height=h,spawn=spawn,finish=finish,terrain=grid,props=[],objects=[],enemies=[])

def box(r,x,y,w,h,t):
    for yy in range(y,y+h):
        for xx in range(x,x+w):r['terrain'][yy][xx]=t

def path(r,points,width=2,t=':'):
    for (x,y),(xx,yy) in zip(points,points[1:]):
        if x!=xx and y!=yy:raise ValueError('Paths use deliberate orthogonal segments')
        for cy in range(min(y,yy),max(y,yy)+1):
            for cx in range(min(x,xx),max(x,xx)+1):
                for a in range(-(width//2),width-width//2):
                    for b in range(-(width//2),width-width//2):r['terrain'][cy+b][cx+a]=t

def prop(r,sprite,x,y):r['props'].append(dict(sprite=sprite,position=[x,y],scale=1))
def obj(r,id,kind,name,x,y,sprite=-1,**kw):r['objects'].append(dict(id=id,kind=kind,name=name,position=[x,y],sprite=sprite,**kw))
def foe(r,id,x,y,type=0,boss=False):r['enemies'].append(dict(id=id,position=[x,y],type=type,boss=boss))

def borders(r):
    # Repeated stamps form fixed tree lines, not sampled or generated layouts.
    w,h=r['width'],r['height']
    for x in range(2,w-2,2):
        prop(r,0 if x%4 else 1,x,2);prop(r,0 if x%4 else 1,x,h-2)
    for y in range(5,h-3,3):prop(r,1,2,y);prop(r,0,w-2,y)

r=room(0,'Lanternwick',40,30,[20,21],[20,27])
path(r,[(20,27),(20,12)],3)
path(r,[(10,15),(32,15)],3)
box(r,16,17,10,6,':');path(r,[(12,21),(29,21)],2)
box(r,17,18,7,4,'p')
box(r,34,2,3,26,'~');box(r,33,15,5,3,'+')
box(r,25,5,7,6,'=');box(r,25,11,7,2,'v');box(r,27,10,2,4,'^')
for x,y in [(10,13),(30,13),(11,23),(29,24)]:prop(r,7,x,y)
prop(r,8,23,16);prop(r,2,20,10)
for x,y,s in [(7,17,0),(15,10,0),(25,16,0),(31,19,0),(14,25,1),(31,8,1),(5,9,0),(6,23,0),(28,5,16)]:prop(r,s,x,y)
for x,y in [(14,15),(25,21),(32,15),(17,24)]:prop(r,11,x,y)
for x,y in [(7,19),(8,19),(9,19),(7,20),(8,20),(9,20),(30,21),(31,21),(30,22),(31,22)]:prop(r,13,x,y)
for x,y in [(6,18),(7,18),(6,21),(7,21),(8,21),(9,21),(30,23),(31,23)]:prop(r,20,x,y)
prop(r,21,17,17);prop(r,21,24,22);prop(r,22,9,18)
obj(r,'mira','npc','Mira · Cartographer',20,14)
obj(r,'orin','npc','Orin · Lantern keeper',12,15)
obj(r,'sella','npc','Sella · Gardener',27,21)
r['objects'][-1]['path']=[[27,21],[29,21],[29,22],[27,22]]
for npc in r['objects']:
    if npc['id']=='orin':npc['path']=[[12,15],[13,15],[13,17],[12,17]]
obj(r,'lantern','rest','The village lantern',23,21,11)
obj(r,'exit_1','exit','To Wispwood Path',20,27,to=1)
obj(r,'ritual','ritual','The Remembering Stone',28,9,6)
obj(r,'board','board',"Wayfarer's board",24,18,14)
obj(r,'fish_0','fishing','Fish the quiet river',33,20,14)
obj(r,'shop','shop','The little provisions stall',9,19)
borders(r)
rooms=[r]

r=room(1,'Wispwood Path',32,28,[16,24],[22,3])
path(r,[(16,25),(16,22),(12,22),(12,17),(19,17),(19,12),(15,12),(15,7),(22,7),(22,3)],3)
path(r,[(15,12),(10,12),(10,10)],2)
box(r,9,18,5,4,'.');path(r,[(12,19),(10,19)],2)
box(r,21,14,4,4,'.');path(r,[(19,15),(22,15)],2)
obj(r,'back_1','exit','Back to Lanternwick',16,25,to=0)
obj(r,'exit_2','exit','Stonewater Crossing',22,3,10,to=2)
obj(r,'rest_1','rest',"Orin's first lantern",18,24,11)
for i,(x,y) in enumerate([(10,19),(22,15),(14,7)]):obj(r,f'memory_1_{i}','memory','A memory in the leaves',x,y,6)
obj(r,'chest_1','chest','An old leather satchel',10,10,15)
obj(r,'wood_1','woodcutting','Gather fallen willow wood',8,12,12)
for i,(x,y,t) in enumerate([(12,20,0),(18,17,1),(19,10,2),(22,5,3)]):foe(r,f'r1_e{i}',x,y,t)
for x,y,s in [(6,7,0),(9,7,1),(24,10,0),(25,14,1),(7,17,2),(25,21,0),(8,23,0),(21,21,1),(7,10,0),(25,5,1),(19,4,0)]:prop(r,s,x,y)
for x,y in [(8,15),(22,19),(18,6),(26,23),(10,5)]:prop(r,13,x,y)
prop(r,4,6,19)
# An authored root-court off the winding road.
box(r,20,7,5,4,'p')
prop(r,24,22,7)
for x,y in [(20,10),(24,10)]:prop(r,11,x,y)
obj(r,'root_lore','lore','Read the root-court inscription',20,8,6,pages=['The Briar Crown was once a gardener. It kept a single name alive until every root in this court learned to speak it.', 'Its roots strike where you were standing. Keep moving between the marked circles; the crown will not follow.'])
foe(r,'briar_crown',22,9,6,True)
r['enemies'][-1].update(name='The Briar Crown',hp=900.0,max_hp=900.0)
foe(r,'star_wisp',10,9,4)
borders(r);rooms.append(r)

r=room(2,'Stonewater Crossing',36,28,[10,24],[27,3])
path(r,[(10,25),(10,20),(14,20),(14,15),(27,15),(27,8),(27,3)],3)
box(r,17,2,4,24,'~');box(r,16,14,6,3,'+')
path(r,[(27,15),(29,15),(29,20)],2)
box(r,5,7,7,4,'=');box(r,5,11,7,2,'v');box(r,8,10,2,4,'^')
path(r,[(10,20),(8,20),(8,14)],2)
obj(r,'back_2','exit','Back to Wispwood',10,25,to=1)
obj(r,'exit_3','exit','The old observatory',27,3,10,to=3)
obj(r,'rest_2','rest',"Orin's second lantern",12,24,11)
for i,(x,y) in enumerate([(8,9),(24,15),(29,8)]):obj(r,f'memory_2_{i}','memory','A voice above the water',x,y,6)
obj(r,'chest_2','chest',"Elian's undelivered letter",29,20,15)
obj(r,'fish_2','fishing','Fish beneath the bridge',16,18,14)
for i,(x,y,t) in enumerate([(13,19,1),(15,15,0),(25,13,2),(27,6,3)]):foe(r,f'r2_e{i}',x,y,t)
for x,y,s in [(6,5,1),(13,5,0),(24,6,1),(30,11,0),(6,17,0),(25,22,1),(29,24,0),(13,23,0),(23,18,1)]:prop(r,s,x,y)
for x,y in [(7,15),(12,9),(25,9),(30,17)]:prop(r,13,x,y)
box(r,23,17,6,4,'p')
prop(r,25,26,17)
for x,y in [(23,20),(28,20)]:prop(r,11,x,y)
obj(r,'bell_lore','lore','Read the chapel ledger',24,18,6,pages=["The chapel bell rang once for every boat that returned. When the seal took the ferryman's name, it kept ringing for a passenger who could never come home.", 'The bell casts staggered waves. Wait for the first ring to fall, then cross the gap behind it.'])
foe(r,'tide_bell',26,19,7,True)
r['enemies'][-1].update(name='The Drowned Bell',hp=1250.0,max_hp=1250.0)
borders(r);rooms.append(r)

r=room(3,'The Unremembered Observatory',30,26,[15,22],[15,3])
path(r,[(15,23),(15,5)],3)
box(r,7,6,16,13,'=')
box(r,7,19,16,1,'v')
box(r,14,18,3,3,'^');box(r,14,5,3,3,'^')
prop(r,26,15,8)
for x,y in [(7,7),(22,7),(7,17),(22,17)]:prop(r,16,x,y)
obj(r,'star_lore','lore',"Read the astronomer's oath",11,19,6,pages=['A circle is a promise made to the self. A star is a promise carried for another. The Keeper was built to hold both, and given no way to refuse.', 'It marks your last position with a falling star. At half health, four satellite marks follow. Leave space between yourself and the Keeper.'])
for x,y in [(5,8),(24,8),(5,19),(24,19)]:prop(r,1,x,y)
obj(r,'back_3','exit','Back to Stonewater',15,23,to=2)
obj(r,'rest_3','rest','The last small light',18,22,11)
obj(r,'seal','seal','The Observatory Seal',15,7,16)
obj(r,'home','exit','Follow the lanterns home',15,3,10,to=0)
foe(r,'the_keeper',15,12,5,True)
r['enemies'][-1].update(hp=1800.0,max_hp=1800.0)
borders(r);rooms.append(r)

for r in rooms:
    r['terrain']=[''.join(row) for row in r['terrain']]
    (OUT/f'{r["id"]:02}_{["lanternwick","wispwood","stonewater","observatory"][r["id"]]}.json').write_text(json.dumps(r,indent=2),encoding='utf-8')
print('Wrote four fixed, authored maps. No random layouts or procedural terrain.')
