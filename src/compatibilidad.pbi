; Adaptacion local del enlazador. No modifica PureBasic ni GCC.
#CORRECCION_MEMCPY = "gcc-memcpy-v1"
Procedure.s TextoAdaptadorGCC()
  Protected texto.s
  texto+"#!/bin/sh"+#LF$
  texto+"wrap=0; memoria=0; base=0; presente=0"+#LF$
  texto+"for arg do"+#LF$
  texto+" case "+Chr(34)+"$arg"+Chr(34)+" in"+#LF$
  texto+"  -Wl,--wrap=memcpy) wrap=1;;"+#LF$
  texto+"  -lpbmimalloc) memoria=1;;"+#LF$
  texto+"  "+Chr(34)+"$PUREBASIC_HOME/compilers/systembase.a"+Chr(34)+") base=1;;"+#LF$
  texto+"  -Wl,-u,__wrap_memcpy) presente=1;;"+#LF$
  texto+" esac"+#LF$
  texto+"done"+#LF$
  texto+"if [ "+Chr(34)+"$wrap$memoria$base$presente"+Chr(34)+" = 1110 ]; then"+#LF$
  texto+" exec /usr/bin/gcc -Wl,-u,__wrap_memcpy "+Chr(34)+"$@"+Chr(34)+""+#LF$
  texto+"fi"+#LF$
  texto+"exec /usr/bin/gcc "+Chr(34)+"$@"+Chr(34)+""+#LF$
  ProcedureReturn texto
EndProcedure
Procedure.s CarpetaAdaptador(*dato.VersionPB)
  If *dato\Perfil<>"separado" Or *dato\Tipo<>"gestionada" Or Not IdValido(*dato\Id) : ProcedureReturn "" : EndIf
  ProcedureReturn RutaPerfil(*dato)+"/compatibilidad"
EndProcedure
Procedure PuedeOfrecerCorreccion(*dato.VersionPB)
  ProcedureReturn Bool(*dato\Correccion="" And CarpetaAdaptador(*dato)<>"" And FindString(*dato\Diagnostico,"solución experimental -Wl,-u,__wrap_memcpy verificada"))
EndProcedure
; Solo el proceso gestor/IDE y sus hijos heredan este PATH. El llamante de
; validacion restaura el PATH original; el lanzador lo mantiene hasta salir.
Procedure EntornoCompatible(*dato.VersionPB,crear.i=0)
  Protected carpeta.s,ruta.s,texto.s,entorno.s
  If *dato\Correccion="" : ProcedureReturn #True : EndIf
  If *dato\Correccion<>#CORRECCION_MEMCPY : ProcedureReturn Fallar("Corrección local desconocida; no se iniciará el compilador.") : EndIf
  carpeta=CarpetaAdaptador(*dato)
  If carpeta="" Or FindString(carpeta,":") Or TipoArchivo(Canonica("/usr/bin/gcc"))<>32768
    ProcedureReturn Fallar("No se puede preparar el adaptador local de GCC.")
  EndIf
  ruta=carpeta+"/gcc" : texto=TextoAdaptadorGCC()
  If crear And TipoArchivo(carpeta)=0
    If Not CrearCarpetas(carpeta) Or Not SetFileAttributes(carpeta,448) : ProcedureReturn Fallar("No se puede crear el perfil de compatibilidad.") : EndIf
  EndIf
  If Canonica(carpeta)<>carpeta Or TipoArchivo(carpeta)<>16384 : ProcedureReturn Fallar("Perfil de compatibilidad ausente o no válido.") : EndIf
  If crear And TipoArchivo(ruta)=0
    If Not Guardar(ruta,texto,448) : ProcedureReturn Fallar("No se pudo crear el adaptador local.") : EndIf
  EndIf
  If TipoArchivo(ruta)<>32768 Or LeerTexto(ruta)<>texto Or (GetFileAttributes(ruta)&511)<>448
    ProcedureReturn Fallar("El adaptador local está ausente o modificado. No se ejecutará.")
  EndIf
  entorno=GetEnvironmentVariable("PATH")
  If entorno="" : entorno="/usr/bin:/bin" : EndIf
  SetEnvironmentVariable("PATH",carpeta+":"+entorno)
  ProcedureReturn #True
EndProcedure
