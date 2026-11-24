XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i, Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : End 2 : EndIf
Global sdk.s=ProgramParameter(1)
Procedure CrearInstalacion(ruta.s,*dato.VersionPB)
  If Not CrearCarpetas(ruta+"/compilers") Or Not CrearCarpetas(ruta+"/residents") Or Not CrearCarpetas(ruta+"/purelibraries") : ProcedureReturn #False : EndIf
  If Not CopyFile(sdk+"/compilers/purebasic",ruta+"/compilers/purebasic") Or Not CopyFile(sdk+"/compilers/pbcompiler",ruta+"/compilers/pbcompiler") Or Not CopyFile(sdk+"/logo.png",ruta+"/logo.png") : ProcedureReturn #False : EndIf
  SetFileAttributes(ruta+"/compilers/purebasic",493) : SetFileAttributes(ruta+"/compilers/pbcompiler",493)
  If Not RegistrarExistente(ruta) : ProcedureReturn #False : EndIf
  CargarVersiones()
  ForEach Versiones()
    If Versiones()\Ruta=ruta
      CopyStructure(@Versiones(),*dato,VersionPB)
      ; Estado controlado de prueba: no representa una validación del SDK comercial.
      *dato\Comprobada=1 : *dato\Motor="C" : *dato\Perfil="separado" : *dato\Validacion="consola"
      ProcedureReturn GuardarVersion(*dato)
    EndIf
  Next
EndProcedure
Procedure.s NombreAcceso(*dato.VersionPB)
  ProcedureReturn "PureBasic-"+ReplaceString(Etiqueta(*dato)," ","-")+"-"+*dato\Edicion+"-"+*dato\Id+".desktop"
EndProcedure
Define uno.VersionPB,dos.VersionPB,actual.VersionPB, rutaUno.s=Hogar+"/PB Uno",rutaDos.s=Hogar+"/PB Dos",escritorio.s=Hogar+"/Escritorio", nombreUno.s,nombreDos.s,ajeno.s,perfil.s,fd, rutaDirecta.s, contenido.s, accesoUno.s
CrearCarpetas(escritorio) : CrearCarpetas(Datos+"/applications")
Comprobar(CrearInstalacion(rutaUno,@uno),"registra instalacion uno con archivos ELF reales")
Comprobar(CrearInstalacion(rutaDos,@dos),"registra instalacion dos independiente")
nombreUno=NombreAcceso(@uno) : nombreDos=NombreAcceso(@dos) : accesoUno=escritorio+"/"+nombreUno
Comprobar(CrearAccesoVersion(uno\Id,0),"crea menu y escritorio de version uno")
Comprobar(Bool(FileSize(accesoUno)>0 And FileSize(Datos+"/applications/"+nombreUno)>0),"existen ambos accesos")
Comprobar(Bool(ValorDesktop(LeerTexto(accesoUno),"Icon")=EscaparValor(rutaUno+"/logo.png") And (GetFileAttributes(accesoUno)&511)=493),"logo oficial y permiso ejecutable")
Comprobar(CrearAccesoVersion(dos\Id,0),"crea acceso separado de otra version")
DeleteFile(accesoUno)
Comprobar(Bool(CrearAccesoVersion(uno\Id,0) And FileSize(accesoUno)>0),"repara acceso borrado sin reinstalar")
contenido=LeerTexto(accesoUno) : ajeno="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Exec=/usr/bin/true"+#LF$+"X-GestorPureBasic-Version="+uno\Id+#LF$
Guardar(accesoUno,ajeno,493)
Comprobar(Bool(Not CrearAccesoVersion(uno\Id,0) And LeerTexto(accesoUno)=ajeno),"no sobrescribe acceso ajeno aunque copie ID")
Guardar(accesoUno,contenido,493)
Guardar(Estado+"/activa.txt",uno\Id) : Guardar(Estado+"/anterior.txt",dos\Id)
Guardar(escritorio+"/Alias-activo.desktop",TextoAcceso(@uno),493)
Guardar(escritorio+"/Ajeno.desktop",ajeno,493)
rutaDirecta=escritorio+"/Antiguo.desktop" : Guardar(rutaDirecta,"[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Exec="+CitarDesktop(rutaUno+"/compilers/purebasic")+#LF$,493)
perfil=RutaPerfil(@uno) : CrearCarpetas(perfil) : Guardar(perfil+"/preferencias-personales.txt","privadas")
Guardar(rutaUno+"/proyecto-nuevo.pb","personal")
Comprobar(Bool(Not RetirarRecuperable(uno\Id) And FileSize(rutaUno+"/proyecto-nuevo.pb")>0 And Activa()=uno\Id And FileSize(accesoUno)>0),"cambios posteriores bloquean borrado sin cambiar accesos")
DeleteFile(rutaUno+"/proyecto-nuevo.pb")
fd=BloqueoVersion(uno\Id)
Comprobar(Bool(fd>=0 And Not RetirarRecuperable(uno\Id) And FileSize(rutaUno)=-2),"bloqueo compartido impide desinstalar durante lanzamiento")
If fd>=0 : CerrarNativo(fd) : EndIf
; Fallo de integración inyectado: tras mover, se conserva la carpeta y se puede recuperar.
FalloEscritura=Estado+"/activa.txt"
Comprobar(Bool(Not RetirarRecuperable(uno\Id) And LeerVersion(uno\Id,@actual) And actual\Estado="retirada" And FileSize(actual\Ruta)=-2),"fallo tras retirada conserva SDK recuperable")
FalloEscritura=""
Comprobar(RecuperarTransaccion(),"recupera integracion tras fallo inyectado")
Comprobar(Bool(RestaurarVersionRetirada(uno\Id) And FileSize(rutaUno)=-2 And Activa()=uno\Id),"restaura ruta exacta y seleccion anterior")
Comprobar(Bool(RetirarRecuperable(uno\Id) And DesinstalarVersion(uno\Id,1)),"elimina version activa expresamente seleccionada")
Comprobar(Bool(FileSize(rutaUno)=-1 And FileSize(Almacen+"/retiradas/"+uno\Id)=-1 And Not LeerVersion(uno\Id,@actual)),"carpetas SDK y registro eliminados")
Comprobar(Bool(FileSize(uno\Manifiesto)=-1 And Activa()="" And LeerTexto(Estado+"/anterior.txt")=dos\Id),"limpia manifiesto y predeterminada sin alterar historial ajeno")
Comprobar(Bool(FileSize(accesoUno)=-1 And FileSize(Datos+"/applications/"+nombreUno)=-1 And FileSize(rutaDirecta)=-1 And FileSize(escritorio+"/Alias-activo.desktop")=-1),"retira accesos propios y alias exactos")
Comprobar(Bool(FileSize(rutaDos)=-2 And FileSize(escritorio+"/"+nombreDos)>0 And LeerTexto(escritorio+"/Ajeno.desktop")=ajeno),"otra instalacion y acceso ajeno intactos")
Comprobar(Bool(FileSize(perfil)=-1 And LeerTexto(Estado+"/copias/perfil-retirado-"+uno\Id+"/preferencias-personales.txt")="privadas"),"conserva perfil privado en copia recuperable")
Comprobar(Bool(Not DesinstalarVersion(uno\Id) And FileSize(rutaDos)=-2),"segunda solicitud no afecta otras versiones")
Comprobar(Bool(RetirarRecuperable(dos\Id) And DesinstalarVersion(dos\Id,1)),"elimina ultima version sin exigir otra activa")
Comprobar(Bool(FileSize(rutaDos)=-1 And FileSize(escritorio+"/"+nombreDos)=-1 And LeerTexto(escritorio+"/Ajeno.desktop")=ajeno),"ultima version sin restos de integracion reconocida")
Comprobar(MontajesSinCruce("12 1 0:1 / / rw - tmpfs tmpfs rw"+#LF$,Hogar),"montaje padre normal no bloquea")
Comprobar(Bool(Not MontajesSinCruce("12 1 0:1 / "+ReplaceString(Hogar+"/PB Uno/interior"," ",Chr(92)+"040")+" rw - tmpfs tmpfs rw"+#LF$,Hogar+"/PB Uno")),"rechaza montaje anidado con espacios")
Comprobar(Bool(Not MontajesSinCruce("12 1 0:1 / "+Hogar+" rw - tmpfs tmpfs rw"+#LF$,Hogar)),"rechaza montaje en la raiz")
Comprobar(Bool(Not MontajesSinCruce("truncado",Hogar)),"tabla truncada bloquea borrado")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
