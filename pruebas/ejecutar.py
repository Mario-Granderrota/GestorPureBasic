#!/usr/bin/env python3
"""Pruebas aisladas. Python se necesita solo para esta bateria, no para el gestor."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from generar_casos import generar

argumentos = argparse.ArgumentParser()
argumentos.add_argument('purebasic', type=Path)
argumentos.add_argument('paquete', type=Path)
argumentos.add_argument('--salida', type=Path)
opciones = argumentos.parse_args()
proyecto = Path(__file__).resolve().parent.parent
compilador = opciones.purebasic.resolve() / 'compilers/pbcompilerc'
paquete = opciones.paquete.resolve()
raiz = opciones.salida.resolve() if opciones.salida else Path(tempfile.mkdtemp(prefix='pruebas-gestor-pb-'))
raiz.mkdir(parents=True, exist_ok=True)
entorno = os.environ.copy()
entorno['PUREBASIC_HOME'] = str(opciones.purebasic.resolve())
registros = []
correctas = 0

def ejecutar(comando, carpeta=None, limite=180):
    resultado = subprocess.run([str(x) for x in comando], cwd=carpeta, env=entorno,
                               text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               timeout=limite)
    registros.append(resultado.stdout)
    print(resultado.stdout, end='')
    if resultado.returncode:
        (raiz / 'RESULTADOS.txt').write_text('\n'.join(registros), encoding='utf-8')
        raise SystemExit('Fallo de comprobacion; consulta ' + str(raiz / 'RESULTADOS.txt'))
    return resultado

casos = raiz / 'casos'
generar(casos)
# Complementos independientes de los casos basicos.
import gzip
import io
import tarfile
datos = (casos / 'valido.tar').read_bytes()
roto = bytearray(datos)
roto[0] ^= 1
(casos / 'checksum_invalido.tar').write_bytes(roto)
with tarfile.open(casos / 'gnu_largo.tar', 'w', format=tarfile.GNU_FORMAT) as tar:
    entrada = tarfile.TarInfo('raiz/' + 'directorio-largo-' * 12 + '/archivo.txt')
    entrada.size = 3
    tar.addfile(entrada, io.BytesIO(b'abc'))
roto = bytearray(gzip.compress(datos))
roto[-8] ^= 1
(casos / 'crc_invalido.tgz').write_bytes(roto)

for nombre in ('ciclo', 'fiabilidad', 'seguridad', 'escritorio'):
    perfil = raiz / (nombre + '-perfil')
    perfil.mkdir()
    binario = raiz / (nombre + '-test')
    trabajo = raiz / (nombre + '-compilacion')
    trabajo.mkdir()
    ejecutar([compilador, proyecto / 'pruebas' / (nombre + '.pb'), '--thread',
              '--constant', 'MODO_PRUEBAS=1', '--output', binario], trabajo)
    origen = casos if nombre == 'seguridad' else opciones.purebasic.resolve() if nombre == 'escritorio' else paquete
    resultado = ejecutar([binario, perfil, origen])
    coincidencia = re.search(r'RESULTADO: (\d+) correctas, (\d+) fallidas', resultado.stdout)
    if not coincidencia or int(coincidencia[2]):
        raise SystemExit('Resultado no verificable: ' + nombre)
    correctas += int(coincidencia[1])

lanzador = proyecto / 'compilar-pb'
if lanzador.exists():
    carpeta = raiz / 'proyecto con espacios-y-acentos-\u00e1'
    carpeta.mkdir()
    (carpeta / 'fuente relativa.pb').write_text(
        'OpenConsole()\nDefine texto.s="PROYECTO_OK"\nPrintN(texto)\n', encoding='utf-8-sig')
    ejecutar([lanzador, '--perfil', raiz / 'ciclo-perfil', '--', 'fuente relativa.pb',
              '--output', carpeta / 'programa'], carpeta)
    resultado = ejecutar([carpeta / 'programa'], carpeta)
    if resultado.stdout.strip() != 'PROYECTO_OK':
        raise SystemExit('La salida del proyecto no coincide')
    correctas += 1
    registros.append('OK lanzador nativo: fuente relativa, espacios y acentos; salida exacta PROYECTO_OK\n')

resumen = f'GLOBAL: {correctas} comprobaciones correctas; 0 fallidas.\n'
registros.append(resumen)
(raiz / 'RESULTADOS.txt').write_text('\n'.join(registros), encoding='utf-8')
print(resumen)
print('Se conservan los datos aislados en:', raiz)
