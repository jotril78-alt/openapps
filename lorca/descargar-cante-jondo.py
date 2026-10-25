#!/usr/bin/env python3
"""Download, clean and verify Lorca Wikisource sections before publication."""
import html.parser,json,pathlib,re,urllib.parse,urllib.request
ROOT=pathlib.Path(__file__).resolve().parent
SECTIONS=['Baladilla de los tres ríos','Poema de la siguiriya gitana','Poema de la soleá','Poema de la saeta','Gráfico de la Petenera','Dos muchachas','Viñetas flamencas','Tres ciudades','Seis caprichos','Escena del teniente coronel de la Guardia Civil','Diálogo del Amargo']
class Clean(html.parser.HTMLParser):
 def __init__(self):super().__init__(convert_charrefs=True);self.out=[];self.skip=0
 def handle_starttag(self,t,a):
  if t in ('script','style','nav','iframe','form'):self.skip+=1
  if self.skip:return
  if t in ('p','h2','h3','h4','blockquote','br','b','strong','em','i','ul','li','div'):self.out.append('<'+t+'>')
 def handle_endtag(self,t):
  if t in ('script','style','nav','iframe','form'):self.skip=max(0,self.skip-1);return
  if not self.skip and t in ('p','h2','h3','h4','blockquote','b','strong','em','i','ul','li','div'):self.out.append('</'+t+'>')
 def handle_data(self,d):
  if not self.skip:self.out.append(d.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;'))
def fetch(title):
 params=urllib.parse.urlencode({'action':'parse','format':'json','formatversion':'2','prop':'text|categories','page':title})
 req=urllib.request.Request('https://es.wikisource.org/w/api.php?'+params,headers={'User-Agent':'MiBibliotecaLorca/1.0 (educational; github.com/jotril78-alt/openapps)'})
 with urllib.request.urlopen(req,timeout=35) as r:data=json.load(r)
 if 'error' in data or not data.get('parse',{}).get('text'):raise ValueError('Missing source '+title)
 return data['parse']['text']
out=ROOT/'textos'/'cante-jondo';out.mkdir(parents=True,exist_ok=True)
manifest=[]
for i,title in enumerate(SECTIONS):
 raw=fetch(title)
 p=Clean();p.feed(raw);body=''.join(p.out)
 plain=re.sub(r'<[^>]*>',' ',body)
 if len(plain.strip())<350:raise ValueError('Insufficient text: '+title)
 name='seccion-%02d.html'%(i+1)
 (out/name).write_text(body,encoding='utf-8')
 manifest.append({'title':title,'file':name,'characters':len(plain.strip()),'source':'https://es.wikisource.org/wiki/'+urllib.parse.quote(title.replace(' ','_'))})
 print(title,len(plain.strip()))
 (out/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
