# OpenApps

Biblioteca de aplicaciones Android libres, gratuitas, sin publicidad y centradas en la privacidad.

## Principios
- Código público y licencia libre para cada aplicación.
- Funcionamiento local siempre que sea posible.
- Sin anuncios, rastreadores, SDK de analítica ni recopilación de datos personales por nuestras apps.
- Sin registros ni pagos obligatorios.
- Donaciones voluntarias, sin presión ni funciones exclusivas.

## Publicar la web
En **Settings → Pages** configura **Deploy from a branch**, rama **main**, carpeta **/(root)**. La web quedará disponible en https://jotril78-alt.github.io/openapps/ cuando GitHub Pages termine de desplegarla.

## Añadir una aplicación
Publica el código en un repositorio propio, genera una Release con APK firmada y hash SHA-256, y añade al archivo `apps/catalog.json` un objeto con `name`, `description`, `source` y `apk`.

Consulta [la lista de verificación](docs/PUBLICACION.md).

## Estado
Web inicial y catálogo vacío. No hay APK publicadas ni donaciones activadas. GitHub, como proveedor de alojamiento, puede procesar datos técnicos de las visitas.
