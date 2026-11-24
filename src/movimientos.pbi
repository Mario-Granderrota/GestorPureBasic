Structure MovimientoPB
  Id.s
  Origen.s
  Destino.s
  Anterior.s
  Accion.s
EndStructure
Procedure RutaPublicacionValida(origen.s,destino.s)
  Protected padre.s=RTrim(GetPathPart(origen),"/")
  ProcedureReturn Bool(Dentro(origen,Almacen) And RTrim(GetPathPart(padre),"/")=Almacen And Left(GetFilePart(padre),9)=".trabajo-" And Canonica(padre)=padre And RTrim(GetPathPart(destino),"/")=Almacen+"/versiones" And Canonica(Almacen+"/versiones")=Almacen+"/versiones")
EndProcedure
; La ruta disponible debe concordar con el tipo de registro. No se autoriza
; una restauracion hacia carpetas internas del gestor ni a un ancestro de ellas.
Procedure RutaDisponibleValida(*dato.VersionPB,ruta.s)
  If Not Dentro(ruta,Hogar) Or Controles(ruta) Or ruta=Almacen Or ruta=Estado Or Dentro(Almacen,ruta) Or Dentro(Estado,ruta) Or Dentro(ruta,Estado)
    ProcedureReturn #False
  EndIf
  Select *dato\Tipo
    Case "gestionada"
      ProcedureReturn Bool(RTrim(GetPathPart(ruta),"/")=Almacen+"/versiones")
    Case "externa"
      ProcedureReturn Bool(ruta=*dato\Origen And Not Dentro(ruta,Almacen))
  EndSelect
  ProcedureReturn #False
EndProcedure
Procedure GuardarMovimiento(*movimiento.MovimientoPB)
  Protected json=CreateJSON(#PB_Any), bien
  If Not json : ProcedureReturn #False : EndIf
  InsertJSONStructure(JSONValue(json),*movimiento,MovimientoPB)
  bien=Guardar(Estado+"/movimiento.json",ComposeJSON(json,#PB_JSON_PrettyPrint)) : FreeJSON(json) : ProcedureReturn bien
EndProcedure
Procedure RecuperarMovimiento()
  Protected json, movimiento.MovimientoPB, dato.VersionPB, previo.VersionPB, retirada.s, padre.s
  If PersistenciaIncierta : ProcedureReturn Fallar("Persistencia incierta: reinicia antes de recuperar el movimiento.") : EndIf
  If FileSize(Estado+"/movimiento.json")=-1 : ProcedureReturn #True : EndIf
  If TipoArchivo(Estado+"/movimiento.json")<>32768 : ProcedureReturn Fallar("Diario de movimiento no válido.") : EndIf
  json=ParseJSON(#PB_Any,LeerTexto(Estado+"/movimiento.json"))
  If Not json : ProcedureReturn Fallar("Diario de movimiento ilegible.") : EndIf
  If Not CamposJSON(JSONValue(json),"Id|Origen|Destino|Anterior|Accion","","Id|Origen|Destino|Accion") : FreeJSON(json) : ProcedureReturn Fallar("Diario de movimiento no válido.") : EndIf
  ExtractJSONStructure(JSONValue(json),@movimiento,MovimientoPB) : FreeJSON(json)
  If Not IdValido(movimiento\Id) Or Not Dentro(movimiento\Origen,Hogar) Or Not Dentro(movimiento\Destino,Hogar) Or Enlace(movimiento\Origen) Or Enlace(movimiento\Destino)
    ProcedureReturn Fallar("Movimiento pendiente con rutas no válidas.")
  EndIf
  If movimiento\Accion="publicar"
    If Not RutaPublicacionValida(movimiento\Origen,movimiento\Destino) : ProcedureReturn Fallar("Rutas de publicación inesperadas.") : EndIf
  ElseIf movimiento\Accion="retirar" Or movimiento\Accion="restaurar"
    retirada=Almacen+"/retiradas/"+movimiento\Id
    json=ParseJSON(#PB_Any,movimiento\Anterior)
    If Not json : ProcedureReturn Fallar("El diario no contiene el registro previo.") : EndIf
    If Not DecodificarVersion(JSONValue(json),movimiento\Id,@previo) : FreeJSON(json) : ProcedureReturn Fallar("Registro previo no válido.") : EndIf
    FreeJSON(json)
    If previo\Id<>movimiento\Id Or previo\Ruta<>movimiento\Origen Or previo\Manifiesto<>Estado+"/versiones/"+movimiento\Id+".manifest"
      ProcedureReturn Fallar("El diario no corresponde al registro previo de la versión.")
    EndIf
    If movimiento\Accion="retirar"
      If movimiento\Destino<>retirada Or previo\Estado<>"disponible" Or Not RutaDisponibleValida(@previo,movimiento\Origen) : ProcedureReturn Fallar("Retirada pendiente con rutas incoherentes.") : EndIf
    Else
      If movimiento\Origen<>retirada Or previo\Estado<>"retirada" Or Not RutaDisponibleValida(@previo,movimiento\Destino) : ProcedureReturn Fallar("Restauración pendiente con rutas incoherentes.") : EndIf
      If previo\RutaRetirada<>""
        If movimiento\Destino<>previo\RutaRetirada : ProcedureReturn Fallar("La restauración no apunta a la ruta de retirada registrada.") : EndIf
      ElseIf previo\Tipo="externa"
        If movimiento\Destino<>previo\Origen : ProcedureReturn Fallar("La restauración no apunta a su origen.") : EndIf
      ElseIf previo\Tipo<>"gestionada" Or movimiento\Destino<>Almacen+"/versiones/"+movimiento\Id
        ProcedureReturn Fallar("Destino de restauración inesperado.")
      EndIf
    EndIf
    padre=RTrim(GetPathPart(movimiento\Origen),"/")
    If Canonica(padre)<>padre : ProcedureReturn Fallar("Ruta de recuperación no canónica.") : EndIf
    padre=RTrim(GetPathPart(movimiento\Destino),"/")
    If Canonica(padre)<>padre : ProcedureReturn Fallar("Ruta de recuperación no canónica.") : EndIf
  Else
    ProcedureReturn Fallar("Tipo de movimiento desconocido.")
  EndIf
  If FileSize(movimiento\Destino)=-2 And FileSize(movimiento\Origen)=-2 : ProcedureReturn Fallar("Ambas rutas existen; se conserva el diario para revisión.") : EndIf
  If LeerVersion(movimiento\Id,@dato) And dato\Ruta=movimiento\Destino
    If FileSize(movimiento\Destino)<>-2 Or Not VerificarContenido(@dato) Or Not BorrarPersistente(Estado+"/movimiento.json") : ProcedureReturn Fallar("No se pudo resolver el movimiento registrado.") : EndIf
    ProcedureReturn #True
  EndIf
  If FileSize(movimiento\Destino)=-2 And FileSize(movimiento\Origen)=-1
    If RenombrarSinReemplazo(-100,movimiento\Destino,-100,movimiento\Origen,1)<>0 : ProcedureReturn Fallar("No se puede recuperar la carpeta de la operación interrumpida.") : EndIf
    If Not SincronizarMovimiento(movimiento\Destino,movimiento\Origen) : ProcedureReturn #False : EndIf
  ElseIf FileSize(movimiento\Origen)<>-2
    ProcedureReturn Fallar("Revisa el movimiento pendiente; no se ha borrado ninguna carpeta automáticamente.")
  EndIf
  If movimiento\Accion="publicar"
    If TipoArchivo(Estado+"/versiones/"+movimiento\Id+".json")<>0 : ProcedureReturn Fallar("Registro de publicación inesperado; revisar manualmente.") : EndIf
    If TipoArchivo(Estado+"/versiones/"+movimiento\Id+".manifest")<>0 And Not DeleteFile(Estado+"/versiones/"+movimiento\Id+".manifest") : ProcedureReturn Fallar("No se pudo retirar el manifiesto pendiente.") : EndIf
    If Not BorrarPersistente(Estado+"/movimiento.json") : ProcedureReturn Fallar("No se pudo cerrar el diario pendiente.") : EndIf
    Registrar("Publicación interrumpida recuperada; contenido temporal conservado.") : ProcedureReturn #True
  EndIf
  If Not Guardar(Estado+"/versiones/"+movimiento\Id+".json",movimiento\Anterior) : ProcedureReturn Fallar("No se puede recuperar el registro anterior.") : EndIf
  If PersistenciaIncierta Or Not BorrarPersistente(Estado+"/movimiento.json") : ProcedureReturn Fallar("No se pudo confirmar la recuperación del movimiento.") : EndIf
  Registrar("Movimiento interrumpido recuperado.") : ProcedureReturn #True
EndProcedure
Procedure PublicarVersion(*dato.VersionPB,destino.s)
  Protected movimiento.MovimientoPB, origen.s=*dato\Ruta, huella.s
  If Cancelacion() Or Not IdValido(*dato\Id) Or Not RutaPublicacionValida(origen,destino) Or Canonica(origen)<>origen Or TipoArchivo(destino)<>0
    ProcedureReturn Fallar("No se cumplen las condiciones de publicación.")
  EndIf
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If Not SincronizarArbol(origen) Or Not SincronizarPadre(origen) Or Not SincronizarDirectorio(Almacen) : ProcedureReturn Fallar("No se pudo persistir el SDK antes de publicarlo.") : EndIf
  *dato\Manifiesto=Estado+"/versiones/"+*dato\Id+".manifest"
  If TipoArchivo(*dato\Manifiesto)<>0 Or TipoArchivo(Estado+"/versiones/"+*dato\Id+".json")<>0 : ProcedureReturn Fallar("El identificador ya existe.") : EndIf
  If Not CrearManifiesto(origen,*dato\Manifiesto) : ProcedureReturn #False : EndIf
  huella=FileFingerprint(*dato\Manifiesto,#PB_Cipher_SHA2,256)
  If Len(huella)<>64 Or Cancelacion() : DeleteFile(*dato\Manifiesto) : ProcedureReturn Fallar("Publicación cancelada o manifiesto ilegible.") : EndIf
  movimiento\Id=*dato\Id : movimiento\Origen=origen : movimiento\Destino=destino : movimiento\Accion="publicar"
  If Not GuardarMovimiento(@movimiento) : DeleteFile(*dato\Manifiesto) : ProcedureReturn Fallar("No se pudo guardar el diario de publicación.") : EndIf
  If PersistenciaIncierta : ProcedureReturn Fallar("Persistencia del diario no acreditada; se conserva la carpeta temporal.") : EndIf
  If RenombrarSinReemplazo(-100,origen,-100,destino,1)<>0
    DeleteFile(Estado+"/movimiento.json") : DeleteFile(*dato\Manifiesto) : ProcedureReturn Fallar("No se pudo publicar la carpeta.")
  EndIf
  If Not SincronizarMovimiento(origen,destino) : ProcedureReturn #False : EndIf
  *dato\Huella=huella : *dato\Ruta=destino
  If Not GuardarVersion(*dato)
    If RenombrarSinReemplazo(-100,destino,-100,origen,1)=0 And SincronizarMovimiento(destino,origen)
      *dato\Ruta=origen : DeleteFile(*dato\Manifiesto) : DeleteFile(Estado+"/movimiento.json")
    EndIf
    ProcedureReturn Fallar("No se pudo registrar la publicación. Se conserva el diario si el traslado no se pudo revertir.")
  EndIf
  If PersistenciaIncierta Or Not BorrarPersistente(Estado+"/movimiento.json") : Registrar("Publicación registrada; el diario se resolverá al iniciar.") : EndIf
  ProcedureReturn #True
EndProcedure
