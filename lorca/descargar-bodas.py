#!/usr/bin/env python3
"""Build checked local snapshots of the three acts from Wikisource. Stdlib only."""
import html.parser, json, pathlib, re, urllib.parse, urllib.request
ROOT=pathlib.Path(__file__).resolve().parent
DEST=ROOT/'textos'/'bodas-de-sangre'
DEST.mkdir(parents=True,exist_ok=True)
class Clean(html.parser.HTMLParser):
    DROP={'script','style','nav','iframe','form'}
    def __init__(self): super().__init__(convert_charrefs=True);self.out=[];self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in self.DROP:self.skip+=1
        if self.skip:return
        if tag in ('p','h2','h3','h4','blockquote','br','b','strong','em','i','ul','li'):
            self.out.append('<'+tag+'>')
    def handle_endtag(self,tag):
        if tag in self.DROP:self.skip=max(0,self.skip-1)
        if self.skip:return
        if tag in ('p','h2','h3','h4','blockquote','b','strong','em','i','ul','li'):
            self.out.append('</'+tag+'>')
    def handle_data(self,data):
        if not self.skip:self.out.append(data.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;'))
for i,title in enumerate(('Primer Acto','Segundo Acto','Tercer Acto'),1):
    params=urllib.parse.urlencode({'action':'parse','format':'json','formatversion':2,'prop':'text','page':'Bodas de sangre/'+title})
    req=urllib.request.Request('https://es.wikisource.org/w/api.php?'+params,headers={'User-Agent':'MiBibliotecaLorca/1.0 (static public-domain reading; contact via GitHub)'})
    with urllib.request.urlopen(req,timeout=35) as response:
        data=json.load(response)
    source=data['parse']['text']
    parser=Clean();parser.feed(source)
    body=''.join(parser.out)
    visible=re.sub('<[^>]+>','',body)
    if len(visible)<2500 or not any(x in visible.upper() for x in ('CUADRO','NOVIA','MADRE','LEÑADORES')):
        raise RuntimeError('Act %d failed completeness checks (%d chars)'%(i,len(visible)))
    target=DEST/('acto-%d.html'%i)
    target.write_text(body,encoding='utf-8')
    print(title, len(visible),'characters; saved',target)
