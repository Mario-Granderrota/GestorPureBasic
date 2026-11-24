#!/usr/bin/env python3
"""Crea exclusivamente datos de prueba; la aplicacion no necesita Python."""
import io
import os
from pathlib import Path
import sys
import tarfile

def generar(destino):
    destino.mkdir(parents=True, exist_ok=True)
    casos = [
        ('ascenso', '../escape.txt', tarfile.REGTYPE, ''),
        ('absoluta', '/tmp/gestor-pb-escape.txt', tarfile.REGTYPE, ''),
        ('ascenso_interno', 'raiz/../../escape.txt', tarfile.REGTYPE, ''),
        ('simbolico', 'raiz/enlace', tarfile.SYMTYPE, '/tmp'),
        ('duro', 'raiz/enlace', tarfile.LNKTYPE, '/etc/passwd'),
        ('fifo', 'raiz/tuberia', tarfile.FIFOTYPE, ''),
        ('barra_inversa', 'raiz\\escape', tarfile.REGTYPE, ''),
        ('control', 'raiz/salto\nlinea', tarfile.REGTYPE, ''),
    ]
    for nombre, ruta, tipo, enlace in casos:
        with tarfile.open(destino / (nombre + '.tar'), 'w') as paquete:
            entrada = tarfile.TarInfo(ruta)
            entrada.type, entrada.linkname = tipo, enlace
            entrada.size = 3 if tipo == tarfile.REGTYPE else 0
            paquete.addfile(entrada, io.BytesIO(b'abc') if entrada.size else None)
    with tarfile.open(destino / 'duplicado.tar', 'w') as paquete:
        for _ in range(2):
            entrada = tarfile.TarInfo('duplicado.txt')
            entrada.size = 3
            paquete.addfile(entrada, io.BytesIO(b'abc'))
    entrada = tarfile.TarInfo('truncado.txt')
    entrada.size = 10000
    (destino / 'truncado.tar').write_bytes(entrada.tobuf() + b'x' * 512)
    entrada = tarfile.TarInfo('enorme.txt')
    entrada.size = 1073741825
    (destino / 'enorme.tar').write_bytes(entrada.tobuf() + b'\0' * 1024)
    with tarfile.open(destino / 'valido.tar', 'w') as paquete:
        entrada = tarfile.TarInfo('raiz/carpeta con espacios/acentos-á+%.txt')
        entrada.size, entrada.mode = 3, 0o4755
        paquete.addfile(entrada, io.BytesIO(b'abc'))
    carpeta = destino / 'carpeta-enlace'
    carpeta.mkdir(exist_ok=True)
    (carpeta / 'enlace').symlink_to('/etc/passwd')
    carpeta = destino / 'carpeta-fifo'
    carpeta.mkdir(exist_ok=True)
    os.mkfifo(carpeta / 'tuberia')

if __name__ == '__main__':
    generar(Path(sys.argv[1]))
