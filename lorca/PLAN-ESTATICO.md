# Biblioteca Lorca — entrega estática

Objetivo: GitHub Pages, sin backend ni cuenta, con EPUB y audio pregrabado. Los archivos MP3 deben existir en el repositorio antes de anunciarlos como disponibles.

## Decisiones cerradas
- La voz «Pablo 2» es referencia aceptada; no cambiarla por otra sin solicitud.
- Narraciones finales pregrabadas y reproducibles con HTMLAudioElement, independientes de speechSynthesis.
- Los archivos MP3 deben tener sus marcas de tiempo por verso en JSON; sincronización por audio.currentTime, no heurísticas de coincidencia con el texto.
- Mantener lector EPUB y zoom/menús validados por el usuario. Voz del navegador como alternativa hasta disponer de MP3.
- Catálogo y activos servidos por GitHub Pages. No anunciar modo sin conexión completo sin service worker y pruebas.
- Revisar procedencia y derechos de cada texto, edición y narración antes de publicación.

## Bloqueos reales
- Aún no hay narraciones completas en MP3, ni marcas de tiempo verificadas.
- La voz instalada «Pablo 2» no se puede empaquetar ni generar idénticamente desde el navegador mediante Web Speech API. Requiere producción de audio fuera del navegador y autorización de uso correspondiente.
- El catálogo aún enlaza a obras externas; no afirmar biblioteca completa.

## Orden de entrega
1. Mantener versión funcional publicada.
2. Inventario de obras locales y procedencia.
3. Producir narración de una obra, MP3 y tiempos por verso.
4. Integrar audio HTML en el lector con fallback a voz del navegador.
5. Probar en Firefox, Brave, Chrome y Samsung Tab A8; después ampliar catálogo.
