#!/bin/sh
set -eu
carpeta_proyecto=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ "$#" -lt 1 ]; then
  printf '%s\n' 'Uso: ./compilar.sh "/ruta/a/purebasic-6.41"' >&2
  exit 2
fi
carpeta_purebasic=$(CDPATH= cd -- "$1" && pwd)
compilador="$carpeta_purebasic/compilers/pbcompilerc"
export PUREBASIC_HOME="$carpeta_purebasic"
# El compilador crea purebasic.c y purebasic.o en el directorio de trabajo.
# No compartirlo con otros procesos de compilacion.
trabajo=$(mktemp -d)
trap 'rm -rf -- "$trabajo"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cd "$trabajo"
"$compilador" "$carpeta_proyecto/src/gestor.pb" --thread --output "$carpeta_proyecto/gestor-purebasic"
"$compilador" "$carpeta_proyecto/src/compilar.pb" --thread --console --output "$carpeta_proyecto/compilar-pb"
printf '%s\n' 'Compilados: gestor-purebasic y compilar-pb'
