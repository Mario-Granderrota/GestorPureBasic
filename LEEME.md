# Gestor PureBasic — versión 0 · Linux x64

> Nota para el repositorio de fuentes: las referencias a ejecutables incluidos y a SHA256SUMS describen el paquete de distribución original, no este árbol Git. Para obtener los ejecutables desde los fuentes, consulta [README.md](README.md).

Revisión de depuración, contratos de instalación y recuperación sobre la versión 2.5.0. Interfaz y lógica de instalación nativas en PureBasic. Incluye ejecutables, fuentes completos, pruebas y script de compilación. No incluye una copia del IDE ni una licencia de PureBasic.

## Versión 0 — nueva numeración de referencia

- Cabecera azul petróleo de alto contraste, título de 24 puntos y nueva distribución de 880 × 570 (mínimo 800 × 550).
- Indicador de actividad indeterminado: indica que se está trabajando, no un porcentaje estimado. Se oculta al terminar.
- Botón «Ver registro» que abre el registro técnico con el visor predeterminado de Linux cuando existe y no hay una operación en curso.
- Indicaciones contextuales, ayudas al pasar el puntero y rechazo explícito de arrastres múltiples.
- Los diálogos de comparación y mantenimiento permiten cancelar con Escape y copiar la información completa.
- Se reinicia únicamente la numeración pública del gestor a «0». Se conservan las rutas, el formato de registros, los lanzadores, las validaciones, el adaptador privado de GCC y las reglas de retirada y restauración. No hay que reinstalar PureBasic.

## Novedades 2.5.2 — interfaz y legibilidad

- Tema GTK3 privado de la aplicación (azul petróleo, fondo gris azulado, avisos ámbar y mantenimiento destructivo en rojo); tipografía Sans del sistema. No cambia el tema de Cinnamon ni instala fuentes.
- Ventana redimensionable, de 820 × 520 inicialmente y 760 × 500 como mínimo, con columnas adaptables, contador de instalaciones y ruta seleccionable.
- Diálogos de comparación y compatibilidad ampliados, con texto desplazable y un botón «Copiar información». Se conserva el foco inicial en Cancelar y todas las políticas de autorización. La confirmación de mantenimiento distingue retirada de borrado definitivo.
- El módulo `tema.pbi` aísla la presentación. Si GTK no admite la hoja de estilo, se conservan los controles nativos sin personalizar. El núcleo de 2.5.1 no cambia, salvo la constante de versión.
- Regresión de 113 casos repetida y comprobaciones gráficas reales de arranque, redimensionado, detección, copiado y cancelación. Consulta VALIDACION.md.

## Novedades 2.5.1 — depuración y coherencia de operaciones

- **Instalación completa y limitada son resultados distintos.** Antes de publicar una instalación limitada, hay que pulsar «Aceptar limitada»; autorizar una corrección no implica aceptar el fallo residual. Una instalación limitada aceptada permanece en paralelo y no sustituye a la anterior. La comprobación definitiva sigue siendo obligatoria. Si descubre una limitación no autorizada, el registro queda pendiente de validación, no se publica un acceso nuevo ni se cambia la selección activa. Las instalaciones gestionadas sin validar no se abren desde el lanzador.
- **Retirada y purga son operaciones separadas también en el núcleo.** No se puede purgar directamente una versión disponible. Una instalación importada requiere además la confirmación literal `ELIMINAR` después de revisar y respaldar su contenido: el manifiesto no identifica la propiedad original de cada archivo. Es una autorización explícita, no una copia automática de los proyectos. Si no se concede, los datos quedan en la carpeta retirada.
- Restaurar una versión exige que el origen coincida con el ID de retirada, que el destino corresponda al tipo y origen registrados y que las rutas sean seguras. Restauración y creación de accesos comparten el bloqueo exclusivo por versión; no se restaura mientras la versión esté bloqueada.
- Se impide iniciar una nueva operación si hay diarios pendientes o persistencia incierta. La limpieza temporal no elimina perfiles asociados a un registro ilegible ni directorios anidados que no correspondan a un área temporal del almacén. Se revisan los puntos de montaje antes de limpiar.
- Se registra la huella antigua y la nueva antes de publicar el ejecutable del gestor. Si el proceso se interrumpe después de cambiar el binario, el arranque puede reconciliar su huella con el diario. Si el contenido no coincide con ninguna huella registrada, se conserva para revisión. Esto no equivale a una copia íntegra de la versión anterior del gestor ni a un mecanismo de actualización remota.
- Se conservan las rutas de datos, los formatos de registros y las protecciones de 2.5.0. No se añaden dependencias de ejecución al gestor. Los registros externos incoherentes o sin ruta de origen acreditada requieren revisión antes de retirarlos o restaurarlos.

## Uso

1. Extrae el TAR.GZ y ejecuta `gestor-purebasic` como usuario normal, sin sudo. Si tu gestor de archivos no respeta los permisos, `chmod +x gestor-purebasic`.
2. Se buscan instalaciones registradas en el gestor anterior, accesos conocidos del escritorio y menú, carpetas habituales y carpetas de primer nivel de HOME y `~/Apps`. Si falta alguna, pulsa **Añadir instalación existente** y elige la raíz que contiene `compilers`.
3. Selecciona la versión que deseas comparar (si hay varias). Pulsa **Instalar / actualizar desde paquete...** o arrastra el archivo `.tgz`, `.tar.gz` o `.tar` a la ventana. Se compara el contenido del compilador, no el nombre del archivo, antes de ejecutar el nuevo paquete.
4. El aviso informa si la versión es superior, anterior o igual. Puedes **Sustituir anterior**, **Conservar ambas** o **Cancelar**. La primera instalación solo ofrece Instalar y Cancelar. Si una edición gratuita pudiera sustituir una completa, o alguna de las dos ediciones no está identificada, solo se permite instalar por separado.
5. Si sustituyes, se prepara y verifica la nueva instalación antes de retirar la carpeta anterior de manera recuperable. Si conservas ambas, se crean accesos individuales y perfiles separados para las nuevas instalaciones. Se conserva la selección predeterminada anterior si existe. Puedes abrir cualquier versión desde la lista o su acceso propio.

**Aviso importante:** la sustitución conserva toda la carpeta anterior y su perfil en una retirada recuperable. No hay borrado automático por antigüedad. La eliminación definitiva exige seleccionar la versión retirada y confirmar de nuevo. Guarda tus proyectos, bibliotecas personalizadas y archivos personales fuera de ella antes de esa eliminación. No se borran instalaciones en uso ni carpetas que hayan cambiado respecto a su manifiesto. Si es necesario reconocer cambios legítimos, revisa y guarda tus archivos primero; la interfaz simplificada no ofrece un botón para revalidar el manifiesto. Un retroceso de versión está permitido tras la elección explícita. La aplicación no necesita credenciales de tu licencia.

Si se detecta una limitación, no se permite sustituir la versión anterior, ni siquiera mediante la antigua autorización expresa. Puedes conservar ambas o cancelar; si se verifica el fallo específico de memcpy, se ofrece además Corregir y comprobar. Se comprueban independientemente los backends C y ASM incluidos: fuente mínimo, depurador, memoria, hilo real, rechazo de código inválido y, desde la aplicación gráfica, creación de una ventana GTK. Cada caso usa un directorio exclusivo. La sustitución requiere superar todas las pruebas de los backends incluidos y repetirlas en la ubicación definitiva antes de cambiar la predeterminada o retirar la anterior. Si hay una limitación, la instalación en paralelo no cambia la predeterminada; incluso en la primera instalación limitada puedes abrirla mediante su acceso individual.

El error `GLIBC_x.y not found` identifica una incompatibilidad con el paquete descargado; se indica la versión requerida y, si está disponible, la instalada. No se modifica GLIBC. Para `__wrap_memcpy`, se intenta un caso de diagnóstico con `ImportC "-Wl,-u,__wrap_memcpy" : EndImport` en un fuente temporal. Si funciona, se ofrece **Corregir y comprobar**. Solo si lo aceptas, el gestor crea un adaptador privado de GCC en el perfil separado de esa versión y vuelve a probar el compilador ordinario, sin añadir código a los proyectos. El adaptador añade `-Wl,-u,__wrap_memcpy` únicamente cuando GCC recibe las opciones de enlace características de PureBasic y la biblioteca de memoria afectada. No modifica el compilador, sus bibliotecas, GCC ni GLIBC. Se verifica el contenido del adaptador antes de usarlo. Es necesario iniciar PureBasic mediante los accesos del gestor o compilar mediante `compilar-pb`/`gestor-purebasic --compilar`, pues el acceso directo al binario oficial no hereda ese entorno. Si queda un backend limitado, no se borra la versión anterior. En perfiles separados nuevos y aún intactos, el gestor configura C como compilador de los fuentes nuevos cuando supera todas las pruebas del backend y es el elegido. No modifica perfiles originales ni preferencias que el usuario ya haya editado. Los proyectos existentes pueden indicar su propio compilador. Consulta `VALIDACION.md` para reproducir el experimento.

El registro técnico completo se conserva en `~/.local/state/gestor-purebasic-2/registro.log`. Las pruebas son comprobaciones de funcionamiento, no una certificación exhaustiva de todas las bibliotecas del IDE.

## Mantenimiento (2.5.0)

- **Crear acceso directo en escritorio:** selecciona una instalación disponible y pulsa el botón. Si no consta validada, se comprueba primero; si ya está comprobada, se verifica el manifiesto. Crea o recupera el acceso individual en el escritorio XDG y el menú con el logo del paquete (o un icono genérico si falta). Una instalación limitada previamente aceptada se identifica como tal. Una nueva comprobación limitada no publica el acceso sin consentimiento explícito. Si el escritorio está deshabilitado o no existe, el botón informa de ello. Cinnamon puede solicitar autorizar la ejecución.
- **Retirar versión seleccionada / Eliminar definitivamente:** son dos decisiones separadas; puedes retirar y, después, purgar incluso la predeterminada y la última instalación. La confirmación muestra versión, edición, ruta y alcance. Cancelar es el control con foco inicial. Se comprueban el catálogo, el contenido registrado, el uso de la versión y los montajes del árbol. Se retira la carpeta a `~/Apps/PureBasic-Gestor2/retiradas/ID` antes de limpiar accesos. El perfil se conserva en su ubicación mientras la retirada sea reversible. La purga se ofrece solo en una segunda acción sobre la versión retirada. Para una instalación importada se exige además escribir ELIMINAR tras revisar y respaldar los archivos. No se selecciona otra predeterminada automáticamente al borrar la activa; las otras versiones conservan sus accesos individuales.
- Las preferencias de perfil separado se mueven a `~/.local/state/gestor-purebasic-2/copias/perfil-retirado-ID`. Los perfiles originales compartidos, proyectos fuera del SDK, paquetes descargados, el propio gestor y copias anteriores no se borran. Los archivos personales presentes cuando se generó el manifiesto se conservan al retirar, pero sí forman parte del árbol que se eliminará si confirmas expresamente la purga: respáldalos antes de esa segunda confirmación. Las modificaciones posteriores bloquean el borrado; no se ofrece un botón para forzarlo.
- Si falla la integración tras retirar la carpeta, se muestra «Retirada · recuperable». El botón **Restaurar versión retirada** recupera la ubicación exacta y el perfil privado respaldado si corresponde. Si se inició un borrado irreversible y quedó incompleto, se muestra «Borrado incompleto · revisar»; no se intenta borrar los restos automáticamente. Si quedó un diario, reinicia el gestor para su recuperación y consulta `registro.log`.
- El bloqueo exclusivo cooperativo por ID permanece activo durante toda la sesión del IDE o la compilación por consola. Impide abrir otra sesión o compilar simultáneamente mediante otro lanzador de la misma versión. Los procesos externos también se comprueban mediante `/proc` cuando se retira una carpeta. No impide todas las carreras con programas externos, cambios de montaje posteriores o gestores antiguos.

## Novedades de seguridad 2.5.0

- Validación de texto UTF-8 por bytes mediante el módulo nativo `TextoSeguro`, rechazo de NUL y secuencias malformadas en registros y metadatos; reconstrucción de la salida estándar de los procesos sin dividir caracteres entre lecturas.
- Validación de tipos JSON antes de extraer estructuras, con estados y niveles acotados. Se aceptan campos históricos opcionales ausentes, no valores con tipos incorrectos. Los diarios se validan antes de aplicar cambios y las copias de texto inválidas se rechazan.
- Sincronización de archivos y directorios de un SDK recién extraído, del registro atómico y de las rutas implicadas en los traslados. Si una sincronización posterior falla, se bloquean nuevas operaciones del gestor y la purga irreversible. No se afirma resistencia absoluta frente a cortes de corriente, fallos de hardware o escrituras concurrentes externas.
- Comprobación de sintaxis independiente mediante `--check` cuando el compilador anuncia esa opción. Si no se acredita el soporte, no se penaliza esa versión por omitir la prueba.
- Conservación del registro y acceso a restauración tras sustituir. La versión restaurada no pasa a ser predeterminada automáticamente.

No se incorpora aún la migración selectiva de preferencias, la reparación desde un paquete de referencia, el diagnóstico ELF completo previo a ejecutar, la instalación asistida de dependencias ni una actualización completa con copia y reversión del propio gestor. La revisión 2.5.1 sí añade un diario para recuperar la publicación de su ejecutable. Tampoco se ha implementado una clasificación fiable de propiedad de archivos de instalaciones antiguas; por ello la retirada no borra ningún dato y la purga requiere confirmación independiente.

## Dónde quedan las versiones

Las instalaciones nuevas se guardan en `~/Apps/PureBasic-Gestor2/versiones/PureBasic-VERSION-EDICION`; si esa carpeta ya existe, se añade un sufijo numérico. La sustitución no mezcla archivos de distintas versiones ni obliga a reutilizar el nombre de la carpeta anterior. Los perfiles nuevos de preferencias, plantillas, herramientas e historial se almacenan por separado en `~/.local/state/gestor-purebasic-2/perfiles/`. Los perfiles originales de instalaciones externas se conservan; las preferencias no se migran automáticamente a la nueva versión.

Los accesos del menú y el escritorio se identifican por versión y edición (y carpeta si son idénticas), usan el icono oficial del paquete y lanzan la instalación específica. Se conservan los identificadores de menú heredados reconocidos como alias ocultos de la predeterminada para no romper asociaciones. En el flujo 2.4.0 se conservan los accesos directos independientes de otras instalaciones; solo se sincronizan los alias activos propios del gestor. Los accesos de versiones eliminadas se retiran si su ID y comando corresponden a la versión o si apuntan directamente al IDE de la carpeta retirada. Las entradas ajenas no se sobrescriben. Los accesos retirados se respaldan. Cinnamon puede exigir autorizar la ejecución de un acceso por primera vez.

El estado de los gestores 2.0.1, 2.1.x y 2.2.x se conserva para mantener los registros. Los diarios de integración y movimientos y las copias de accesos permanecen en `~/.local/state/gestor-purebasic-2`. El registro técnico está en `registro.log` de esa carpeta. Si se instala la nueva pero falla la retirada, el mensaje informa de una instalación con incidencias. Revisa las rutas y el registro antes de intervenir; una carpeta retirada se encuentra en `~/Apps/PureBasic-Gestor2/retiradas/ID`. No borres manualmente los diarios. Desde 2.2.0 se registra también el traslado de una instalación nueva; si la publicación se interrumpe, el arranque recupera el traslado sin borrar datos automáticamente. Si conserva una carpeta temporal para revisión, consulta el registro. Los traslados de versiones no reemplazan un destino ocupado. La interfaz permite restaurar una versión retirada tras una incidencia. Las funciones avanzadas de preparación APT y selección manual del backend permanecen en las fuentes heredadas.

## Compilar

Con una instalación PureBasic compatible y los paquetes de desarrollo habituales de la distribución:

```sh
./compilar.sh /ruta/a/purebasic
```

El script usa `pbcompilerc` con `--thread` y crea `gestor-purebasic` y `compilar-pb`. No necesitas recompilar para probar los ejecutables incluidos. Construido y probado con PureBasic 6.41 Free x64 en Debian 13. No se ha probado físicamente en Linux Mint 21.3 ni con una licencia comercial 6.02. El binario requiere GTK 3 y glibc 2.34 o posterior. Consulta `VALIDACION.md`, `ARQUITECTURA.md` y `RESULTADOS_PRUEBAS.txt`.

Para verificar el archivo extraído: `sha256sum -c SHA256SUMS`.

## Novedades 2.3.0

- Verifica ambos banners de versión cuando están disponibles. El C gratuito 6.41 no incluye «Free» en su banner; no se deduce de él una licencia completa.
- Verifica también las instalaciones paralelas en su ubicación final; el registro permanece pendiente hasta acreditar la identidad, el contenido, la compilación y la configuración inicial. Si falla, conserva la carpeta para revisión y la anterior intacta. No crea nuevos accesos individuales para versiones gestionadas sin validación.
- Al aceptar conservar ambas tras una advertencia, evita repetir el ensayo temporal que ya se había realizado; mantiene obligatoria la prueba definitiva.
- El diario de integración se valida entero antes de aplicar su recuperación. Las rutas deben ser canónicas y estar expresamente autorizadas; no se restaura parcialmente por una copia corrupta.
- El manifiesto debe ser el propio de esa versión. Registros solapados o ilegibles impiden una retirada o borrado.
- Corrige el análisis PAX/TAR para medir longitudes en bytes UTF-8 y rechazar rutas equivalentes ambiguas.
- Los diagnósticos tienen marcas temporales y el registro guarda los niveles individuales de C y ASM.

Las pruebas nuevas no constituyen una auditoría formal de seguridad ni una garantía frente a todos los fallos del sistema de archivos, cortes de corriente o software malicioso. Solo deben instalarse paquetes oficiales de confianza. No se ha verificado FASM en este contenedor ni el ciclo comercial de Linux Mint.
