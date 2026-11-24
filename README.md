# Gestor PureBasic — versión 0

Instalador y gestor de versiones de PureBasic para Linux x64, escrito en PureBasic. Permite instalar, actualizar y mantener versiones independientes sin modificar las bibliotecas del sistema.

**Estado del repositorio:** preparación inicial. La importación del código fuente completo de la versión 0 está pendiente.

## Características de la versión 0

- Comparación de versiones y ediciones del paquete, con comprobaciones C y ASM.
- Instalación en paralelo o sustitución reversible; restauración de versiones retiradas.
- Corrección local opcional para el error de enlace `__wrap_memcpy`, sin modificar GCC ni el paquete oficial.
- Accesos de escritorio y menú independientes, perfiles separados y desinstalación en dos etapas.
- Validación de integridad, diarios de recuperación y bloqueo de instalaciones en uso.
- Interfaz GTK3 redimensionable con diagnóstico copiable.

## Requisitos y compilación

Linux x86-64, PureBasic 6.41 compatible con la distribución y sus herramientas de desarrollo (GCC, GTK3 y las dependencias aplicables). Los binarios de distribución de la versión 0 requieren GLIBC 2.34 o posterior.

El SDK de PureBasic y sus paquetes comerciales no forman parte del proyecto. Descarga PureBasic desde [su página oficial](https://www.purebasic.com/).

Una vez incorporados los fuentes:

```sh
./compilar.sh /ruta/a/purebasic
./gestor-purebasic
```

Ejecutar como usuario normal, sin `sudo`. Utilizar únicamente paquetes oficiales de confianza: las comprobaciones dinámicas ejecutan sus compiladores. Antes de purgar una versión retirada, respaldar los archivos personales.

## Pruebas

Python 3 es necesario únicamente para las baterías automatizadas. Ejecutarlas secuencialmente en un entorno de pruebas con un SDK compatible y un paquete oficial local.

La documentación de la versión 0 registra 113 comprobaciones de regresión repetidas y pruebas gráficas adicionales. Las baterías ampliadas corresponden a revisiones anteriores del núcleo; no se repitieron todas para la versión 0. La validación completa de ASM y de distintas distribuciones sigue pendiente.

## Licencia

[MIT](LICENSE). PureBasic es un producto independiente de Fantaisie Software y no está cubierto por la licencia de este gestor.
