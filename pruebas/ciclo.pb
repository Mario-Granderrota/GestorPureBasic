XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : PrintN(ErrorActual) : End 2 : EndIf
Global paquete.s=ProgramParameter(1),id.s,dato.VersionPB,previo.s
Define archivo=CreateFile(#PB_Any,Hogar+"/truncado"), Dim cabecera.a(19)
cabecera(0)=127 : cabecera(1)=69 : cabecera(2)=76 : cabecera(3)=70 : cabecera(4)=2 : cabecera(5)=1 : cabecera(18)=62
If archivo : WriteData(archivo,@cabecera(),20) : CloseFile(archivo) : SetFileAttributes(Hogar+"/truncado",493) : EndIf
Comprobar(Bool(Not ELFValido(ProgramParameter(0)+"/truncado")),"rechaza ELF truncado")
Comprobar(Bool(PonerIdentidad(@dato,"PureBasic 6.02 LTS (Linux - x64)") And dato\Numero="6.02" And dato\Edicion="completa"),"interpreta la identidad de 6.02 LTS completa")
PermitirGratuita=0
Comprobar(Bool(Not Instalar(paquete,"C")),"no instala una gratuita como actualización completa sin elección expresa")
PermitirGratuita=1
Comprobar(Instalar(paquete,"C"),"extrae y comprueba compilador oficial")
id=LeerTexto(Estado+"/ultima.txt")
Comprobar(LeerVersion(id,@dato),"registro JSON completo")
Comprobar(Bool(dato\Numero="6.41" And dato\Edicion="gratuita"),"identifica versión y edición")
Comprobar(VerificarContenido(@dato),"manifiesto coincide con el contenido")
If dato\Limitacion<>""
  Comprobar(Bool(Not Activar(id) And Activa()=""),"una limitación real bloquea la activación normal")
EndIf
Comprobar(Activar(id,1),"la aceptación expresa permite continuar con la versión conservada")
Comprobar(Bool(Activa()=id),"selección activa correcta")
Comprobar(Bool(Not Retirar(id)),"impide retirar la versión activa")
Guardar(Estado+"/activa.txt","")
Comprobar(Retirar(id),"retira sin destruir")
Comprobar(LeerVersion(id,@dato),"lee registro de retirada")
Comprobar(Bool(dato\Estado="retirada" And FileSize(dato\Ruta)=-2),"carpeta retirada recuperable")
Comprobar(Restaurar(id),"restaura versión retirada")
Comprobar(LeerVersion(id,@dato),"lee versión restaurada")
Comprobar(Activar(id,1),"activa versión restaurada")
; Una modificación posterior bloquea el borrado.
Guardar(dato\Ruta+"/archivo-del-usuario.pb","dato propio")
Comprobar(Bool(Not VerificarContenido(@dato)),"detecta archivos posteriores y los conserva")
DeleteFile(dato\Ruta+"/archivo-del-usuario.pb")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
