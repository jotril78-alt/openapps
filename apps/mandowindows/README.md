# MandoWindows 0.7 beta

Convierte un mando PS4 por USB o Bluetooth (experimental) en ratón y teclado para Windows de escritorio x64 con Windows PowerShell 5.1. Gratuita, código abierto y funcionamiento local. No implementa conexiones de red, anuncios ni telemetría. No pertenece al proyecto Navaliche.

## Estado y descarga

La versión 0.6 fue probada y aceptada por su usuario con un mando PS4 USB. La 0.7 añade correcciones de seguridad y está pendiente de repetir la prueba física. No equivale a una auditoría independiente ni garantiza compatibilidad con todos los mandos o PC.

Fuentes en esta carpeta; `src/Iniciar.cmd` ejecuta el programa. El EXE se genera desde `build/Build.ps1` o con el workflow de Windows. Es un lanzador que verifica el hash del script y abre PowerShell: mantener `MandoWindows.ps1` a su lado. No está firmado digitalmente. No desactivar antivirus ni políticas corporativas si Windows bloquea su ejecución. No hay una descarga estable certificada.

## Uso

Extraer el paquete, abrir Iniciar.cmd (o el EXE cuando se haya compilado), comprobar los indicadores y seleccionar las asignaciones. Soltar palancas y botones antes de activar. Empieza siempre pausado; guardar es opcional para aplicar cambios. F8 pausa; cerrar termina. Ambos joysticks tienen velocidad independiente. Cruceta y botones se configuran por separado. El panel PS4 USB mueve el puntero; clic mediante botones. El aro azul cambia a naranja al dejar el cursor quieto.

## Seguridad y privacidad

- Sin administrador, servicios, inicio automático ni instalación de drivers.
- Genera entradas en la ventana activa: copiar/pegar usa el portapapeles normal de Windows, pero no lee, guarda ni transmite su contenido.
- Guarda únicamente perfil y errores técnicos en `%LOCALAPPDATA%\MandoWindows`. No registra pulsaciones del teclado. Consulta F8 como parada de emergencia.
- Una sola instancia por sesión; desconexión y cambio de mando pausan el control. Los clics sostenidos tienen liberación independiente de la interfaz y temporizador de seguridad.
- No controla escritorio seguro/UAC; hay limitaciones con aplicaciones elevadas y pantallas completas exclusivas. No usarlo en tareas críticas.
- El launcher/archivo CMD usa `ExecutionPolicy Bypass` solo para el proceso hijo: no cambia la configuración permanente ni desactiva antivirus. El script sigue visible y revisable.
- SHA256SUMS permite detectar diferencias, no certifica al autor ni sustituye una firma. Si modificas las fuentes, recompila el lanzador.

## Compilar

En Windows PowerShell 5.1, desde la raíz del repositorio:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\apps\mandowindows\build\Build.ps1
```

No descarga paquetes ni requiere administrador. Analiza sintaxis PowerShell, compila clases C# y lanzador con .NET Framework y genera ZIP y hashes en una carpeta nueva `dist/`. No promete compilaciones bit a bit reproducibles. Ejecuta luego `tests/Safety.Tests.ps1` para probar la lógica de clics con llamadas nativas simuladas.

## Antes de declarar estable

Probar en hardware: ambos joysticks, perfil guardado del panel, cruceta y diagonales, aro al abrir/cerrar ventanas, 10 ciclos de minimizar/restaurar con mando, arrastrar, doble clic, F8, dos botones asignados al mismo clic, desconectar/reconectar y cerrar mientras se mantiene un clic. Comprobar además el paquete EXE en un PC limpio. Los cambios 0.7 todavía requieren esta aceptación.

Licencia MIT solo para esta aplicación, sin cambiar las licencias del resto de OpenApps.

## Conectividad

Selector Automático / USB / Bluetooth. Para Bluetooth, emparejar previamente en Configuración de Windows manteniendo SHARE + PS hasta que parpadee la luz; seleccionar Wireless Controller. La app no cambia adaptadores ni credenciales. Mover el mando y pulsar Detectar. En modo USB/Bluetooth explícito solo se ofrece el dispositivo HID compatible con ese transporte; Automático admite además mandos WinMM cuyo transporte no está verificado.

El lector admite informes USB 01 y Bluetooth extendidos 11-19 hex. Algunos mandos envían por Bluetooth solo datos básicos: botones y joysticks pueden funcionar, pero el panel necesita informes extendidos. No se envían comandos para forzar ese modo. Bluetooth no se ha validado físicamente; clones no garantizados. En USB y Bluetooth la aplicación usa ejes X/Y para palanca izquierda y Z/R para derecha al seleccionar PS4 HID.

Wi-Fi no es un transporte directo del DualShock 4. Un modo remoto necesitaría un puente autenticado, emparejamiento y cifrado; no hay servidor ni puertos de red abiertos en esta versión.

Referencia del formato HID: implementación SDL (https://github.com/libsdl-org/SDL/blob/main/src/joystick/hidapi/SDL_hidapi_ps4.c). Esta implementación interpreta el formato; no incorpora una dependencia SDL.
