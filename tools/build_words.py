import json, re
from nltk.corpus import wordnet as wn
from wordfreq import zipf_frequency as z
HEAD = {
 'a': "happy sad big small fast slow angry smart stupid brave afraid beautiful ugly strange old new rich poor strong weak loud quiet funny calm tired hungry cold hot bright dark clean dirty kind cruel lazy busy honest proud wild empty full hard easy",
 'v': "walk run talk eat think look laugh cry fight help break make take go say throw push steal hide shout jump hit change start stop",
 'n': "house friend fool food fight noise mess talk anger fear joy money car boat road party crowd trouble idea story",
}
out=[]
def clean(w): return w.replace('_',' ')
for pos, words in HEAD.items():
  for h in words.split():
    syns=wn.synsets(h, pos=wn.ADJ if pos=='a' else pos)
    if pos=='a': syns += [s for s in wn.synsets(h, pos='s')]
    cand=set()
    for i,s in enumerate(syns[:8]):
      groups=[s]
      if pos=='a': groups += s.similar_tos() + s.also_sees()
      elif i<2 and pos=="v": groups += s.hyponyms()
      for g in groups:
        for l in g.lemma_names():
          w=l.lower()
          if l!=w: continue
          if re.fullmatch(r"[a-z]+", w) and w!=h and not w.startswith(h[:max(4,len(h)-1)]):
            f=z(w,'en')
            if f>=1.0: cand.add((w,f))
    if len(cand)>=10:
      out.append({'w':h,'pos':pos,'syn':{w:round(f,2) for w,f in sorted(cand,key=lambda x:-x[1])}})
    print(h,len(cand))
json.dump(out,open('words.json','w'),separators=(',',':'))
print(len(out))
BAD=set("fucker twat ass jackass cock prick dick bastard bitch shit crap piss tit tits cunt wanker bugger arse damn hell nigger fag faggot whore slut screw bang hump balls nuts sod pussy".split())
final=[]
for e in out:
  syn={w:f for w,f in e['syn'].items() if w not in BAD}
  if 12<=len(syn)<=90: final.append({'w':e['w'],'pos':e['pos'],'syn':syn})
seen=set(); final=[e for e in final if not (e['w'] in seen or seen.add(e['w']))]
json.dump(final,open('words.json','w'),separators=(',',':'))
print('final',len(final),[e['w'] for e in final])
