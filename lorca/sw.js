// Keep books and reader available offline after their first successful download.
const CACHE='lorca-libros-v6';
const FILES=['./','./index.html','./lector-epub.html','./epubs/romancero-gitano.epub','./epubs/libro-de-poemas.epub','./prueba-local.html','./obras.html','./dos-poemas.html','./tres-poemas.html','./canciones-seleccion.html'];
const CDN=new Set(['cdn.jsdelivr.net']);
self.addEventListener('install',event=>{
 event.waitUntil(caches.open(CACHE).then(cache=>Promise.allSettled(FILES.map(url=>cache.add(url)))));
 self.skipWaiting();
});
self.addEventListener('activate',event=>{
 event.waitUntil(Promise.all([
  caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('lorca-libros-')&&k!==CACHE).map(k=>caches.delete(k)))),
  self.clients.claim()
 ]));
});
self.addEventListener('fetch',event=>{
 const request=event.request;
 if(request.method!=='GET')return;
 const url=new URL(request.url);
 const local=url.origin===self.location.origin;
 const libraryScript=CDN.has(url.hostname)&&/\/(epub|jszip)(\.min)?\.js$/.test(url.pathname);
 if(!local&&!libraryScript)return;
 const isDocument=local&&(request.mode==='navigate'||request.destination==='document');
 event.respondWith(caches.open(CACHE).then(async cache=>{
  const cached=await cache.match(request,{ignoreSearch:local});
  // HTML updates should remain visible whenever there is a connection.
  if(isDocument){
   try{const fresh=await fetch(request);if(fresh.ok)await cache.put(request,fresh.clone());return fresh}catch(e){if(cached)return cached;throw e}
  }
  if(cached)return cached;
  const response=await fetch(request);
  if(response.ok||(libraryScript&&response.type==='opaque'))await cache.put(request,response.clone());
  return response;
 }));
});