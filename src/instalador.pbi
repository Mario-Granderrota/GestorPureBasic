; Flujo simplificado. Previsualizacion estatica, comprobacion y publicacion.
Structure PaquetePB
  Temporal.s
  Dato.VersionPB
EndStructure

Procedure LimpiarPaquete(*paquete.PaquetePB)
  Protected perfil.s
  If Not PersistenciaIncierta And TipoArchivo(Estado+"/movimiento.json")=0 And IdValido(*paquete\Dato\Id) And TipoArchivo(Estado+"/versiones/"+*paquete\Dato\Id+".json")=0
    perfil=Estado+"/perfiles/"+*paquete\Dato\Id
    If Canonica(perfil)=perfil And FileSize(perfil)=-2 And SinMontajes(perfil) : DeleteDirectory(perfil,"",#PB_FileSystem_Recursive) : EndIf
  EndIf
  If Not PersistenciaIncierta And TipoArchivo(Estado+"/movimiento.json")=0 And RTrim(GetPathPart(*paquete\Temporal),"/")=Almacen And Left(GetFilePart(*paquete\Temporal),9)=".trabajo-" And Canonica(*paquete\Temporal)=*paquete\Temporal And SinMontajes(*paquete\Temporal)
    If FileSize(*paquete\Temporal)=-2 : DeleteDirectory(*paquete\Temporal,"",#PB_FileSystem_Recursive) : EndIf
  EndIf
  ClearStructure(*paquete,PaquetePB)
EndProcedure

Procedure PrepararPaquete(origen.s,*paquete.PaquetePB)
  Protected carpeta.s,bien
  ErrorActual="" : If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  LimpiarPaquete(*paquete) : origen=Canonica(origen)
  If origen="" Or (TipoArchivo(origen)<>32768 And TipoArchivo(origen)<>16384) : ProcedureReturn Fallar("Selecciona un paquete o una carpeta legible.") : EndIf
  *paquete\Temporal=Almacen+"/.trabajo-"+IdNuevo()
  If Not CreateDirectory(*paquete\Temporal) : ClearStructure(*paquete,PaquetePB) : ProcedureReturn Fallar("No se puede preparar la carpeta temporal.") : EndIf
  SetFileAttributes(*paquete\Temporal,448)
  carpeta=PrepararContenido(origen,*paquete\Temporal) : bien=Bool(carpeta<>"")
  If bien And Not Cancelacion()
    *paquete\Dato\Id=IdNuevo() : *paquete\Dato\Ruta=carpeta : *paquete\Dato\Estado="disponible" : *paquete\Dato\Tipo="gestionada" : *paquete\Dato\Motor="AUTO" : *paquete\Dato\Perfil="separado" : *paquete\Dato\Origen=origen
    *paquete\Dato\Fecha=FormatDate("%yyyy-%mm-%dd %hh:%ii",Date())
    If EstructuraValida(carpeta) And PonerIdentidad(@*paquete\Dato,IdentidadEstatica(carpeta))
      ProcedureReturn #True
    EndIf
    Fallar("No se pudo reconocer una versión válida de PureBasic Linux x64.")
  EndIf
  LimpiarPaquete(*paquete)
  If ErrorActual="" : Fallar("Análisis cancelado o paquete no válido.") : EndIf
  ProcedureReturn #False
EndProcedure

Procedure.s NombreCarpeta(*dato.VersionPB)
  Protected nombre.s="PureBasic-"+ReplaceString(Etiqueta(*dato)," ","-")+"-"+*dato\Edicion, base.s, indice=1
  If Not IdValido(nombre) : nombre="PureBasic-"+*dato\Id : EndIf
  base=Almacen+"/versiones/"+nombre : nombre=base
  While TipoArchivo(nombre)<>0
    indice+1 : nombre=base+"-"+Str(indice)
  Wend
  ProcedureReturn nombre
EndProcedure

; Resultado explicito de Politica: completa, limitada, incidencias, bloqueada o no instalada.
Procedure ConfirmarPaquete(*paquete.PaquetePB, idAnterior.s, reemplazar.i, aceptarLimitacion.i=0, ofrecerCorreccion.i=0)
  Protected antigua.VersionPB, dato.VersionPB, identidad.s, bien, carpeta.s, teniaAnterior, mensaje.s
  ErrorActual=""
  If Not OperacionDisponible() : ProcedureReturn Politica::#NoInstalada : EndIf
  CopyStructure(@*paquete\Dato,@dato,VersionPB)
  teniaAnterior=LeerVersion(idAnterior,@antigua)
  If reemplazar
    If Not teniaAnterior Or antigua\Estado<>"disponible" Or Not Dentro(Canonica(antigua\Ruta),Hogar) Or VersionEnUso(antigua\Ruta) Or Dentro(dato\Origen,antigua\Ruta) Or dato\Origen=antigua\Ruta
      LimpiarPaquete(*paquete) : ProcedureReturn Fallar("No se puede sustituir esa instalación: cierra el IDE y usa un paquete situado fuera de su carpeta.")
    EndIf
    If Not Politica::LicenciaCompatible(antigua\Edicion,dato\Edicion)
      LimpiarPaquete(*paquete) : ProcedureReturn Fallar("La licencia del paquete no permite una sustitución segura. Instálalo por separado.")
    EndIf
    If Not RaizSinSolapamiento(antigua\Ruta,antigua\Id) Or Not VerificarContenido(@antigua)
      mensaje=ErrorActual : LimpiarPaquete(*paquete) : ProcedureReturn Fallar("La instalación anterior contiene cambios o no puede verificarse. Se conserva íntegra. "+mensaje)
    EndIf
  EndIf
  identidad=Etiqueta(@dato)+"/"+dato\Edicion
  If reemplazar And *paquete\Dato\Comprobada And Not Politica::PuedeSustituir(dato\Comprobada,dato\Limitacion,dato\Validacion,#MODO_PRUEBAS)
    ; Solo se reutiliza un resultado negativo para DENEGAR. Nunca para autorizar.
    bien=1
  ElseIf Not reemplazar And aceptarLimitacion And Not ofrecerCorreccion And dato\Comprobada
    ; Al aceptar conservar ambas tras el aviso no repetir la prueba temporal.
    ; La comprobacion definitiva y la integridad siguen siendo obligatorias.
    bien=1
  Else
    dato\Motor="AUTO"
    bien=VerificarVersion(@dato,1)
  EndIf
  If bien And identidad<>Etiqueta(@dato)+"/"+dato\Edicion : bien=Fallar("La identidad ejecutada no coincide con la detectada en el paquete.") : EndIf
  If Not Cancelacion() And ((bien And reemplazar And Not Politica::PuedeSustituir(dato\Comprobada,dato\Limitacion,dato\Validacion,#MODO_PRUEBAS)) Or (bien And Not reemplazar And dato\Limitacion<>"" And Not aceptarLimitacion) Or (ofrecerCorreccion And PuedeOfrecerCorreccion(@dato) And (Not bien Or dato\Limitacion<>"")))
    CopyStructure(@dato,@*paquete\Dato,VersionPB)
    If dato\Limitacion<>"" : ErrorActual=dato\Limitacion : EndIf : If ErrorActual="" : ErrorActual="La validación completa no está acreditada." : EndIf : ProcedureReturn Politica::#SustitucionBloqueada
  EndIf
  If bien And Not Cancelacion()
    ; El registro persistente nunca acredita la prueba definitiva antes del traslado.
    dato\Comprobada=0 : dato\Validacion="" : dato\Limitacion="Pendiente de validación en su ubicación definitiva."
    bien=PublicarVersion(@dato,NombreCarpeta(@dato))
  Else : bien=0
  EndIf
  LimpiarPaquete(*paquete)
  If Not bien
    ; PublicarVersion gestiona su propio manifiesto y diario.
    If ErrorActual="" : Fallar("No se pudo publicar la instalación nueva. La anterior no se ha borrado.") : EndIf
    ProcedureReturn Politica::#NoInstalada
  EndIf
  If Not Guardar(Estado+"/ultima.txt",dato\Id) : Fallar("No se pudo registrar la última instalación. No se ha borrado la anterior.") : ProcedureReturn Politica::#ConIncidencias : EndIf
  If Not OperacionDisponible() : Fallar("Existe una recuperación pendiente; se conserva la anterior.") : ProcedureReturn Politica::#ConIncidencias : EndIf
  ; El punto de publicacion ya paso: no se admite cancelacion durante la integracion.
  CambiarCancelacion(0)
  ; Todas las instalaciones se verifican tras el traslado, antes de publicar accesos.
  dato\Motor="AUTO"
  bien=VerificarVersion(@dato,1)
  If bien And identidad<>Etiqueta(@dato)+"/"+dato\Edicion : bien=Fallar("La identidad cambió en la ubicación definitiva.") : EndIf
  If bien : bien=VerificarContenido(@dato) : EndIf
  If bien : bien=ConfigurarMotorInicial(@dato) : EndIf
  If Not bien
    mensaje=ErrorActual
    dato\Comprobada=0 : dato\Validacion="" : dato\Limitacion="Falló la validación en la ubicación definitiva. "+mensaje
    GuardarVersion(@dato)
    Fallar("La carpeta nueva se conserva para revisión; no se han publicado sus accesos ni borrado la anterior. "+mensaje) : ProcedureReturn Politica::#ConIncidencias
  EndIf
  If dato\Limitacion<>"" And (reemplazar Or Not aceptarLimitacion) : dato\Comprobada=0 : EndIf
  If Not GuardarVersion(@dato) : ProcedureReturn Politica::#ConIncidencias : EndIf
  If reemplazar And Not Politica::PuedeSustituir(dato\Comprobada,dato\Limitacion,dato\Validacion,#MODO_PRUEBAS)
    Fallar("La comprobación definitiva mantiene limitaciones. Ambas instalaciones se conservan. "+dato\Limitacion) : ProcedureReturn Politica::#ConIncidencias
  EndIf
  If dato\Limitacion<>"" And Not aceptarLimitacion
    Fallar("La validación definitiva ha detectado una limitación no autorizada. Se conserva la carpeta para revisión, sin cambiar la predeterminada.") : ProcedureReturn Politica::#ConIncidencias
  EndIf
  If Not AccesosIndividuales() : ProcedureReturn Politica::#ConIncidencias : EndIf
  If reemplazar Or (Activa()="" And Not teniaAnterior And dato\Limitacion="")
    If dato\Limitacion<>"" : Fallar(dato\Limitacion) : ProcedureReturn Politica::#ConIncidencias : EndIf
    If Not Activar(dato\Id,0,0,1) : ProcedureReturn Politica::#ConIncidencias : EndIf
    If Not AccesosIndividuales() : ProcedureReturn Politica::#ConIncidencias : EndIf
  EndIf
  If reemplazar
    If Not RetirarRecuperable(antigua\Id) : ProcedureReturn Politica::#ConIncidencias : EndIf
  EndIf
  ErrorActual=dato\Limitacion
  If dato\Limitacion<>""
    Registrar("Instalada con limitación: "+dato\Limitacion)
    ProcedureReturn Politica::#InstaladaLimitada
  EndIf
  Registrar("Instalada: "+dato\Ruta)
  ProcedureReturn Politica::#Instalada
EndProcedure

Procedure DetectarCarpetas(carpeta.s)
  Protected listado=ExamineDirectory(#PB_Any,carpeta,"*"), ruta.s, nombre.s
  If listado
    While NextDirectoryEntry(listado)
      nombre=DirectoryEntryName(listado)
      If Left(nombre,1)="." Or DirectoryEntryType(listado)<>#PB_DirectoryEntry_Directory : Continue : EndIf
      ruta=carpeta+"/"+nombre
      If Canonica(ruta)=ruta And ELFValido(ruta+"/compilers/pbcompiler") And ELFValido(ruta+"/compilers/purebasic")
        RegistrarExistente(ruta)
      EndIf
    Wend
    FinishDirectory(listado)
  EndIf
EndProcedure
