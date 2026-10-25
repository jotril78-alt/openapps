#!/usr/bin/env python3
"""Generate a tiny, truthful Lorca catalog from local files. Stdlib only."""
import json, pathlib, zipfile
root=pathlib.Path(__file__).resolve().parent
inventory=json.loads((root/'inventario-maestro.json').read_text(encoding='utf-8'))
items=[]
for work in inventory['works']:
    entry={'id':work['id'],'title':work['title'],'category':work['category']}
    rel=work.get('local')
    if rel:
        target=(root/rel).resolve()
        if target.is_relative_to(root.resolve()) and target.is_file():
            valid=target.suffix.lower()=='.html'
            if target.suffix.lower()=='.epub':
                try:
                    with zipfile.ZipFile(target) as z:
                        valid=z.read('mimetype')==b'application/epub+zip' and any(n.endswith('.opf') for n in z.namelist())
                except (OSError,KeyError,zipfile.BadZipFile): pass
            if valid:
                entry.update(file=rel,bytes=target.stat().st_size,format=target.suffix.lower()[1:],available=True)
    if 'available' not in entry: entry['available']=False
    items.append(entry)
out={'version':1,'note':'Availability reflects files verified in repository, not rights clearance','works':items}
target=root/'base-obras.json'
target.write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
print('Catalog entries:',len(items),'verified local:',sum(x['available'] for x in items),'catalog bytes:',target.stat().st_size)
