"""Generate original, quiet ambient and interaction sounds with the stdlib."""
import wave,math,random,struct
from pathlib import Path
random.seed(42)
def write(name,duration,fn):
 rate=22050
 with wave.open(str(Path(__file__).resolve().parents[1]/'assets'/name),'wb') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'))
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*32767)) for i in range(int(rate*duration))))
chords=[[110,130.813,164.814],[97.999,123.471,146.832],[87.307,110,130.813],[97.999,130.813,164.814]]
def ambient(t):
 c=chords[int(t/8)%4];fade=min(1,(t%8)/2,(8-t%8)/2)
 return fade*sum(math.sin(2*math.pi*f*t)*0.018+math.sin(2*math.pi*f*2.003*t)*0.008 for f in c)+random.uniform(-.007,.007)
write('ambience.wav',32,ambient)
write('tool.wav',.2,lambda t:math.exp(-t*25)*(math.sin(2*math.pi*440*t)*.15+random.uniform(-.1,.1)))
write('step.wav',.12,lambda t:random.uniform(-.08,.08)*math.exp(-t*30))
