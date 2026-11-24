Structure CambioPB
  Ruta.s
  Copia.s
  Huella.s
  Existia.i
  Permisos.i
EndStructure
Global NewList Cambios.CambioPB()
Procedure RutaIntegracionValida(ruta.s)
  Protected carpeta.s=RTrim(GetPathPart(ruta),"/"), escritorio.s=EscritorioUsuario(), nombre.s=GetFilePart(ruta), extension.s=LCase(GetExtensionPart(ruta))
  If Controles(ruta) Or carpeta="" Or Canonica(carpeta)<>carpeta Or ruta<>carpeta+"/"+nombre Or (TipoArchivo(ruta)<>0 And TipoArchivo(ruta)<>32768) : ProcedureReturn #False : EndIf
  If ruta=Estado+"/activa.txt" Or ruta=Estado+"/anterior.txt" : ProcedureReturn #True : EndIf
  If carpeta=Estado+"/versiones"
    ProcedureReturn Bool((extension="json" Or extension="manifest") And IdValido(GetFilePart(nombre,#PB_FileSystem_NoExtension)))
  EndIf
  If extension<>"desktop" : ProcedureReturn #False : EndIf
  ProcedureReturn Bool(carpeta=Datos+"/applications" Or (escritorio<>"" And carpeta=escritorio))
EndProcedure
Procedure RecuperarTransaccion()
  Protected json, bien=#True, indice, copiaEsperada.s, contenido.String
  If PersistenciaIncierta : ProcedureReturn Fallar("Persistencia incierta: reinicia el gestor antes de recuperar el diario.") : EndIf
  Protected NewMap revisadas.i()
  If FileSize(Estado+"/transaccion/diario.json")=-1
    If FileSize(Estado+"/transaccion")=-2 And Not Enlace(Estado+"/transaccion") : DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive) : EndIf
    ProcedureReturn #True
  EndIf
  json=ParseJSON(#PB_Any,LeerTexto(Estado+"/transaccion/diario.json"))
  If Not json : ProcedureReturn Fallar("El diario de recuperación no puede leerse. Conserva la carpeta de estado.") : EndIf
  If JSONType(JSONValue(json))<>#PB_JSON_Array Or JSONArraySize(JSONValue(json))>10000 : FreeJSON(json) : ProcedureReturn Fallar("Diario de integración no válido.") : EndIf
  For indice=0 To JSONArraySize(JSONValue(json))-1
    If Not CamposJSON(GetJSONElement(JSONValue(json),indice),"Ruta|Copia|Huella","Existia|Permisos","Ruta|Existia|Permisos")
      FreeJSON(json) : ProcedureReturn Fallar("Campos del diario de integración no válidos.")
    EndIf
  Next
  indice=0 : ClearList(Cambios()) : ExtractJSONList(JSONValue(json),Cambios()) : FreeJSON(json)
  ; Validar el diario completo antes de restaurar o borrar el primer archivo.
  ForEach Cambios()
    copiaEsperada=Estado+"/transaccion/"+Str(indice)+".copia"
    If Not RutaIntegracionValida(Cambios()\Ruta) Or FindMapElement(revisadas(),Cambios()\Ruta) Or (Cambios()\Existia<>0 And Cambios()\Existia<>1) Or Cambios()\Permisos<0 Or Cambios()\Permisos>511
      ProcedureReturn Fallar("Diario de integración incoherente. No se ha aplicado ningún cambio.")
    EndIf
    revisadas(Cambios()\Ruta)=1
    If Cambios()\Existia
      If Cambios()\Copia<>copiaEsperada Or TipoArchivo(copiaEsperada)<>32768 Or Canonica(copiaEsperada)<>copiaEsperada Or Len(Cambios()\Huella)<>64 Or FileSize(copiaEsperada)>8388608 Or FileFingerprint(copiaEsperada,#PB_Cipher_SHA2,256)<>Cambios()\Huella Or Not LeerTextoSeguro(copiaEsperada,@contenido)
        ProcedureReturn Fallar("Copia de recuperación ausente o alterada. No se ha aplicado ningún cambio.")
      EndIf
    EndIf
    indice+1
  Next
  ForEach Cambios()
    If Not RutaIntegracionValida(Cambios()\Ruta) Or Enlace(Cambios()\Ruta) : bien=#False : Continue : EndIf
    If Cambios()\Existia
      If Not Dentro(Cambios()\Copia,Estado+"/transaccion") Or FileFingerprint(Cambios()\Copia,#PB_Cipher_SHA2,256)<>Cambios()\Huella
        bien=#False : Continue
      EndIf
      If Not LeerTextoSeguro(Cambios()\Copia,@contenido) Or Not Guardar(Cambios()\Ruta,contenido\s,Cambios()\Permisos) : bien=#False : EndIf
    ElseIf FileSize(Cambios()\Ruta)>=0
      If Not BorrarPersistente(Cambios()\Ruta) : bien=#False : EndIf
    EndIf
  Next
  If bien And Not PersistenciaIncierta And BorrarPersistente(Estado+"/transaccion/diario.json")
    DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive)
    Registrar("Se ha recuperado el estado anterior a una operación interrumpida.")
  Else
    bien=#False
    Fallar("No se ha podido completar la recuperación. Se conserva el diario; revisa permisos y espacio libre.")
  EndIf
  ProcedureReturn bien
EndProcedure
Procedure IniciarTransaccion(List rutas.s())
  Protected json, texto.s, indice, contenido.String
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  Protected NewMap revisadas.i()
  If FileSize(Estado+"/transaccion")<>-1
    If Not RecuperarTransaccion() : ProcedureReturn #False : EndIf
  EndIf
  If Not CreateDirectory(Estado+"/transaccion") : ProcedureReturn Fallar("No se puede crear el diario de la operación.") : EndIf
  SetFileAttributes(Estado+"/transaccion",448) : ClearList(Cambios())
  ForEach rutas()
    If Not RutaIntegracionValida(rutas()) Or FindMapElement(revisadas(),rutas()) Or FileSize(rutas())>8388608
      DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive) : ProcedureReturn Fallar("Destino de integración no seguro: "+rutas())
    EndIf
    revisadas(rutas())=1
    AddElement(Cambios()) : Cambios()\Ruta=rutas() : Cambios()\Existia=Bool(FileSize(rutas())>=0)
    If Cambios()\Existia
      Cambios()\Copia=Estado+"/transaccion/"+Str(indice)+".copia" : Cambios()\Permisos=GetFileAttributes(rutas())&511
      If Not CopyFile(rutas(),Cambios()\Copia) Or Not LeerTextoSeguro(Cambios()\Copia,@contenido) Or Not SincronizarArchivo(Cambios()\Copia)
        DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive) : ProcedureReturn Fallar("No se pudo guardar la integración anterior.")
      EndIf
      Cambios()\Huella=FileFingerprint(Cambios()\Copia,#PB_Cipher_SHA2,256)
    EndIf
    indice+1
  Next
  json=CreateJSON(#PB_Any) : If Not json : ProcedureReturn #False : EndIf
  InsertJSONList(JSONValue(json),Cambios()) : texto=ComposeJSON(json,#PB_JSON_PrettyPrint) : FreeJSON(json)
  If Not SincronizarDirectorio(Estado) : ProcedureReturn Fallar("No se pudo sincronizar la carpeta del diario.") : EndIf
  If Not Guardar(Estado+"/transaccion/diario.json",texto) : DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive) : ProcedureReturn Fallar("No se pudo guardar el diario.") : EndIf
  If PersistenciaIncierta : ProcedureReturn Fallar("Persistencia del diario no acreditada.") : EndIf
  ProcedureReturn #True
EndProcedure
Procedure ConfirmarTransaccion()
  ; El diario se retira primero: su ausencia marca el commit completo.
  If PersistenciaIncierta Or Not BorrarPersistente(Estado+"/transaccion/diario.json") : ProcedureReturn Fallar("No se pudo confirmar la transacción.") : EndIf
  DeleteDirectory(Estado+"/transaccion","",#PB_FileSystem_Recursive) : ProcedureReturn #True
EndProcedure
