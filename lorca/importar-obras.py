#!/usr/bin/env python3
"""Conservative public-domain Lorca EPUB importer. Run in GitHub Actions."""
import json, re, hashlib, pathlib, urllib.parse, urllib.request, zipfile, io, html.parser, time
ROOT=pathlib.Path(__file__).resolve().parent
OUT=ROOT/'epubs'
OUT.mkdir(exist_ok=True)
BASE='https://www.textos.info'
AGENT={'User-Agent':'LorcaBiblioteca/1.0 (educational static library; public domain)'}
class Links(html.parser.HTMLParser):
 def __init__(self): super().__init__();self.links=[];self.href=None;self.text=[]
 def handle_starttag(self,tag,attrs):
  if tag=='a': self.href=dict(attrs).get('href');self.text=[]
 def handle_data(self,data):
  if self.href is not None:self.text.append(data)
 def handle_endtag(self,tag):
  if tag=='a' and self.href:
   self.links.append((self.href,' '.join(self.text).strip()))
   self.href=None
def fetch(url):
 req=urllib.request.Request(url,headers=AGENT)
 with urllib.request.urlopen(req,timeout=25) as r:
  if r.status!=200:raise RuntimeError('HTTP '+str(r.status))
  return r.read(12000000)
def links(data):
 p=Links();p.feed(data.decode('utf-8','replace'));return p.links
def slug(url):
 s=urllib.parse.urlparse(url).path.rstrip('/').split('/')[-1]
 return re.sub('[^a-z0-9-]','',s)[:75]
def valid_epub(b):
 try:
  with zipfile.ZipFile(io.BytesIO(b)) as z:
   return z.read('mimetype')==b'application/epub+zip' and any(n.endswith('.opf') for n in z.namelist())
 except Exception:return False
records=[]
seen=set()
for page in range(1,4):
 listing=BASE+'/textos/autor/federico-garcia-lorca'+('/pag/'+str(page) if page>1 else '')
 try: anchors=links(fetch(listing))
 except Exception as e: print('Index error:',listing,str(e));continue
 candidates=[urllib.parse.urljoin(BASE,h) for h,t in anchors if '/textos/autor/federico-garcia-lorca/' in h]
 for url in candidates:
  if url in seen:continue
  seen.add(url)
  rec={'page':url,'epub':None,'status':'not-downloaded'}
  try:
   page_links=links(fetch(url))
   downloads=[urllib.parse.urljoin(url,h) for h,t in page_links if '.epub' in h.lower() or ('descargar' in t.lower() and 'epub' in t.lower())]
   for target in downloads[:3]:
    if urllib.parse.urlparse(target).netloc not in ('www.textos.info','textos.info'):continue
    b=fetch(target)
    if not valid_epub(b):continue
    name='textos-'+slug(url)+'.epub';(OUT/name).write_bytes(b)
    rec.update(epub='epubs/'+name,status='downloaded-needs-edition-review',sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
    break
  except Exception as e:rec['error']=str(e)[:200]
  records.append(rec)
  time.sleep(.2)
(ROOT/'importacion-textos-info.json').write_text(json.dumps({'source':BASE+'/textos/autor/federico-garcia-lorca','warning':'Review edition and distribution terms before public listing','items':records},ensure_ascii=False,indent=2)+'\n')
print('Pages:',len(records),'Valid EPUB downloads:',sum(x['epub'] is not None for x in records))
