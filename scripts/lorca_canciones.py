#!/usr/bin/env python3
"""Construye Canciones 1927 desde las 80+ entradas del índice Wikisource.
No publica un EPUB si una sola entrada del índice falla."""
import re, pathlib, requests, html as htmlmod, time
from urllib.parse import unquote, urljoin
from bs4 import BeautifulSoup
from ebooklib import epub

BASE='https://es.wikisource.org'
session=requests.Session()
session.headers['User-Agent']='MiBibliotecaLorca/1.0 (noncommercial epub archive; contact GitHub jotril78-alt/openapps)'
def get(url):
    for attempt in range(4):
        try:
            r=session.get(url,timeout=35);r.raise_for_status();return r.text
        except Exception:
            if attempt==3:raise
            time.sleep(2+attempt*3)

source=BeautifulSoup(get(BASE+'/wiki/Canciones'),'lxml')
main=source.select_one('#mw-content-text .mw-parser-output') or source.select_one('#mw-content-text')
if not main:raise RuntimeError('Sin índice Wikisource')
anchors=[a for a in main.select('a[href]') if '/wiki/' in a.get('href','') or a.get('href','').startswith('./')]
start=next((i for i,a in enumerate(anchors) if a.get_text(' ',strip=True).casefold()=='teorías'),None)
if start is None:raise RuntimeError('No se encontró inicio del índice original')
end=next((i for i,a in enumerate(anchors[start:],start) if a.get_text(' ',strip=True).casefold()=='canción del día que se va'),None)
if end is None:raise RuntimeError('Índice truncado')
sections={'Teorías','Nocturnos de la ventana','Canciones para niños','Andaluzas','Tres retratos con sombra','Juegos','Canciones de luna','Eros con bastón','Trasmundo','Amor','Canciones para terminar'}
entries=[]
for a in anchors[start:end+1]:
    label=a.get_text(' ',strip=True)
    href=a.get('href','')
    if not label or label in sections or ':' in unquote(href.removeprefix('/wiki/')):continue
    entries.append((label,urljoin(BASE+'/wiki/Canciones',href)))
print('Poemas del índice:',len(entries))
if len(entries)<75:raise RuntimeError('No se hallaron al menos 75 entradas; no se publica')
if len(entries)>100:raise RuntimeError('Índice sospechoso: demasiadas entradas')
book=epub.EpubBook()
book.set_identifier('lorca-canciones-1927-indice-wikisource')
book.set_title('Canciones (1921-1924), edición de 1927')
book.set_language('es')
book.add_author('Federico García Lorca')
css=epub.EpubItem(uid='styles',file_name='style/main.css',media_type='text/css',content='body{font-family:Georgia,serif;line-height:1.45}h2{text-align:center}p.verso{margin:0;line-height:1.42}p.estrofa{margin:.75em 0 0}')
book.add_item(css)
chapters=[]
for i,(title,url) in enumerate(entries):
    soup=BeautifulSoup(get(url),'lxml')
    root=soup.select_one('#mw-content-text .mw-parser-output') or soup.select_one('#mw-content-text')
    if root is None:raise RuntimeError('Sin contenido: '+title)
    for br in root.select('br'): br.replace_with('\n')
    for unwanted in root.select('nav,script,style,.mw-editsection,.noprint,.ws-noexport,.mw-references-wrap,.reference,.mw-headline'):
        unwanted.decompose()
    text=root.get_text('\n',strip=True)
    # Excluir metadatos iniciales de Wikisource que preceden al título en muchos poemas.
    pos=text.casefold().find(title.casefold())
    if pos>=0:text=text[pos+len(title):].strip()
    text=text.replace('\u00a0',' ').strip()
    lines=[line.strip() for line in text.splitlines()]
    lines=[line for line in lines if line and not line.startswith(('Obtenido de','Categoría:','Categorías:'))]
    if sum(len(line) for line in lines)<35 or len(lines)<3:raise RuntimeError('Poema incompleto: '+title+' '+url)
    chapter=epub.EpubHtml(title=title,file_name=f'poema_{i+1:03}.xhtml',lang='es')
    chapter.content='<html xmlns="http://www.w3.org/1999/xhtml"><head><title>'+htmlmod.escape(title)+'</title></head><body><h2>'+htmlmod.escape(title)+'</h2>'+''.join('<p class="verso">'+htmlmod.escape(line)+'</p>' for line in lines)+'</body></html>'
    chapter.add_item(css);book.add_item(chapter);chapters.append(chapter)
    print(f'{i+1}/{len(entries)}',title,len(text))
book.toc=tuple(chapters)
book.spine=['nav']+chapters
book.add_item(epub.EpubNcx())
book.add_item(epub.EpubNav())
p=pathlib.Path('lorca/epubs/canciones-1927.epub');p.parent.mkdir(parents=True,exist_ok=True)
epub.write_epub(str(p),book)
import zipfile
with zipfile.ZipFile(p) as z:
    assert z.read('mimetype')==b'application/epub+zip'
    assert len([n for n in z.namelist() if n.startswith('EPUB/poema_') and n.endswith('.xhtml')])==len(entries)
print('VERIFICADO',p,p.stat().st_size,'bytes',len(entries),'poemas')
