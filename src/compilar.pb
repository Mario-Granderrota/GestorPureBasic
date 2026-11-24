; Lanzador de compilacion nativo: funciona tambien sin sesion grafica.
XIncludeFile "base.pbi"
XIncludeFile "compatibilidad.pbi"
OpenConsole()
Define perfil.s,id.s,motor.s,indice,primero=-1,argumentos.s,dato.VersionPB,compilador.s, resultadoProceso.ResultadoProcesoPB
For indice=0 To CountProgramParameters()-1
  Select ProgramParameter(indice)
    Case "--perfil" : indice+1 : perfil=ProgramParameter(indice)
    Case "--id" : indice+1 : id=ProgramParameter(indice)
    Case "--motor" : indice+1 : motor=UCase(ProgramParameter(indice))
    Case "--" : primero=indice+1 : Break
    Default : PrintN("Argumento desconocido: "+ProgramParameter(indice)) : End 2
  EndSelect
Next
If primero<0 Or primero>=CountProgramParameters()
  PrintN("Uso: compilar-pb [--perfil CARPETA] [--id ID] [--motor C|ASM] -- fuente.pb --output programa") : End 2
EndIf
If Not Inicializar(perfil) : PrintN(ErrorActual) : End 1 : EndIf
If id="" : id=Activa() : EndIf
Define bloqueoVersionActual=BloqueoVersion(id,1)
If bloqueoVersionActual<0 : PrintN(ErrorActual) : End 1 : EndIf
If Not LeerVersion(id,@dato) Or dato\Estado<>"disponible" : PrintN("No hay una version disponible seleccionada.") : End 1 : EndIf
If dato\Tipo="gestionada" And Not dato\Comprobada : PrintN("La instalación está pendiente de validación.") : End 1 : EndIf
If motor="" : motor=dato\Motor : EndIf
If motor<>"C" And motor<>"ASM" : PrintN("Selecciona un backend valido: C o ASM.") : End 2 : EndIf
compilador=dato\Ruta+"/compilers/pbcompiler"
If motor="C" : compilador=dato\Ruta+"/compilers/pbcompilerc" : EndIf
If TipoArchivo(compilador)<>32768 Or Not (GetFileAttributes(compilador)&64) : PrintN("Compilador no disponible.") : End 1 : EndIf
For indice=primero To CountProgramParameters()-1 : argumentos+" "+Citar(ProgramParameter(indice)) : Next
SetEnvironmentVariable("PUREBASIC_HOME",dato\Ruta)
If Not EntornoCompatible(@dato) : PrintN(ErrorActual) : End 1 : EndIf
If EjecutarProceso(compilador,argumentos,GetCurrentDirectory(),@resultadoProceso,3600)
  Print(resultadoProceso\Salida) : End 0
EndIf
Print(resultadoProceso\Salida) : If ErrorActual<>"" : PrintN(ErrorActual) : EndIf : End 1
