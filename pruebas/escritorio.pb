XIncludeFile "../src/nucleo.pbi"
OpenConsole()
Global Correctas.i,Fallos.i
Procedure Comprobar(valor.i,texto.s)
  If valor : Correctas+1 : PrintN("OK "+texto) : Else : Fallos+1 : PrintN("FALLO "+texto+" | "+ErrorActual) : EndIf
EndProcedure
If Not Inicializar(ProgramParameter(0)) : End 2 : EndIf
If ProgramParameter(2)="recuperar"
  If Not RecuperarTransaccion() : End 1 : EndIf
  End 0
EndIf
Global fuente.s=ProgramParameter(1), raiz.s=Hogar+"/Apps/mi PureBasic antiguo", escritorio.s=Hogar+"/Zona de trabajo", viejo.s, texto.s, id.s, dato.VersionPB
Global menu.s=Datos+"/applications/purebasic-nativo-2.desktop", antiguoMenu.s=Datos+"/applications/PureBasic.desktop", acceso.s, otro.s, original.s, menuPrevio.s, listado, nombre.s, copia.s, encontrado.i, proceso, codigo
Global NewList rutas.s()
CrearCarpetas(Hogar+"/Escritorio") : CrearCarpetas(Hogar+"/.config") : CrearCarpetas(escritorio) : CrearCarpetas(Datos+"/applications")
Comprobar(Bool(EscritorioUsuario()=Hogar+"/Escritorio"),"encuentra Escritorio cuando no hay configuracion XDG")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+"$HOME/Zona de trabajo"+Chr(34)+#LF$)
Comprobar(Bool(EscritorioUsuario()=escritorio),"resuelve el escritorio XDG con HOME y espacios")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+"${HOME}/Zona de trabajo"+Chr(34)+#LF$)
Comprobar(Bool(EscritorioUsuario()=escritorio),"resuelve HOME con llaves sin interpretar shell")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+"$HOME"+Chr(34)+#LF$)
Comprobar(Bool(EscritorioUsuario()=""),"respeta el escritorio deshabilitado sin escribir en HOME")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+"/usr/bin"+Chr(34)+#LF$)
Comprobar(Bool(EscritorioUsuario()=""),"rechaza el escritorio fuera del perfil")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+"$(touch archivo-inyectado)"+Chr(34)+#LF$)
Comprobar(Bool(EscritorioUsuario()="" And FileSize(Hogar+"/archivo-inyectado")=-1),"no ejecuta sintaxis de shell de la configuracion")
Guardar(Hogar+"/.config/user-dirs.dirs","XDG_DESKTOP_DIR="+Chr(34)+escritorio+Chr(34)+#LF$)
CrearCarpetas(raiz+"/compilers") : CrearCarpetas(raiz+"/purelibraries") : CrearCarpetas(raiz+"/residents")
CopyFile(fuente+"/compilers/purebasic",raiz+"/compilers/purebasic") : SetFileAttributes(raiz+"/compilers/purebasic",493)
CopyFile(fuente+"/compilers/pbcompiler",raiz+"/compilers/pbcompiler") : SetFileAttributes(raiz+"/compilers/pbcompiler",493)
CopyFile(fuente+"/logo.png",raiz+"/logo.png")
viejo="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Name=PureBasic antiguo"+#LF$+"Exec="+CitarDesktop(raiz+"/compilers/purebasic")+#LF$+"Icon="+EscaparValor(raiz+"/logo.png")+#LF$
Comprobar(Bool(ComandoDesktop(viejo,escritorio)=raiz+"/compilers/purebasic"),"interpreta el ejecutable absoluto entre comillas y con espacios")
texto="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Exec=./purebasic %F"+#LF$+"Path="+EscaparValor(raiz+"/compilers")+#LF$
Comprobar(Bool(ComandoDesktop(texto,escritorio)=raiz+"/compilers/purebasic"),"resuelve un ejecutable relativo a Path")
Comprobar(Bool(ComandoDesktop(viejo+"Exec=/usr/bin/true"+#LF$,escritorio)=""),"rechaza claves Exec duplicadas")
texto="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Exec=/bin/sh -c "+CitarDesktop(raiz+"/compilers/purebasic")+#LF$
Comprobar(Bool(ComandoDesktop(texto,escritorio)=""),"no interpreta envoltorios de shell como accesos simples")
acceso=escritorio+"/PB con nombre propio.desktop" : Guardar(acceso,viejo,420)
Comprobar(DetectarExistentes(),"detecta la instalacion desde el comando del escritorio")
id=Activa()
Comprobar(Bool(LeerVersion(id,@dato) And dato\Ruta=raiz),"registra una carpeta de nombre arbitrario sin ejecutar su compilador")
otro=escritorio+"/PureBasic.desktop" : original="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Name=Otra aplicacion"+#LF$+"Exec=/usr/bin/true"+#LF$
Guardar(otro,original,420) : Guardar(antiguoMenu,viejo,420)
Comprobar(SincronizarAccesos(),"actualiza menu y escritorio de una instalacion existente sin compilar")
Comprobar(Bool(LeerTexto(otro)=original),"conserva un acceso ajeno aunque se llame PureBasic.desktop")
Comprobar(Bool(ValorDesktop(LeerTexto(antiguoMenu),"NoDisplay")="true" And FileSize(menu)>0),"mantiene un alias oculto para conservar asociaciones sin duplicar el menu")
Comprobar(Bool(ValorDesktop(LeerTexto(acceso),"X-GestorPureBasic-Acceso")="true"),"sustituye el acceso reconocido conservando su nombre de archivo")
Comprobar(Bool(DesescaparValor(ValorDesktop(LeerTexto(acceso),"Icon"))=raiz+"/logo.png"),"utiliza exactamente el logo oficial de la version seleccionada")
Comprobar(Bool(DesescaparValor(ValorDesktop(LeerTexto(menu),"Path"))=raiz+"/compilers"),"fija el directorio de trabajo de la instalacion")
Comprobar(Bool(FindString(LeerTexto(acceso),"--abrir-activa %F") And FindString(LeerTexto(acceso),CitarDesktop(EjecutableGestor))),"el acceso usa el lanzador estable y acepta archivos")
Comprobar(Bool((GetFileAttributes(acceso)&511)=493),"otorga permiso de ejecucion al acceso del escritorio")
listado=ExamineDirectory(#PB_Any,Estado+"/copias","*")
If listado
  While NextDirectoryEntry(listado)
    nombre=DirectoryEntryName(listado)
    If Left(nombre,8)<>"accesos-" : Continue : EndIf
    copia=Estado+"/copias/"+nombre
    If FindString(LeerTexto(copia+"/RUTAS.txt"),acceso)
      Define indice
      For indice=0 To 5
        If LeerTexto(copia+"/"+Str(indice)+".desktop")=viejo : encontrado=1 : EndIf
      Next
    EndIf
  Wend
  FinishDirectory(listado)
EndIf
Comprobar(encontrado,"la copia permanente conserva el contenido del acceso original")
Comprobar(SincronizarAccesos(),"repetir la sincronizacion actualiza el mismo acceso")
Comprobar(Bool(FileSize(escritorio+"/PureBasic-Gestor.desktop")=-1),"no crea un segundo acceso si ya reconoce uno")
menuPrevio=LeerTexto(menu) : texto=LeerTexto(acceso)
Guardar(acceso,viejo,420) : FalloEscritura=acceso
Comprobar(Bool(Not SincronizarAccesos()),"un fallo de escritura del escritorio nunca anuncia exito")
FalloEscritura=""
Comprobar(RecuperarTransaccion(),"recupera el diario del acceso al poder escribir otra vez")
Comprobar(Bool(LeerTexto(acceso)=viejo And LeerTexto(menu)=menuPrevio And (GetFileAttributes(acceso)&511)=420),"restaura contenido y permisos originales junto con el menu")
AddElement(rutas()) : rutas()=acceso : AddElement(rutas()) : rutas()=menu
Comprobar(IniciarTransaccion(rutas()),"incluye escritorio y menu en el mismo diario")
Guardar(acceso,"interrumpido",493) : Guardar(menu,"interrumpido",493)
proceso=RunProgram(ProgramFilename(),Citar(Hogar)+" "+Citar(fuente)+" recuperar","",#PB_Program_Open|#PB_Program_Wait)
If proceso : codigo=ProgramExitCode(proceso) : CloseProgram(proceso) : Else : codigo=-1 : EndIf
Comprobar(Bool(codigo=0 And LeerTexto(acceso)=viejo And LeerTexto(menu)=menuPrevio),"otra instancia recupera conjuntamente el escritorio y el menu")
Comprobar(SincronizarAccesos(),"restablece el acceso gestionado despues de la recuperacion")
Comprobar(Desactivar(),"desactiva los accesos gestionados de ambas ubicaciones")
Comprobar(Bool(FileSize(acceso)=-1 And FileSize(menu)=-1 And LeerTexto(otro)=original),"elimina solo sus accesos y conserva los ajenos")
Guardar(Estado+"/activa.txt",id)
Comprobar(SincronizarAccesos(),"crea un nuevo acceso si ya no existe ninguno reconocido")
Comprobar(Bool(FileSize(escritorio+"/PureBasic-Gestor.desktop")>0 And LeerTexto(otro)=original),"elige otro nombre sin pisar el archivo ajeno ocupado")
; Cambio de seleccion: las rutas se derivan del registro actual, nunca de Mario ni de v7.
Global segundaRaiz.s=Hogar+"/Apps/PureBasic nuevo", segundaId.s, primerMenu.s=LeerTexto(menu)
CrearCarpetas(segundaRaiz+"/compilers") : CrearCarpetas(segundaRaiz+"/purelibraries") : CrearCarpetas(segundaRaiz+"/residents")
CopyFile(raiz+"/compilers/purebasic",segundaRaiz+"/compilers/purebasic") : SetFileAttributes(segundaRaiz+"/compilers/purebasic",493)
CopyFile(raiz+"/compilers/pbcompiler",segundaRaiz+"/compilers/pbcompiler") : SetFileAttributes(segundaRaiz+"/compilers/pbcompiler",493)
CopyFile(raiz+"/logo.png",segundaRaiz+"/logo.png")
Comprobar(RegistrarExistente(segundaRaiz),"registra otra raiz para verificar rutas relativas a la seleccion")
CargarVersiones()
ForEach Versiones() : If Versiones()\Ruta=segundaRaiz : segundaId=Versiones()\Id : EndIf : Next
Guardar(Estado+"/activa.txt",segundaId)
Comprobar(SincronizarAccesos(),"sincroniza la segunda seleccion sin recompilar")
Comprobar(Bool(DesescaparValor(ValorDesktop(LeerTexto(menu),"Icon"))=segundaRaiz+"/logo.png" And DesescaparValor(ValorDesktop(LeerTexto(menu),"Path"))=segundaRaiz+"/compilers"),"icono y directorio siguen la version nueva")
Comprobar(Bool(ValorDesktop(LeerTexto(menu),"Exec")=ValorDesktop(primerMenu,"Exec")),"el comando estable no queda ligado a la carpeta antigua")
Guardar(Estado+"/activa.txt",id)
Comprobar(SincronizarAccesos(),"volver a otra seleccion actualiza de nuevo las rutas")
Comprobar(Bool(IconoOficial(raiz)=raiz+"/logo.png" And IconoOficial(Hogar)=""),"solo acepta un logo PNG local presente en la raiz")
; Un nombre con comillas requiere dos niveles de escape segun Desktop Entry.
CrearCarpetas(Hogar+"/ruta con "+Chr(34)+"comillas"+Chr(34))
CopyFile(raiz+"/compilers/purebasic",Hogar+"/ruta con "+Chr(34)+"comillas"+Chr(34)+"/purebasic")
texto="[Desktop Entry]"+#LF$+"Type=Application"+#LF$+"Exec="+CitarDesktop(Hogar+"/ruta con "+Chr(34)+"comillas"+Chr(34)+"/purebasic")+#LF$
Comprobar(Bool(ComandoDesktop(texto,escritorio)=Hogar+"/ruta con "+Chr(34)+"comillas"+Chr(34)+"/purebasic"),"conserva las comillas literales mediante el escape correcto")
Comprobar(Bool(Not RutaIntegracionValida(Hogar+"/archivo.txt") And Not RutaIntegracionValida(Hogar+"/Escritorio/no-usado.desktop")),"el diario solo admite las ubicaciones de integracion actuales")
PrintN("RESULTADO: "+Str(Correctas)+" correctas, "+Str(Fallos)+" fallidas")
End Bool(Fallos>0)
