# Revisión para distribución — 30/10/2026

Alcance: inspección del código 0.6 aceptado por el usuario, cambios preventivos 0.7-beta y pruebas automatizadas de compilación y lógica. No es pentest, certificación antivirus ni prueba de hardware independiente.

Hallazgos y correcciones:
1. Panel: sus ajustes se restauraban antes de leer el perfil. Se restauran tras la lectura y se limitan valores.
2. Clics: dos botones con la misma acción podían soltar el ratón prematuramente; un hilo antiguo podía interferir con otro. Se agrega propiedad por botón del ratón, máscaras compartidas y cancelación coordinada.
3. F8/liberación: dependía del temporizador UI. El hilo de clics ahora consulta F8 y la actividad de UI; suelta ante 2 s de falta de latido. La UI sigue necesitando responder para mover el puntero.
4. Desconexión/cambio de dispositivo: pausa inmediata; el panel también se desactiva.
5. Doble ejecución: mutex local por sesión.
6. Perfil: escritura atómica y límite de tamaño al leer; acciones y ejes limitados a las listas de la interfaz. Nunca se evalúan comandos del perfil.
7. Panel: límites de coordenadas y comprobaciones de longitud del informe HID; caché de identificación Sony. No abre sockets ni escribe informes HID al mando.
8. Lanzador: ejecución sin elevación, hash del script fijado durante la compilación. Sin descargas ni actualizador oculto.

Límites: funciones Win32 para entrada sintética pueden ser bloqueadas por Windows o aplicaciones. El código abierto reduce opacidad, no elimina errores. No se han añadido drivers ni acceso de administrador para sortear restricciones. Hashes y compilación no sustituyen firma digital.

La versión original 0.6 se conserva por separado; 0.7 no debe etiquetarse como aceptada por el usuario sin volver a probarla.
