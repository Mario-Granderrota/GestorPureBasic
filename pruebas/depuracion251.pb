XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : End 2 : EndIf
Define dato.VersionPB, id.s, ruta.s=Hogar+"/PureBasic importado", sdk.s=ProgramParameter(1), fd, paquete.PaquetePB, perfil.s, temporal.s, NewList rutas.s()
Comprobar(Bool(CrearCarpetas(ruta+"/compilers") And CrearCarpetas(ruta+"/residents") And CrearCarpetas(ruta+"/purelibraries")),"crea estructura aislada")
Comprobar(Bool(CopyFile(sdk+"/compilers/purebasic",ruta+"/compilers/purebasic") And CopyFile(sdk+"/compilers/pbcompiler",ruta+"/compilers/pbcompiler")),"copia ejecutables ELF del SDK de prueba")
SetFileAttributes(ruta+"/compilers/purebasic",493) : SetFileAttributes(ruta+"/compilers/pbcompiler",493)
Guardar(ruta+"/datos-personales.pb","DATOS PERSONALES")
Comprobar(RegistrarExistente(ruta),"registra una carpeta importada con datos previos")
CargarVersiones() : FirstElement(Versiones()) : id=Versiones()\Id
Comprobar(Bool(Not DesinstalarVersion(id,1) And FileSize(ruta)=-2),"ni una autorizacion permite purgar sin retirar primero")
AddElement(rutas()) : rutas()=Estado+"/activa.txt"
Comprobar(IniciarTransaccion(rutas()),"abre diario de integracion pendiente")
Comprobar(Bool(Not RetirarRecuperable(id) And FileSize(ruta)=-2),"diario pendiente impide retirar una version")
Comprobar(Bool(Not PrepararPaquete(sdk,@paquete) And paquete\Temporal=""),"diario pendiente impide preparar otro paquete")
Comprobar(Bool(Not CrearAccesoVersion(id,0)),"diario pendiente impide generar accesos")
Comprobar(RecuperarTransaccion(),"recupera diario sin alterar la instalacion")
Comprobar(Bool(RetirarRecuperable(id) And LeerVersion(id,@dato) And dato\Estado="retirada"),"retira el SDK sin borrar")
Comprobar(Bool(Not DesinstalarVersion(id) And LeerTexto(dato\Ruta+"/datos-personales.pb")="DATOS PERSONALES"),"purga de importacion exige autorizacion adicional")
Comprobar(Bool(Not BorrarDefinitivamente(id) And FileSize(dato\Ruta)=-2),"la regla protege tambien el procedimiento de bajo nivel")
Define retiradaOriginal.s=dato\Ruta, destinoOriginal.s=dato\RutaRetirada
dato\RutaRetirada=Estado+"/versiones/archivo-ajeno" : GuardarVersion(@dato)
Comprobar(Bool(Not RestaurarVersionRetirada(id) And FileSize(retiradaOriginal)=-2),"rechaza destino de restauracion interno al gestor")
dato\RutaRetirada=destinoOriginal : GuardarVersion(@dato)
dato\Ruta=Hogar+"/otra-retirada" : GuardarVersion(@dato)
Comprobar(Bool(Not RestaurarVersionRetirada(id) And FileSize(retiradaOriginal)=-2),"rechaza raiz de retirada no correspondiente al ID")
dato\Ruta=retiradaOriginal : GuardarVersion(@dato)
fd=BloqueoVersion(id,1)
Comprobar(Bool(fd>=0 And Not RestaurarVersionRetirada(id) And FileSize(ruta)=-1),"restauracion respeta bloqueo de version")
If fd>=0 : CerrarNativo(fd) : EndIf
Comprobar(Bool(RestaurarVersionRetirada(id) And LeerTexto(ruta+"/datos-personales.pb")="DATOS PERSONALES"),"restaura ruta y datos exactos")
fd=BloqueoVersion(id,1)
Comprobar(Bool(fd>=0 And Not CrearAccesoVersion(id,0)),"creacion de accesos respeta bloqueo exclusivo")
If fd>=0 : CerrarNativo(fd) : EndIf
paquete\Dato\Id=IdNuevo() : perfil=Estado+"/perfiles/"+paquete\Dato\Id
CrearCarpetas(perfil) : Guardar(perfil+"/datos","NO BORRAR")
Guardar(Estado+"/versiones/"+paquete\Dato\Id+".json","JSON ilegible")
LimpiarPaquete(@paquete)
Comprobar(Bool(LeerTexto(perfil+"/datos")="NO BORRAR"),"un registro ilegible no permite borrar su perfil")
; Un contexto corrupto no puede seleccionar un directorio anidado como temporal.
temporal=Almacen+"/versiones/.trabajo-falso" : CrearCarpetas(temporal) : Guardar(temporal+"/datos","CONSERVAR")
paquete\Temporal=temporal : LimpiarPaquete(@paquete)
Comprobar(Bool(LeerTexto(temporal+"/datos")="CONSERVAR"),"limpieza limitada a temporales directos del almacen")
Comprobar(Bool(Politica::#InstaladaLimitada<>Politica::#Instalada And Politica::#InstaladaLimitada<>Politica::#ConIncidencias),"estado limitado distinto de exito completo e integracion fallida")
; Interrupciones de la actualización del propio gestor.
FalloEscritura=Estado+"/ejecutable.sha256"
Comprobar(Bool(Not PrepararEjecutable() And TipoArchivo(Estado+"/ejecutable.pendiente")=32768 And TipoArchivo(EjecutableGestor)=32768),"fallo tras trasladar ejecutable conserva diario de su huella")
FalloEscritura=""
Comprobar(Bool(RecuperarEjecutable(EjecutableGestor) And LeerTexto(Estado+"/ejecutable.sha256")=FileFingerprint(EjecutableGestor,#PB_Cipher_SHA2,256) And TipoArchivo(Estado+"/ejecutable.pendiente")=0),"recupera y confirma la huella nueva")
Define huellaActual.s=FileFingerprint(EjecutableGestor,#PB_Cipher_SHA2,256)
Guardar(Estado+"/ejecutable.pendiente",huellaActual+#LF$+LSet("",64,"0"))
Comprobar(Bool(RecuperarEjecutable(EjecutableGestor) And LeerTexto(Estado+"/ejecutable.sha256")=huellaActual),"recupera interrupcion antes de publicar conservando ejecutable anterior")
Guardar(Estado+"/ejecutable.pendiente",LSet("",64,"1")+#LF$+LSet("",64,"0"))
Comprobar(Bool(Not RecuperarEjecutable(EjecutableGestor) And FileFingerprint(EjecutableGestor,#PB_Cipher_SHA2,256)=huellaActual And TipoArchivo(Estado+"/ejecutable.pendiente")=32768),"diario incoherente no altera el ejecutable")
Comprobar(Bool(Not OperacionDisponible()),"diario del gestor pendiente bloquea operaciones nuevas")
DeleteFile(Estado+"/ejecutable.pendiente")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
