XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : PrintN(ErrorActual) : End 2 : EndIf
If ProgramParameter(2)="recuperar"
  If Not RecuperarMovimiento() Or Not RecuperarTransaccion() : PrintN(ErrorActual) : End 1 : EndIf
  PrintN("RECUPERADO") : End 0
EndIf
Global paquete.s=ProgramParameter(1),primera.s,segunda.s,dato.VersionPB,anterior.s,menuAnterior.s,proceso,estadoProceso
Global NewList rutas.s()
Comprobar(Instalar(paquete,"C"),"instala una versión real para los ensayos")
primera=LeerTexto(Estado+"/ultima.txt")
Comprobar(Activar(primera,1),"activa una base comprobada")
Comprobar(LeerVersion(primera,@dato),"obtiene el registro de base")
Comprobar(CopiarArbol(dato\Ruta,Hogar+"/purebasic_v7"),"prepara instalación anterior externa")
Comprobar(RegistrarExistente(Hogar+"/purebasic_v7"),"registra instalación externa sin moverla")
CargarVersiones()
ForEach Versiones()
  If Versiones()\Tipo="externa" : segunda=Versiones()\Id : EndIf
Next
Comprobar(Bool(segunda<>""),"identifica la instalación existente")
anterior=LeerTexto(Estado+"/anterior.txt") : menuAnterior=LeerTexto(Datos+"/applications/purebasic-nativo-2.desktop")
FalloEscritura=Estado+"/activa.txt"
Comprobar(Bool(Not Activar(segunda,1)),"un fallo al publicar la selección nunca anuncia éxito")
Comprobar(Bool(Activa()=primera),"mantiene activa la versión anterior tras el fallo")
FalloEscritura=""
Comprobar(RecuperarTransaccion(),"recupera el diario cuando vuelve a poder escribir")
Comprobar(Bool(LeerTexto(Estado+"/anterior.txt")=anterior),"restaura también el historial de selección")
Comprobar(Bool(LeerTexto(Datos+"/applications/purebasic-nativo-2.desktop")=menuAnterior),"conserva el acceso anterior completo")
; Simula interrupción después de publicar parte de una transacción.
AddElement(rutas()) : rutas()=Estado+"/activa.txt"
Comprobar(IniciarTransaccion(rutas()),"persiste un diario antes de cambiar la selección")
Comprobar(Guardar(Estado+"/activa.txt",segunda),"simula publicación antes de una interrupción")
proceso=RunProgram(ProgramFilename(),Citar(Hogar)+" "+Citar(paquete)+" recuperar","",#PB_Program_Open|#PB_Program_Wait)
If proceso : estadoProceso=ProgramExitCode(proceso) : CloseProgram(proceso) : Else : estadoProceso=-1 : EndIf
Comprobar(Bool(estadoProceso=0 And Activa()=primera),"otra instancia recupera la selección anterior")
Comprobar(Activar(segunda,1),"activa la instalación externa tras comprobarla")
FalloEscritura=Estado+"/activa.txt"
Comprobar(Bool(Not Activar(primera,1) And Activa()=segunda),"el fallo conserva también una selección anterior externa")
FalloEscritura=""
Comprobar(RecuperarTransaccion(),"recupera el diario con una instalación externa anterior")
Comprobar(Activar(primera,1),"vuelve a la instalación gestionada")
Guardar(Hogar+"/purebasic_v7/proyecto-del-usuario.pb","no borrar")
Comprobar(Bool(Not Retirar(segunda)),"conserva la instalación externa si aparecen archivos del usuario")
Comprobar(ActualizarRegistro(segunda),"la revisión expresa permite registrar cambios legítimos sin borrar datos")
Comprobar(Retirar(segunda),"retira explícitamente la instalación antigua externa")
Comprobar(Bool(FileSize(Hogar+"/purebasic_v7")=-1),"libera la ubicación original mediante traslado recuperable")
Comprobar(Restaurar(segunda),"restaura una instalación externa en su ruta original")
Comprobar(Bool(FileSize(Hogar+"/purebasic_v7/compilers/purebasic")>64 And LeerTexto(Hogar+"/purebasic_v7/proyecto-del-usuario.pb")="no borrar"),"recupera los ejecutables y el contenido del usuario revisado")
Comprobar(Retirar(segunda),"prepara una retirada para el borrado explícito")
Comprobar(BorrarDefinitivamente(segunda,1),"borra solo la versión retirada seleccionada")
Comprobar(Bool(Activa()=primera And LeerVersion(primera,@dato) And FileSize(dato\Ruta)=-2),"conserva operativa la otra versión")
Comprobar(Bool(Not IdValido("../fuera") And Not Dentro(Hogar,Hogar)),"rechaza identificadores y raíces peligrosos")
Comprobar(Desactivar(),"desactiva los accesos propios sin borrar las versiones")
Comprobar(Bool(Activa()="" And FileSize(dato\Ruta)=-2),"permite desinstalar también la última versión conservando el contenido hasta retirarlo")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
