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

## Decisión aprobada por el usuario (2026-10-25)
La biblioteca es un corpus cerrado: obras de Lorca, archivos EPUB/HTML alojados estáticamente, narraciones de audio generadas previamente y almacenadas en la web, y tiempos de sincronización por fragmento/verso precomputados. El navegador solo descarga, muestra, reproduce y reanuda. No generar voz durante la lectura definitiva. Pablo voz 2 queda como referencia de producción, no como dependencia del cliente. No reabrir cambios de voces, motores ni rediseños hasta completar lotes de contenido. Mantener la lectura TTS existente solo como transición mientras no haya audio grabado. Confirmar derechos y procedencia de textos y grabaciones.

## Presupuesto de datos y rendimiento (2026-10-25)
- Catálogo inicial HTML y JSON ligero, sin imágenes externas, sin fuentes web ni frameworks.
- EPUB: una descarga solo al abrir el libro; preferir EPUB sin imágenes ornamentales; comprimir internamente, no duplicar en formatos idénticos.
- Audio: Opus 24–32 kb/s mono para voz cuando el navegador lo soporte; MP3 mono 40–48 kb/s como alternativa de compatibilidad, generados una sola vez. **No descargar ambos**: elegir formato reproducible y usar un único recurso.
- Audio por capítulo/poema, no un fichero gigantesco: el usuario descarga solo lo que escucha; reproducción HTML con precarga metadata o none, nunca auto.
- Índice de sincronización compacto en JSON, descargado al iniciar audio, no al abrir catálogo.
- Caché: guardar opcionalmente EPUB/audio ya abiertos, nunca precargar toda la colección en la tableta.
- Compresión HTTP, encabezados Cache-Control y rangos de audio dependen del alojamiento GitHub Pages; comprobarlos antes de afirmar ahorro efectivo.
- Validación: registrar tamaño de catálogo, EPUB, audio por minuto y bytes transferidos al abrir catálogo, abrir libro y escuchar primer poema.
- Importador: descargas de candidatos limitadas a 2.5 MB por archivo; no confundir descarga automática con autorización legal de republicación.
