; Casos de uso de mantenimiento: no dependen de gadgets ni de decisiones de UI.
Procedure AccesoActivoPropio(texto.s)
  ProcedureReturn Bool(ValorDesktop(texto,"Type")="Application" And ValorDesktop(texto,"X-GestorPureBasic-Acceso")="true" And FindString(texto,"# "+#MARCA_GESTOR+#LF$) And ValorDesktop(texto,"Exec")=CitarDesktop(EjecutableGestor)+" --perfil "+CitarDesktop(Hogar)+" --abrir-activa %F")
EndProcedure

Procedure PlanRetiradaAccesos(*dato.VersionPB,List accesos.AccesoPB())
  Protected carpeta.s, origen.s=*dato\Ruta, listado, ruta.s, texto.s, comando.s, indice, activa.i=Bool(LeerTexto(Estado+"/activa.txt")=*dato\Id)
  If *dato\Estado<>"disponible" : origen=*dato\RutaRetirada : If origen="" And *dato\Tipo="externa" : origen=*dato\Origen : EndIf : EndIf
  ; Una carpeta antigua recreada puede ser otra instalación; no retirar sus accesos.
  If *dato\Estado<>"disponible" And origen<>"" And TipoArchivo(origen)<>0 : origen="" : EndIf
  If origen<>"" And *dato\Estado<>"disponible"
    If (*dato\Tipo="externa" And origen<>*dato\Origen) Or (*dato\Tipo="gestionada" And RTrim(GetPathPart(origen),"/")<>Almacen+"/versiones") : origen="" : EndIf
  EndIf
  For indice=0 To 1
    If indice=0 : carpeta=Datos+"/applications" : Else : carpeta=EscritorioUsuario() : EndIf
    If carpeta="" Or TipoArchivo(carpeta)=0 : Continue : EndIf
    If Canonica(carpeta)<>carpeta : ProcedureReturn Fallar("No se puede comprobar la carpeta de accesos: "+carpeta) : EndIf
    listado=ExamineDirectory(#PB_Any,carpeta,"*.desktop")
    If Not listado : ProcedureReturn Fallar("No se puede leer la carpeta de accesos: "+carpeta) : EndIf
    While NextDirectoryEntry(listado)
      ruta=carpeta+"/"+DirectoryEntryName(listado)
      If TipoArchivo(ruta)<>32768 Or FileSize(ruta)>65536 : Continue : EndIf
      texto=LeerTexto(ruta)
      If AccesoIndividualPropio(texto,*dato\Id) Or (activa And AccesoActivoPropio(texto))
        AgregarAcceso(accesos(),ruta,"",420+73*indice)
      ElseIf origen<>"" And Dentro(origen,Hogar)
        comando=ComandoDesktop(texto,carpeta)
        If comando="" : comando=ComandoDesktop(texto,carpeta,1) : EndIf
        If comando=origen+"/compilers/purebasic" : AgregarAcceso(accesos(),ruta,"",420+73*indice) : EndIf
      EndIf
    Wend
    FinishDirectory(listado)
  Next
  ProcedureReturn #True
EndProcedure

Procedure LimpiarIntegracionVersion(*dato.VersionPB)
  Protected NewList accesos.AccesoPB(), NewList rutas.s(), activa.i=Bool(LeerTexto(Estado+"/activa.txt")=*dato\Id), anterior.i=Bool(LeerTexto(Estado+"/anterior.txt")=*dato\Id), bien.i=#True
  If Not PlanRetiradaAccesos(*dato,accesos()) : ProcedureReturn #False : EndIf
  If ListSize(accesos()) And Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  If activa : AddElement(rutas()) : rutas()=Estado+"/activa.txt" : EndIf
  If anterior : AddElement(rutas()) : rutas()=Estado+"/anterior.txt" : EndIf
  If ListSize(rutas())=0 : ProcedureReturn #True : EndIf
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=PublicarAccesos(accesos())
  If bien And activa : bien=Guardar(Estado+"/activa.txt","") : EndIf
  If bien And anterior : bien=Guardar(Estado+"/anterior.txt","") : EndIf
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se pudo retirar toda la integración. La versión retirada sigue recuperable.") : EndIf
  ProcedureReturn #True
EndProcedure

Procedure ConservarPerfilRetirado(*dato.VersionPB)
  Protected ruta.s=RutaPerfil(*dato), destino.s
  If ruta="" : ProcedureReturn #True : EndIf
  If TipoArchivo(ruta)=0 : ProcedureReturn #True : EndIf
  If Canonica(ruta)<>ruta Or TipoArchivo(ruta)<>16384 : ProcedureReturn Fallar("El perfil personal no es una carpeta segura. Se conserva.") : EndIf
  destino=Estado+"/copias/perfil-retirado-"+*dato\Id
  If Canonica(Estado+"/copias")<>Estado+"/copias" Or RenombrarSinReemplazo(-100,ruta,-100,destino,1)<>0 : ProcedureReturn Fallar("No se pudo conservar el perfil personal. No se ha borrado la instalación retirada.") : EndIf
  If Not SincronizarMovimiento(ruta,destino) : ProcedureReturn #False : EndIf
  Registrar("Perfil personal conservado en: "+destino)
  ProcedureReturn #True
EndProcedure

; Retirada ordinaria: no elimina el SDK ni su perfil. La purga exige otra decisión.
Procedure RetirarRecuperable(id.s)
  Protected fd=BloqueoVersion(id,1), dato.VersionPB,bien
  If fd<0 : ProcedureReturn #False : EndIf
  If OperacionDisponible() And LeerVersion(id,@dato) And dato\Estado="disponible"
    bien=Retirar(id,1)
    If bien And LeerVersion(id,@dato) : bien=LimpiarIntegracionVersion(@dato) : Else : bien=#False : EndIf
  Else
    Fallar("No se puede retirar la versión o hay una recuperación pendiente.")
  EndIf
  CerrarNativo(fd) : ProcedureReturn bien
EndProcedure
Procedure DesinstalarVersionInterna(id.s, autorizarExterna.i=0)
  Protected dato.VersionPB
  ErrorActual=""
  If Not LeerVersion(id,@dato) : ProcedureReturn Fallar("Selecciona una instalación registrada.") : EndIf
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If dato\Estado="disponible" : ProcedureReturn Fallar("Retira primero la versión. El borrado definitivo exige una segunda operación independiente.") : EndIf
  If dato\Tipo<>"gestionada" And (dato\Tipo<>"externa" Or Not autorizarExterna) : ProcedureReturn Fallar("Instalación importada: revisa y respalda los archivos personales antes de autorizar expresamente su purga.") : EndIf
  If dato\Estado<>"retirada" : ProcedureReturn Fallar("No se permite continuar un borrado parcial automáticamente.") : EndIf
  If dato\Ruta<>Almacen+"/retiradas/"+id Or Not RaizSinSolapamiento(dato\Ruta,id) Or VersionEnUso(dato\Ruta) Or Not VerificarContenido(@dato) : ProcedureReturn Fallar("No se acredita una retirada segura. No se borrará su contenido. "+ErrorActual) : EndIf
  If Not LimpiarIntegracionVersion(@dato) Or Not ConservarPerfilRetirado(@dato) : ProcedureReturn #False : EndIf
  ProcedureReturn BorrarDefinitivamente(id,autorizarExterna)
EndProcedure

Procedure DesinstalarVersion(id.s, autorizarExterna.i=0)
  Protected fd=BloqueoVersion(id,1), bien
  If fd<0 : ProcedureReturn #False : EndIf
  bien=DesinstalarVersionInterna(id,autorizarExterna)
  CerrarNativo(fd) : ProcedureReturn bien
EndProcedure

Procedure RestaurarVersionRetiradaInterna(id.s)
  Protected dato.VersionPB, ruta.s, copia.s, destino.s
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If Not LeerVersion(id,@dato) Or dato\Estado<>"retirada" : ProcedureReturn Fallar("Selecciona una versión retirada.") : EndIf
  If dato\Ruta<>Almacen+"/retiradas/"+id Or Canonica(dato\Ruta)<>dato\Ruta : ProcedureReturn Fallar("La carpeta retirada no corresponde al identificador.") : EndIf
  destino=dato\RutaRetirada
  If destino=""
    If dato\Tipo="externa" : destino=dato\Origen : Else : destino=Almacen+"/versiones/"+id : EndIf
  EndIf
  If Not RutaDisponibleValida(@dato,destino) Or TipoArchivo(destino)<>0 Or Not VerificarContenido(@dato) : ProcedureReturn Fallar("No se puede restaurar la carpeta; se conserva también el perfil.") : EndIf
  ruta=RutaPerfil(@dato) : copia=Estado+"/copias/perfil-retirado-"+id
  If ruta<>"" And TipoArchivo(copia)<>0
    If TipoArchivo(ruta)<>0 Or Canonica(copia)<>copia Or TipoArchivo(copia)<>16384 Or Canonica(Estado+"/perfiles")<>Estado+"/perfiles" Or RenombrarSinReemplazo(-100,copia,-100,ruta,1)<>0
      ProcedureReturn Fallar("No se pudo recuperar el perfil personal. Se conserva la carpeta retirada.")
    EndIf
    If Not SincronizarMovimiento(copia,ruta) : ProcedureReturn #False : EndIf
  EndIf
  ProcedureReturn Restaurar(id)
EndProcedure

Procedure RestaurarVersionRetirada(id.s)
  Protected fd=BloqueoVersion(id,1), bien
  If fd<0 : ProcedureReturn #False : EndIf
  bien=RestaurarVersionRetiradaInterna(id)
  CerrarNativo(fd) : ProcedureReturn bien
EndProcedure

Procedure CrearAccesoVersionInterna(id.s, verificar.i=1)
  Protected dato.VersionPB, NewList accesos.AccesoPB(), NewList rutas.s(), escritorio.s=EscritorioUsuario(), bien, repetidas=0
  ErrorActual=""
  If Not OperacionDisponible() : ProcedureReturn #False : EndIf
  If escritorio="" : ProcedureReturn Fallar("No hay un escritorio habilitado dentro de tu carpeta personal.") : EndIf
  If Not LeerVersion(id,@dato) Or dato\Estado<>"disponible" Or Not EstructuraValida(dato\Ruta) : ProcedureReturn Fallar("Selecciona una instalación disponible.") : EndIf
  If Not VerificarContenido(@dato) : ProcedureReturn #False : EndIf
  If verificar And Not dato\Comprobada
    If VersionEnUso(dato\Ruta) : ProcedureReturn Fallar("Cierra PureBasic antes de validar esta instalación.") : EndIf
    dato\Motor="AUTO"
    If Not VerificarVersion(@dato) : ProcedureReturn #False : EndIf
    If dato\Limitacion<>"" : ProcedureReturn Fallar("La instalación no está validada completamente. No se creará un acceso sin aceptar expresamente la limitación. "+dato\Limitacion) : EndIf
    If Not ConfigurarMotorInicial(@dato) Or Not VerificarContenido(@dato) Or Not GuardarVersion(@dato) : ProcedureReturn #False : EndIf
  EndIf
  If Not dato\Comprobada : ProcedureReturn Fallar("La instalación aún no está comprobada.") : EndIf
  If Not PrepararEjecutable() : ProcedureReturn #False : EndIf
  CargarVersiones()
  ForEach Versiones()
    If Versiones()\Estado="disponible" And Etiqueta(@Versiones())=Etiqueta(@dato) And Versiones()\Edicion=dato\Edicion : repetidas+1 : EndIf
  Next
  If Not PlanIndividual(@dato,accesos(),0,repetidas) Or Not RespaldarAccesos(accesos()) : ProcedureReturn #False : EndIf
  ForEach accesos() : AddElement(rutas()) : rutas()=accesos()\Ruta : Next
  If Not IniciarTransaccion(rutas()) : ProcedureReturn #False : EndIf
  bien=PublicarAccesos(accesos())
  If bien : bien=ConfirmarTransaccion() : EndIf
  If Not bien : RecuperarTransaccion() : ProcedureReturn Fallar("No se pudo crear el acceso. Se conserva el estado anterior.") : EndIf
  MarcarAccesos(accesos()) : ErrorActual=dato\Limitacion
  ProcedureReturn #True
EndProcedure

Procedure CrearAccesoVersion(id.s, verificar.i=1)
  Protected fd=BloqueoVersion(id,1), bien
  If fd<0 : ProcedureReturn #False : EndIf
  bien=CrearAccesoVersionInterna(id,verificar)
  CerrarNativo(fd) : ProcedureReturn bien
EndProcedure
