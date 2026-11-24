; Integracion de accesos. No ejecuta ni interpreta comandos de archivos .desktop.
Structure AccesoPB
  Ruta.s
  Texto.s
  Permisos.i
EndStructure

Procedure.s ValorDesktop(texto.s, clave.s)
  Protected indice, linea.s, grupo.i, encontrada.i, valor.s
  For indice=1 To CountString(texto,#LF$)+1
    linea=Trim(RemoveString(StringField(texto,indice,#LF$),#CR$))
    If Left(linea,1)="[" : grupo=Bool(linea="[Desktop Entry]") : Continue : EndIf
    If grupo And Left(linea,Len(clave)+1)=clave+"="
      If encontrada : ProcedureReturn "" : EndIf
      encontrada=1 : valor=Mid(linea,Len(clave)+2)
    EndIf
  Next
  ProcedureReturn valor
EndProcedure

Procedure.s DesescaparValor(texto.s)
  Protected indice, caracter.s, salida.s
  indice=1
  While indice<=Len(texto)
    caracter=Mid(texto,indice,1)
    If caracter=Chr(92)
      indice+1 : caracter=Mid(texto,indice,1)
      Select caracter
        Case "s" : caracter=" "
        Case Chr(92)
        Default : ProcedureReturn ""
      EndSelect
    EndIf
    salida+caracter : indice+1
  Wend
  If Controles(salida) : ProcedureReturn "" : EndIf
  ProcedureReturn salida
EndProcedure

Procedure.s EscaparValor(texto.s)
  texto=ReplaceString(texto,Chr(92),Chr(92)+Chr(92))
  ProcedureReturn ReplaceString(texto," ",Chr(92)+"s")
EndProcedure

Procedure.s EscritorioUsuario()
  Protected configuracion.s=Hogar+"/.config/user-dirs.dirs", texto.s, linea.s, valor.s, indice, configurada.i
  If FileSize(configuracion)>=0 And FileSize(configuracion)<65536 And Not Enlace(configuracion)
    texto=LeerTexto(configuracion)
    For indice=1 To CountString(texto,#LF$)+1
      linea=Trim(RemoveString(StringField(texto,indice,#LF$),#CR$))
      If Left(linea,16)="XDG_DESKTOP_DIR=" : Break : EndIf
    Next
    ; Solo se admite la asignacion declarativa de XDG, nunca sintaxis de shell.
    If Left(linea,16)="XDG_DESKTOP_DIR="
      valor=Trim(Mid(linea,FindString(linea,"=")+1)) : configurada=1
      If Left(valor,1)<>Chr(34) Or Right(valor,1)<>Chr(34) : ProcedureReturn "" : EndIf
      valor=Mid(valor,2,Len(valor)-2)
      If Left(valor,6)="$HOME/" : valor=Hogar+Mid(valor,6)
      ElseIf Left(valor,8)="${HOME}/" : valor=Hogar+Mid(valor,8)
      ElseIf valor="$HOME" Or valor="${HOME}" : ProcedureReturn ""
      EndIf
      If FindString(valor,"$") Or FindString(valor,"`") Or FindString(valor,Chr(34)) Or Controles(valor) : ProcedureReturn "" : EndIf
      valor=Canonica(valor)
      If valor<>"" And Dentro(valor,Hogar) And FileSize(valor)=-2 : ProcedureReturn valor : EndIf
      ProcedureReturn ""
    EndIf
  EndIf
  If Not configurada
    If FileSize(Hogar+"/Escritorio")=-2 And Canonica(Hogar+"/Escritorio")=Hogar+"/Escritorio" : ProcedureReturn Hogar+"/Escritorio" : EndIf
    If FileSize(Hogar+"/Desktop")=-2 And Canonica(Hogar+"/Desktop")=Hogar+"/Desktop" : ProcedureReturn Hogar+"/Desktop" : EndIf
  EndIf
EndProcedure

Procedure.s ComandoDesktop(texto.s, carpeta.s, literal.i=0)
  Protected comando.s=DesescaparValor(ValorDesktop(texto,"Exec")), ruta.s, indice=1, caracter.s, comillas.i, cerrado.i, resto.s, base.s
  If ValorDesktop(texto,"Type")<>"Application" Or comando="" : ProcedureReturn "" : EndIf
  If Left(comando,1)=Chr(34) : comillas=1 : indice=2 : EndIf
  While indice<=Len(comando)
    caracter=Mid(comando,indice,1)
    If comillas And caracter=Chr(34) : cerrado=1 : indice+1 : Break : EndIf
    If Not comillas And caracter=" " : Break : EndIf
    If caracter=Chr(92)
      indice+1 : caracter=Mid(comando,indice,1)
      If caracter<>Chr(34) And caracter<>Chr(92) And caracter<>"$" And caracter<>"`" : ProcedureReturn "" : EndIf
    ElseIf caracter=Chr(34) Or caracter="`" Or caracter="$"
      ProcedureReturn ""
    EndIf
    ruta+caracter : indice+1
  Wend
  If comillas And Not cerrado : ProcedureReturn "" : EndIf
  resto=Trim(Mid(comando,indice))
  If resto<>"" And resto<>"%F" And resto<>"%f" And resto<>"%U" And resto<>"%u" : ProcedureReturn "" : EndIf
  ruta=ReplaceString(ruta,"%%","%")
  If ruta="" Or Controles(ruta) : ProcedureReturn "" : EndIf
  If Left(ruta,1)<>"/"
    base=DesescaparValor(ValorDesktop(texto,"Path"))
    If Left(base,1)<>"/" : ProcedureReturn "" : EndIf
    ruta=base+"/"+ruta
  EndIf
  If literal : ProcedureReturn ReplaceString(ruta,"/./","/") : EndIf
  ProcedureReturn Canonica(ruta)
EndProcedure

Procedure AccesoReconocido(ruta.s)
  Protected texto.s, comando.s
  If Enlace(ruta) Or TipoArchivo(ruta)<>32768 Or FileSize(ruta)>65536 : ProcedureReturn #False : EndIf
  texto=LeerTexto(ruta)
  If FindString(texto,"# "+#MARCA_GESTOR+#LF$) And ValorDesktop(texto,"X-GestorPureBasic-Acceso")="true" : ProcedureReturn #True : EndIf
  comando=ComandoDesktop(texto,GetPathPart(ruta))
  If comando="" : ProcedureReturn #False : EndIf
  ForEach Versiones()
    If comando=Canonica(Versiones()\Ruta+"/compilers/purebasic") And comando<>"" : ProcedureReturn #True : EndIf
  Next
EndProcedure

Procedure.s IconoOficial(raiz.s)
  Protected ruta.s=raiz+"/logo.png", archivo, Dim firma.a(7)
  If Enlace(ruta) Or TipoArchivo(ruta)<>32768 Or FileSize(ruta)<24 Or FileSize(ruta)>4194304 : ProcedureReturn "" : EndIf
  archivo=ReadFile(#PB_Any,ruta) : If Not archivo : ProcedureReturn "" : EndIf
  ReadData(archivo,@firma(),8) : CloseFile(archivo)
  If firma(0)=137 And firma(1)=80 And firma(2)=78 And firma(3)=71 And firma(4)=13 And firma(5)=10 And firma(6)=26 And firma(7)=10 : ProcedureReturn ruta : EndIf
EndProcedure

Procedure.s TextoAcceso(*dato.VersionPB)
  Protected icono.s=IconoOficial(*dato\Ruta)
  If icono="" : icono="applications-development" : Registrar("No se encuentra logo.png oficial legible; se utiliza el icono de desarrollo del sistema.") : EndIf
  ProcedureReturn "[Desktop Entry]"+#LF$+"# "+#MARCA_GESTOR+#LF$+"Type=Application"+#LF$+"Name=PureBasic (gestor)"+#LF$+"Comment=PureBasic "+*dato\Numero+" · versión activa del gestor"+#LF$+"Exec="+CitarDesktop(EjecutableGestor)+" --perfil "+CitarDesktop(Hogar)+" --abrir-activa %F"+#LF$+"Icon="+EscaparValor(icono)+#LF$+"Path="+EscaparValor(*dato\Ruta+"/compilers")+#LF$+"Terminal=false"+#LF$+"StartupNotify=false"+#LF$+"Categories=Development;IDE;"+#LF$+"MimeType=text/purebasic;"+#LF$+"X-GestorPureBasic-Acceso=true"+#LF$
EndProcedure

Procedure AgregarAcceso(List accesos.AccesoPB(), ruta.s, texto.s, permisos.i)
  ForEach accesos() : If accesos()\Ruta=ruta : ProcedureReturn : EndIf : Next
  AddElement(accesos()) : accesos()\Ruta=ruta : accesos()\Texto=texto : accesos()\Permisos=permisos
EndProcedure

Procedure BuscarAccesos(List accesos.AccesoPB(), carpeta.s, texto.s, soloPropios.i=0)
  Protected listado, nombre.s, ruta.s, contenido.s
  If carpeta="" Or Enlace(carpeta) : ProcedureReturn : EndIf
  listado=ExamineDirectory(#PB_Any,carpeta,"*")
  If listado
    While NextDirectoryEntry(listado)
      nombre=DirectoryEntryName(listado) : ruta=carpeta+"/"+nombre
      If LCase(GetExtensionPart(nombre))<>"desktop" Or ruta=Datos+"/applications/gestor-purebasic-2.desktop" : Continue : EndIf
      If AccesoReconocido(ruta)
        contenido=LeerTexto(ruta)
        If Not soloPropios Or (FindString(contenido,"# "+#MARCA_GESTOR+#LF$) And ValorDesktop(contenido,"X-GestorPureBasic-Acceso")="true" And ValorDesktop(contenido,"Exec")=CitarDesktop(EjecutableGestor)+" --perfil "+CitarDesktop(Hogar)+" --abrir-activa %F")
          AgregarAcceso(accesos(),ruta,texto,493)
        EndIf
      EndIf
    Wend
    FinishDirectory(listado)
  EndIf
EndProcedure

Procedure PlanificarAccesos(*dato.VersionPB, List accesos.AccesoPB(), soloPropios.i=0)
  Protected menu.s=Datos+"/applications/purebasic-nativo-2.desktop", escritorio.s=EscritorioUsuario(), texto.s=TextoAcceso(*dato), cantidad, destino.s
  ClearList(accesos()) : CargarVersiones()
  If FileSize(menu)<>-1 And (Enlace(menu) Or Not FindString(LeerTexto(menu),#MARCA_GESTOR)) : ProcedureReturn Fallar("Se conserva un acceso ajeno en la ubicación del gestor.") : EndIf
  AgregarAcceso(accesos(),menu,texto,420)
  BuscarAccesos(accesos(),Datos+"/applications",texto+"NoDisplay=true"+#LF$,soloPropios)
  cantidad=ListSize(accesos())
  BuscarAccesos(accesos(),escritorio,texto,soloPropios)
  If escritorio<>"" And cantidad=ListSize(accesos())
    destino=escritorio+"/PureBasic.desktop"
    If TipoArchivo(destino)<>0 : destino=escritorio+"/PureBasic-Gestor.desktop" : EndIf
    If TipoArchivo(destino)<>0 : ProcedureReturn Fallar("Se conservan los dos nombres de acceso ocupados en el escritorio; revisa PureBasic.desktop y PureBasic-Gestor.desktop.") : EndIf
    AgregarAcceso(accesos(),destino,texto,493)
  ElseIf escritorio=""
    Registrar("No se ha encontrado un escritorio habilitado dentro de la carpeta personal. Se actualiza el menú.")
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure RespaldarAccesos(List accesos.AccesoPB())
  Protected carpeta.s=Estado+"/copias/accesos-"+IdNuevo(), indice, registro.s, origen.s
  If Not CrearCarpetas(carpeta) : ProcedureReturn Fallar("No se puede respaldar la integración anterior.") : EndIf
  ForEach accesos()
    origen=accesos()\Ruta
    If TipoArchivo(origen)=32768 And Not Enlace(origen)
      If Not CopyFile(origen,carpeta+"/"+Str(indice)+".desktop") Or FileFingerprint(origen,#PB_Cipher_SHA2,256)<>FileFingerprint(carpeta+"/"+Str(indice)+".desktop",#PB_Cipher_SHA2,256) : ProcedureReturn Fallar("No se pudo conservar el acceso anterior: "+origen) : EndIf
      registro+Str(indice)+".desktop -> "+origen+" | permisos="+Str(GetFileAttributes(origen)&511)+#LF$
      indice+1
    EndIf
  Next
  If Not Guardar(carpeta+"/RUTAS.txt",registro) : ProcedureReturn Fallar("No se pudo registrar la copia de los accesos.") : EndIf
  Registrar("Copia de accesos anteriores: "+carpeta) : ProcedureReturn #True
EndProcedure

Procedure MarcarAccesos(List accesos.AccesoPB())
  Protected escritorio.s=EscritorioUsuario(), proceso
  ForEach accesos()
    If accesos()\Texto<>"" And escritorio<>"" And GetPathPart(accesos()\Ruta)=escritorio+"/"
      Registrar("Acceso del escritorio actualizado: "+accesos()\Ruta)
      If Not #MODO_PRUEBAS And TipoArchivo("/usr/bin/gio")=32768
        proceso=RunProgram("/usr/bin/gio","set "+Citar(accesos()\Ruta)+" metadata::trusted true",Hogar,#PB_Program_Open|#PB_Program_Hide)
        If proceso
          WaitProgram(proceso,5000)
          If ProgramRunning(proceso) : KillProgram(proceso) : EndIf
          CloseProgram(proceso)
        EndIf
      EndIf
    EndIf
  Next
  Registrar("Si Cinnamon muestra el acceso como texto, pulsa su botón derecho y permite su ejecución.")
EndProcedure

Procedure BuscarRaicesAccesos(List raices.s(), carpeta.s)
  Protected listado, ruta.s, comando.s, raiz.s, existente.i
  If carpeta="" Or Enlace(carpeta) : ProcedureReturn : EndIf
  listado=ExamineDirectory(#PB_Any,carpeta,"*")
  If listado
    While NextDirectoryEntry(listado)
      ruta=carpeta+"/"+DirectoryEntryName(listado)
      If LCase(GetExtensionPart(ruta))<>"desktop" Or Enlace(ruta) Or TipoArchivo(ruta)<>32768 Or FileSize(ruta)>65536 : Continue : EndIf
      comando=ComandoDesktop(LeerTexto(ruta),carpeta)
      If Right(comando,Len("/compilers/purebasic"))<>"/compilers/purebasic" : Continue : EndIf
      raiz=Left(comando,Len(comando)-Len("/compilers/purebasic"))
      If Not Dentro(raiz,Hogar) : Continue : EndIf
      existente=0
      ForEach raices() : If raices()=raiz : existente=1 : Break : EndIf : Next
      If Not existente : AddElement(raices()) : raices()=raiz : EndIf
    Wend
    FinishDirectory(listado)
  EndIf
EndProcedure
