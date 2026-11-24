#!/usr/bin/env python3
"""Baterías adicionales, secuenciales; no modifica el SDK oficial de origen."""
from pathlib import Path
import argparse, shutil, subprocess, os, tempfile, re
p=argparse.ArgumentParser()
p.add_argument('purebasic',type=Path); p.add_argument('paquete',type=Path)
p.add_argument('--salida',type=Path); p.add_argument('--grafica',action='store_true')
a=p.parse_args(); proyecto=Path(__file__).resolve().parent.parent
raiz=a.salida.resolve() if a.salida else Path(tempfile.mkdtemp(prefix='gestor-pb-ampliadas-'))
raiz.mkdir(parents=True,exist_ok=True)
sdk=raiz/'sdk'; shutil.copytree(a.purebasic.resolve(),sdk)
entorno=os.environ.copy(); entorno['PUREBASIC_HOME']=str(sdk)
casos=raiz/'casos'; subprocess.run(['python3',str(proyecto/'pruebas/generar_robustez.py'),str(casos)],check=True)
registros=[]; total=0
nombres = ('solid','instalador','compatibilidad','robustez')
# Mantenimiento inyecta fallos de escritura y estados controlados de prueba.
if not a.grafica: nombres += ('mantenimiento','seguridad25','depuracion251')
for nombre in nombres:
    base=raiz/nombre; perfil=base/'perfil'; trabajo=base/'build'; perfil.mkdir(parents=True); trabajo.mkdir()
    exe=base/'test'; opciones=[] if a.grafica else ['--constant','MODO_PRUEBAS=1']
    # En modo grafico las pruebas de sustitución no admiten acreditación solo de consola.
    r=subprocess.run([str(sdk/'compilers/pbcompilerc'),str(proyecto/'pruebas'/f'{nombre}.pb'),'--thread',*opciones,'--output',str(exe)],cwd=trabajo,env=entorno,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=180)
    (base/'build.log').write_text(r.stdout); print(r.stdout,end=''); r.check_returncode()
    r=subprocess.run([str(exe),str(perfil),str(casos if nombre=='robustez' else sdk if nombre in ('mantenimiento','seguridad25','depuracion251') else a.paquete.resolve())],env=entorno,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=300)
    (base/'test.log').write_text(r.stdout); print(r.stdout,end=''); r.check_returncode()
    m=re.search(r'RESULTADO: (\d+) correctas, (\d+) fallidas',r.stdout)
    if not m or int(m[2]): raise SystemExit('Resultados no verificables')
    total+=int(m[1]); registros.append(r.stdout)
resumen=f'GLOBAL AMPLIADAS: {total} correctas, 0 fallidas.'; print(resumen)
(raiz/'RESULTADOS.txt').write_text('\n'.join(registros+[resumen]))
