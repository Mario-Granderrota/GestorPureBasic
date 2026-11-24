; Diario mínimo de actualización del gestor: se confirma la huella solo
; después del traslado duradero. Una interrupción acepta únicamente la
; huella anterior o la nueva registradas antes de publicar.
Procedure HuellaEjecutableValida(huella.s)
  Protected indice
  If Len(huella)<>64 : ProcedureReturn #False : EndIf
  For indice=1 To 64
    If Not FindString("0123456789abcdef",LCase(Mid(huella,indice,1))) : ProcedureReturn #False : EndIf
  Next
  ProcedureReturn #True
EndProcedure
Procedure RecuperarEjecutable(destino.s)
  Protected diario.s=Estado+"/ejecutable.pendiente", contenido.String, anterior.s,nueva.s,actual.s
  If TipoArchivo(diario)=0 : ProcedureReturn #True : EndIf
  If PersistenciaIncierta Or Not LeerTextoSeguro(diario,@contenido) Or CountString(contenido\s,#LF$)<>1 : ProcedureReturn Fallar("Diario de actualización del gestor ilegible. No se modificará el ejecutable.") : EndIf
  anterior=StringField(contenido\s,1,#LF$) : nueva=StringField(contenido\s,2,#LF$)
  If (anterior<>"-" And Not HuellaEjecutableValida(anterior)) Or Not HuellaEjecutableValida(nueva) : ProcedureReturn Fallar("Huellas del diario del gestor no válidas.") : EndIf
  If TipoArchivo(destino)=32768 And Canonica(destino)=destino
    actual=FileFingerprint(destino,#PB_Cipher_SHA2,256)
    If Not HuellaEjecutableValida(actual) Or Not SincronizarArchivo(destino) : ProcedureReturn Fallar("No se puede acreditar el ejecutable instalado.") : EndIf
  ElseIf TipoArchivo(destino)=0
    actual="-"
  Else
    ProcedureReturn Fallar("Destino de actualización del gestor no válido.")
  EndIf
  If actual<>anterior And actual<>nueva : ProcedureReturn Fallar("El ejecutable no coincide con ninguna huella del diario; se conserva para revisión.") : EndIf
  If Not SincronizarPadre(destino) : ProcedureReturn Fallar("No se puede acreditar la persistencia del ejecutable.") : EndIf
  If actual="-" : actual="" : EndIf
  If Not Guardar(Estado+"/ejecutable.sha256",actual) Or PersistenciaIncierta : ProcedureReturn Fallar("No se pudo confirmar la huella del ejecutable. Se conserva el diario.") : EndIf
  If Not BorrarPersistente(diario) : ProcedureReturn Fallar("No se pudo cerrar el diario del ejecutable.") : EndIf
  Registrar("Actualización del ejecutable del gestor recuperada o confirmada.")
  ProcedureReturn #True
EndProcedure
Procedure PrepararEjecutable()
  Protected origen.s=Canonica(ProgramFilename()), temporal.s, huella.s, destino.s=EjecutableGestor, menu.s, texto.s, huellaDestino.s, anterior.s, traslado
  If Not CrearCarpetas(RTrim(GetPathPart(destino),"/")) Or Not CrearCarpetas(Datos+"/applications") : ProcedureReturn Fallar("No se puede preparar el acceso del gestor.") : EndIf
  If (TipoArchivo(destino)<>0 And TipoArchivo(destino)<>32768) Or Enlace(Datos+"/applications/gestor-purebasic-2.desktop") : ProcedureReturn Fallar("Los accesos del gestor no pueden ser enlaces ni destinos ajenos.") : EndIf
  If Not RecuperarEjecutable(destino) : ProcedureReturn #False : EndIf
  huella=FileFingerprint(origen,#PB_Cipher_SHA2,256)
  If Len(huella)<>64 : ProcedureReturn Fallar("No se pudo verificar la identidad del gestor.") : EndIf
  If origen<>destino
    If FileSize(destino)>=0
      huellaDestino=FileFingerprint(destino,#PB_Cipher_SHA2,256)
      If huellaDestino<>LeerTexto(Estado+"/ejecutable.sha256") And huellaDestino<>huella
        ProcedureReturn Fallar("Se conserva un ejecutable ajeno en la ubicación del gestor.")
      EndIf
    EndIf
    If huellaDestino<>huella Or (GetFileAttributes(destino)&511)<>493
      temporal=destino+".nuevo-"+IdNuevo()
      If Not CopyFile(origen,temporal) Or FileFingerprint(temporal,#PB_Cipher_SHA2,256)<>huella Or Not SetFileAttributes(temporal,493) Or Not SincronizarArchivo(temporal)
        DeleteFile(temporal) : ProcedureReturn Fallar("No se pudo instalar el ejecutable del gestor.")
      EndIf
      anterior=huellaDestino : If anterior="" : anterior="-" : EndIf
      If Not Guardar(Estado+"/ejecutable.pendiente",anterior+#LF$+huella)
        DeleteFile(temporal) : ProcedureReturn Fallar("No se pudo preparar el diario de actualización del gestor.")
      EndIf
      If PersistenciaIncierta : ProcedureReturn Fallar("Diario de actualización no persistido; se conserva el ejecutable anterior.") : EndIf
      If anterior="-"
        traslado=RenombrarSinReemplazo(-100,temporal,-100,destino,1)
      ElseIf TipoArchivo(destino)=32768 And FileFingerprint(destino,#PB_Cipher_SHA2,256)=anterior
        traslado=RenombrarNativo(temporal,destino)
      Else
        traslado=-1
      EndIf
      If traslado<>0 : DeleteFile(temporal) : ProcedureReturn Fallar("No se pudo publicar el ejecutable del gestor; se conserva el diario.") : EndIf
      If Not SincronizarMovimiento(temporal,destino) Or Not RecuperarEjecutable(destino) : ProcedureReturn #False : EndIf
    EndIf
  EndIf
  If LeerTexto(Estado+"/ejecutable.sha256")<>huella And Not Guardar(Estado+"/ejecutable.sha256",huella) : ProcedureReturn Fallar("No se pudo registrar la identidad del gestor.") : EndIf
  menu=Datos+"/applications/gestor-purebasic-2.desktop"
  If FileSize(menu)>=0 And Not FindString(LeerTexto(menu),#MARCA_GESTOR) : ProcedureReturn Fallar("Se conserva un menú ajeno.") : EndIf
  texto="[Desktop Entry]"+#LF$+"# "+#MARCA_GESTOR+#LF$+"Type=Application"+#LF$+"Name=Gestor PureBasic"+#LF$+"Comment=Instalar, actualizar y gestionar PureBasic"+#LF$+"Exec="+CitarDesktop(destino)+" --perfil "+CitarDesktop(Hogar)+#LF$+"Icon=applications-development"+#LF$+"Terminal=false"+#LF$+"Categories=Development;"+#LF$
  If (LeerTexto(menu)<>texto Or (GetFileAttributes(menu)&511)<>420) And Not Guardar(menu,texto,420) : ProcedureReturn Fallar("No se pudo crear el menú del gestor.") : EndIf
  ProcedureReturn #True
EndProcedure
