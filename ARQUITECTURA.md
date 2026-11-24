# Arquitectura — versión 0

## Presentación de la versión 0

Se mantienen los módulos y las políticas del motor 2.5.2. La nueva cabecera usa un contenedor nativo GTK3 y el estilo privado de `Tema`; si no se puede cargar CSS, no se impone el fondo oscuro. `Tema::Pulso()` encapsula el indicador de actividad GTK3. El controlador de interfaz decide cuándo mostrarlo, sin alterar los hilos ni los estados del motor. Los atajos de Escape son locales a cada diálogo. El registro se abre mediante xdg-open, sin ejecutar una orden de shell.

## Presentación 2.5.2

`tema.pbi` es un módulo nativo aislado que aplica CSS mediante las interfaces GTK3 ya enlazadas. Las reglas se limitan a las ventanas del gestor con la clase `pb-ventana`. No conoce el repositorio, las transacciones ni las políticas de instalación. `gestor.pb` conserva la coordinación de eventos y centraliza el redimensionado en `DistribuirVentana()`. El tema es opcional en ejecución y no se modifica la configuración GTK del usuario.

La política de dominio incorpora `#InstaladaLimitada` como resultado diferenciado, sin cambiar los valores existentes de otros resultados. El consentimiento para instalar con limitaciones se transmite explícitamente desde el controlador gráfico al caso de uso `ConfirmarPaquete`. Aceptar la reparación no autoriza una limitación residual. La autorización de sustitución sigue exigiendo validación completa en ambas ubicaciones.

`OperacionDisponible` centraliza la condición de ausencia de diarios y persistencia incierta antes de iniciar las operaciones de mantenimiento. `RutaDisponibleValida` distingue las rutas de instalaciones gestionadas e importadas y se reutiliza en retirada, restauración y recuperación. Los procedimientos públicos de mantenimiento adquieren el bloqueo por versión; la UI no accede directamente al borrado. `DesinstalarVersion` exige que exista una retirada anterior, y `BorrarDefinitivamente` verifica por separado la autorización adicional para una instalación externa. Los perfiles privados no se trasladan durante una restauración si su SDK o destino no están acreditados. Se evita eliminar el registro antes de retirar el manifiesto en la purga final.

`RecuperarEjecutable` valida el diario de huellas y solo confirma un binario cuyo contenido coincide con la huella anterior o la nueva. `PrepararEjecutable` persiste el binario temporal y el diario, publica el ejecutable, sincroniza el directorio y reconcilia la huella. La recuperación se puede repetir sin volver a copiar el ejecutable. No se crea una copia anterior completa ni se ofrece un actualizador remoto.

La estructura de archivos sigue siendo procedural y modular; se ha priorizado la corrección de contratos y el uso de servicios comunes frente a una refactorización integral. Sigue habiendo estado compartido y riesgos de concurrencia externa que los bloqueos cooperativos no cubren.

---

# Arquitectura — cambios de la versión 2.5.0

El flujo ordinario de sustitución y retirada ya no ejecuta `BorrarDefinitivamente`. `RetirarRecuperable` obtiene el bloqueo exclusivo, retira la carpeta mediante el diario de movimiento y limpia la integración; el perfil y el SDK permanecen disponibles para restaurar. La interfaz exige una segunda acción para invocar `DesinstalarVersion`. Se conserva la API interna previa para las pruebas de purga explícita.

`TextoSeguro` es un módulo PureBasic nativo con funciones puras y dos declaraciones públicas: `UTF8Valido` y `TextoSalidaUTF8`. Se utiliza desde rutas, archivos y procesos. `LeerTextoSeguro` diferencia el texto vacío legítimo de una lectura inválida. `CamposJSON` y `DecodificarVersion` validan tipos y valores antes de copiar estructuras; la recuperación no aplica cambios si las copias de texto no se pueden decodificar.

Se añade sincronización de ficheros, directorios, traslados y del árbol nuevo antes de publicación. `PersistenciaIncierta` señala una escritura que cambió el estado visible pero cuya persistencia no se ha acreditado. No se autoriza la purga en ese estado. Es un indicador de proceso, no una garantía física ni un sustituto del diario. La arquitectura no se ha migrado íntegramente a módulos; los demás servicios y el estado compartido heredado se mantienen para evitar una reescritura simultánea.

Los lanzadores del IDE y de compilación usan un bloqueo exclusivo por ID, y el supervisor IDE espera a la terminación del proceso abierto. No se bloquean por esa vía procesos externos al gestor ni instalaciones distintas.

---

# Evolución 2.4.0 — mantenimiento por versión

`mantenimiento.pbi` separa los casos de uso CrearAccesoVersion, DesinstalarVersion y RestaurarVersionRetirada de la interfaz. Reutiliza la retirada recuperable y el borrado del núcleo; las sustituciones completas también usan el mismo caso de uso de desinstalación. `accesos_individuales.pbi` valida el ID y el comando del lanzador; no se acepta una marca aislada como prueba de propiedad. `repositorio.pbi` implementa un bloqueo cooperativo por versión para los lanzadores y la desinstalación. `operaciones.pbi` comprueba la tabla de montajes antes de retirar y borrar. La interfaz no ejecuta directamente operaciones destructivas.

El campo opcional `RutaRetirada` conserva la ubicación exacta anterior, sin alterar el manifiesto ni invalidar registros previos. Los perfiles separados se conservan mediante un traslado sin reemplazo. Una operación de mantenimiento consta de retirada recuperable, transacción de accesos/selección, respaldo de perfil y borrado irreversible. No es una única transacción ACID: una interrupción puede dejar la versión retirada o un borrado incompleto visible para revisión. La protección frente a procesos externos y cambios de sistema de archivos no es absoluta.

# Ampliación 2.2.1 — adaptador de compatibilidad

`compatibilidad.pbi` encapsula la política de elegibilidad de la adaptación y el servicio de preparación del entorno. La persistencia añade el campo opcional `Correccion` (vacío en los registros heredados). Verificación y lanzadores comparten el mismo servicio; la GUI solo solicita consentimiento. Se mantiene la política de autorización de sustitución sin cambios: todos los backends incluidos deben superar todas las pruebas, y se comprueban de nuevo en destino. El estado de validación ya no se marca como completo cuando hay un backend residual limitado.

# Arquitectura 2.2.0 — refactorización SOLID

## Objetivo y límites

Mantener la interfaz simplificada, PureBasic nativo, la compatibilidad de los registros y las garantías de 2.1.1. Evitar una jerarquía de clases artificial: SOLID se aplica a responsabilidades, contratos y dependencias también en un diseño procedural. El núcleo no es todavía una arquitectura completamente libre de estado global; las operaciones siguen serializadas por diseño. No se ha introducido un framework, un motor de scripts ni dependencias de ejecución nuevas aparte de utilizar la llamada Linux renameat2 disponible en las GLIBC ya soportadas.

## Organización

| Archivo | Responsabilidad |
|---|---|
| `gestor.pb` | Entrada gráfica, comandos de apertura y coordinación del hilo de trabajo |
| `compilar.pb` | Entrada CLI para compilar proyectos |
| `nucleo.pbi` | Composición estática de dependencias |
| `base.pbi` | Tipos y estado compartido heredado, constantes, registro y cancelación |
| `politica.pbi` | Módulo encapsulado de reglas de versión, licencia, backend y sustitución, sin E/S |
| `versiones.pbi` | Adaptación del registro VersionPB al dominio |
| `rutas.pbi` | Rutas, archivos de texto, escritura atómica y argumentos |
| `repositorio.pbi` | Persistencia de versiones, perfiles y selección |
| `procesos.pbi` | Ejecución supervisada; contrato EjecutorPB y ResultadoProcesoPB |
| `archivos.pbi` | Lectura y validación TAR/GZIP |
| `arbol.pbi` | Copia, selección de raíz y manifiestos |
| `identidad.pbi` | Validación ELF e identificación estática |
| `verificacion.pbi` | Identificación ejecutada, diagnóstico y pruebas de backends |
| `transacciones.pbi` | Diario y recuperación de archivos de integración |
| `movimientos.pbi` | Diario, publicación y recuperación de traslados de versiones |
| `ejecutable.pbi` | Integración del propio gestor y actualización cuando cambia |
| `escritorio.pbi` | Lectura, identificación, respaldo y planificación de accesos |
| `accesos_individuales.pbi` | Integración de los accesos individuales por versión |
| `operaciones.pbi` | Operaciones heredadas sobre el ciclo de vida |
| `instalador.pbi` | Casos de uso del flujo actual y detección de instalaciones |

## Aplicación de SOLID

- **S (responsabilidad única):** separación de reglas, identificación, verificación, repositorio, procesos, archivos y recuperación. Un cambio en la política de precedencia ya no requiere editar el instalador. El flujo gráfico no realiza directamente un borrado.
- **O (abierto/cerrado):** un nuevo ejecutor compatible puede suministrarse a ProbarCasoCon sin modificar el caso de prueba. El módulo Politica contiene las decisiones de selección y precedencia. La ampliación del catálogo de pruebas de compilador aún requiere cambiar ProbarMotor; no se declara un sistema de plugins completo.
- **L (sustitución de Liskov):** no hay jerarquías de herencia. Se aplica el principio al contrato EjecutorPB: éxito/fracaso, código de salida y resultado independiente, verificados con un ejecutor real y un sustituto de prueba. El sustituto se usa solo en pruebas unitarias, nunca en el camino productivo de autorización de borrado.
- **I (segregación de interfaces):** los contratos de ejecución y las funciones del dominio son pequeños y especializados. El repositorio, la extracción y los accesos mantienen entradas independientes. Se conservan las funciones heredadas para la compatibilidad de las pruebas.
- **D (inversión de dependencias):** Politica no conoce el sistema de archivos, la interfaz ni el ejecutor de procesos. ProbarCasoCon recibe una función por el contrato EjecutorPB; ProbarCaso enlaza el ejecutor real. La inversión no es completa: el caso de uso general aún utiliza adaptadores concretos y las rutas de perfil compartidas. No se considera que toda la aplicación sea reentrante ni multisesión en el mismo proceso.

## Invariantes de seguridad

- Una validación negativa previamente almacenada puede denegar la sustitución, nunca autorizarla. Una instalación paralela tras el aviso vuelve a comprobar ambos backends.
- Un backend presente pero dañado no se confunde con uno no incluido.
- La autorización requiere una comprobación acreditada, ausencia de limitaciones y validación completa (modo de consola exclusivamente en compilaciones de pruebas).
- Una edición gratuita no sustituye la completa.
- La publicación central genera y comprueba el manifiesto, guarda un diario, traslada sin reemplazar y registra la versión. La operación intenta revertirse si falla el registro. Si queda un diario pendiente, se bloquea la sustitución. Las carpetas temporales pendientes se conservan para recuperación.
- No se cambia el formato del registro JSON de versiones ni el manifiesto. El diario de movimientos acepta un nuevo tipo `publicar`; no ejecutar una versión antigua del gestor mientras exista un diario pendiente de esta revisión.
- No se modifican GCC, GLIBC, PureBasic ni proyectos del usuario para esconder el error de enlace.
- Los borrados siguen siendo conservadores. No existe una garantía absoluta frente a modificaciones concurrentes externas, un fallo del soporte físico, un sistema de archivos no compatible o paquetes maliciosos. Los paquetes deben proceder de la fuente oficial.

## Optimizaciones verificadas

- Cálculo incremental del tamaño UTF-8 de los manifiestos; mismo orden y formato. Rechazo explícito de huellas ausentes.
- Contadores de copia privados de cada operación, no globales.
- Resultados de procesos independientes; lectura por lotes para no retrasar indefinidamente la revisión de cancelación y tiempo límite si hay mucha salida.
- Reutilización de una lectura de la versión activa al refrescar la lista; recuento de nombres repetidos mediante mapa en lugar de un recorrido de toda la lista para cada acceso.
- Evita copiar de nuevo el ejecutable del gestor y reescribir su huella y menú cuando son idénticos y los permisos son correctos.
- El formato de manifiesto es idéntico entre 2.1.1 y 2.2.0 en la prueba comparativa; se conservan las comprobaciones criptográficas y de seguridad.

Consultar VALIDACION.md para el alcance, las mediciones y las limitaciones de las pruebas.

## Evolución 2.3.0

Se conserva la separación de dominio (`politica.pbi`), identificación (`identidad.pbi`), pruebas (`verificacion.pbi`), repositorio y manifiestos (`repositorio.pbi`, `arbol.pbi`), operaciones y recuperación (`movimientos.pbi`, `transacciones.pbi`), y orquestación (`instalador.pbi`). La política no depende de la GUI. La autorización destructiva exige edición conocida, ausencia de solapamiento, manifiesto propio, prueba definitiva y validación completa de los backends incluidos. La persistencia de un registro provisional no significa autorización de lanzamiento ni borrado. Las preferencias iniciales de C se escriben solo en el perfil separado e intacto, después de verificar la ubicación definitiva.

La recuperación prevalidada reduce el riesgo de restauraciones parciales por diarios incoherentes, pero no convierte varias escrituras en una transacción ACID frente a un fallo de disco durante su aplicación. El diario sigue siendo el mecanismo de recuperación. La autenticidad del paquete no está certificada criptográficamente: SHA-256 se emplea para comprobar contenido y detectar cambios, no como firma del fabricante.
