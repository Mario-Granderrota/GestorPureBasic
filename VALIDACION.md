# Validación del Gestor PureBasic — versión 0

## Validación de la versión 0

- Ambos binarios compilados con PureBasic 6.41 C, --thread, en Debian 13; se utilizaron descriptores pkg-config temporales para las bibliotecas instaladas. Se repitió la compilación secuencial tras un fallo intermitente de purebasic.o al coincidir con la regresión. Requisito máximo GLIBC_2.34 en ambos binarios.
- 113/113 comprobaciones del núcleo y lanzador superadas con la nueva constante de versión. Después se ajustó exclusivamente la presentación de la cabecera; ambos ejecutables se recompilaron y se comprobó la interfaz final.
- Comparación de fuentes frente a 2.5.2: únicamente cambian gestor.pb, tema.pbi y la constante VERSION_GESTOR de base.pbi. Los módulos de instalación, compatibilidad, registros y transacciones permanecen idénticos.
- Pruebas gráficas con Xvfb y usuario nobody: arranque utilizando el registro existente de una instalación real; cabecera legible, tamaño inicial y mínimo, indicador de actividad visible durante la identificación de un paquete real, copia íntegra de la comparación y de la confirmación de retirada mediante lectura del portapapeles, cancelación de ambos diálogos mediante Escape y conservación de la carpeta.
- No se ha repetido la instalación completa corregida, las baterías ampliadas históricas ni se ha verificado la apertura del registro con un visor instalado en Cinnamon. No se ha validado el paquete comercial del usuario ni el escalado de escritorio. Las pruebas de la versión 2.5.1 que se conservan abajo son históricas.

## Validación de 2.5.2

- Compilación de ambos ejecutables con PureBasic 6.41 C, `--thread`. En el contenedor se emplearon los ficheros pkg-config locales que enlazan con las bibliotecas GTK3/Cairo instaladas, sin redistribuirlos.
- 113/113 comprobaciones de regresión repetidas en esta revisión. Las 200 comprobaciones ampliadas de 2.5.1 y sus 24 comprobaciones gráficas adicionales son resultados históricos, no se han repetido en 2.5.2.
- Comparación de fuentes: únicamente `gestor.pb`, `tema.pbi` (nuevo) y la constante de versión de `base.pbi` difieren respecto al paquete 2.5.1.
- Sesión Xvfb con usuario sin privilegios: arranque vacío y con una instalación de prueba real registrada; ventana 820 × 520 y 760 × 500; selección y ruta legibles; diálogo de comparación de la misma versión, botón de copiar comprobado mediante lectura del portapapeles; cancelación conserva la instalación; diálogo real de compatibilidad con __wrap_memcpy, copiado y cancelación; confirmación de retirada y cancelación conservan la carpeta.
- La sesión virtual presenta advertencias de dconf relativas al entorno aislado, no a la CSS. No se ha comprobado el tema en Cinnamon ni escalados superiores ni repetido la aplicación de la corrección de GCC en esta revisión. El código del adaptador se conserva. FASM no utilizable en el contenedor y el ensayo gráfico del compilador requiere dependencias de desarrollo ausentes en esa sesión.

## Validación histórica de 2.5.1

Compilado nativamente mediante PureBasic 6.41 C gratuito en Debian 13 x86-64. En el contenedor faltaban los descriptores de desarrollo GTK/Cairo; para construir se utilizaron descriptores pkg-config temporales que enlazan con los SONAME instalados. No se modificó el SDK oficial ni las bibliotecas del sistema. Los dos binarios tienen GLIBC_2.34 como mayor versión de símbolo GLIBC requerida. `ldd` no detectó dependencias sin resolver en el entorno de pruebas.

| Batería final | Correctas | Fallidas |
|---|---:|---:|
| Regresión del núcleo y lanzador | 113 | 0 |
| SOLID y movimientos | 36 | 0 |
| Instalación | 33 | 0 |
| Compatibilidad | 24 | 0 |
| Robustez | 26 | 0 |
| Mantenimiento | 26 | 0 |
| Seguridad 2.5 | 30 | 0 |
| Depuración 2.5.1 | 25 | 0 |
| **Total** | **313** | **0** |

Las baterías de regresión y ampliadas se ejecutaron secuencialmente con el código definitivo, el paquete gratuito 6.41 aportado y perfiles aislados. Se adaptaron pruebas previas a los nuevos contratos de consentimiento y separación de retirada/purga, sin ocultar los resultados: las comprobaciones específicas de 2.5.1 prueban también que las llamadas antiguas sin autorización se deniegan. Las pruebas de mantenimiento son controladas y no eliminan instalaciones reales del usuario. Se incluyen las salidas originales de las baterías finales.

Comprobaciones adicionales, no sumadas al total: 25 casos nuevos repetidos por separado; arranque del ejecutable gráfico de producción bajo el usuario `nobody` en Xvfb; 24 casos de compatibilidad en sesión gráfica Xvfb (incluye compilación y ejecución de ventana del backend C, diagnóstico y aceptación de limitación residual). La primera compilación de esta batería gráfica adicional falló con `getcwd` y `can't create purebasic.o` al coincidir con otra compilación; se repitió después, secuencialmente, y las 24 comprobaciones fueron correctas. La causa exacta de ese fallo intermitente no queda acreditada. No se ha validado la totalidad de la interfaz interactiva en Cinnamon, el paquete comercial concreto del usuario, el funcionamiento de ASM/FASM i386 ni la resistencia física a cortes de corriente. No se ha certificado la sustitución integral con los dos backends funcionales. No se han medido mejoras de rendimiento en esta versión.

El diario de actualización propia permite reconciliar la huella antigua/nueva tras un fallo simulado de escritura; no conserva por sí mismo una copia completa anterior del binario. La autorización adicional de purga de una instalación importada no identifica ni protege automáticamente los proyectos que formen parte del manifiesto; se debe revisar y respaldar su contenido antes de confirmar. Se mantienen las limitaciones de autenticidad del paquete, concurrencia externa y migración de preferencias descritas en revisiones anteriores. No se ha realizado una auditoría formal de seguridad.

Para repetir las pruebas, ejecutar `python3 pruebas/ejecutar.py /ruta/sdk /ruta/paquete.tgz` y después `python3 pruebas/ejecutar_ampliadas.py /ruta/sdk /ruta/paquete.tgz`, en un entorno de desarrollo compatible con PureBasic y con sus dependencias. No compilar en paralelo con el mismo SDK. Python solo es necesario para la batería de pruebas, no para el gestor. `RESULTADOS_PRUEBAS.txt` contiene las salidas de esta revisión. Consultar `LEEME.md` y `ARQUITECTURA.md` para el contrato de las operaciones.

---

## Histórico 2.5.0

# Validación del Gestor PureBasic 2.5.0

Compilación nativa con el SDK gratuito PureBasic 6.41 C aportado, en Debian 13 x64. Se utilizaron descriptores temporales pkg-config para enlazar las bibliotecas GTK/Cairo de ejecución instaladas, sin alterar el SDK ni las bibliotecas del sistema. Ambos binarios de producción tienen GLIBC_2.34 como versión máxima requerida de símbolos GLIBC y `ldd` no detectó dependencias ausentes en el entorno de construcción.

| Batería final | Correctas | Fallidas |
|---|---:|---:|
| Regresión de núcleo y lanzador | 113 | 0 |
| SOLID y movimientos | 36 | 0 |
| Instalación | 32 | 0 |
| Compatibilidad | 23 | 0 |
| Robustez | 26 | 0 |
| Mantenimiento | 26 | 0 |
| Seguridad y reversibilidad 2.5 | 30 | 0 |
| **Total** | **286** | **0** |

Las pruebas finales se completaron en ejecuciones separadas, secuenciales. La ejecución conjunta final se interrumpió por el límite temporal del entorno después de núcleo y SOLID; el resto se repitió y completó en perfiles de prueba nuevos. Los resultados incluidos corresponden al código definitivo. La batería nueva comprueba UTF-8 acotado, salidas de procesos fragmentadas, JSON mal tipado, recuperación, sincronización, bloqueo y retirada/restauración de una instalación con un proyecto preexistente. La purga explícita se prueba sobre datos sintéticos aislados.

Pruebas complementarias, no sumadas: arranque gráfico del gestor como usuario no administrador en Xvfb; arranque del IDE real 6.41 con el lanzador y bloqueo exclusivo aún retenido cuatro segundos después, comprobado mediante flock. Se terminó el proceso IDE mediante SIGTERM y se comprobó que el supervisor liberó el bloqueo al terminar. No se validó aquí el cierre interactivo normal ni el ciclo completo de la nueva interfaz de retirada/purga con Cinnamon. No se ha probado el paquete comercial del usuario. FASM i386 sigue sin poder validarse en el contenedor; el flujo integral de sustitución con ambos backends funcionales no está acreditado. Sí se prueba la política de retirada y restauración independientemente. No se han realizado cortes reales de corriente ni pruebas físicas de persistencia. La sincronización adicional puede aumentar los tiempos de publicación; no se ha medido su coste total.

Reproducción: `python3 pruebas/ejecutar.py /ruta/sdk /ruta/paquete.tgz` y `python3 pruebas/ejecutar_ampliadas.py /ruta/sdk /ruta/paquete.tgz`. Ambas utilizan perfiles aislados. No ejecutar en paralelo con el mismo SDK. Python solo es necesario para las pruebas, no para el gestor. El fichero RESULTADOS_PRUEBAS.txt recoge las salidas finales.

---

## Histórico 2.4.0

# Validación del Gestor PureBasic 2.4.0

Compilado con PureBasic 6.41 C, Linux Debian x64. Regresión final secuencial de esta revisión, con el paquete oficial gratuito aportado y perfiles aislados:

| Batería | Correctas | Fallidas |
|---|---:|---:|
| Núcleo y lanzador | 113 | 0 |
| SOLID y movimientos | 36 | 0 |
| Instalación | 32 | 0 |
| Compatibilidad | 23 | 0 |
| Robustez | 26 | 0 |
| Mantenimiento | 26 | 0 |
| Total | 256 | 0 |

La batería `mantenimiento.pb` utiliza un conjunto mínimo de archivos ELF y logo oficiales con un estado de validación controlado para las operaciones de archivos, y un fallo de escritura inyectado. Comprueba creación y reparación de accesos, rechazo de colisiones, conservación de otras versiones, protección de archivos añadidos, bloqueo cooperativo, recuperación de retirada, desinstalación de activa y última instalación, copia de perfil y análisis de montajes (casos sintéticos). La tabla de montajes real se consulta durante las desinstalaciones. No se montaron sistemas de archivos reales como prueba destructiva.

Adicionalmente, se ejecutó la aplicación de producción como usuario no administrador en Xvfb. Se comprobó la cancelación y confirmación de desinstalación sobre una instalación de ensayo, y la eliminación de su registro. Con un paquete 6.41 real instalado mediante la batería de compatibilidad (C corregido, ASM limitado), se verificó el acceso automático en Escritorio y su recreación pulsando el botón del gestor real. Estos casos gráficos complementarios no se suman a las 256 comprobaciones. No se certifica el gestor de escritorio Cinnamon, la autorización gráfica del icono mediante su gestor de archivos, ni el paquete comercial del usuario. FASM sigue limitado en el contenedor; no se afirma que el backend ASM esté corregido. Las limitaciones históricas siguen aplicándose.

Para repetir las pruebas secuenciales usa `pruebas/ejecutar.py` y `pruebas/ejecutar_ampliadas.py`, con el SDK y el paquete original. La última incluye mantenimiento en modo de pruebas; la opción `--grafica` omite mantenimiento porque requiere inyección de fallos. No usar el HOME real. Los registros de ejecución de esta entrega están en RESULTADOS_PRUEBAS.txt.

---

## Histórico 2.3.0

# Validación del Gestor PureBasic 2.3.0

## Resultados de esta revisión

Compilación nativa de `gestor-purebasic` y `compilar-pb` con PureBasic 6.41 Free, Debian 13 x64, GCC 14, GLIBC 2.41. `readelf --version-info` confirma que la versión máxima de los símbolos GLIBC de ambos ejecutables es 2.34. Para enlazar GTK/Cairo se usaron descriptores pkg-config locales temporales de las bibliotecas de ejecución presentes, no distribuidos con el gestor. No se modifica el paquete oficial ni el sistema del usuario.

| Batería | Correctas | Fallidas |
|---|---:|---:|
| Regresión de núcleo y lanzador | 113 | 0 |
| SOLID y movimientos | 36 | 0 |
| Flujo de instalación | 32 | 0 |
| Compatibilidad en consola | 23 | 0 |
| Robustez nueva | 26 | 0 |
| **Total** | **230** | **0** |

Además se repitieron los 23 casos de compatibilidad en una sesión gráfica Xvfb, sin MODO_PRUEBAS: 23 correctos, 0 fallidos. Son casos repetidos, no 23 pruebas funcionales distintas. El backend C con adaptador superó todos los casos, incluida GUI; ASM sigue sin poder validarse por FASM i386 en el contenedor. Se conservó el bloqueo de sustitución. El código del IDE oficial documenta las preferencias `CompilerDefaults`, `CustomCompiler` y `CompilerVersion`: https://github.com/fantaisie-software/purebasic/blob/devel/PureBasicIDE/Preferences.pb. En un perfil nuevo de las pruebas se confirmó el proceso `pbcompilerc --standby --language Spanish` al abrir el IDE. F5 generó un ELF x64 con el código de prueba C (el fuente rechaza por directiva cualquier otro backend); su ejecución manual devolvió 0 y escribió `IDE_C_OK`. No se obtuvo el testigo de ejecución automática desde el IDE virtual. No se ha probado el paquete comercial ni Cinnamon/Mint del usuario.

Se observó un fallo intermitente de archivos intermedios (`can't create purebasic.o`) al ejecutar baterías simultáneas, incluso con SDKs separados. Se repitió la regresión secuencialmente y pasó 113/113. Las pruebas ampliadas finales se ejecutaron secuencialmente. No se afirma que el gestor elimine las colisiones internas del compilador en usos concurrentes externos.

## Reproducción

Desde un entorno compatible con PureBasic 6.41 y el paquete de prueba original, utiliza rutas de prueba nuevas, nunca tu HOME real. Ejecuta las baterías una detrás de otra:

```sh
./compilar.sh /ruta/a/purebasic
python3 pruebas/ejecutar.py /ruta/a/purebasic /ruta/demo-6.41.tgz
python3 pruebas/ejecutar_ampliadas.py /ruta/a/purebasic /ruta/demo-6.41.tgz
# En una sesión gráfica, con perfil de ensayo nuevo:
python3 pruebas/ejecutar_ampliadas.py /ruta/a/purebasic /ruta/demo-6.41.tgz --grafica
```

Los resultados reales están en `RESULTADOS_PRUEBAS.txt`. Los históricos siguientes describen otras revisiones y no se suman al resultado actual. Las pruebas no sustituyen una auditoría de seguridad ni una prueba del sistema operativo de destino; la validación de un conjunto finito de programas no garantiza todos los posibles proyectos PureBasic. Una interrupción durante las escrituras de recuperación puede requerir volver a aplicar el diario. Se exige que los paquetes procedan de una fuente de confianza.

---

## Histórico 2.2.1

# Validación de la revisión 2.2.1

## Evidencia nueva

En Debian 13, PureBasic Free 6.41 Linux x64 del usuario. Una compilación mínima ordinaria reproduce `undefined reference to __wrap_memcpy`. Se interceptaron los argumentos de GCC en un entorno de ensayo y se observó `-Wl,--wrap=memcpy`, `systembase.a` y `-lpbmimalloc` (en ese orden). Se comprobó que añadir `-Wl,-u,__wrap_memcpy` permite compilar y ejecutar el mismo fuente sin modificarlo, también con `--thread`. La causa probable es la extracción de miembros de bibliotecas estáticas; no se dispone de confirmación oficial del fabricante para este paquete.

La adaptación se solicita expresamente y se almacena fuera de la instalación, en el perfil de la versión. Se comprueba su contenido y permisos antes de ejecutar. No se habilita globalmente ni se modifican archivos oficiales. Se repiten las pruebas reales con el adaptador, también tras publicar la instalación. No se autoriza la sustitución si queda una limitación. El ejecutable del gestor y el CLI se han compilado con PureBasic 6.41 y mantienen GLIBC_2.34 como mayor requisito de símbolo GLIBC.

Resultados de la revisión: 113 comprobaciones de regresión, 36 SOLID, 32 de instalación con paquete real y 20 específicas de compatibilidad (201 en total). Además, el lanzador `compilar-pb` compiló y ejecutó un fuente mínimo sin ImportC ni cambios de código. La apertura real del IDE desde el gestor como usuario no administrador confirmó la herencia de PATH y PUREBASIC_HOME, pero no se completó una compilación interactiva F5. El IDE inició por defecto el servidor ASM, no se cambia su preferencia automáticamente. El backend C superó normal, depurador, memoria, multihilo, GUI y rechazo de fuente incorrecto. ASM no se valida en el contenedor porque FASM i386 no se ejecuta (Exec format error). No se puede certificar ASM ni la sustitución integral con dos backends sanos en el equipo del usuario. El paquete comercial concreto y su Linux Mint no están disponibles.

Para las pruebas gráficas se empleó Xvfb y descriptores pkg-config temporales que apuntan a las bibliotecas GTK/Cairo de ejecución instaladas (el contenedor no tiene sus paquetes de desarrollo). Estos descriptores no se incluyen en la entrega y no se aplican al sistema del usuario. Durante las compilaciones simultáneas se reprodujeron colisiones de archivos intermedios de PureBasic incluso con carpetas de trabajo distintas; las baterías finales de instalación y compatibilidad se realizaron secuencialmente. Las pruebas de regresión y SOLID finalizaron correctamente; no se garantiza la compilación concurrente desde una misma instalación de SDK.

Repetición de la prueba específica (requiere el paquete demo 6.41 afectado y sesión gráfica):

```sh
export PUREBASIC_HOME=/ruta/a/purebasic
mkdir -p /tmp/perfil-prueba-compatibilidad
"$PUREBASIC_HOME/compilers/pbcompilerc" pruebas/compatibilidad.pb --thread --output /tmp/prueba-compatibilidad
/tmp/prueba-compatibilidad /tmp/perfil-prueba-compatibilidad /ruta/paquete-demo.tgz
```

## Histórico de validación 2.2.0

Los siguientes apartados describen la revisión anterior, no son pruebas nuevas de 2.2.1.

# Validación del Gestor PureBasic 2.2.0

## Entorno y alcance

Debian 13 x86-64, PureBasic 6.41 Free procedente del paquete aportado, GCC 14 y GNU ld. Se usó Xvfb para la ejecución de las comprobaciones gráficas. La compilación de los ejecutables gráficos en este contenedor requirió archivos pkg-config temporales que apuntan a las bibliotecas GTK 3 de ejecución presentes, porque no están instalados los archivos de desarrollo. No se incluyen ni se requiere ese ajuste en un sistema con los paquetes de desarrollo ordinarios. Los ejecutables se enlazan con símbolos GLIBC de hasta 2.34. No se ha probado en el Linux Mint concreto del usuario, en Cinnamon ni con su paquete comercial.

## Investigación del enlace

Se reprodujo el error ejecutando `pbcompilerc` directamente sobre:

```purebasic
OpenConsole()
PrintN("GESTOR_MINIMO_OK")
```

La orden GCC observada incluye `-Wl,--wrap=memcpy`, varias apariciones de `systembase.a` antes de `-lpbmimalloc`. `nm` identifica `__wrap_memcpy` definido en el miembro `Memcpy.o` de `systembase.a`. GNU ld busca bibliotecas estáticas en el orden de la línea de comandos; una referencia descubierta más tarde no provoca otra búsqueda automática de las anteriores. En la prueba local, forzar la referencia mediante `-Wl,-u,__wrap_memcpy` resuelve el enlace. No se ha encontrado una confirmación oficial específica del fallo; la reproducción y el experimento sustentan el diagnóstico local.

Solución provisional por fuente, verificada con el backend C del paquete aportado:

```purebasic
ImportC "-Wl,-u,__wrap_memcpy"
EndImport
OpenConsole()
PrintN("GESTOR_MINIMO_OK")
```

El gestor ejecuta una prueba diagnóstica equivalente solo cuando detecta ese error. No instala parches, no modifica el SDK ni configura GCC. No se declara compatible un paquete por superar la prueba modificada: sigue bloqueada la sustitución si falla una prueba ordinaria.

Referencia GNU ld: https://www.sourceware.org/binutils/docs/ld/Options.html

## Protecciones heredadas y mantenidas de 2.1.1

- La autorización antigua de sustitución con limitaciones queda deshabilitada también en la lógica del núcleo, no solo en el diálogo.
- Separación física de carpetas para todos los casos y backends; no se reutiliza ningún ejecutable previo. La prueba de interfaz exige un archivo testigo nuevo y código de salida correcto. Se comprueba el código de salida y una línea testigo exacta en las demás pruebas, registrando la salida.
- Cada backend incluido se comprueba de manera independiente. Una limitación de cualquiera de los dos incluidos bloquea la sustitución; se prefiere el backend con mejor resultado para la instalación en paralelo. Se conserva el registro detallado y la selección previa.
- Antes de retirar la anterior, se repiten las comprobaciones en la ubicación definitiva. Se conservan los controles de edición de licencia, manifiesto, procesos en ejecución, recuperación de operaciones y accesos.
- `setsid --wait` y drenado final de salida para reducir carreras de supervisión. No se garantiza recuperación de todos los fallos de hardware ni contención de paquetes maliciosos: solo instalar paquetes oficiales de confianza.

## Pruebas de esta entrega 2.2.0

- 113/113 comprobaciones heredadas de regresión, incluida la ejecución del lanzador nativo, con el paquete real y perfiles nuevos aislados.
- 32/32 comprobaciones del flujo actual con el mismo paquete y sesión gráfica virtual Xvfb, incluidas las pruebas de protección de la versión anterior.
- 36/36 comprobaciones adicionales de SOLID y fiabilidad: reglas puras de precedencia, edición, backends y autorización; independencia del resultado de los procesos y tiempo límite; pruebas del puerto mediante sustituto; recuperación de una publicación interrumpida, fallo al registrar, coherencia del manifiesto y traslado sin reemplazo. Las pruebas simuladas no certifican un compilador real.
- 181 comprobaciones satisfactorias en total; todas las baterías se ejecutaron sobre la revisión entregada. Se mantienen los límites de la validación de 2.1.1: el backend ASM del paquete no puede ejecutar FASM de 32 bits en el contenedor. El backend C sigue presentando el fallo de enlace en determinados casos. Por ello no se certifica el flujo integral de sustitución con dos backends íntegramente correctos; sí se han ejercitado la política positiva aisladamente, la publicación central y el rechazo real de la sustitución.
- Los dos binarios compilados mantienen GLIBC_2.34 como mayor versión de símbolo GLIBC requerida, verificada con readelf. El nuevo traslado usa renameat2 con RENAME_NOREPLACE; un sistema de archivos que no lo soporte debe fallar de forma conservadora, no hay un fallback que sobrescriba.

## Medición de rendimiento

Árbol sintético: 50 directorios y 5.000 archivos pequeños, mismos permisos y nombres para ambas revisiones. Tres ejecuciones por revisión con el mismo PureBasic 6.41 y misma máquina, primero la antigua y después la nueva. Tiempo interno de CrearManifiesto (incluye el cálculo SHA-256 de los archivos y escritura), no el tiempo total de instalación.

| Revisión | Tiempos (ms) | Mediana (ms) |
|---|---|---:|
| 2.1.1 | 3263, 2806, 3321 | 3263 |
| 2.2.0 | 274, 239, 232 | 239 |

Ambos manifiestos son idénticos byte a byte. SHA-256: `37bb0d4927fcfc3790548864a13518323490ae3de55875a3a5fc1e92cb387dd3`. La mediana observada es unas 13,7 veces menor; no es una garantía de rendimiento en el equipo del usuario. Las cachés de E/S, la carga del sistema y el tamaño de los archivos influyen. La mejora algorítmica demostrable es que el cómputo de longitud en UTF-8 ya no recorre el texto acumulado por cada línea. El ordenamiento y el cálculo de huellas se mantienen.

## Repetición

```sh
export PUREBASIC_HOME=/ruta/a/purebasic
./compilar.sh "$PUREBASIC_HOME"
mkdir -p /tmp/prueba-instalador-pb/Desktop
"$PUREBASIC_HOME/compilers/pbcompilerc" pruebas/instalador.pb --thread --output /tmp/prueba-instalador-pb-bin
/tmp/prueba-instalador-pb-bin /tmp/prueba-instalador-pb /ruta/paquete-oficial.tgz
python3 pruebas/ejecutar.py "$PUREBASIC_HOME" /ruta/paquete-oficial.tgz
```

Ejecuta desde una sesión gráfica y con una carpeta de pruebas nueva; el modo `--constant MODO_PRUEBAS=1` omite la comprobación de GUI solo para las pruebas de consola. No utilices tu HOME real para las pruebas automatizadas.

Pruebas nuevas (usar un perfil aislado y existente):

```sh
mkdir -p /tmp/prueba-solid-pb
"$PUREBASIC_HOME/compilers/pbcompilerc" pruebas/solid.pb --thread --constant MODO_PRUEBAS=1 --output /tmp/prueba-solid-pb-bin
/tmp/prueba-solid-pb-bin /tmp/prueba-solid-pb
```

Para medir un árbol con `pruebas/rendimiento.pb`, compílalo con `--thread` y pasa la ruta del árbol y una ruta de manifiesto que todavía no exista, fuera del árbol. No se deben usar perfiles de pruebas reutilizados.

La ventana del gestor se inició como usuario no administrador en Xvfb con un perfil nuevo y permaneció en ejecución durante cinco segundos. La finalización se provocó mediante timeout (124); no constituye una prueba interactiva completa.
