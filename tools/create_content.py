"""Author the offline content pack. No network or runtime generation service needed."""
import json
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'data'
OUT.mkdir(exist_ok=True)
DIMENSIONS = ['agency', 'duty', 'compassion', 'ambition', 'uncertainty', 'identity', 'belonging', 'sacrifice', 'truth', 'change']

# Every signature below has its own execution branch in combat.gd.
ROWS = [
('Gambler','The house is a state of mind.','luck','circle','uncertainty','ambition','Loaded Fate','Roll a visible die: a low roll restores mana; a high roll strikes harder. Six resets the cooldown.','House Edge','Dodging danger builds luck for the next roll.'),
('Debtweaver','Every gift leaves a thread.','debt','circle','duty','sacrifice','Borrowed Tomorrow','Borrow health for power; marked enemies repay the loan when struck.','Interest','Marked foes return health when defeated.'),
('Coin Saint','Value is what you choose to save.','coin','hybrid','compassion','sacrifice','Mercy Mint','Spend ten coins to heal and scatter sanctified coins that stagger nearby foes.','Alms','Collecting a memory restores a little health.'),
('Fortune Thief','Luck belongs to whoever survives it.','fortune','star','agency','uncertainty','Stolen Tomorrow','Steal an enemy attack windup, briefly freezing foes and gaining haste.','Sleight','Attacking a staggered foe restores stamina.'),
('Auctioneer','Everything has a price. Name yours.','auction','circle','ambition','truth','Final Bid','Hold your ground to place a damaging field; each enemy inside increases its final blast.','Appraisal','Reveals enemy health and rewards extra coins.'),
('Memory Shepherd','What is forgotten still needs a home.','memory','circle','compassion','identity','Remembered Blade','Record your position and attack; a spectral echo repeats the strike a moment later.','Keepsake','Memory fragments increase maximum mana.'),
('Name Thief','A name is a door left unlocked.','name','circle','agency','identity','Unname','Silence and weaken the nearest foe, borrowing its strength for your next attack.','Alias','First strike against each enemy deals extra damage.'),
('Echo Duelist','No movement ends where you think.','echo','star','identity','change','Second Answer','Dash through a target; an echo delivers a second cut along the same line.','Refrain','Consecutive attacks build an echo bonus.'),
('Maskwright','The self is something we rehearse.','mask','hybrid','identity','belonging','Borrowed Face','Leave a taunting mask behind and become briefly invisible to enemies.','Persona','Entering combat grants a small shield.'),
('Epitaph Keeper','An ending deserves a witness.','epitaph','circle','duty','identity','Last Words','Inscribes a grave seal that executes weakened foes and slows the rest.','Elegy','Enemy defeats lower your active cooldown.'),
('Oathbreaker','Some promises deserve to die.','oath','star','agency','change','Break the Vow','Attacking builds a vow. Break it to discharge a broad, armor-shattering crescent.','Unbound','Your third basic attack builds additional vow.'),
('Vow Knight','Freedom can be a chosen limit.','vow','star','duty','identity','Standfast','Root yourself briefly, gain a strong shield, and punish nearby enemies.','Resolve','Standing still steadily restores posture.'),
('Witness','Seeing creates responsibility.','witness','circle','truth','duty','Testimony','Mark every visible foe; their next damage is repeated by a spectral witness.','Attention','Marked enemies have longer attack windups.'),
('Penitent','Pain is a question, not an answer.','penance','hybrid','sacrifice','compassion','Absolution','Spend health to unleash a cleansing ring; defeating a foe returns the sacrifice.','Penance','Damage grows as health falls.'),
('Bannerless','No king can own the horizon.','banner','star','agency','belonging','No Crown','Raise a wandering standard that restores stamina and empowers movement attacks.','Wanderer','Moving continuously builds momentum.'),
('Clock Mourner','Time keeps what we cannot.','clock','circle','identity','sacrifice','Still Hour','Create a clock face that slows foes while its hands sweep outward.','Patience','Slow effects last longer.'),
('Tomorrow Smith','The future must be made by hand.','smith','star','ambition','change','Future Forged','Temper your next three attacks into expanding shockwaves.','Temper','Each third hit restores a little mana.'),
('Delayblade','The cut arrives when it is needed.','delay','star','duty','uncertainty','Unpaid Cut','Slash now; all enemies struck receive a second wound after two seconds.','Interval','Dodging reduces delayed-cut cooldown.'),
('Moment Thief','A second can hold an entire life.','moment','star','agency','ambition','Borrow a Second','Blink toward your aim and steal stamina from enemies near your arrival.','Quickening','Defeating a foe grants brief haste.'),
('Afterimage','Absence has a shape.','afterimage','hybrid','identity','uncertainty','Absent Self','Split into three spectral decoys that explode when their short lives end.','Blur','Dodging leaves a brief distracting echo.'),
('Thorn Host','Let the wound grow into something.','thorn','hybrid','sacrifice','change','Bloom from Hurt','Plant a thorn garden. Stored damage feeds its reach and venom.','Cultivation','Damage taken stores growth for the next garden.'),
('Bloom Alchemist','Healing is an unruly experiment.','bloom','circle','compassion','change','Verdant Reaction','A restorative bloom heals you and poisons nearby foes in equal measure.','Sap','Poisoned enemies yield additional healing.'),
('Mothkeeper','Small lights lead through enormous dark.','moth','circle','compassion','uncertainty','Lantern Swarm','Release homing moth lights that seek enemies and restore mana on impact.','Nocturne','Casting at low mana costs less.'),
('Rot Gardener','Decay is a form of generosity.','rot','circle','change','compassion','Patient Orchard','Seed a spreading rot field; defeated enemies nourish a healing patch.','Compost','Poison defeats restore health.'),
('Wild Anatomist','To understand life is to be changed.','anatomy','hybrid','truth','change','Expose the Seam','Reveal a target weakness; the next five hits shred its defenses.','Study','Repeated hits against one target deal more damage.'),
('Doorwright','Distance is a habit of the world.','door','circle','agency','change','Two Places, One Step','Place linked gates, blink between them, and cut every enemy along their seam.','Threshold','Gate travel restores a little stamina.'),
('Horizon Lancer','The farthest point is a promise.','lance','star','ambition','duty','Beyond the Line','Lunge a great distance, piercing every foe in your path.','Reach','Attacks at the edge of reach deal extra damage.'),
('Foldwalker','There is always another way through.','fold','hybrid','agency','uncertainty','Paper World','Fold space around your position, pulling enemies into a compact knot.','Crease','Pulled foes remain briefly staggered.'),
('Compass Heretic','North is only one opinion.','compass','circle','agency','truth','False North','Reverse nearby enemies away from you and mark a new path with damaging needles.','Deviation','Moving against your last attack direction grants haste.'),
('Gravity Dancer','Fall with intention.','gravity','star','uncertainty','change','Falling Upward','Lift foes in a graceful spiral before slamming them into the earth.','Poise','Dodges cost less stamina.'),
('Ink Summoner','Creation is a kind of confession.','ink','circle','identity','change','Living Marginalia','Draw an ink familiar that hunts enemies with splashing strikes.','Margins','Your familiar returns mana with each third hit.'),
('Silence Bard','Listen to what remains unsaid.','silence','circle','compassion','truth','The Quiet Between','A soundless wave cancels windups and silences nearby enemies.','Rest','A pause between attacks restores extra mana.'),
('Glass Composer','Even breaking can make a song.','glass','hybrid','identity','ambition','Shatter Sonata','Arrange resonant glass prisms; strike again to shatter them into damaging shards.','Harmony','Each active prism amplifies your spell damage.'),
('Marionettist','Control has a cost on both ends.','puppet','circle','ambition','belonging','Cut the Strings','Bind nearby foes together, then pull their shared strings for linked damage.','Tension','Bound enemies move more slowly.'),
('Dream Sculptor','Possibility needs a place to sleep.','dream','circle','uncertainty','identity','Gentle Impossibility','Create a dream field that sleeps enemies until struck, amplifying the waking hit.','Lucidity','Waking a sleeper restores mana.'),
('Wound Alchemist','Nothing suffered must be wasted.','wound','hybrid','sacrifice','truth','Red Transmutation','Convert missing health into a damaging blood ring and temporary protection.','Conversion','Low health increases shield strength.'),
('Ash Pilgrim','What burned can still guide us.','ash','star','sacrifice','identity','Road of Embers','Dash and leave a burning pilgrim trail that punishes pursuit.','Cinder','Dodge trails deal lingering damage.'),
('Hunger Monk','Desire can be disciplined, never erased.','hunger','star','ambition','sacrifice','Empty Bowl','Drain nearby enemies to refill stamina; overflow restores health.','Fasting','At low mana, weapon damage increases.'),
('Last Lantern','Hope is a task you keep doing.','lantern','hybrid','compassion','duty','Keep the Light','Kindle a protective lantern that heals and repels enemies in pulses.','Vigil','Surviving a lethal hit once per rest leaves one health.'),
('Burden Bearer','Strength can mean carrying another.','burden','star','belonging','sacrifice','Weight of the World','Convert stamina to armor, then release a weighted ground slam.','Shoulder','High stamina reduces incoming damage.'),
('Paradox Scholar','A contradiction can be a doorway.','paradox','circle','truth','uncertainty','Impossible Proof','Alternate frost and fire: one cast freezes; the next detonates frozen foes.','Contradiction','Alternating basic attacks and spells increases damage.'),
('False Prophet','Belief changes what survives.','prophet','circle','ambition','belonging','Useful Lie','Declare yourself invulnerable for a short time; afterward lose the remaining ward.','Conviction','Your first hit after a ward expires deals more damage.'),
('Questioner','Certainty is where inquiry begins.','question','circle','truth','agency','Why Must It Be?','Strip enemy shields and interrupt attacks with a piercing question.','Doubt','Interrupted enemies take more damage.'),
('Cipher Monk','Meaning hides in the intervals.','cipher','hybrid','truth','duty','Threefold Key','Set three orbiting runes that strike sequentially and unlock a finishing blast.','Pattern','Every third action has reduced mana cost.'),
('Null Cartographer','The blank places belong to everyone.','null','circle','truth','change','Uncharted Ground','Erase hostile projectiles and make a null field where enemies cannot cast.','Blank','Standing inside your null field restores mana.'),
('Threadbinder','A bond is made, not found.','thread','circle','belonging','duty','Shared Fate','Link foes with silver thread; a fraction of each strike reaches all linked enemies.','Kinship','Each linked enemy strengthens your ward.'),
('Pactless','Consent is the first magic.','pact','star','agency','truth','I Refuse','Break every status effect, gain brief immunity, and strike those who bound you.','Sovereignty','Control effects on you have reduced duration.'),
('Familiar King','A crown is a promise to the small.','familiar','circle','belonging','compassion','Court of Small Things','Summon three tiny familiars that orbit, intercept, and attack.','Court','Familiars grant a small passive shield.'),
('Hearth Witch','A home is an action, repeated.','hearth','circle','belonging','compassion','A Place to Return','Mark a warm hearth. It heals nearby; recasting returns you to it.','Welcome','Resting at lanterns grants extra maximum health.'),
('Exile Sovereign','Belonging can be built beyond borders.','exile','hybrid','agency','belonging','Kingdom of One','Claim a circle of land: gain power inside it and blast foes across its boundary.','Sovereign','Fighting far from the town increases your damage.'),
]

PROMPTS = [
('The bridge remembers','A bridge will save a village, but it can be built only from the memories of its oldest resident. She offers them willingly. What do you ask first?', [('Whether her consent can survive losing who she is.','identity','agency'),('Whether another bridge can be made, even at greater risk.','change','uncertainty'),('Whether the village will care for her afterward.','compassion','belonging'),('Whether I can give my memories in her place.','sacrifice','duty')]),
('A fair coin','A stranger offers a coin that can save one unknown life or grant you the strength to save many later. The future cannot be verified.', [('Save the life that exists in front of me.','compassion','duty'),('Take the strength and accept responsibility for the wager.','ambition','uncertainty'),('Investigate who made the rules of this bargain.','truth','agency'),('Let the stranger choose; I will share the consequence.','belonging','sacrifice')]),
('The borrowed name','A child has stolen the name of a dead hero. The name gives her courage and brings comfort to a grieving town.', [('Tell her the truth in private, then help her find her own name.','truth','compassion'),('Let the name belong to whoever needs it.','change','identity'),('Ask what she will do when the town needs the hero again.','duty','ambition'),('Stand beside her and share the lie openly.','belonging','sacrifice')]),
('A vow made young','You promised never to draw a weapon. Keeping the vow now leaves another person defenseless.', [('Break the vow and remember why I broke it.','agency','compassion'),('Keep it and put my own body in the way.','duty','sacrifice'),('Find a way to change what a weapon means.','change','uncertainty'),('Ask the threatened person what help they want.','belonging','truth')]),
('The perfect map','An accurate map would reveal a hidden sanctuary to refugees and to the army pursuing them.', [('Make the map, then entrust it to the refugees.','agency','truth'),('Leave the sanctuary blank and accept an imperfect truth.','compassion','uncertainty'),('Draw a false route and take responsibility for the deception.','duty','sacrifice'),('Move the sanctuary so no map can own it.','change','ambition')]),
('The empty throne','A city asks you to rule for one year. You can improve its laws, but leaving will be harder than arriving.', [('Accept, with a public agreement that I cannot extend my rule.','duty','truth'),('Help its people form a council instead.','belonging','agency'),('Accept; good intentions need real power to matter.','ambition','compassion'),('Decline, but return each season to be held accountable.','identity','sacrifice')]),
('The last seed','A seed can restore a dead forest, or become medicine for someone you love.', [('Choose the person; love makes a claim I will answer.','belonging','identity'),('Choose the forest, and bear the grief without calling it justice.','sacrifice','compassion'),('Delay the choice to search for a third use.','uncertainty','change'),('Give the choice to the person who needs the medicine.','agency','duty')]),
('A useful monster','A creature protects the town only because it is chained. Releasing it may undo years of safety.', [('Release it and help the town learn a different safety.','agency','change'),('Ask whether it would protect the town by agreement.','belonging','truth'),('Maintain the chain until an alternative is ready.','duty','compassion'),('Take its place while the town prepares.','sacrifice','identity')]),
('An honest failure','Your failed experiment proves a respected theory wrong. Publishing it will end your teacher\'s career.', [('Publish it and credit the teacher for making inquiry possible.','truth','duty'),('Speak with the teacher before anyone else.','compassion','belonging'),('Repeat the experiment until uncertainty is small enough.','uncertainty','identity'),('Build a better theory before bringing the old one down.','ambition','change')]),
('The road home','You can return to the life you remember, but only if you forget everything learned on the road.', [('Continue; the road has become part of who I am.','identity','change'),('Return; being needed matters more than being remarkable.','belonging','duty'),('Find who built the gate and question the condition.','truth','agency'),('Let chance choose, then commit to the life it leaves.','uncertainty','sacrifice')]),
('The unearned gift','You inherit power from someone whose actions harmed strangers. The power itself could help them.', [('Use it, but let those harmed set the terms.','compassion','duty'),('Refuse it; some inheritances repeat the injury.','identity','sacrifice'),('Transform it into something that cannot serve its old purpose.','change','ambition'),('Learn its full history before deciding what it is.','truth','uncertainty')]),
('The witness and the crowd','You alone remember an event differently from everyone else. Both versions explain the evidence.', [('Keep a record of both versions.','truth','uncertainty'),('Trust my memory while remaining open to correction.','identity','agency'),('Ask which version helps people heal, without calling it proven.','compassion','change'),('Stay with the people who share the cost of remembering.','belonging','sacrifice')]),
('A debt without a creditor','Someone who saved your life asks you to repay the debt to a stranger they dislike.', [('Help the stranger because need is enough.','compassion','agency'),('Honor the request; promises outlive our preferences.','duty','identity'),('Ask what harm repayment might quietly continue.','truth','uncertainty'),('Turn the debt into a community fund anyone can draw from.','belonging','change')]),
('A door with no return','Beyond a door is knowledge that may solve the world\'s oldest problem. Nobody who enters has returned.', [('Enter, leaving my work for someone who may follow.','ambition','sacrifice'),('Study the door with others until we can return together.','truth','belonging'),('Protect the right of others to decide whether to enter.','agency','duty'),('Leave the door open and build a life beside the mystery.','uncertainty','identity')]),
('The gentle lie','A dying traveler asks whether their estranged family forgave them. You do not know.', [('Say I do not know, and stay with them.','truth','compassion'),('Tell them the forgiveness they need to hear.','compassion','sacrifice'),('Ask what forgiving themselves would mean.','identity','agency'),('Offer to carry their final words to the family.','duty','belonging')]),
('The rival\'s triumph','A rival discovers what you have pursued for years. They invite you to help finish the work.', [('Join; the discovery matters more than its owner.','truth','belonging'),('Join, and ask for responsibility equal to my contribution.','ambition','duty'),('Follow a new question their discovery makes possible.','change','uncertainty'),('Admit my envy before deciding whether I can help honestly.','identity','agency')]),
('The garden of grief','A garden blooms only when its keeper remembers a loss. Healing their grief would make it wither.', [('Help the keeper heal, and mourn the garden too.','compassion','change'),('Ask whether tending the garden is their chosen way of living.','agency','identity'),('Find a way to share the remembering.','belonging','sacrifice'),('Study whether the garden needs grief or merely attention.','truth','uncertainty')]),
('A law for the storm','Breaking a city\'s evacuation order lets you reach people the official plan has overlooked.', [('Break it and account for every risk I create.','agency','duty'),('Work within the plan to redirect help quickly.','belonging','ambition'),('Go alone so others do not bear my decision.','sacrifice','identity'),('Ask those overlooked which route they trust.','compassion','truth')]),
('A second self','A perfect copy of you awakens with your memories and a different desire for the future.', [('Treat them as kin, with a life of their own.','belonging','agency'),('Compare our differences to understand how selves are made.','truth','change'),('Share our obligations, but not ownership of our choices.','duty','identity'),('Let them take my place while I begin again.','sacrifice','uncertainty')]),
('The bargain of peace','Two enemies will stop fighting if their children are never told what began the conflict.', [('Accept a truce, but preserve a record for a later generation.','duty','truth'),('Refuse inherited silence and work for a harder peace.','change','ambition'),('Ask the children what they want to inherit.','agency','compassion'),('Build shared rituals before asking for shared history.','belonging','uncertainty')]),
('What the fire leaves','You have time to save one thing from a burning archive: a cure, a history, a letter, or an unfinished map.', [('The cure: knowledge should answer suffering.','compassion','duty'),('The history: a future needs an honest past.','truth','identity'),('The letter: one irreplaceable bond is enough.','belonging','sacrifice'),('The map: leave the future room to become something else.','change','uncertainty')]),
('A power that listens','Your magic grows stronger when people believe you cannot fail. Telling them your doubts weakens you.', [('Tell them; trust must leave room for weakness.','truth','belonging'),('Carry the doubt privately while the danger lasts.','duty','sacrifice'),('Teach them to believe in recovery instead of perfection.','change','compassion'),('Use the power, but set a goal after which I relinquish it.','ambition','agency')]),
('The unfinished answer','A teacher says every life must serve one purpose. You have found several that conflict.', [('Choose one for now, without calling the others mistakes.','identity','agency'),('Build a life in which several purposes can take turns.','change','belonging'),('Ask why a life must justify itself through purpose.','truth','uncertainty'),('Choose the purpose that helps the people relying on me.','compassion','duty')]),
('The blank page','The Atlas offers to write the ending you deserve. It asks you to define deserve.', [('An ending I chose while allowing others their choices.','agency','identity'),('An ending where fewer people must suffer for our safety.','compassion','sacrifice'),('An ending that tells the truth, even about my failures.','truth','duty'),('No ending yet. Leave something unwritten.','uncertainty','change')]),
]

questions=[]
for n,(title,text,choices) in enumerate(PROMPTS):
    questions.append(dict(id=f'q{n+1:02}',title=title,text=text,choices=[dict(text=t,weights={a:2,b:1}) for t,a,b in choices]))
questions[11]['reflection']={'question':0,'text':'Earlier, you considered whose memories a bridge could claim. Now consider who may claim the truth.'}
questions[18]['reflection']={'question':2,'text':'Earlier, a borrowed name gave a child courage. Here, the borrowed life is your own.'}
questions[23]['reflection']={'question':9,'text':'You have already considered what returning home might cost. What should an ending offer instead?'}

classes=[]
for i,row in enumerate(ROWS):
    name,tagline,mechanic,discipline,a,b,sig,desc,passive,pdesc=row
    rng=random.Random(7619+i*7919)
    prototype=[]
    for q in questions:
        scores=[c['weights'].get(a,0)*1.2+c['weights'].get(b,0)*.8+rng.uniform(0,3.5) for c in q['choices']]
        prototype.append(max(range(4),key=lambda k:scores[k]))
    # The response profile is attainable by construction, with a distinct
    # question-level motif as well as interpretable value affinities.
    profile={d:0 for d in DIMENSIONS}
    for q,answer in zip(questions,prototype):
        for d,v in q['choices'][answer]['weights'].items():profile[d]+=v
    classes.append(dict(id=mechanic,name=name,tagline=tagline,discipline=discipline,values=[a,b],signature=sig,description=desc,passive=passive,passive_description=pdesc,prototype=prototype,profile=profile,color=['#dfbd76','#80d6c4','#cb9fcf','#a7c591','#91b9e1'][i//10],showcase=mechanic in ['luck','oath','memory','thorn','door','glass'],progression=[{'rank':1,'name':sig,'bonus':'Unlock your signature and passive.'},{'rank':2,'name':'Resonance','bonus':'Signature power +20%; unlock a seeded specialization.'},{'rank':3,'name':'Ascendance','bonus':'Signature power +40%; reduce signature cooldown by 15%.'}]))

regions=[
dict(id='vale',name='Lantern Vale',theme='Memory, belonging, and the cost of shelter',seal='The Remembering Willow',color='#71c4aa'),
dict(id='coast',name='Glassstep Coast',theme='Trade, consent, and the price of safe passage',seal='The Tidal Mirror',color='#8acbd7'),
dict(id='orchard',name='Rainbound Orchard',theme='Grief, renewal, and the ownership of healing',seal='The Patient Seed',color='#a7be80'),
dict(id='choir',name='Ashen Choir',theme='Faith, testimony, and useful lies',seal='The Last Bell',color='#dba286'),
dict(id='peaks',name='Inverted Peaks',theme='Ambition, hierarchy, and chosen limits',seal='The Falling Star',color='#b4adcf'),
dict(id='library',name='Salt Library',theme='Truth, privacy, and inherited blame',seal='The Drowned Index',color='#8bbcc7'),
dict(id='crown',name='Hollow Crown',theme='Power, legitimacy, and shared responsibility',seal='The Empty Throne',color='#cbb07b'),
dict(id='meridian',name='Dawnless Meridian',theme='Identity, freedom, and an unwritten future',seal='The First Absence',color='#b597bf')]

# The live roster: (rarity, basic attack, gameplay description).
ROSTER = {
'luck': ('S', 'Dice Fan', 'Throw three dice. Every third volley exposes enemies; dodges load your special.'),
'oath': ('B', 'Oath Cleave', 'Wide sword arcs build vows. Spend vows on a devastating exposure strike.'),
'memory': ('A', 'Recollection', 'A short blast repeats after a delay. Echoes reward holding a choke point.'),
'thorn': ('B', 'Briar Seed', 'Poison bolts wear foes down. Received damage feeds a slowing thorn garden.'),
'door': ('SSS', 'Rift Needle', 'Long piercing lines weaken foes. Teleport through the battlefield with your special.'),
'glass': ('SS', 'Shard Fan', 'Five short-range shards. Basic attacks detonate your placed prisms.'),
'clock': ('SS', 'Pendulum', 'Slow a wide area. The third pulse briefly stops time around you.'),
'ink': ('A', 'Ink Lance', 'Long ink bolts mark targets. Summon an ink familiar to maintain pressure.'),
'dream': ('S', 'Lullaby', 'Every third close-range pulse sleeps foes; the next hit wakes them for bonus damage.'),
'puppet': ('S', 'Marionette Wire', 'Piercing threads bind enemies, making bound targets share direct damage.'),
'ash': ('A', 'Cinder Scatter', 'Three burning projectiles. Dash away while leaving damaging fire behind.'),
'lance': ('B', 'Starlance', 'Narrow long thrusts deal more damage at range. Charge through foes to reposition.'),
'smith': ('B', 'Forge Hammer', 'Slow heavy circles stagger foes. The special empowers your next three strikes.'),
'echo': ('A', 'Echo Blade', 'Fast close slashes strengthen with consecutive hits. Dash and leave a delayed echo.'),
'debt': ('S', 'Blood Receipt', 'Drain health from marked foes. Sacrifice health to mark an entire group.'),
'lantern': ('B', 'Lantern Pulse', 'Close light pulses slow foes and replenish mana. Place a healing sanctuary.'),
'gravity': ('SS', 'Falling Star', 'A delayed area strike stuns foes. Predict movement to land the impact.'),
'paradox': ('SSS', 'Contradiction', 'Alternate freezing and burning bolts. Your special alternates control and burst.'),
'anatomy': ('A', 'Surgical Cut', 'Precise close cuts expose foes; repeated hits increase your damage.'),
'familiar': ('S', 'Spirit Peck', 'Command a distant spirit strike. Your special calls a protective familiar flock.')
}
classes = [dict(c, rarity=ROSTER[c['id']][0], basic_name=ROSTER[c['id']][1], gameplay=ROSTER[c['id']][2]) for c in classes if c['id'] in ROSTER]

# Live descriptions match the implemented mechanics; each calling has its own accent.
COLORS = ['#e8c577','#cc8da3','#8edbd5','#afbeda','#d9ac87','#b4c4e8','#e2ae77','#9ac98d','#caadce','#8ce0ce','#b8d5d1','#adc9e7','#d8ace1','#c7b2e7','#dba5cd','#c6b5e9','#efae7e','#efd79d','#b3badf','#bad7a3']
DESCRIPTIONS = {
'debt': ('Marked foes return 3 health per hit and 5 health on defeat.', 'Spend 12 health to mark nearby foes for nine seconds and strike each for 48 base damage.'),
'smith': ('Each third basic attack restores 4 mana.', 'Temper your next three hammer strikes into expanding shockwaves.'),
'memory': ('Each collected memory grants 3 maximum mana while equipped.', 'Strike ahead for 29 base damage; a recorded echo repeats for 42 after 0.9 seconds. Nearby enemies become vulnerable to the next repeat.'),
'anatomy': ('Each direct hit against the same foe builds 4% damage, up to 40%.', 'Expose the nearest foe for nine seconds, then make a precise 40-damage strike.'),
'door': ('Gate travel restores 15 stamina.', 'Open a linked pair of gates and blink up to 260 units, cutting and exposing foes along the seam.'),
'familiar': ('Your summoned flock maintains at least 10 shield while active.', 'Call three orbiting familiars for ten seconds. They strike nearby targets together every half second.'),
'lantern': ('Survive one lethal hit per lantern rest at 1 health, with three seconds of invulnerability.', 'Place a sanctuary for nine seconds: pulses heal you and damage and slow nearby enemies.'),
'paradox': ('Alternating a basic attack and a paid spell grants 15% direct damage.', 'Alternate a three-second freeze and a 75-damage detonation. Both casts slow nearby enemies.')
}
for index,c in enumerate(classes):
    c['color'] = COLORS[index]
    if c['id'] in DESCRIPTIONS:
        c['passive_description'],c['description'] = DESCRIPTIONS[c['id']]

for filename,content in [('classes.json',classes),('ritual.json',questions),('regions.json',regions)]:
    (OUT/filename).write_text(json.dumps(content,indent=2,ensure_ascii=False),encoding='utf-8')
print(f'Authored {len(classes)} classes, {len(questions)} dilemmas, {len(regions)} regions.')
