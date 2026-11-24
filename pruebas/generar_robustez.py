#!/usr/bin/env python3
from pathlib import Path
import io, tarfile, sys
raiz=Path(sys.argv[1]); raiz.mkdir(parents=True,exist_ok=True)
with tarfile.open(raiz/'unicode.tar','w',format=tarfile.PAX_FORMAT) as t:
    x=tarfile.TarInfo('raiz/'+'á'*80+'.txt'); x.size=9; x.pax_headers={'comment':'información ñ', 'mtime':'12.34'}; t.addfile(x,io.BytesIO(b'contenido'))
with tarfile.open(raiz/'pax-mal.tar','w',format=tarfile.USTAR_FORMAT) as t:
    b=b'9999 path=raiz/fichero\n'; x=tarfile.TarInfo('PaxHeader'); x.type=tarfile.XHDTYPE; x.size=len(b); t.addfile(x,io.BytesIO(b))
    x=tarfile.TarInfo('raiz/fichero'); x.size=1; t.addfile(x,io.BytesIO(b'x'))
with tarfile.open(raiz/'alias.tar','w',format=tarfile.USTAR_FORMAT) as t:
    x=tarfile.TarInfo('raiz/./fichero'); x.size=1; t.addfile(x,io.BytesIO(b'x'))
